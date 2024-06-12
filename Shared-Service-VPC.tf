// VPC CIDRS for Customer VPC
variable "csvpccidr" {
  default = "20.1.0.0/16"
}


variable "csprivatecidraz1" {
  default = "20.1.1.0/24"
}

variable "csprivatecidraz2" {
  default = "20.1.3.0/24"
}

// AWS VPC - Customer
resource "aws_vpc" "customer-vpc" {
  cidr_block           = var.csvpccidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "Shared-Service-VPC"
  }
}

resource "aws_subnet" "csprivatesubnetaz1" {
  vpc_id            = aws_vpc.customer-vpc.id
  cidr_block        = var.csprivatecidraz1
  availability_zone = var.azs[0]
  tags = {
    Name = "Share-Service private subnet az1"
  }
}

resource "aws_subnet" "csprivatesubnetaz2" {
  vpc_id            = aws_vpc.customer-vpc.id
  cidr_block        = var.csprivatecidraz2
  availability_zone = var.azs[1]
  tags = {
    Name = "Share-Service private subnet az2"
  }
}


resource "aws_route_table" "csprivatert" {
  vpc_id = aws_vpc.customer-vpc.id

  tags = {
    Name = "Share-Service-private-rt"
  }
}

resource "aws_route" "csinternalroute" {
  depends_on             = [aws_route_table.csprivatert]
  route_table_id         = aws_route_table.csprivatert.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.osi-tgw.id
}
resource "aws_route" "cs-tmp-firewallroute" {
  depends_on             = [aws_route_table.csprivatert]
  route_table_id         = aws_route_table.csprivatert.id
  destination_cidr_block = "10.1.0.0/22"
  transit_gateway_id     = aws_ec2_transit_gateway.osi-tgw.id
}
resource "aws_route_table_association" "csinternalassociateaz1" {
  subnet_id      = aws_subnet.csprivatesubnetaz1.id
  route_table_id = aws_route_table.csprivatert.id
}

resource "aws_route_table_association" "csinternalassociateaz2" {
  subnet_id      = aws_subnet.csprivatesubnetaz2.id
  route_table_id = aws_route_table.csprivatert.id
}



