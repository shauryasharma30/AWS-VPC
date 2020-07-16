provider "aws" {
  region = "ap-south-1"
  profile = "task3"
}

resource "aws_vpc" "task3vpc" {
  cidr_block       = "192.168.0.0/16"
  enable_dns_support="true"
  enable_dns_hostnames="true"
  instance_tenancy = "default"

  tags = {
    Name = "vpctask3"
  }
}

resource "aws_subnet" "task3subnet" {
  vpc_id     =  aws_vpc.task3vpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "publicsubnet_task3"
  }
}

resource "aws_subnet" "privatesubnet" {
  vpc_id     =  aws_vpc.task3vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "privatesubnet_task3"
  }
}

resource "aws_internet_gateway" "gtwy" {
  vpc_id =  aws_vpc.task3vpc.id

  tags = {
    Name = "gateway"
  }
}

resource "aws_route_table" "routetable" {
  vpc_id =  aws_vpc.task3vpc.id
  
  tags = {
    Name = "routetabletask3"
  }
}

resource "aws_route" "route" {
  route_table_id            =   aws_route_table.routetable.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id =  aws_internet_gateway.gtwy.id
  
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.task3subnet.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_key_pair" "key" {
key_name = "mykeyaws"
public_key="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAqFjcYEdo+PWRYCjBuQhAn5SdKNhOqyIbZiocYQpy541zJNcIl966ogFJEQT91kuZ/ukrV3bRgUbAWl3Vreq14a5VDs0+VKLjpIWobaikiq3VdNApbaKJzHuwPvjWdepcK/odEZccM3LEHxPjx21y64drrEG2y3URA/dCs9C0nFpEgmtRLRAOhX/s2OOG7P50D7XQl/weZD8Knex2H02ogKFgDulzmn2qeJNBmbloYXKSz4yE06K0SVOQZWWpXTRNw9MxRAXzzk92yWLCRawkOo20La9VA1bbHBo1w3eD0NM+6kbggIimUaWgOnwhchUG0aiufmifHYJSANIzPkOfHQ== rsa-key-20200714"
}

resource "aws_security_group" "wordsg" {
  name        = "wordpress"
  description = "Allow TLS inbound-traffic"
  vpc_id      =   aws_vpc.task3vpc.id

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
  vpc_id      =   aws_vpc.task3vpc.id

  ingress {
    description = "MYSQL/Aurora"
    from_port   = 0
    to_port     = 3306
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
    Name = "Mysql"
  }
}


resource "aws_instance" "wordpress" {
  ami                  = "ami-000cbce3e1b899ebd"
  instance_type  = "t2.micro"
  key_name        = "mykeyaws"
  vpc_security_group_ids =  [  aws_security_group.wordsg.id  ]
  subnet_id =  aws_subnet.task3subnet.id
  
  tags = {
    Name = "Wordpress-os"
  }
}


resource "aws_instance" "mysql" {
  ami                  = "ami-08706cb5f68222d09"
  instance_type  = "t2.micro"
  key_name        = "mykeyaws"
  vpc_security_group_ids =  [  aws_security_group.sqlsg.id  ]
  subnet_id =  aws_subnet.privatesubnet.id

  
  tags = {
    Name = "mysql-os"
  }
}
