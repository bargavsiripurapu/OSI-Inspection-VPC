// FGTVM instance AZ2

resource "aws_network_interface" "fgt2eth0" {
  description = "fgtvm2-port1"
  subnet_id   = aws_subnet.fw_mgmt_subnet[1].id
  }

resource "aws_network_interface" "fgt2eth1" {
  description       = "fgtvm2-port2"
  subnet_id         = aws_subnet.fw_data_subnet[1].id
  source_dest_check = false
}

data "aws_network_interface" "fgt2eth1" {
  id = aws_network_interface.fgt2eth1.id
}

resource "aws_eip" "FGT2PublicIP" {
  depends_on        = [aws_instance.fgtvm2]
  domain            = "vpc"
  network_interface = aws_network_interface.fgt2eth0.id
}

//
data "aws_network_interface" "vpcendpointipaz2" {
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
  //  Using AZ1's endpoint ip
  filter {
    name   = "availability-zone"
    values = ["${var.azs[1]}"]
  }
}

resource "aws_network_interface_sg_attachment" "fgt2publicattachment" {
  depends_on           = [aws_network_interface.fgt2eth0]
  security_group_id    = aws_security_group.fw-mgmt-sg.id
  network_interface_id = aws_network_interface.fgt2eth0.id
}

resource "aws_network_interface_sg_attachment" "fgt2internalattachment" {
  depends_on           = [aws_network_interface.fgt2eth1]
  security_group_id    = aws_security_group.fw-data-sg.id
  network_interface_id = aws_network_interface.fgt2eth1.id
}


resource "aws_instance" "fgtvm2" {
  //it will use region, architect, and license type to decide which ami to use for deployment
  ami               = var.fgtami[var.region][var.arch][var.license_type]
  instance_type     = var.size
  availability_zone = var.azs[1]
  key_name          = var.keyname
  user_data = chomp(templatefile("${var.bootstrap-fgtvm2}", {
    type         = "${var.license_type}"
    license_file = "${var.license2}"
    adminsport   = "${var.adminsport}"
    cidr         = "${var.fw_data_subnets[0]}"
    gateway      = cidrhost(var.fw_data_subnets[1], 1)
    endpointip   = "${data.aws_network_interface.vpcendpointipaz2.private_ip}"
    endpointip2  = "${data.aws_network_interface.vpcendpointip.private_ip}"
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
    network_interface_id = aws_network_interface.fgt2eth0.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.fgt2eth1.id
    device_index         = 1
  }

  tags = {
    Name = "FortiGateVM2"
  }
}
