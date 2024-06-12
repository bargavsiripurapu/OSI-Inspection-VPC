# ---------------------------------------------------------------------------------------------------------------------
# MANDATORY PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------
region = "us-east-1"  # Set your preferred AWS region here
access_key = "AKIATCKAQOOO5W5S3VP7"
secret_key = "imPN/U+K6DuCQ1g8id6i3+jJdTeE9pTk26ceW6NB"
azs = ["us-east-1a", "us-east-1b"] #set azs according to region
ins_vpc_cidr = "10.1.0.0/22"
ins_vpc_name = "Inspection-VPC"
#Total number of firewalls needed.
fw_count = 2
#Network CIDRs allowed to access FW Management ENI
fw_mgmt_sg_list =["0.0.0.0/0"]
#Inspection-VPC subnets
tgw_subnets = ["10.1.2.64/28", "10.1.3.64/28"]
gwlbe_subnets = ["10.1.2.48/28", "10.1.3.48/28"]
natgw_subnets = ["10.1.2.32/28", "10.1.3.32/28"]
fw_mgmt_subnets = ["10.1.2.0/27", "10.1.3.0/27"]
fw_data_subnets = ["10.1.0.0/24", "10.1.1.0/24"]
transitgw_id = ""
route_table_cidr_blocks = [
  "0.0.0.0/0",
  "20.0.0.0/8"
]

