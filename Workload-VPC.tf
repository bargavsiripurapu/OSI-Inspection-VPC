// VPC CIDRS for Customer VPC
variable "pv-vpccidr" {
  default = "20.2.0.0/16"
}

variable "pv-publiccidraz1" {
  default = "20.2.0.0/24"
}

variable "pv-privatecidraz1" {
  default = "20.2.1.0/24"
}


variable "pv-publiccidraz2" {
  default = "20.2.2.0/24"
}

variable "pv-privatecidraz2" {
  default = "20.2.3.0/24"
}

variable "pv-gwlbe-az1" {
  default = "20.2.128.0/28"
}

variable "pv-gwlbe-az2" {
  default = "20.2.128.16/28"
}

// AWS VPC - Customer Public
resource "aws_vpc" "public-customer-vpc" {
  cidr_block           = var.pv-vpccidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "Workload-VPC"
  }
}

resource "aws_subnet" "pv-publicsubnetaz1" {
  vpc_id            = aws_vpc.public-customer-vpc.id
  cidr_block        = var.pv-publiccidraz1
  availability_zone = var.azs[0]
  tags = {
    Name = "Workload public subnet az1"
  }
}

resource "aws_subnet" "pv-privatesubnetaz1" {
  vpc_id            = aws_vpc.public-customer-vpc.id
  cidr_block        = var.pv-privatecidraz1
  availability_zone = var.azs[0]
  tags = {
    Name = "Workload private subnet az1"
  }
}

resource "aws_subnet" "pv-publicsubnetaz2" {
  vpc_id            = aws_vpc.public-customer-vpc.id
  cidr_block        = var.pv-publiccidraz2
  availability_zone = var.azs[1]
  tags = {
    Name = "Workload public subnet az2"
  }
}

resource "aws_subnet" "pv-privatesubnetaz2" {
  vpc_id            = aws_vpc.public-customer-vpc.id
  cidr_block        = var.pv-privatecidraz2
  availability_zone = var.azs[1]
  tags = {
    Name = "Workload private subnet az2"
  }
}

resource "aws_subnet" "pv-gwlbe-az1" {
  vpc_id            = aws_vpc.public-customer-vpc.id
  cidr_block        = var.pv-gwlbe-az1
  availability_zone = var.azs[0]
  tags = {
    Name = "Workload gwlbe subnet az1"
  }
}

resource "aws_subnet" "pv-gwlbe-az2" {
  vpc_id            = aws_vpc.public-customer-vpc.id
  cidr_block        = var.pv-gwlbe-az2
  availability_zone = var.azs[1]
  tags = {
    Name = "Workload gwlbe subnet az2"
  }
}

// Public VPC IGW
resource "aws_internet_gateway" "pvigw" {
  vpc_id = aws_vpc.public-customer-vpc.id
  tags = {
    Name = "Workload-igw"
  }
}

//Public VPC Route Tables
resource "aws_route_table" "pv-publicrt" {
  vpc_id = aws_vpc.public-customer-vpc.id

  tags = {
    Name = "Workload-public-IGW-rt"
  }
}

resource "aws_route_table" "pv-publicrtaz1" {
  vpc_id = aws_vpc.public-customer-vpc.id

  tags = {
    Name = "Workload-publicaz1-egress-rt"
  }
}

resource "aws_route_table" "pv-publicrtaz2" {
  vpc_id = aws_vpc.public-customer-vpc.id

  tags = {
    Name = "Workload-publicaz2-egress-rt"
  }
}

resource "aws_route_table" "pv-privatert" {
  vpc_id     = aws_vpc.public-customer-vpc.id

  tags = {
    Name = "Workload-private-rt"
  }
}

resource "aws_route_table" "pv-gwlbeaz1-rt" {
  vpc_id     = aws_vpc.public-customer-vpc.id

  tags = {
    Name = "Workload-gwlbeaz1-rt"
  }
}

resource "aws_route_table" "pv-gwlbeaz2-rt" {
  vpc_id     = aws_vpc.public-customer-vpc.id

  tags = {
    Name = "Workload-gwlbeaz2-rt"
  }
}

# Public VPC Routes
resource "aws_route" "pv-publicrouteaz1" {
  depends_on             = [aws_route_table.pv-publicrt]
  route_table_id         = aws_route_table.pv-publicrt.id
  destination_cidr_block = var.pv-publiccidraz1
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint.id
}

resource "aws_route" "pv-publicrouteaz2" {
  depends_on             = [aws_route_table.pv-publicrt]
  route_table_id         = aws_route_table.pv-publicrt.id
  destination_cidr_block = var.pv-publiccidraz2
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpointaz2.id
}

