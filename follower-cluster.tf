# provider "aws" {
#   access_key =
#   secret_key =
#   region     = "eu-west-2"
# }

resource "aws_instance" "example" {
  ami           = "${var.ami}"
  instance_type = "t2.micro"
  tags{  Name = "terraform-example"
Owner = "astubbs"}

provisioner "local-exec" {
    command = "echo ${aws_instance.example.public_ip} > ip_address.txt"
  }

  key_name = "tony-follower-cluster-london"
}

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

resource "aws_instance" "euwest1-brokers" {
  count = 2
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  availability_zone = "${element(var.azs, count.index)}"
  tags {
	Name = "as-broker-${count.index}-${element(var.azs, count.index)}"
	Role = "broker"
  	Owner = "${var.owner}"
  }
}

resource "aws_instance" "euwest1-bastion" {
  count = 1
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  availability_zone = "eu-west-2b"
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
  tags {
	Name = "as-zookeeper-${count.index}-${element(var.azs, count.index)}"
	Role = "zookeeper"
  	Owner = "${var.owner}"
  }
}


output "public_ips" {
  value = ["${aws_instance.example.*.public_ip}"]
}
output "first_ip" {
  value = ["${aws_instance.example.0.public_ip}"]
}