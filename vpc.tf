#create VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

#create Availability zones
data "aws_availability_zones" "available" {
  state = "available"
}


#create public subnets
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)
  availability_zone = element(data.aws_availability_zones.available.names,count.index)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.public-cidr,count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-cidr-${count.index+1}"
  }
}

#create private subnets
resource "aws_subnet" "private" {
  count = length(data.aws_availability_zones.available.names)
  availability_zone = element(data.aws_availability_zones.available.names,count.index)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.private-cidr,count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "private-cidr-${count.index+1}"
  }
}

#create data subnets
resource "aws_subnet" "data" {
  count = length(data.aws_availability_zones.available.names)
  availability_zone = element(data.aws_availability_zones.available.names,count.index)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.data-cidr,count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "data-cidr-${count.index+1}"
  }
}

#create Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "IGW"
  }
}

#create Elastic IP
resource "aws_eip" "eip" {
  vpc      = true
}

#create Nat Gateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.private[0].id

  tags = {
    Name = "gw NAT"
  }
}

#create public Route table
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-Route"
  }
}

#create private Route table
resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "Private-Route"
  }
}

#create public route table association
resource "aws_route_table_association" "public" {
  count = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.public[*].id,count.index)
  route_table_id = aws_route_table.public-route.id
}

#create private route table association
resource "aws_route_table_association" "private" {
  count = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.private[*].id,count.index)
  route_table_id = aws_route_table.private-route.id
}

#create private route table association
resource "aws_route_table_association" "data" {
  count = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.data[*].id,count.index)
  route_table_id = aws_route_table.private-route.id
}