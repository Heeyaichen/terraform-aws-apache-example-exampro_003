data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_security_group" "sg_my_server" {
  name        = "sg_my_server"
  description = "MyServer Security Group"
  vpc_id      = data.aws_vpc.main.id

}

# Allow inbound HTTP traffic (IPv4)
resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.sg_my_server.id
  cidr_ipv4         = "0.0.0.0/0" # Open to everyone - aws_vpc.main.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Allow inbound SSH traffic (IPv6)
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv6" {
  security_group_id = aws_security_group.sg_my_server.id
  cidr_ipv6         = "::/0" # Open to everyone (IPv6) - aws_vpc.main.ipv6_cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Allow all outbound traffic (IPv4)
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sg_my_server.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports - allow all protocols and ports
}

# Allow all outbound traffic (IPv6)
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.sg_my_server.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports - allow all protocols and ports
}

# Allow SSH only from my IP (replace with your actual IP address)
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_my_ip" {
  security_group_id = aws_security_group.sg_my_server.id
  cidr_ipv4         = "49.47.140.154/32" # Replace with your actual IP address
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.public_key
}

data "template_file" "user_data" {
  template = file("${abspath(path.module)}/userdata.yml")
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


resource "aws_instance" "my_server" {
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.sg_my_server.id]
  user_data              = data.template_file.user_data.rendered

  tags = {
    Name = var.server_name
  }
}

