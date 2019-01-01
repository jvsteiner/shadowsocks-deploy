provider "aws" {
  # region          = "us-east-1"
  # region          = "us-east-2"
  # region          = "us-west-1"
  # region          = "us-west-2"
  region          = "ap-south-1"
  # region          = "ap-northeast-2"
  # region          = "ap-southeast-1"
  # region          = "ap-southeast-2"
  # region          = "ap-northeast-1"
  # region          = "eu-central-1"
  # region          = "eu-west-1"
  # region          = "eu-west-2"
  # region          = "eu-west-3"
  # region          = "eu-north-1"
  # region          = "ca-central-1"
  # region          = "cn-north-1"
  # region          = "sa-east-1"
}

resource "aws_instance" "ssocks" {
  count           = 1 # number of copies to spin up - if you put 1000 here, your bill might surprise you...
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "t2.micro"
  key_name        = "narc_key"
  security_groups = [
    "${aws_security_group.ssh_https.name}"
  ]

  provisioner "remote-exec" {
    script        = "scripts/provision.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("~/.ssh/narc_key.pem")}"
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
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
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
