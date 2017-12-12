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
variable "c3-count" {}

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

# variable "instance_type" {
#   default = "t2.medium"
# }

# T2 Medium t2.medium 4.0 GiB 2 vCPUs for a 4h 48m burst  EBS only  Low to Moderate $0.050000 hourly
# T2 Large  t2.large  8.0 GiB 2 vCPUs for a 7h 12m burst  EBS only  Low to Moderate $0.100800 hourly
# M5 General Purpose Extra Large m5.xlarge 16.0 GiB  4 vCPUs EBS only  High  $0.214000 hourly
# M5 General Purpose Double Extra Large m5.2xlarge  32.0 GiB  8 vCPUs EBS only  High  $0.428000 hourly

# # strong high performance images
locals {
  bastion-instance-type = "m4.xlarge"
  zk-instance-type = "m4.xlarge"
  connect-instance-type = "m4.xlarge"
  broker-instance-type = "m4.xlarge"
  c3-instance-type = "m4.xlarge"
  client-instance-type = "m4.xlarge"
  monitoring-instance-type = "m4.xlarge"
}

# # strong high performance images
# locals {
#   bastion-instance-type = "t2.2xlarge"
#   zk-instance-type = "i3.large" # I3 High I/O Large i3.large  15.25 GiB 2 vCPUs 475 GiB NVMe SSD  Up to 10 Gigabit  $0.172000 hourly
#   # c5.2xlarge not available in c4
#   # connect-instance-type = "c5.2xlarge" # C5 High-CPU Double Extra Large c5.2xlarge  16.0 GiB  8 vCPUs EBS only  Up to 10 Gbps $0.384000 hourly\
#   connect-instance-type = "c4.2xlarge"  # C4 High-CPU Double Extra Large c4.2xlarge  15.0 GiB  8 vCPUs EBS only  High  $0.454000 hourly
#   broker-instance-type = "r4.2xlarge" # 61.0 GiB  8 vCPUs EBS only  Up to 10 Gigabit $0.593000 hourly
#   c3-instance-type = "i3.4xlarge"  # 122.0 GiB 16 vCPUs  3800 GiB (2 * 1900 GiB NVMe SSD)  Up to 10 Gigabit  $1.376000 hourly
#   client-instance-type = "r4.large" # R4 High-Memory Large  r4.large  15.25 GiB 2 vCPUs EBS only  Up to 10 Gigabit  $0.148000 hourly
#   monitoring-instance-type = "m4.xlarge"
# }

# testing instance sizes - t2.medium 4.0 GiB 2 vCPUs for a 4h 48m burst  EBS only  Low to Moderate $0.050000 hourly
# locals {
#   bastion-instance-type = "t2.large"
#   zk-instance-type = "t2.large"
#   connect-instance-type = "t2.large"
#   broker-instance-type = "t2.large"
#   c3-instance-type = "t2.large"
#   client-instance-type = "t2.large"
#   monitoring-instance-type = "t2.large"
# }

locals {
  brokers-eu-west-one = "0.0.0.0/0" # need to lock this down
  brokers-eu-central-one = "0.0.0.0/0" # need to lock this down
  brokers-all = "0.0.0.0/0" # need to lock this down
}

variable "azs" {
  description = "Run the EC2 Instances in these Availability Zones"
  type = "list"
}

variable "myip" { }
locals {
  myip-cidr = "${var.myip}/32"
}


