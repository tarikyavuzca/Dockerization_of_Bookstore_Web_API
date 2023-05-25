terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.61.0"
    }
    github = {
      source  = "integrations/github"
      version = "4.13.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "github" {
  token = "YOUR_GITHUB_TOKEN"
}


resource "github_repository" "myrepo" {
  name        = "Dockerization_of_Bookstore_Web_API" # Specify the name of the repository you want to create
  description = "Repository name you want to create with Terraform" # Add a description (optional)
  private     = true
  auto_init = true

}

resource "github_branch_default" "main" {
  branch = "main"
  repository = github_repository.myrepo.name
}

variable "files" {
  default = ["bookstore-api.py", "requirements.txt", "Dockerfile", "docker-compose.yaml"]
}
resource "github_repository_file" "app-files" {
  for_each = toset(var.files)
  content    = file(each.value) # Local path to the file content
  file = each.value
  repository = github_repository.myrepo.name
  branch     = "main"
  message    = "Add file via Terraform" # Commit message
  overwrite_on_create = true
}

data "aws_ami" "latest_2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.????????-x86_64-gp2"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "example_instance" {
  ami           = data.aws_ami.latest_2023.id
  instance_type = "t2.micro"
  key_name = "your key name" # change here
  vpc_security_group_ids = []
  tags = {
    Name = "Web server of Bookstore"
  }
  #please update your user date based on your information / you can use git clone instead of using curl
  user_data = <<-EOF
          #! /bin/bash
          yum update -y
          yum install docker -y
          systemctl start docker
          systemctl enable docker
          usermod -a -G docker ec2-user
          newgrp docker
          curl -SL https://github.com/docker/compose/releases/latest/download/v2.16.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
          chmod +x /usr/local/bin/docker-compose

          mkdir -p /home/ec2-user/bookstore-api
          TOKEN=<YOUR GITHUB TOKEN>
          FOLDER=https:/$TOKEN@raw.githubusercontent.com/<githubusername>/...
          curl -s --create-dirs -o "/home/ec2-user/bookstore-api/app.py" -L "$FOLDER"bookstore-api.py
          curl -s --create-dirs -o "/home/ec2-user/bookstore-api/requirements.txt" -L "$FOLDER"requirements.txt
          curl -s --create-dirs -o "/home/ec2-user/bookstore-api/Dockerfile" -L "$FOLDER"Dockerfile
          curl -s --create-dirs -o "/home/ec2-user/bookstore-api/docker-compose.yml" -L "$FOLDER"docker-compose.yaml
          cd /home/ec2-user/bookstore-api
          docker build -t tarikyavuzca/bookstoreapi:latest .
          docker-compose up -d
  EOF
  depends_on = [github_repository.myrepo,github_repository_file.app-files]
}

resource "aws_security_group" "tf-docker-sec-gr" {
  name = "docker-sec-gr-203-oliver"
  tags = {
    Name = "docker-sec-group-203"
  }
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "website" {
  value = "http://${aws_instance.tf-docker-ec2.public_dns}"

}