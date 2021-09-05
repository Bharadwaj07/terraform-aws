provider "aws" {
  region  = "ap-south-1"
  access_key = "<access_key>"
  secret_key = "<secret_key>"
}

#create vpc
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
#create IG
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id
}

# create route table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id

  route = [
    {
        cidr_block = "0.0.0.0/0"
        ipv6_cidr_block        = null
        gateway_id = aws_internet_gateway.ig.id
        carrier_gateway_id = null
        destination_prefix_list_id = null
        egress_only_gateway_id = null
        instance_id = null
        local_gateway_id = null
        nat_gateway_id = null
        network_interface_id = null
        transit_gateway_id = null
        vpc_endpoint_id = null
        vpc_peering_connection_id = null
    }
  ]

  tags = {
    Name = "example"
  }
}
#create subnet
resource "aws_subnet" "subnet_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "test subnet"
  }
} 
#subnet assosiation
resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route_table.id
}

#security group 
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow WEB inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress = [
    {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      self             = null
      security_groups  = null
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      self             = null
      security_groups  = null
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      self             = null
      security_groups  = null
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  ]

  egress = [
    { 
      description      = "All Trafic"
      prefix_list_ids  = null
      self             = null
      security_groups  = null
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  ]

  tags = {
    Name = "allow_web"
  }
}

# create network interface
resource "aws_network_interface" "nic"  {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

#eip
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.ig
  ]
}

#instance 
resource "aws_instance" "ubuntu_web_server" {
  ami           = "ami-04bde106886a53080" 
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "testingKeyPair"

  network_interface {
    network_interface_id = aws_network_interface.nic.id
    device_index         = 0
  }
  user_data = <<-EOF
            #!/bin/bash
            sudo apt-get update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2 
            sudo bash -c 'echo your very first web server > /var/www/html/index.html'
            EOF
    tags = {
      Name = "test-instance"
    }

}
