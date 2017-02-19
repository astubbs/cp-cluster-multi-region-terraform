variable "b-count" {}

variable "name" {}

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

variable "myip" { default = "90.207.16.137/32" }

variable "key_name" {
  default = "tony-follower-cluster-london"
}


resource "aws_security_group" "cluster" {
  # description = "follower-cluster - Managed by Terraform"
  name = "${var.name}-follower-cluster"

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

  # # from bastion
  # ingress {
  #     from_port = 22
  #     to_port = 22
  #     protocol = "TCP"
  #     security_groups = ["${aws_security_group.bastions.id}"] 
  # }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "brokers" {
  count = "${var.b-count}"
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  availability_zone = "${element(var.azs, count.index)}"
  security_groups = ["${aws_security_group.cluster.name}"]
  key_name = "${var.key_name}"

  tags {
    Name = "${var.name}-k-${count.index}-${element(var.azs, count.index)}"
    nice-name = "kafka-${count.index}"
    big-nice-name = "follower-kafka-${count.index}"
    Role = "broker"
    Owner = "${var.owner}"
    sshUser = "ubuntu"
    ansible_python_interpreter = "/usr/bin/python3"
    #EntScheduler = "mon,tue,wed,thu,fri;1600;mon,tue,wed,thu;fri;sat;0400;"
  }
}