resource "aws_security_group" "bastions" {
  name = "${var.ownershort}-bastions"
  # description = "follower-cluster - Managed by Terraform"
  # description = "follower-cluster"

  # Allow ping from my ip
  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["${local.myip-cidr}"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      self = true
      cidr_blocks = ["${local.myip-cidr}"]
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

  # Allow ping from my ip and self
  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    self = true
    cidr_blocks = ["${local.myip-cidr}"]
  }

  # ssh from me and self
  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      self = true
      cidr_blocks = ["${local.myip-cidr}"]
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
  }

  # allow clients from anywhere - temporary for follower cluster in frankfurt - should get their submet range from terraform
  # 9092-9095 for all broker protocols
  ingress {
      from_port = 9092
      to_port = 9096
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
  }

  # client connections from ssh hosts, connect, my ip, clients
  ingress {
      from_port = 9092
      to_port = 9092
      protocol = "TCP"
      self = true
      cidr_blocks = ["${local.myip-cidr}"]
      security_groups = ["${aws_security_group.ssh.id}", "${aws_security_group.connect.id}"] # should an explicit group for clients, ssh covers it
  }

  # Allow ping from my ip, self, bastion
  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    self = true
    security_groups = ["${aws_security_group.bastions.id}"]
    cidr_blocks = ["${local.myip-cidr}"]
  }

  # from bastion
  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      security_groups = ["${aws_security_group.bastions.id}"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "zookeepers" {
  description = "Zookeeper security group - Managed by Terraform"
  name = "${var.ownershort}-zookeepers"

  ingress {
      from_port = 2181
      to_port = 2181
      protocol = "TCP"
      security_groups = ["${aws_security_group.brokers.id}", "${aws_security_group.connect.id}"]
      cidr_blocks = ["${local.myip-cidr}", "0.0.0.0/0"] # zk needs to be accessible from target cluster in frankfurt
  }

  ingress {
      from_port = 2888
      to_port = 2888
      protocol = "TCP"
      self = true
  }

  ingress {
      from_port = 3888
      to_port = 3888
      protocol = "TCP"
      self = true
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "c3" {
  description = "C3 security group - Managed by Terraform"
  name = "${var.ownershort}-c3"

  # web ui
  ingress {
      from_port = 9021
      to_port = 9021
      protocol = "TCP"
      cidr_blocks = ["${local.myip-cidr}"]
  }

  # KDC server hack
  # TODO lock this down
  ingress {
      from_port = 88
      to_port = 88
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port = 88
      to_port = 88
      protocol = "UDP"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "connect" {
  description = "Connect security group - Managed by Terraform"
  name = "${var.ownershort}-connect"

  # connect http interface - only accessable on host, without this
  # c3 needs access
  ingress {
      from_port = 8083
      to_port = 8083
      protocol = "TCP"
      self = true
      cidr_blocks = ["${local.myip-cidr}"]
      security_groups = ["${aws_security_group.c3.id}", "${aws_security_group.ssh.id}"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

# should lock down input to this group
resource "aws_security_group" "monitoring" {
  description = "Monitoring security group - Managed by Terraform"
  name = "${var.ownershort}-monitoring"


  # Logstash
  ingress {
      from_port = 5000
      to_port = 5000
      protocol = "TCP"
      self = true
      cidr_blocks = ["${local.myip-cidr}"]
      security_groups = ["${aws_security_group.ssh.id}"]
  }

  # Elastic
  ingress {
      from_port = 9200
      to_port = 9200
      protocol = "TCP"
      self = true
      cidr_blocks = ["${local.myip-cidr}"]
      security_groups = ["${aws_security_group.ssh.id}"]
  }

  # Elastic
  ingress {
      from_port = 9300
      to_port = 9300
      protocol = "TCP"
      self = true
      cidr_blocks = ["${local.myip-cidr}"]
      security_groups = ["${aws_security_group.ssh.id}"]
  }

  # kibana
  ingress {
      from_port = 5601
      to_port = 5601
      protocol = "TCP"
      self = true
      cidr_blocks = ["${local.myip-cidr}"]
      security_groups = ["${aws_security_group.ssh.id}"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_eip" "bastion" {
#   instance = "${aws_instance.bastion.0.id}"
#   vpc      = true
# }

# resource "aws_eip" "broker-0" {
#   instance = "${aws_instance.brokers.0.id}"
#   vpc      = true
# }

# resource "aws_eip" "zookeeper-0" {
#   instance = "${aws_instance.zookeeper.0.id}"
#   vpc      = true
# }


resource "aws_instance" "bastion" {
  count = 1
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${local.bastion-instance-type}"
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
    region = "${var.region}"
  }
}

resource "aws_instance" "brokers" {
  count         = "${var.broker-count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${local.broker-instance-type}"
  availability_zone = "${element(var.azs, count.index)}"
  # security_groups = ["${var.security_group}"]
  security_groups = ["${aws_security_group.brokers.name}", "${aws_security_group.ssh.name}"]
  key_name = "${var.key_name}"
  root_block_device {
    volume_size = 1000 # 1TB
  }
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
    region = "${var.region}"
    role_region = "brokers-${var.region}"
  }
}

resource "aws_instance" "zookeeper" {
  count         = "${var.zk-count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${local.zk-instance-type}"
  availability_zone = "${element(var.azs, count.index)}"
  security_groups = ["${aws_security_group.ssh.name}", "${aws_security_group.zookeepers.name}"]
  key_name = "${var.key_name}"
  tags {
    Name = "${var.ownershort}-zookeeper-${count.index}-${element(var.azs, count.index)}"
    description = "zookeeper nodes - Managed by Terraform"
    role = "zookeeper"
    zookeeperid = "${count.index}"
    Owner = "${var.owner}"
    sshUser = "ubuntu"
    region = "${var.region}"
    role_region = "zookeepers-${var.region}"
  }
}

resource "aws_instance" "connect-cluster" {
  count         = "${var.connect-count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${local.connect-instance-type}"
  availability_zone = "${element(var.azs, count.index)}"
  security_groups = ["${aws_security_group.ssh.name}", "${aws_security_group.connect.name}"]
  key_name = "${var.key_name}"
  tags {
    Name = "${var.ownershort}-connect-${count.index}-${element(var.azs, count.index)}"
    description = "Connect nodes - Managed by Terraform"
    role = "connect"
    Owner = "${var.owner}"
    sshUser = "ubuntu"
    region = "${var.region}"
    role_region = "connect-${var.region}"
  }
}

resource "aws_instance" "control-center" {
  count         = "${var.c3-count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${local.c3-instance-type}"
  availability_zone = "${element(var.azs, count.index)}"
  security_groups = ["${aws_security_group.ssh.name}", "${aws_security_group.c3.name}"]
  key_name = "${var.key_name}"
  root_block_device {
    volume_size = 300 # 300 GB
  }
  tags {
    Name = "${var.ownershort}-c3-${count.index}-${element(var.azs, count.index)}"
    description = "Control Center - Managed by Terraform"
    role = "c3"
    Owner = "${var.owner}"
    sshUser = "ubuntu"
    region = "${var.region}"
    role_region = "c3-${var.region}"
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



// clients
variable "producer-count" {
  default = 2
}
variable "client-instance-type" {
  default = "t2.small"
}
resource "aws_instance" "performance-producer" {
  count         = "${var.producer-count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${local.client-instance-type}"
  availability_zone = "${element(var.azs, count.index)}"
  security_groups = ["${aws_security_group.ssh.name}"]
  key_name = "${var.key_name}"
  tags {
    Name = "${var.ownershort}-performance-producer-${count.index}-${element(var.azs, count.index)}"
    description = "performance-producer - Managed by Terraform"
    role = "performance-producer"
    Owner = "${var.owner}"
    sshUser = "ubuntu"
    region = "${var.region}"
    role_region = "performance-producer-${var.region}"
    role_type = "client"
  }
}
variable "consumer-count" {
  default = 2
}
variable "consumer-instance-type" {
  default = "t2.small"
}
resource "aws_instance" "performance-consumer" {
  count         = "${var.consumer-count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${local.client-instance-type}"
  availability_zone = "${element(var.azs, count.index)}"
  security_groups = ["${aws_security_group.ssh.name}"]
  key_name = "${var.key_name}"
  tags {
    Name = "${var.ownershort}-performance-consumer-${count.index}-${element(var.azs, count.index)}"
    description = "performance-consumer - Managed by Terraform"
    role = "performance-consumer"
    Owner = "${var.owner}"
    sshUser = "ubuntu"
    region = "${var.region}"
    role_region = "performance-consumer-${var.region}"
    role_type = "client"
  }
}

resource "aws_instance" "monitoring-node" {
  count         = 1
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${local.monitoring-instance-type}"
  availability_zone = "${element(var.azs, count.index)}"
  security_groups = ["${aws_security_group.ssh.name}", "${aws_security_group.monitoring.name}"]
  key_name = "${var.key_name}"
  tags {
    Name = "${var.ownershort}-monitoring-node-${count.index}-${element(var.azs, count.index)}"
    description = "monitoring-node - Managed by Terraform"
    role = "monitoring-node"
    Owner = "${var.owner}"
    sshUser = "ubuntu"
    region = "${var.region}"
    role_region = "monitoring-node-${var.region}"
    role_type = "monitoring"
  }
}
