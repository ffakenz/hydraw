// based on: https://serverfault.com/questions/1084705/unable-to-ssh-into-a-terraform-created-ec2-instance

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.28"
    }
  }
}

provider "aws" {
  profile = "personal"  // aws-profile configured
  region  = "eu-west-3" // Paris
}

resource "aws_instance" "hydra" {

  ami           = "ami-04f862d90d8e4ebfc" // Ubuntu 20.10 https://cloud-images.ubuntu.com/locator/ec2/
  instance_type = "t2.micro"              // t2.micro is available in the AWS free tier
  key_name      = "dev-personal"          // name of key-pair created

  security_groups             = ["${aws_security_group.hydra-sg.id}"]
  subnet_id                   = aws_subnet.hydra-subnet.id
  associate_public_ip_address = true

  user_data = <<-EOF
      #! /bin/bash -xe
      sudo su
      
      cd /home/ubuntu
      touch .bashrc
      
      echo "alias logs='cat /var/log/cloud-init-output.log'" >> .bashrc
      echo "alias g=git" >> .bashrc
      
      echo 'update system'
      apt update -y
     
      # https://docs.docker.com/engine/install/ubuntu/
      echo 'installing docker'
      curl -fsSL https://get.docker.com -o get-docker.sh
      sh ./get-docker.sh

      echo "alias d=docker" >> .bashrc

      echo 'installing docker-compose'
      curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose
      alias dc='/usr/local/bin/docker-compose'
      
      echo "alias dc=docker-compose" >> .bashrc

      echo 'cloning hydra repo'
      git clone https://github.com/input-output-hk/hydra-poc.git
      cd hydra-poc/demo
      
       echo 'preparing devnet'
      ./prepare-devnet.sh

      # dc up -d cardano-node 
    EOF

  tags = {
    Name = "Hydraw"
  }
}
