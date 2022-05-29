
provider "aws" {
    region = "us-east-1"
 
}

variable "vpc_cider_block" {}
variable "subnet_cider_block" {}
variable "availability_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "public_key_location" {}
variable "private_key_location" {}
variable "instance_type" {}
resource "aws_vpc" "gabi_myapp_vpc" {
    cidr_block=var.vpc_cider_block
    tags = {
        Name : "${var.env_prefix}-vpc" 
        createdby = "gabi magilner-terraform"
    }
}


resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.gabi_myapp_vpc.id
    cidr_block = var.subnet_cider_block
    availability_zone = var.availability_zone
    tags = {
      Name : "${var.env_prefix}-subnet-1" 
      createdby = "gabi magilner-terraform"
    }
  
}

resource "aws_route_table" "myapp_route_table" {
    vpc_id = aws_vpc.gabi_myapp_vpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id

  }
    tags = {
        Name = "${var.env_prefix}-routetable-igw" 
        createdby = "gabi magilner-terraform"
    }
} 

resource "aws_route_table_association" "myapp_route_table-todev-subnet-1" {
  subnet_id      = aws_subnet.dev-subnet-1.id
  route_table_id = aws_route_table.myapp_route_table.id

}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.gabi_myapp_vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
    createdby = "gabi magilner-terraform"
  }
}


resource "aws_security_group" "myapp_sg" {
  name        = "myapp-sg"
  description = "open ssh to my ip and http"
  vpc_id      = aws_vpc.gabi_myapp_vpc.id

  ingress {
    description      = "open ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${var.my_ip}"]
    
  }
  ingress {
    description      = "http access"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  } 

  egress {
    description      = "http access"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
        Name = "${var.env_prefix}-sg"
    createdby = "gabi magilner-terraform"
  }
}

data "aws_ami" "latest_amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
      name = "name"
      values = ["amzn2-ami-kernel-*x86_64-gp2"]
    }
}

resource "aws_key_pair" "gabi-server-key" {
  key_name = "gabi-server-key-pem"
  public_key = file(var.public_key_location)
}


resource "aws_instance" "myapp-server-gabi-terraform" {
    ami = data.aws_ami.latest_amazon-linux-image.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.dev-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp_sg.id]
    availability_zone = var.availability_zone
    associate_public_ip_address = true
    key_name = aws_key_pair.gabi-server-key.key_name

    user_data = file("user-data-script.sh")
 ######    run provisioner and connection as last result!!! --> terraform dont know the status of the resource after you run --> not recommended way!
connection {
  type = "ssh"
  host = self.public_ip
  user = "ec2-user"
  private_key = file(var.private_key_location)
  
}

provisioner "file" {
  source = "user-data-script.sh"
  destination = "/home/ec2-user/user-data-script.sh"


}

provisioner "remote-exec" {

script = file("user-data-script.sh")
  
}

    tags = {
        Name = "${var.env_prefix}-ec2-terraform01"
    createdby = "gabi magilner-terraform"
  }

}




output "aws_ami_id" {
  value = data.aws_ami.latest_amazon-linux-image.id
}

output "public_ip" {
  value = aws_instance.myapp-server-gabi-terraform.public_ip
}