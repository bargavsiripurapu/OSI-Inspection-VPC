# ---------------------------------------------------------------------------------------------------------------------
# CREATE ROUTE TABLES AND ASSOCIATIONS
# ROUTE TABLES (FW MGMT, FW DATA, GWLBE, GWLB, NATGW, TGW)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route" "fw_mgmt_rt" {
  for_each = var.route_table_cidr_blocks

  vpc_id = aws_vpc.ins_vpc.id
  route_table_id = aws_route_table.fw_mgmt_rt.id
  destination_cidr_block = each.value
  gateway_id = aws_internet_gateway.igw.id
  
  tags = {
    "Name" = format("%s-FW-MGMT-rt-%s", var.ins_vpc_name, each.key)
  }

  depends_on = [aws_vpc.ins_vpc]
}


resource "aws_route_table_association" "fw_mgmt_rt_association" {
  count = length(var.azs)
  subnet_id      = aws_subnet.fw_mgmt_subnet[count.index].id

  route_table_id = aws_route_table.fw_mgmt_rt[count.index].id

  depends_on = [aws_subnet.fw_mgmt_subnet, aws_route_table.fw_mgmt_rt]
}

resource "aws_route_table" "fw_data_rt_1a" {
  vpc_id = aws_vpc.ins_vpc.id
# Route 0.0.0.0/0 forwarded to Firewall Data Interface for Traffic Inspection (line35) 
  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_network_interface.fgt1eth1.id
    }
# Route cidr_block ="Workload/Shared Service VPC" for Internal Connectivity check    
  route {
    cidr_block = "20.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.osi-tgw.id
    }
  tags = {
    "Name" = format("%s-FW-DATA-rt-us-east-1a", var.ins_vpc_name)
  }

  depends_on = [aws_vpc.ins_vpc]
}

resource "aws_route_table_association" "fw_data_rt_1a_association" {
  count = length(var.azs)
  subnet_id      = aws_subnet.fw_data_subnet[0].id

  route_table_id = aws_route_table.fw_data_rt_1a.id

  depends_on = [aws_subnet.fw_data_subnet, aws_route_table.fw_data_rt_1a]
}

resource "aws_route_table" "fw_data_rt_1b" {
  vpc_id = aws_vpc.ins_vpc.id
# Route 0.0.0.0/0 forwarded to Firewall Data Interface for Traffic Inspection  (line 62)
  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_network_interface.fgt2eth1.id
    }
# Route cidr_block ="Workload/Shared Service VPC" for Internal (PING)Connectivity check    
  route {
    cidr_block = "20.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.osi-tgw.id
    }
  tags = {
    "Name" = format("%s-FW-DATA-rt-us-east-1b", var.ins_vpc_name)
  }

  depends_on = [aws_vpc.ins_vpc]
}

resource "aws_route_table_association" "fw_data_rt_1b_association" {
  count = length(var.azs)
  subnet_id      = aws_subnet.fw_data_subnet[1].id

  route_table_id = aws_route_table.fw_data_rt_1b.id

  depends_on = [aws_subnet.fw_data_subnet, aws_route_table.fw_data_rt_1b]
}

resource "aws_route_table" "gwlbe_rt" {
  count = length(var.azs)
  vpc_id = aws_vpc.ins_vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
    }
    route {
    cidr_block = "20.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.osi-tgw.id
    }
  tags = {
    "Name" = format("%s-GWLBe-rt-%s", var.ins_vpc_name, var.azs[count.index])
  }

  depends_on = [aws_vpc.ins_vpc]
}

resource "aws_route_table_association" "gwlbe_rt_association" {
  count = length(var.azs)
  subnet_id      = aws_subnet.gwlbe_subnet[count.index].id

  route_table_id = aws_route_table.gwlbe_rt[count.index].id

  depends_on = [aws_subnet.gwlbe_subnet, aws_route_table.gwlbe_rt]
}

resource "aws_route_table" "natgw_rt" {
  count = length(var.azs)
  vpc_id = aws_vpc.ins_vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
    }
    route {
    cidr_block = "20.0.0.0/8"
    vpc_endpoint_id = aws_vpc_endpoint.gwlbe[count.index].id
    }
  tags = {
    "Name" = format("%s-NATGW-rt-%s", var.ins_vpc_name, var.azs[count.index])
  }

  depends_on = [aws_vpc.ins_vpc, aws_vpc_endpoint.gwlbe]
}

resource "aws_route_table_association" "natgw_rt_association" {
  count = length(var.azs)
  subnet_id      = aws_subnet.natgw_subnet[count.index].id

  route_table_id = aws_route_table.natgw_rt[count.index].id

  depends_on = [aws_subnet.natgw_subnet, aws_route_table.natgw_rt]
}

resource "aws_route_table" "tgwa_rt" {
  count = length(var.azs)
  vpc_id = aws_vpc.ins_vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.gwlbe[count.index].id
    }
  tags = {
    "Name" = format("%s-TGWe-rt-%s", var.ins_vpc_name, var.azs[count.index])
  }

  depends_on = [aws_vpc.ins_vpc, aws_vpc_endpoint.gwlbe]
}

resource "aws_route_table_association" "tgwa_rt_association" {
  count = length(var.azs)
  subnet_id      = aws_subnet.tgw_subnet[count.index].id

  route_table_id = aws_route_table.tgwa_rt[count.index].id

  depends_on = [aws_subnet.tgw_subnet, aws_route_table.tgwa_rt]
}
