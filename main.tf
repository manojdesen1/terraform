terraform {
  required_providers {
    aws = {
      source  = "aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Create a VPC
resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "pub" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a" 
  tags = {
    Name = "Main"
  }
}
resource "aws_subnet" "priv" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "Main"
  }
}
resource "aws_internet_gateway" "test_sg" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "main"
  }
}
resource "aws_route_table" "pubroute" {
    vpc_id = aws_vpc.test_vpc.id
  
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.test_sg.id
    }  
    tags = {
      Name = "test"
    }
  }
  resource "aws_route_table_association" "pubass" {
    subnet_id      = aws_subnet.pub.id
    route_table_id = aws_route_table.pubroute.id
  }
  resource "aws_eip" "lb" {
    domain  = "vpc"
  }
  resource "aws_nat_gateway" "testnat" {
    allocation_id = aws_eip.lb.id
    subnet_id     = aws_subnet.pub.id
  
    tags = {
      Name = "gw NAT"
    }
  }
  resource "aws_route_table" "priroute" {
    vpc_id = aws_vpc.test_vpc.id
  
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.testnat.id
    }  
    tags = {
      Name = "test"
    }
  }
  resource "aws_route_table_association" "priass" {
    subnet_id      = aws_subnet.priv.id
    route_table_id = aws_route_table.priroute.id
  }
  resource "aws_security_group" "newtest" {
    name        = "newtest"
    description = "Allow TLS inbound traffic and all outbound traffic"
    vpc_id      = aws_vpc.test_vpc.id
  
    tags = {
      Name = "allow_tls"
    }
  }
  
  resource "aws_vpc_security_group_ingress_rule" "newtest" {
    security_group_id = aws_security_group.newtest.id
    cidr_ipv4        = "0.0.0.0/0"
    from_port         = 22
    ip_protocol       = "tcp"
    to_port           = 22
  }
 resource "aws_vpc_security_group_egress_rule" "newtest" {
    security_group_id = aws_security_group.newtest.id
    cidr_ipv4         = "0.0.0.0/0"
    ip_protocol       = "-1" # semantically equivalent to all ports
  }
  resource "aws_security_group" "private" {
    name        = "private"
    description = "Allow TLS inbound traffic and all outbound traffic"
    vpc_id      = aws_vpc.test_vpc.id
  
    tags = {
      Name = "private"
    }
  }
  
  resource "aws_vpc_security_group_ingress_rule" "private" {
    security_group_id = aws_security_group.private.id
    cidr_ipv4        = "10.0.1.0/24"
    from_port         = 22
    ip_protocol       = "tcp"
    to_port           = 22
  }
  
  resource "aws_vpc_security_group_egress_rule" "private" {
    security_group_id = aws_security_group.private.id
    cidr_ipv4         = "0.0.0.0/0"
    ip_protocol       = "-1" # semantically equivalent to all ports
  }
  resource "aws_instance" "public" {
    ami           = "ami-03f4878755434977f"  # Update with your desired AMI ID
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.pub.id
    security_groups = [aws_security_group.newtest.id]
    key_name      = "sap"
    associate_public_ip_address = true
  
    tags = {
      Name = "public-instance"
    }
  }
  resource "aws_instance" "private" {
    ami           = "ami-03f4878755434977f"  # Update with your desired AMI ID
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.priv.id
    security_groups = [aws_security_group.private.id]
    key_name      = "sap"
  
    tags = {
      Name = "private-instance"
    }
  }
