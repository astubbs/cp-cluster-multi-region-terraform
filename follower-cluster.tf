# provider "aws" {
#   access_key =
#   secret_key =
#   region     = "eu-west-2"
# }


variable "my-region" {
  default = "eu-west-2"
}

variable "owner" {
  default = "astubbs"
}

variable "ami" {
  default = "ami-57eae033"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "azs" {
  description = "Run the EC2 Instances in these Availability Zones"
  type = "list"
  default = ["eu-west-2a", "eu-west-2b"]
}





resource "aws_instance" "example" {
  ami           = "${var.ami}"
  instance_type = "t2.micro"
  security_groups = ["follower-cluster"]
  key_name = "tony-follower-cluster-london"
  tags {
    Name = "terraform-example"
    Owner = "astubbs"
  }
  
  provisioner "local-exec" {
    command = "echo ${aws_instance.example.public_ip} > ip_address.txt"
  }
}





resource "aws_security_group" "follower-cluster" {
  # description = "follower-cluster - Managed by Terraform"
  description = "follower-cluster"

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["54.154.77.0/24"]
      security_groups = ["sg-5f10dd36"] //(bastion-london)
      # source_security_group_id = ["sg-5f10dd36"] //(bastion-london)
  }

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      security_groups = ["sg-5f10dd36"] //(bastion-london)
      cidr_blocks = ["54.154.77.0/24"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      # prefix_list_ids = ["pl-12c4e678"]
  }
}

# resource "aws_security_group_rule" "follower-cluster" {}
# resource "aws_security_group_rule" "follower-cluster-1" {}
# resource "aws_security_group_rule" "follower-cluster-2" {}


// Elastic IPS

resource "aws_eip" "bastion-0" {
  instance = "${aws_instance.euwest1-bastion.0.id}"
  vpc      = true
}

resource "aws_eip" "broker-0" {
  instance = "${aws_instance.euwest1-brokers.0.id}"
  vpc      = true
}

resource "aws_eip" "broker-1" {
  instance = "${aws_instance.euwest1-brokers.1.id}"
  vpc      = true
}

resource "aws_eip" "zookeeper-0" {
  instance = "${aws_instance.euwest1-zookeeper.0.id}"
  vpc      = true
}




// Cluster Nodes

resource "aws_instance" "euwest1-brokers" {
  count = 2
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  availability_zone = "${element(var.azs, count.index)}"
  # security_groups = ["follower-cluster"]
  tags {
	  Name = "as-broker-${count.index}-${element(var.azs, count.index)}"
	  Role = "broker"
  	Owner = "${var.owner}"
    #EntScheduler = "mon,tue,wed,thu,fri;1600;mon,tue,wed,thu;fri;sat;0400;"
  }
}

resource "aws_instance" "euwest1-bastion" {
  count = 1
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  availability_zone = "eu-west-2b"
  # security_groups = ["follower-cluster"]
  tags {
	  Name = "as-bastion-${count.index}-${element(var.azs, count.index)}"
	  Role = "bastion"
  	Owner = "${var.owner}"
  }
}

resource "aws_instance" "euwest1-zookeeper" {
  count = 1
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  availability_zone = "${element(var.azs, count.index)}"
  # security_groups = ["follower-cluster"]
  tags {
	  Name = "as-zookeeper-${count.index}-${element(var.azs, count.index)}"
	  Role = "zookeeper"
  	Owner = "${var.owner}"
  }
}


// Output

output "public_ips" {
  value = ["${aws_instance.euwest1-brokers.*.public_ip}"]
}
output "public_dns" {
  value = ["${aws_instance.euwest1-brokers.*.public_dns}"]
}
output "security_groups" {
  value = ["${aws_instance.euwest1-brokers.*.security_groups}"]
}
output "first_ip" {
  value = ["${aws_instance.euwest1-brokers.0.public_ip}"]
}