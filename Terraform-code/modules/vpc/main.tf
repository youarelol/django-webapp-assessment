resource "aws_vpc" "main" {
    cidr_block           = var.aws_vpc_cidr
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "Assessment-vpc"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "Assessment-igw"
    }
}
resource "aws_eip" "Nat_eip" {
    domain = "vpc"
    tags = {
        Name = "Assessment-nat-eip"
    }
  
}
resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.Nat_eip.id
    subnet_id     = aws_subnet.public1.id
    tags = {
        Name = "Assessment-nat-gateway"
    }
  
}

resource "aws_subnet" "public1" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = var.aws_subnet_public_cidr
    map_public_ip_on_launch = true
    availability_zone       = var.availability_zone
    tags = {
        Name = "Assessment-public-subnet1"
    }
}
resource "aws_subnet" "public2" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = var.aws_subnet_public_cidr2
    map_public_ip_on_launch = true
    availability_zone       = var.availability_zone2
    tags = {
        Name = "Assessment-public-subnet2"
    }
}

resource "aws_subnet" "private1" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = var.aws_subnet_private_cidr
    availability_zone = var.availability_zone
    tags = {
        Name = "Assessment-private-subnet"
    }
}
resource "aws_subnet" "private2" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = var.aws_subnet_private_cidr2
    availability_zone = var.availability_zone2
    tags = {
        Name = "Assessment-private-subnet2"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "Assessment-public-rt"
    }
}

resource "aws_route" "public_internet_access" {
    route_table_id         = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
    subnet_id      = aws_subnet.public1.id
    route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public2" {
    subnet_id      = aws_subnet.public2.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "Assessment-private-rt"
    }
}
resource "aws_route" "nat_access" {
    route_table_id         = aws_route_table.private.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat.id  
}

resource "aws_route_table_association" "private" {
    subnet_id      = aws_subnet.private1.id
    route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private2" {
    subnet_id      = aws_subnet.private2.id
    route_table_id = aws_route_table.private.id
}