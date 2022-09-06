data "aws_vpc" "vpc" {
  id = var.vpc_id
}

# to find my router ip
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

#create bastion security group
resource "aws_security_group" "bastion-sg" {
  name        = "allow_admin"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Bastion-SG"
  }
}

#create Bastion-Ec2
resource "aws_instance" "Bastion-Ec2" {
  ami           = "ami-06489866022e12a14"
  instance_type = "t2.micro"
  security_groups = aws_security_group.bastion-sg.id

  tags = {
    Name = "HelloWorld"
  }
}

#create Application security group
resource "aws_security_group" "app-sg" {
  name        = "allow_admin"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = aws_security_group.bastion-sg.id
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "App-SG"
  }
}

# #create App-Ec2
resource "aws_instance" "App-Ec2" {
  ami           = "ami-06489866022e12a14"
  instance_type = "t2.micro"
  security_groups = aws_security_group.app-sg.id

  tags = {
    Name = "HelloWorld"
  }
}

#create ALB security group
resource "aws_security_group" "alb-sg" {
  name        = "allow_admin"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ALB-SG"
  }
}

