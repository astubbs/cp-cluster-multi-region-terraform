# EU (Ireland)  eu-west-1
# EU (London) eu-west-2
# EU (Frankfurt) eu-central-1


variable "my-region" {
  default = "eu-west-1"
}

variable "owner" {
  default = "astubbs"
}

variable "ownershort" {
  default = "as"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "myip" { }

# resource "aws_instance" "example" {
#   ami           = "${var.ami}"
#   instance_type = "t2.micro"
#   # security_groups = ["follower-cluster"]
#   key_name = "tony-follower-cluster-london"
#   count = 1
#   # associate_public_ip_address = true
#   tags {
#     Name = "terraform-example"
#     Owner = "astubbs"
#     sshUser = "ubuntu"
#   }
  
#   # provisioner "local-exec" {
#   #   command = "echo ${aws_instance.example.public_ip} > ip_address.txt"
#   # }
# }





# resource "aws_security_group" "follower-cluster" {
#   # description = "follower-cluster - Managed by Terraform"
#   name = "follower-cluster"

#   # all
#   # ingress {
#   #     from_port = 0
#   #     to_port = 0
#   #     protocol = "-1"
#   #     cidr_blocks = ["0.0.0.0/0"]
#   # }

#   # cluster
#   ingress {
#       from_port = 0
#       to_port = 0
#       protocol = "-1"
#       self = true
#       cidr_blocks = ["54.154.77.0/24"]
#   }

#   # Allow ping from anywhere
#   ingress {
#     from_port = 8
#     to_port = 0
#     protocol = "icmp"
#     cidr_blocks = ["${var.myip}"]
#   }

#   # ssh
#   ingress {
#       from_port = 22
#       to_port = 22
#       protocol = "TCP"
#       cidr_blocks = ["${var.myip}"]
#   }

#   # from bastion
#   ingress {
#       from_port = 22
#       to_port = 22
#       protocol = "TCP"
#       security_groups = ["${aws_security_group.bastions.id}"] 
#   }

#   egress {
#       from_port = 0
#       to_port = 0
#       protocol = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#   }
# }


# resource "aws_security_group" "lead-cluster" {
#   # description = "follower-cluster - Managed by Terraform"
#   name = "lead-cluster"

#    # cluster
#   ingress {
#       from_port = 0
#       to_port = 0
#       protocol = "-1"
#       self = true
#       cidr_blocks = ["54.154.77.0/24"]
#   }

#   # Allow ping from anywhere
#   ingress {
#     from_port = 8
#     to_port = 0
#     protocol = "icmp"
#     cidr_blocks = ["${var.myip}"]
#   }

#   # ssh
#   ingress {
#       from_port = 22
#       to_port = 22
#       protocol = "TCP"
#       cidr_blocks = ["${var.myip}"]
#   }

#   # from bastion
#   ingress {
#       from_port = 22
#       to_port = 22
#       protocol = "TCP"
#       security_groups = ["${aws_security_group.bastions.id}"] 
#   }

#   egress {
#       from_port = 0
#       to_port = 0
#       protocol = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#   }
# }




// Elastic IPS

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


# // Cluster Nodes
# resource "aws_instance" "euwest1-brokers" {
#   count = 2
#   ami           = "${var.ami}"
#   instance_type = "${var.instance_type}"
#   availability_zone = "${element(var.azs, count.index)}"
#   security_groups = ["${aws_security_group.follower-cluster.name}"]
#   key_name = "${var.key_name}"
#   tags {
# 	  Name = "as-k-${count.index}-${element(var.azs, count.index)}"
#     nice-name = "kafka-${count.index}"
#     big-nice-name = "follower-kafka-${count.index}"
# 	  role = "broker"
#   	owner = "${var.owner}"
#     sshUser = "ubuntu"
#     # ansible_python_interpreter = "/usr/bin/python3"
#     sshPrivateIp = true
#     #EntScheduler = "mon,tue,wed,thu,fri;1600;mon,tue,wed,thu;fri;sat;0400;"
#   }
# }


# resource "aws_instance" "euwest1-bastion" {
#   count = 1
#   ami           = "${var.ami}"
#   instance_type = "t2.micro"
#   availability_zone = "eu-west-2b"
#   security_groups = ["${aws_security_group.bastions.name}"]
#   key_name = "${var.key_name}"
#   tags {
#     name = "${var.ownershort}as-b-${count.index}-${element(var.azs, count.index)}"
#     nice-name = "bastion-0"
#     big-nice-name = "bastion-0"
#     role = "bastion"
#     owner = "${var.owner}"
#     sshUser = "ubuntu"
#     # ansible_python_interpreter = "/usr/bin/python3"
#   }
# }


# resource "aws_instance" "euwest1-zookeeper" {
#   count = 1
#   ami           = "${var.ami}"
#   instance_type = "${var.instance_type}"
#   availability_zone = "${element(var.azs, count.index)}"
#   security_groups = ["${aws_security_group.follower-cluster.name}"]
#   key_name = "${var.key_name}"
#   tags {
# 	  Name = "${var.ownershort}-zk-${count.index}-${element(var.azs, count.index)}"
#     nice-name = "zk-${count.index}"
#     big-nice-name = "follower-zk-${count.index}"
# 	  role = "zookeeper"
#   	owner = "${var.owner}"
#     sshUser = "ubuntu"
#     sshPrivateIp = true
#     # ansible_python_interpreter = "/usr/bin/python3"
#   }
# }

# module "frankfurt-cluster" {
#     source = "./confluent"
#     broker-count = 10
#     zk-count = 3
#     connect-count = 2
#     name = "frankfurt-cluster"
#     region = "eu-central-1"
#     azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
#     owner = "${var.owner}"
#     ownershort = "${var.ownershort}"
#     key_name = "antony-frankfurt"
# }

module "ireland-cluster" {
    source = "./confluent"
    broker-count = 5
    zk-count = 3
    connect-count = 2
    name = "frankfurt-cluster"
    region = "eu-west-1"
    azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    owner = "${var.owner}"
    ownershort = "${var.ownershort}"
    key_name = "antony-ireland"
    myip = "${var.myip}"
}

