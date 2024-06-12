########################################################
# Transit Gateway
########################################################

//Transit Gateway configuration for Inspection VPC

resource "aws_ec2_transit_gateway" "osi-tgw" {
  description                     = "Transit Gateway"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = "Inspection-TGW"
  }
}

# Route Table - Inspection VPC
resource "aws_ec2_transit_gateway_route_table" "tgw-inspection-rt" {
  depends_on         = [aws_ec2_transit_gateway.osi-tgw]
  transit_gateway_id = aws_ec2_transit_gateway.osi-tgw.id
  tags = {
    Name = "TGW-Inspection-Att-RT"
  }
}


# VPC attachment - Inspection VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-vpc-ins_vpc" {
  appliance_mode_support                          = "enable"
  subnet_ids                                      = tolist(aws_subnet.tgw_subnet.*.id)
  transit_gateway_id                              = aws_ec2_transit_gateway.osi-tgw.id
  vpc_id                                          = aws_vpc.ins_vpc.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = format("TGWY-%s-attachment",var.ins_vpc_name)
  }
  depends_on = [aws_ec2_transit_gateway.osi-tgw]
}

# TGW Routes - Inspection VPC
resource "aws_ec2_transit_gateway_route" "Inspection-VPC-route" {
  destination_cidr_block         = "10.1.0.0/22"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-ins_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-inspection-rt.id
}

# TGW Routes - Route for Shared service VPC
resource "aws_ec2_transit_gateway_route" "CustomerPrivate-VPC-route" {
  destination_cidr_block         = "20.1.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-inspection-rt.id
}

# TGW Routes - Route for Workload VPC
resource "aws_ec2_transit_gateway_route" "CustomerPublic-VPC-route" {
  destination_cidr_block         = "20.2.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-inspection-rt.id
}

# Route Tables Associations - Associating the TGW with Inspection VPC
resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc-ins-assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-ins_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-inspection-rt.id
}

//Transit Gateway Configuration for Shared Service VPC

# Route Table - Shared Service VPC attachment route table
resource "aws_ec2_transit_gateway_route_table" "tgwy-vpc-route" {
  depends_on         = [aws_ec2_transit_gateway.osi-tgw]
  transit_gateway_id = aws_ec2_transit_gateway.osi-tgw.id
  tags = {
    Name = "TGW-Shared-Service-Att-RT"
  }
}

# VPC attachment - Shared Service VPC attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-vpc-vpc1" {
  subnet_ids                                      = [aws_subnet.csprivatesubnetaz1.id, aws_subnet.csprivatesubnetaz2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.osi-tgw.id
  vpc_id                                          = aws_vpc.customer-vpc.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = "TGWY-Shared-Service-VPC-Attachment"
  }
  depends_on = [aws_ec2_transit_gateway.osi-tgw]
}

# TGW Routes - Shared Service VPC default route for inspecting traffic
resource "aws_ec2_transit_gateway_route" "customer-default-route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-ins_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgwy-vpc-route.id
}

# Route Tables Associations - Sahred Service VPC
resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc-customer-assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgwy-vpc-route.id
}

//Transit Gateway Configuration for Workload VPC

# Route Table - Workload VPC
resource "aws_ec2_transit_gateway_route_table" "tgwy-vpc2-route" {
  depends_on         = [aws_ec2_transit_gateway.osi-tgw]
  transit_gateway_id = aws_ec2_transit_gateway.osi-tgw.id
  tags = {
    Name = "TGW-Workload-VPC-Att-RT"
  }
}

# VPC attachment - Workload VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-vpc-vpc2" {
  subnet_ids                                      = [aws_subnet.pv-privatesubnetaz1.id, aws_subnet.pv-privatesubnetaz2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.osi-tgw.id
  vpc_id                                          = aws_vpc.public-customer-vpc.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = "TGWY-Workload-VPC-Attachment"
  }
  depends_on = [aws_ec2_transit_gateway.osi-tgw]
}

# TGW Routes - Workload  VPC default route for inspecting traffic
resource "aws_ec2_transit_gateway_route" "customerpublic-default-route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-ins_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgwy-vpc2-route.id
}

# Route Tables Associations - Workload VPC
resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc-customerpublic-assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgwy-vpc2-route.id
}