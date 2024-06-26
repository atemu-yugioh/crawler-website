provider "aws" {}

data "cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloud_config.yaml", {})
  }
}

data "cloudinit_config" "config_runner" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloud_config_runner.yaml", {})
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "crawler" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  key_name      = "crawler-window"

  # /var/log/cloud-init-output.log
  user_data     = data.cloudinit_config.config.rendered

  vpc_security_group_ids = [
    aws_security_group.crawler.id
  ]

  root_block_device {
    volume_size = 30
  }

  lifecycle {
    ignore_changes = [
      ami
    ]
  }

  tags = {
    Name = "Crawler"
  }
}


resource "aws_instance" "runner" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  key_name      = "crawler-window"

  # /var/log/cloud-init-output.log
  user_data     = data.cloudinit_config.config_runner.rendered

  vpc_security_group_ids = [
    aws_security_group.runner.id
  ]

  root_block_device {
    volume_size = 30
  }

  lifecycle {
    ignore_changes = [
      ami
    ]
  }

  tags = {
    Name = "Runner"
  }
}

output "ec2" {
  value = aws_instance.crawler.public_ip
}


output "runner" {
  value = aws_instance.runner.public_ip
}
