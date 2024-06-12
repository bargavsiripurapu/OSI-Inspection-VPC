
# ---------------------------------------------------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_vpc" "ins_vpc" {
  cidr_block           = var.ins_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
      "Name" = format("%s", var.ins_vpc_name)
    }
      
  lifecycle {
    create_before_destroy = true
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# SUBNETS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_subnet" "gwlbe_subnet" {
  count = length(var.azs)
  
  vpc_id = aws_vpc.ins_vpc.id
  cidr_block =var.gwlbe_subnets[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    "Name" = format("%s-gwlbe-%s-private-sn",var.ins_vpc_name, var.azs[count.index])
      "Tier" = "private"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "tgw_subnet" {
  count = length(var.azs)
  vpc_id = aws_vpc.ins_vpc.id
  cidr_block =var.tgw_subnets[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    "Name" = format("%s-tgw-%s-private-sn",var.ins_vpc_name, var.azs[count.index])
      "Tier" = "private"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "natgw_subnet" {
  count = length(var.azs)
  vpc_id = aws_vpc.ins_vpc.id
  cidr_block =var.natgw_subnets[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    "Name" = format("%s-natgw-%s-public-sn",var.ins_vpc_name, var.azs[count.index])
      "Tier" = "public"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "fw_data_subnet" {
  count = length(var.azs)
  vpc_id = aws_vpc.ins_vpc.id
  cidr_block =var.fw_data_subnets[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    "Name" = format("%s-fw-data-%s-private-sn",var.ins_vpc_name, var.azs[count.index])
      "Tier" = "private"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "fw_mgmt_subnet" {
  count = length(var.azs)
  vpc_id = aws_vpc.ins_vpc.id
  cidr_block =var.fw_mgmt_subnets[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    "Name" = format("%s-fw-mgmt-%s-private-sn",var.ins_vpc_name, var.azs[count.index])
      "Tier" = "private"
  }
  lifecycle {
    create_before_destroy = true
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# ELASTIC IPs
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_eip" "public_ip" {
  count = length(var.azs)
  tags = {
    "Name" = format("%s-NAT-GW-ip-%s",var.ins_vpc_name, var.azs[count.index])
  }
  lifecycle {
    create_before_destroy = true
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# INTERNET GATEWAY
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ins_vpc.id
  tags = {
    "Name" = format("%s-IGW",var.ins_vpc_name)
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# NAT GATEWAYS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = element(aws_eip.public_ip.*.id, count.index)
  subnet_id     = element(aws_subnet.natgw_subnet.*.id, count.index)

  count = length(var.azs)

  tags = {
    "Name" = format("%s-NAT-GW-%s",var.ins_vpc_name, var.azs[count.index])
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GATEWAY LOADBALANCER CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb" "gwlb" {
  load_balancer_type = "gateway"
  name               = "gwlb-${var.ins_vpc_name}"
  enable_cross_zone_load_balancing = true
  subnets = tolist(aws_subnet.fw_data_subnet.*.id)
}

resource "aws_lb_target_group" "gwlb_target" {
  name     = "gwlb-fw-targets"
  port     = 6081
  protocol = "GENEVE"
  target_type = "ip"
  vpc_id   = aws_vpc.ins_vpc.id

  health_check {
    port     = 443
    protocol = "TCP"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "gwlb_listener" {
  load_balancer_arn = aws_lb.gwlb.id

  default_action {
    target_group_arn = aws_lb_target_group.gwlb_target.id
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "fgtattach" {
  depends_on       = [aws_instance.fgtvm]
  target_group_arn = aws_lb_target_group.gwlb_target.arn
  target_id        = aws_network_interface.fgt1eth1.private_ip
  port             = 6081
}

resource "aws_lb_target_group_attachment" "fgt2attach" {
  depends_on       = [aws_instance.fgtvm2]
  target_group_arn = aws_lb_target_group.gwlb_target.arn
  target_id        = aws_network_interface.fgt2eth1.private_ip
  port             = 6081
}

# ---------------------------------------------------------------------------------------------------------------------
# GATEWAY LOADBALANCER ENDPOINT SERVICE CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint_service" "gwlb_es" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]
  tags = {
    Name = "gwlb-es-${var.ins_vpc_name}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GATEWAY LOADBALANCER ENDPOINTS CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "gwlbe" {
  count = length(var.azs)
  service_name      = aws_vpc_endpoint_service.gwlb_es.service_name
  subnet_ids        = [aws_subnet.gwlbe_subnet[count.index].id]
  vpc_endpoint_type = aws_vpc_endpoint_service.gwlb_es.service_type
  vpc_id            = aws_vpc.ins_vpc.id
    tags = {
    Name = "gwlbe-${var.ins_vpc_name}-${var.azs[count.index]}"
  }
}
