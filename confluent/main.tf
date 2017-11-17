variable "b-count" {}

variable "name" {}
variable "role" {}

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

variable "security_group" {
  default = "tony-follower-cluster-london"
}

resource "aws_instance" "brokers" {
  count = "${var.b-count}"
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  availability_zone = "${element(var.azs, count.index)}"
  security_groups = ["${var.security_group}"]
  key_name = "${var.key_name}"

  tags {
    Name = "${var.name}-k-${count.index}-${element(var.azs, count.index)}"
    nice-name = "kafka-${count.index}"
    big-nice-name = "follower-kafka-${count.index}"
    role = "${var.role}"
    owner = "${var.owner}"
    sshUser = "ubuntu"
    sshPrivateIp = true
    createdBy = "terraform"
    # ansible_python_interpreter = "/usr/bin/python3"
    #EntScheduler = "mon,tue,wed,thu,fri;1600;mon,tue,wed,thu;fri;sat;0400;"
  }
}