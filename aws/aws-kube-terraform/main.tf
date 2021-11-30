terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.61.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  access_key = ""
  secret_key = ""
}

resource "aws_security_group" "allow_kube" {
  name        = "allow_kube"
  description = "Allow Kube ports"

  ingress = [
     {
      description      = "Kube API port"
      from_port        = 6443
      to_port          = 6443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
     description      = "etcd1"
     from_port        = 2379
     to_port          = 2380
     protocol         = "tcp"
     cidr_blocks      = ["0.0.0.0/0"]
     ipv6_cidr_blocks = []
     prefix_list_ids  = []
     security_groups  = []
     self             = false
    },
    {
     description      = "kubeletport"
     from_port        = 10250
     to_port          = 10255
     protocol         = "tcp"
     cidr_blocks      = ["0.0.0.0/0"]
     ipv6_cidr_blocks = []
     prefix_list_ids  = []
     security_groups  = []
     self             = false
    },
    {
     description      = "platformagent"
     from_port        = 8091
     to_port          = 8091
     protocol         = "tcp"
     cidr_blocks      = ["0.0.0.0/0"]
     ipv6_cidr_blocks = []
     prefix_list_ids  = []
     security_groups  = []
     self             = false
    },
    {
     description      = "applicationport"
     from_port        = 30537
     to_port          = 30537
     protocol         = "tcp"
     cidr_blocks      = ["0.0.0.0/0"]
     ipv6_cidr_blocks = []
     prefix_list_ids  = []
     security_groups  = []
     self             = false
    }
    
     ]
  egress {
       description      = "Outgoing all"
       from_port        = 0
       to_port          = 0
       protocol         = "-1"
       cidr_blocks      = ["0.0.0.0/0"]
       ipv6_cidr_blocks = ["::/0"]
    }

  tags = {
    Name = "allow_kube"
  }
}

resource "aws_instance" "kube-control-node" {
  count = 1
  ami = "ami-0c1a7f89451184c8b"
  availability_zone = "ap-south-1b"
  instance_type = "t2.medium"
  key_name = "kubekey"
  security_groups = [
         "allow_kube"
   ]
  tags = {
    Name = "kube-control-0"
  }

provisioner "file" {
  source = "/home/csworks/Documents/aws-kube-terraform/setup.sh"
  destination = "/tmp/setup.sh"
}

provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh"
    ]
  }
connection {
  type = "ssh"
  user = "ubuntu"
  password = ""
  private_key = file(var.keyPath)
  host = self.public_ip
}

provisioner "local-exec" {
     command = "ssh -i ${var.keyPath} ubuntu@${self.public_ip} sudo kubeadm token create --print-join-command > /tmp/joinworker.sh"
}
  }

resource "aws_instance" "kube-compute-node" {
  count = var.computenum
  ami = "ami-0c1a7f89451184c8b"
  availability_zone = "ap-south-1b"
  instance_type = "t2.micro"
  key_name = "kubekey"
  security_groups = [
         "allow_kube"
   ]

  tags = {
    Name = "kube-compute-${count.index}"
  }

provisioner "local-exec" {
     command = "sleep 300 && scp -i ${var.keyPath} /tmp/joinworker.sh ubuntu@${self.public_ip}:/tmp/"
}

provisioner "file" {
  source = "/home/csworks/Documents/aws-kube-terraform/workersetup.sh"
  destination = "/tmp/workersetup.sh"
}

provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/workersetup.sh",
      "sudo /tmp/workersetup.sh"
    ]
  }
connection {
  type = "ssh"
  user = "ubuntu"
  password = ""
  private_key = file(var.keyPath)
  host = self.public_ip
}
  }
