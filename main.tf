
provider "aws" {
    region = "us-east-1"
    access_key = "AKIAUH7SWMJBMHR2DQN7"
    secret_key = "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"
}

variable "dev_subnet_1_cider_block" {
    description = "cider subnet block"
  
}


resource "aws_vpc" "dev-vpc" {  
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "gabi-terraform-vpc"
    }
}

resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = var.dev_subnet_1_cider_block
    availability_zone = "us-east-1a"
    tags = {
        Name = "gabi-terraform-subnet-1"
    }
  
}

data "aws_vpc" "existing_vpc"{
    cidr_block = "10.0.0.0/16"
    tags = {
      "Name" = "gabi-terraform-vpc"
    }

}

resource "aws_subnet" "dev-subnet-2" {
    vpc_id = data.aws_vpc.existing_vpc.id
    cidr_block = "10.0.11.0/24"
    availability_zone = "us-east-1b"
    tags = {
        Name = "gabi-terraform-subnet-2"
    }
}

output "dev_subnet_id-01" {
    value = aws_subnet.dev-subnet-1.id
  
}
output "dev_subnet_id-02" {
    value = aws_subnet.dev-subnet-2.id
  
}
output "dev_subnet_id" {
    value = aws_vpc.dev-vpc.id
  
}