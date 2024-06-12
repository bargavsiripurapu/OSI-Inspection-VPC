output "tgw_attachment_id_of_sec_vpc" {
  value = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-ins_vpc.id
}

output "FGTPublicIP" {
  value = aws_eip.FGTPublicIP.public_ip
}

output "FGT2PublicIP" {
  value = aws_eip.FGT2PublicIP.public_ip
}

output "FGT1-Password" {
  value = aws_instance.fgtvm.id
}

output "FGT2-Password" {
  value = aws_instance.fgtvm2.id
}