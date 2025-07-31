# Create a Virtual Private Gateway and attach it to our VPC
resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-vpn-gateway"
  }
}

# Create a Customer Gateway, representing your on-premises router
# IMPORTANT: Replace 1.2.3.4 with the actual public IP of your on-premises router
resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = "1.2.3.4"
  type       = "ipsec.1"
  tags = {
    Name = "on-premises-gateway"
  }
}

# Create the Site-to-Site VPN Connection
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
    Name = "vpc-to-on-premises"
  }
}

# Create a new route table for the private network
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # Route for traffic destined for the on-premises network
  # IMPORTANT: Replace 192.168.1.0/24 with your on-premises network's CIDR block
  route {
    cidr_block = "192.168.1.0/24"
    gateway_id = aws_vpn_gateway.main.id # Corrected from vpn_gateway_id
  }

  tags = {
    Name = "private-route-table"
  }
}

# To make this functional, you would also need a private subnet and associate it with this route table.
# For example:
# resource "aws_subnet" "private" {
#   vpc_id     = aws_vpc.main.id
#   cidr_block = "10.0.2.0/24"
#   tags = {
#     Name = "private-subnet"
#   }
# }
#
# resource "aws_route_table_association" "private" {
#   subnet_id      = aws_subnet.private.id
#   route_table_id = aws_route_table.private.id
# }
