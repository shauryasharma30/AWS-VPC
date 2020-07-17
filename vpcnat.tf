provider "aws" {
  region = "ap-south-1"
  profile = "task4"
}

resource "aws_vpc" "task4vpc" {
  cidr_block       = "192.168.0.0/16"
  enable_dns_support="true"
  enable_dns_hostnames="true"
  instance_tenancy = "default"

  tags = {
    Name = "task4vpc"
  }
}

resource "aws_subnet" "publicsubnet4" {
  vpc_id     =  aws_vpc.task4vpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "publicsubnet4"
  }
}

resource "aws_subnet" "privatesubnet4" {
  vpc_id     =  aws_vpc.task4vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "privatesubnet4"
  }
}

resource "aws_eip" "elasticip"{
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.elasticip.id
  subnet_id = aws_subnet.publicsubnet4.id
  
  tags = {
    Name = "NATGATEWAY"
  }
}

resource "aws_internet_gateway" "gtwy" {
  vpc_id =  aws_vpc.task4vpc.id

  tags = {
    Name = "gateway"
  }
}

resource "aws_route_table" "roots" {
  vpc_id =  aws_vpc.task4vpc.id
  
  tags = {
    Name = "IRT"
  }
}

resource "aws_route" "one" {
  route_table_id            =  aws_route_table.roots.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id =  aws_internet_gateway.gtwy.id
  
}

resource "aws_route_table_association" "rone" {
  subnet_id      = aws_subnet.publicsubnet4.id
  route_table_id = aws_route_table.roots.id
}

resource "aws_route_table" "nats" {
  vpc_id =  aws_vpc.task4vpc.id
  
  tags = {
    Name = "NATRT"
  }
}

resource "aws_route" "two" {
  route_table_id            =   aws_route_table.nats.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id =  aws_nat_gateway.nat.id
  
}

resource "aws_route_table_association" "rtwo" {
  subnet_id      = aws_subnet.privatesubnet4.id
  route_table_id = aws_route_table.nats.id
}


resource "aws_key_pair" "key" {
key_name = "mykeyvpc"
public_key="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAqFjcYEdo+PWRYCjBuQhAn5SdKNhOqyIbZiocYQpy541zJNcIl966ogFJEQT91kuZ/ukrV3bRgUbAWl3Vreq14a5VDs0+VKLjpIWobaikiq3VdNApbaKJzHuwPvjWdepcK/odEZccM3LEHxPjx21y64drrEG2y3URA/dCs9C0nFpEgmtRLRAOhX/s2OOG7P50D7XQl/weZD8Knex2H02ogKFgDulzmn2qeJNBmbloYXKSz4yE06K0SVOQZWWpXTRNw9MxRAXzzk92yWLCRawkOo20La9VA1bbHBo1w3eD0NM+6kbggIimUaWgOnwhchUG0aiufmifHYJSANIzPkOfHQ== rsa-key-20200714"
}

resource "aws_security_group" "wordsg" {
  name        = "wordpress"
  description = "Allow TLS inbound traffic"
  vpc_id      =   aws_vpc.task4vpc.id

  ingress {
    description = "ssh"
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http"
    from_port   = 0
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
  
  tags = {
    Name = "Wordpress"
  }
}


resource "aws_security_group" "sqlsg" {
  name        = "mysql"
  description = "Allow MYSQL"
  vpc_id      =   aws_vpc.task4vpc.id

  ingress {
    description = "MYSQL/Aurora"
    from_port   = 0
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [ aws_security_group.wordsg.id ]
  }
   
   ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    security_groups = [ aws_security_group.wordsg.id ]
  }

   ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [ aws_security_group.wordsg.id ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "Mysql"
  }
}


resource "aws_instance" "wordpress" {
  ami                  = "ami-000cbce3e1b899ebd"
  instance_type  = "t2.micro"
  key_name        = "mykeyvpc"
  security_groups =  [aws_security_group.wordsg.id]  
  subnet_id =  aws_subnet.publicsubnet4.id
  
  tags = {
    Name = "Wordpress-os"
  }
}


resource "aws_instance" "mysql" {
  ami                  = "ami-08706cb5f68222d09"
  instance_type  = "t2.micro"
  key_name        = "mykeyvpc"
  security_groups =  [aws_security_group.sqlsg.id]  
  subnet_id =  aws_subnet.privatesubnet4.id

  
  tags = {
    Name = "Mysql-os"
  }
}