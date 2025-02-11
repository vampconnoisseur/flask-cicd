provider "aws" {
  region = "us-east-1"
}

variable "image_tag" {}

resource "aws_security_group" "flask_sg" {
  name        = "flask_sg"
  description = "Allow inbound traffic to Flask app"

  ingress {
    from_port   = 8765
    to_port     = 8765
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "flask_server" {
  ami             = "ami-04b4f1a9cf54c11d0"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.flask_sg.name]

  user_data = <<-EOF
            #!/bin/bash

            sudo apt-get update -y
            sudo apt-get install -y ca-certificates curl git

            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin vim vi

            sudo apt install docker-compose -y

            sudo systemctl start docker
            sudo systemctl enable docker

            sudo docker pull vampconnoisseur/flask-server:${image_tag}
            sudo docker run -d -p 8765:8765 vampconnoisseur/flask-server:${image_tag}
  EOF

  tags = {
    Name = "flask_server"
  }
}

output "public_ip" {
  value = aws_instance.flask_server.public_ip
}