resource "aws_route" "pv-internalroute" {
  depends_on             = [aws_route_table.pv-privatert]
  route_table_id         = aws_route_table.pv-privatert.id
  destination_cidr_block = "20.1.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.osi-tgw.id
}
# Server required internet connection for Software updates------------
resource "aws_route" "pv-tmp-externalroute" {
  depends_on             = [aws_route_table.pv-privatert]
  route_table_id         = aws_route_table.pv-privatert.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.osi-tgw.id
}
#---------------------------------------------------------------------
resource "aws_route" "pv-internalrouteaz1" {
  depends_on             = [aws_route_table.pv-publicrtaz1]
  route_table_id         = aws_route_table.pv-publicrtaz1.id
  destination_cidr_block = "20.1.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.osi-tgw.id
}

resource "aws_route" "pv-internalfirewallrouteaz1" {
  depends_on             = [aws_route_table.pv-publicrtaz1]
  route_table_id         = aws_route_table.pv-publicrtaz1.id
  destination_cidr_block = "10.1.0.0/22"
  transit_gateway_id     = aws_ec2_transit_gateway.osi-tgw.id
}

resource "aws_route" "pv-internalrouteaz2" {
  depends_on             = [aws_route_table.pv-publicrtaz2]
  route_table_id         = aws_route_table.pv-publicrtaz2.id
  destination_cidr_block = "20.1.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.osi-tgw.id
}

resource "aws_route" "pv-internalfirewallrouteaz2" {
  depends_on             = [aws_route_table.pv-publicrtaz2]
  route_table_id         = aws_route_table.pv-publicrtaz2.id
  destination_cidr_block = "10.1.0.0/22"
  transit_gateway_id     = aws_ec2_transit_gateway.osi-tgw.id
}

resource "aws_route" "pv-externalroute" {
  depends_on             = [aws_route_table.pv-publicrtaz1]
  route_table_id         = aws_route_table.pv-publicrtaz1.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint.id
}

resource "aws_route" "pv-externalrouteaz2" {
  depends_on             = [aws_route_table.pv-publicrtaz2]
  route_table_id         = aws_route_table.pv-publicrtaz2.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpointaz2.id
}

resource "aws_route" "pv-gwlberouteaz1" {
  depends_on             = [aws_route_table.pv-gwlbeaz1-rt]
  route_table_id         = aws_route_table.pv-gwlbeaz1-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.pvigw.id
}

resource "aws_route" "pv-gwlberouteaz2" {
  depends_on             = [aws_route_table.pv-gwlbeaz2-rt]
  route_table_id         = aws_route_table.pv-gwlbeaz2-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.pvigw.id
}

# Public Subnet Route association
resource "aws_route_table_association" "pvpublicassociate" {
  route_table_id = aws_route_table.pv-publicrt.id
  gateway_id     = aws_internet_gateway.pvigw.id
}

resource "aws_route_table_association" "pvinternalassociateaz1" {
  subnet_id      = aws_subnet.pv-privatesubnetaz1.id
  route_table_id = aws_route_table.pv-privatert.id
}

resource "aws_route_table_association" "pvinternalassociateaz2" {
  subnet_id      = aws_subnet.pv-privatesubnetaz2.id
  route_table_id = aws_route_table.pv-privatert.id
}

resource "aws_route_table_association" "pvpubassociateaz1" {
  subnet_id      = aws_subnet.pv-publicsubnetaz1.id
  route_table_id = aws_route_table.pv-publicrtaz1.id
}

resource "aws_route_table_association" "pvpubassociateaz2" {
  subnet_id      = aws_subnet.pv-publicsubnetaz2.id
  route_table_id = aws_route_table.pv-publicrtaz2.id
}

resource "aws_route_table_association" "pvgwlbeassociateaz1" {
  subnet_id      = aws_subnet.pv-gwlbe-az1.id
  route_table_id = aws_route_table.pv-gwlbeaz1-rt.id
}

resource "aws_route_table_association" "pvgwlbeassociateaz2" {
  subnet_id      = aws_subnet.pv-gwlbe-az2.id
  route_table_id = aws_route_table.pv-gwlbeaz2-rt.id
}

########################################################
# GWLB Endpoint
########################################################

# PV AZ1 Endpoint
resource "aws_vpc_endpoint" "gwlbendpoint" {
  service_name      = aws_vpc_endpoint_service.gwlb_es.service_name
  subnet_ids        = [aws_subnet.pv-gwlbe-az1.id]
  vpc_endpoint_type = aws_vpc_endpoint_service.gwlb_es.service_type
  vpc_id            = aws_vpc.public-customer-vpc.id
}

# PV AZ2 Endpoint
resource "aws_vpc_endpoint" "gwlbendpointaz2" {
  service_name      = aws_vpc_endpoint_service.gwlb_es.service_name
  subnet_ids        = [aws_subnet.pv-gwlbe-az2.id]
  vpc_endpoint_type = aws_vpc_endpoint_service.gwlb_es.service_type
  vpc_id            = aws_vpc.public-customer-vpc.id
}

########################################################
# EC2 Instance
########################################################
//Due to limitation of 5 EIP's in a VPC. We will deploy this Ec2 server manually for testing.