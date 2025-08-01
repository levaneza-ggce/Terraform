# Find the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create a new VPC for our resources
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Create an Internet Gateway to allow internet access
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Create a Route Table to route traffic to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the Route Table with our public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a Security Group to allow SSH and WireGuard traffic
resource "aws_security_group" "allow_traffic" {
  name        = "allow_ssh_wireguard"
  description = "Allow SSH and WireGuard inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "WireGuard from anywhere"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_wireguard"
  }
}

# --- Use Existing Public Key ---

# Create an AWS key pair from the provided public key
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-ec2-key" # You can change this name if you like
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj70Ba4jveChzoWoFftffC9BNwJJ/L7wE9CI2AnMNQO4knoe/SVdDGmy1XVoek6NAX8Sqq7qdiTC3+UTqr/CHqIlheLFN2js+87yH8FKpoTykzNJPtCmIsL1MHcRGEAP5ud0OXwDENdRYbNA5GIZyveeoTLMd0MSs3jpeU28mmQ+fJ2yMj38zNjMobaQWCh7Jx5TxJDCeTKmGFmaOiepQ9lNkDoE2sEiUyqcVQS+gCeZkyASekvpHMqrBt7uiroU4xwYFmZV2ftAsgnbBXSqsoQ3oXlHZwSowCY/JXTW9nBLcrWKBy3K5V9ZQdve3ZRRdSXKkiteoZavc2IHfKFVm1tlpQfQYKl6VpZj9wOrKm0Rxj9oCifQ4YelAAnpynFWZDn8jy8b6UrYNA78ISFf7o6riPZiIaGXjD4vcNb82l+hQE0eZIArABkjsKOVR1Cy1SVuGbBQe4n1Jz+yU/dSvok8c4xTRqGNOv7fwt546V3lrXIrOYyCyquc9kLMh1lk0= la@goplayground"
}

# --- End of Key Pair ---

# Create a free-tier eligible EC2 instance
resource "aws_instance" "my_test_instance" {
  ami                    = data.aws_ami.ubuntu.id # Use the Ubuntu AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_traffic.id]
  key_name               = aws_key_pair.my_key_pair.key_name

  # Install WireGuard on Ubuntu
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y wireguard
              EOF

  tags = {
    Name = "My Ubuntu Instance"
  }
}
