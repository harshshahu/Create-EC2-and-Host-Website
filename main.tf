terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.40.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
    default = true 
}

data "aws_subnets" "default" {
    filter {
      name = "vpc-id"
      values = [ data.aws_vpc.default.id ]
    }
}

resource "tls_private_key" "ec2-key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name = "generated_key_by_terraform"
  public_key = tls_private_key.ec2-key.public_key_openssh
}

resource "local_file" "aws_private_key_pem" {
  content = tls_private_key.ec2-key.private_key_pem
  filename = "${path.module}/aws/generated_key_by_terraform.pem"
  file_permission = "0400"
  directory_permission = "0700"
}

resource "aws_security_group" "http_server_sg" {
  name        = "http_server_sg"
  description = "Allow HTTP traffic"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "http_server_sg"
  }
}

resource "aws_instance" "http_server" {
  ami = "ami-0ea87431b78a82070"
  instance_type = "t2.medium"
  key_name = aws_key_pair.generated_key.key_name
  subnet_id = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.http_server_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash

    yum update -y
    yum install httpd -y

    systemctl start httpd
    systemctl enable httpd

    # Create index.html
    cat <<'HTML' > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Zest Zumba Studio</title>

      <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
      <link rel="stylesheet" href="style.css" />
    </head>
    <body>
      <h1>Welcome to Zest Zumba Studio 💃</h1>
      <p>Your EC2 Apache server is running successfully 🚀</p>
    </body>
    </html>
    HTML

    # Create style.css
    cat <<'CSS' > /var/www/html/style.css
    body {
      background: #0f172a;
      color: white;
      font-family: 'Poppins', sans-serif;
      text-align: center;
      padding-top: 100px;
    }

    h1 {
      color: #ff4f8b;
    }

    p {
      color: #9ca3af;
    }
    CSS

    chmod -R 755 /var/www/html
  EOF

  tags = {
    Name = "http_server"
  }

  depends_on = [ local_file.aws_private_key_pem ]
}
