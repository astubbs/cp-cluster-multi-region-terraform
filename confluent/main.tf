variable "name" {}

variable "region" {}
variable "owner" {}
variable "ownershort" {}

variable "zk-count" {
  default = 1
}
variable "broker-count" {
  default = 1
}
variable "connect-count" {
  default = 1
}


provider "aws" {
  region = "${var.region}"
}

variable "key_name" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# variable "ami" {
#   # default = "ami-57eae033" # us-west-2 ubuntu
#   # default = "ami-960316f2"
#   default = "${data.aws_ami.ubuntu.id}"
# }

variable "instance_type" {
  default = "t2.medium"
}

variable "azs" {
  description = "Run the EC2 Instances in these Availability Zones"
  type = "list"
}

variable "myip" { default = "217.138.75.100/32" }


resource "aws_security_group" "bastions" {
  name = "${var.ownershort}-bastions"
  # description = "follower-cluster - Managed by Terraform"
  # description = "follower-cluster"

  # Allow ping from anywhere
  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["${var.myip}"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      self = true
      # cidr_blocks = ["${var.myip}"]
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ssh" {
  description = "Managed by Terraform"
  name = "${var.ownershort}-ssh"

  # Allow ping from anywhere
  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["${var.myip}"]
  }

  # ssh
  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      cidr_blocks = ["${var.myip}"]
  }

  # from bastion
  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      security_groups = ["${aws_security_group.bastions.id}"] 
  }

  # ssh from anywhere
  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      self = true
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "brokers" {
  description = "brokers - Managed by Terraform"
  name = "${var.ownershort}-brokers"

   # cluster
  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      self = true
      cidr_blocks = ["54.154.77.0/24"]
  }

  # Allow ping from anywhere
  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["${var.myip}"]
  }

  # ssh
  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      cidr_blocks = ["${var.myip}"]
  }

  # from bastion
  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      security_groups = ["${aws_security_group.bastions.id}"] 
  }

  # ssh from anywhere
  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      self = true
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_eip" "bastion" {
#   instance = "${aws_instance.euwest1-bastion.0.id}"
#   vpc      = true
# }

# resource "aws_eip" "broker-0" {
#   instance = "${aws_instance.euwest1-brokers.0.id}"
#   vpc      = true
# }

# # resource "aws_eip" "broker-1" {
# #   instance = "${aws_instance.euwest1-brokers.1.id}"
# #   vpc      = true
# # }

# resource "aws_eip" "zookeeper-0" {
#   instance = "${aws_instance.euwest1-zookeeper.0.id}"
#   vpc      = true
# }





resource "aws_instance" "bastion" {
  count = 1
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  availability_zone = "${element(var.azs, 0)}"
  security_groups = ["${aws_security_group.bastions.name}"]
  key_name = "${var.key_name}"
  tags {
    Name = "${var.ownershort}-bastion-${count.index}-${element(var.azs, count.index)}"
    description = "bastion node - Managed by Terraform"
    nice-name = "bastion-0"
    big-nice-name = "bastion-0"
    role = "bastion"
    owner = "${var.owner}"
    sshUser = "ubuntu"
    # ansible_python_interpreter = "/usr/bin/python3"
  }
}

resource "aws_instance" "brokers" {
  count         = "${var.broker-count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  availability_zone = "${element(var.azs, count.index)}"
  # security_groups = ["${var.security_group}"]
  security_groups = ["${aws_security_group.brokers.name}", "${aws_security_group.ssh.name}"]
  key_name = "${var.key_name}"
  tags {
    Name = "${var.ownershort}-broker-${count.index}-${element(var.azs, count.index)}"
    description = "broker nodes - Managed by Terraform"
    nice-name = "kafka-${count.index}"
    big-nice-name = "follower-kafka-${count.index}"
    brokerid = "${count.index}"
    role = "broker"
    owner = "${var.owner}"
    sshUser = "ubuntu"
    # sshPrivateIp = true // this is only checked for existence, not if it's true or false by terraform.py (ati)
    createdBy = "terraform"
    # ansible_python_interpreter = "/usr/bin/python3"
    #EntScheduler = "mon,tue,wed,thu,fri;1600;mon,tue,wed,thu;fri;sat;0400;"
  }
}

resource "aws_instance" "zookeeper" {
  count         = "${var.zk-count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  availability_zone = "${element(var.azs, count.index)}"
  security_groups = ["${aws_security_group.ssh.name}"]
  key_name = "${var.key_name}"
  tags {
    Name = "${var.ownershort}-zookeeper-${count.index}-${element(var.azs, count.index)}"
    description = "zookeeper nodes - Managed by Terraform"
    role = "zookeeper"
    Owner = "${var.owner}"
    sshUser = "ubuntu"
  }
}

resource "aws_instance" "connect-cluster" {
  count         = "${var.connect-count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  availability_zone = "${element(var.azs, count.index)}"
  security_groups = ["${aws_security_group.ssh.name}"]
  key_name = "${var.key_name}"
  tags {
    Name = "${var.ownershort}-connect-${count.index}-${element(var.azs, count.index)}"
    description = "Connect nodes - Managed by Terraform"
    role = "connect"
    Owner = "${var.owner}"
    sshUser = "ubuntu"
  }
}


// Output
output "public_ips" {
  value = ["${aws_instance.brokers.*.public_ip}"]
}
output "public_dns" {
  value = ["${aws_instance.brokers.*.public_dns}"]
}
output "bastion_ip" {
  value = ["${aws_instance.bastion.public_dns}"]
}
