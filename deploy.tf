variable "region" {
  default = "us-east-1"
}

provider "aws" {
  region = "${var.region}"
  # region          = "us-east-1" # Virginia
  # region          = "us-east-2" # Ohio
  # region          = "us-west-1" # California
  # region          = "us-west-2" # Oregon
  # region          = "ap-south-1" # Mumbai
  # region          = "ap-northeast-1" # Tokyo
  # region          = "ap-northeast-2" # Seoul
  # region          = "ap-southeast-1" # Singapore
  # region          = "ap-southeast-2" # Sydney
  # region          = "eu-central-1" # Frankfurt
  # region          = "eu-west-1" # Ireland
  # region          = "eu-west-2" # London
  # region          = "eu-west-3" # Paris
  # region          = "eu-north-1" # Stockholm
  # region          = "ca-central-1" # Montreal
  # region          = "sa-east-1" # Sao Paulo
}

resource "aws_instance" "ssocks" {
  count           = 1 # number of copies to spin up - if you put 1000 here, your bill might surprise you...
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "t2.micro"
  key_name        = "ssocks_key"
  security_groups = [
    "${aws_security_group.ssh_https.name}"
  ]

  provisioner "remote-exec" {
    script        = "scripts/provision.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("~/.ssh/ssocks_key.pem")}"
    }
  }

  # Return the public dns names into a local file for later use.
  provisioner "local-exec" {
    command       = "echo ${self.public_dns} >> public_dns.txt"
  }
}

resource "aws_security_group" "ssh_https" {
  count           = 1
  name            = "ssh_https"
  description     = "Allow all inbound traffic"

  ingress {
    from_port     = 443
    to_port       = 443
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }

  ingress {
    from_port     = 22
    to_port       = 22
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }

  egress {
    from_port     = 0
    to_port       = 65535
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }

  tags            = {
    Name          = "ssh_https"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "null_resource" "after_cleanup" {
  provisioner "local-exec" {
    when          = "destroy"
    command       = "rm -f public_dns.txt"
  }
}

resource "null_resource" "before_cleanup" {
  provisioner "local-exec" {
    command       = "rm -f public_dns.txt"
  }
}
