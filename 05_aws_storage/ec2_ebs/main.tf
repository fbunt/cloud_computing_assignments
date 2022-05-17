provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ec2_ssh_example" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t2.micro"
  availability_zone = "us-west-2a"
  #key_name               = "aws4"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.http-ssh.id]
}

resource "aws_security_group" "http-ssh" {
  name        = "http-ssh"
  description = "allow ssh and http traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#creating and attaching ebs volume
resource "aws_ebs_volume" "my-ebs-vol" {
  availability_zone = "us-west-2a"
  size              = 1
  tags = {
    Name = "my-ebs-volume"
  }
}
#
resource "aws_volume_attachment" "my-volume-attachment" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.my-ebs-vol.id
  instance_id = aws_instance.ec2_ssh_example.id
}
