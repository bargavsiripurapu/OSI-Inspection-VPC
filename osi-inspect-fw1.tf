// FGTVM instance

resource "aws_network_interface" "eth0" {
  description = "fgtvm-port1"
  subnet_id   = aws_subnet.fw_mgmt_subnet[0].id
}

resource "aws_network_interface" "fgt1eth1" {
  description       = "fgtvm-port2"
  subnet_id         = aws_subnet.fw_data_subnet[0].id
  source_dest_check = false
}

resource "aws_eip" "FGTPublicIP" {
  depends_on        = [aws_instance.fgtvm]
  domain            = "vpc"
  network_interface = aws_network_interface.eth0.id
}



# ---------------------------------------------------------------------------------------------------------------------
# CREATE SECURITY GROUPS
# 2 SG (FW MGMT, FW DATA)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "fw-mgmt-sg" {
  name        = format("%s-fw-mgmt-sg", var.ins_vpc_name)
  description = "Controls traffic to Fortigate Firewall MGMT ENI"
  vpc_id      = aws_vpc.ins_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.fw_mgmt_sg_list
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = format("%s-fw-mgmt-sg", var.ins_vpc_name)
  }

  depends_on = [aws_vpc.ins_vpc]
}

resource "aws_security_group" "fw-data-sg" {
  name        = format("%s-fw-data-sg", var.ins_vpc_name)
  description = "Controls traffic to Fortigate Firewall Data ENI"
  vpc_id      = aws_vpc.ins_vpc.id

  ingress {
    from_port   = 6081
    to_port     = 6081
    protocol    = "udp"
    cidr_blocks = var.fw_data_subnets
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.fw_data_subnets
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = var.fw_data_subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = format("%s-fw-data-sg", var.ins_vpc_name)
  }

  depends_on = [aws_vpc.ins_vpc]
}

data "aws_network_interface" "fgt1eth1" {
  id = aws_network_interface.fgt1eth1.id
}

//
data "aws_network_interface" "vpcendpointip" {
  depends_on = [aws_vpc_endpoint.gwlbe]
  filter {
    name   = "vpc-id"
    values = ["${aws_vpc.ins_vpc.id}"]
  }
  filter {
    name   = "status"
    values = ["in-use"]
  }
  filter {
    name   = "description"
    values = ["*ELB*"]
  }
  filter {
    name   = "availability-zone"
    values = ["${var.azs[0]}"]
  }
}

resource "aws_network_interface_sg_attachment" "publicattachment" {
  depends_on           = [aws_network_interface.eth0]
  security_group_id    = aws_security_group.fw-mgmt-sg.id
  network_interface_id = aws_network_interface.eth0.id
}

resource "aws_network_interface_sg_attachment" "internalattachment" {
  depends_on           = [aws_network_interface.fgt1eth1]
  security_group_id    = aws_security_group.fw-data-sg.id
  network_interface_id = aws_network_interface.fgt1eth1.id
}


resource "aws_instance" "fgtvm" {
  //it will use region, architect, and license type to decide which ami to use for deployment
  ami               = var.fgtami[var.region][var.arch][var.license_type]
  instance_type     = var.size
  availability_zone = var.azs[0]
  key_name          = var.keyname
  user_data = chomp(templatefile("${var.bootstrap-fgtvm}", {
    type         = "${var.license_type}"
    license_file = "${var.license}"
    adminsport   = "${var.adminsport}"
    cidr         = "${var.fw_data_subnets[1]}"
    gateway      = cidrhost(var.fw_data_subnets[0], 1)
    endpointip   = "${data.aws_network_interface.vpcendpointip.private_ip}"
    endpointip2  = "${data.aws_network_interface.vpcendpointipaz2.private_ip}"
  }))

  root_block_device {
    volume_type = "standard"
    volume_size = "2"
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "30"
    volume_type = "standard"
  }

  network_interface {
    network_interface_id = aws_network_interface.eth0.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.fgt1eth1.id
    device_index         = 1
  }

  tags = {
    Name = "FortiGateVM1"
  }
}
