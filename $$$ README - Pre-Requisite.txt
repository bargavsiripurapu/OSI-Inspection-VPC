1. Create a Key Pair in management console and Download it. Copy the name of keypair and add it in variable.tf line 401. This keypair which you will define will used for ec2 instances.
2. Enter your Secret key, access key and region information in terraform.tfvar file. AZ's needs to be modified according to the region.
3. Subnet information has been already defined according to the proposed architecture.
4. Private-VPC.tf and Public-VPC.tf is optional and created for testing purposes. This can be taken as a reference configuration for the existing VPC's.
5. Run the following commands to run this script:
	Terraform init
	Terraform plan (To sort out the errors if any)
	Terraform apply
To delete the infrastructure:
	Terraform destroy

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------

Script Changes:

Change 1: Default route to Firewall Data interface was missing.

1. Added the Default route 0.0.0.0/0 towards Firewall Data Interface for Traffic Inspection.
2. File > osi-inspect-rt.tf
line 35, Route to Firewall-1
route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_network_interface.eth1.id
    }

line 62, Route to Firewall-2
route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_network_interface.fgt2eth1.id
    }
============================================================================================================================

Change 2: Ping Connection was not working between Workload/Shared Service Instances to Firewall (vise-versa)

1. Add Route in Workload/Shared Service subnet (private/public) for FORTIGATE DATA Subnet with Next hop TransitGateway. We will add destination CIDR as 
inspection VPC as there are 2 Firewall Data Subnet.

- File > Private-VPC.tf
Line 59, Route to Firewall Data Interface / Inspection VPC

resource "aws_route" "cs-tmp-firewallroute" {
  depends_on             = [aws_route_table.csprivatert]
  route_table_id         = aws_route_table.csprivatert.id
  destination_cidr_block = "Inspection VPC(10.1.0.0/22)"
  transit_gateway_id     = aws_ec2_transit_gateway.osi-tgw.id
}

- File > Pulbic-VPC.tf
  Line 189,Workload VPC with AZ deployment

resource "aws_route" "pv-internalfirewallrouteaz1" {
  depends_on             = [aws_route_table.pv-publicrtaz1]
  route_table_id         = aws_route_table.pv-publicrtaz1.id
  destination_cidr_block = "Inspection VPC(10.1.0.0/22)"
  transit_gateway_id     = aws_ec2_transit_gateway.osi-tgw.id
}


resource "aws_route" "pv-internalfirewallrouteaz2" {
  depends_on             = [aws_route_table.pv-publicrtaz2]
  route_table_id         = aws_route_table.pv-publicrtaz2.id
  destination_cidr_block = "Inspection VPC(10.1.0.0/22)"
  transit_gateway_id     = aws_ec2_transit_gateway.osi-tgw.id
}

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

2. Add Route in DATA subnet routing table for WORKLOAD/Shared Service VPC with Next hop TransitGateway.
- File > osi-inpsect-rt.tf
  Line 40 & 68 (AZ wise)

route {
    cidr_block = "Workload/Shared Service Subnet/VPC"
    transit_gateway_id = aws_ec2_transit_gateway.osi-tgw.id
    }

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

3. Add Static route in fortigate OS for WORKLOAD/SHARED service VPC with next Hop as Data Subnet Gateway.
File> fgtvm1.conf and fgtvm2.conf

Line 99,

edit 4
set dst 20.0.0.0 255.0.0.0
set gateway 10.1.0.1
set device "port2"
next

Note: PING Connectivity doesn't work over GENEVE Protocol as connection is to/from the firewall interface.