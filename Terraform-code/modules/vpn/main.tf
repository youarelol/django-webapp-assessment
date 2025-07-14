resource "tls_private_key" "vpn_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "vpn_key" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.vpn_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.vpn_key.private_key_pem
  filename        = "${path.module}/openvpn.pem"
  file_permission = "0600"
}

resource "aws_security_group" "vpn-sg" {
  name        = "vpn-sg"
  description = "Enable needed access to Access Server"
  vpc_id      = var.aws_vpc_id

  ingress {
    description = "Admin Web UI"
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Admin Web UI (Alt)"
    from_port   = 945
    to_port     = 945
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "OpenVPN UDP"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "openvpn-security-group"
  }
}

resource "aws_eip" "vpn_eip" {
  domain = "vpc"
  tags = {
    Name = "OpenVPNAccessServer_EIP"
  }
}

resource "aws_instance" "OpenVPNAccessServer_Terraform" {
  ami               = var.ami_id
  instance_type     = var.aws_instance_type
  subnet_id         = var.aws_subnet_id
  key_name          = aws_key_pair.vpn_key.key_name
  security_groups   = [aws_security_group.vpn-sg.id]

  # Enable termination protection
  #disable_api_termination = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  

  user_data = <<-EOF
#!/bin/bash
set -ex

# Install using OpenVPN's official method
bash <(curl -fsS https://packages.openvpn.net/as/install.sh | sed 's/PLIST\\x3d\"openvpn-as\"/PLIST\\x3d\"openvpn-as\\x3d2.14.2*\"/') --yes

# Initialize with EC2 optimized settings
ovpn-init --ec2 --batch --force

# Wait for service socket to be available
while [ ! -S /usr/local/openvpn_as/etc/sock/sagent ]; do
  sleep 1
done

# Configure admin credentials
ADMIN_USER='${var.admin_username}'
ADMIN_PASS='${var.admin_password}'

# Set admin password and enable DCO
/usr/local/openvpn_as/scripts/sacli --user "$ADMIN_USER" --new_pass "$ADMIN_PASS" SetLocalPassword
/usr/local/openvpn_as/scripts/sacli -k 'vpn.server.daemon.ovpndco' -v 'true' ConfigPut

# Configure additional settings
/usr/local/openvpn_as/scripts/confdba -mk "admin_ui.https.ip_address" -v "all"
/usr/local/openvpn_as/scripts/confdba -mk "cs.https.ip_address" -v "all"

# Start services
/usr/local/openvpn_as/scripts/sacli start

# Verify admin user
/usr/local/openvpn_as/scripts/sacli --user "$ADMIN_USER" UserPropGet
EOF

  tags = {
    Name = "OpenVPNAccessServer"
  }
  lifecycle {
    ignore_changes = [
      public_ip,
      associate_public_ip_address,
      vpc_security_group_ids,
      security_groups,
    ]
  }
}
  
resource "aws_eip_association" "vpn_eip_association" {
  instance_id   = aws_instance.OpenVPNAccessServer_Terraform.id
  allocation_id = aws_eip.vpn_eip.id
}

resource "null_resource" "download_ovpn" {
  depends_on = [aws_instance.OpenVPNAccessServer_Terraform, aws_eip_association.vpn_eip_association]

  triggers = {
    instance_id = aws_instance.OpenVPNAccessServer_Terraform.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for OpenVPN to be ready..."
      sleep 300

      ssh-keygen -R ${aws_eip.vpn_eip.public_ip} 2>/dev/null
      ssh-keyscan -H ${aws_eip.vpn_eip.public_ip} >> ~/.ssh/known_hosts 2>/dev/null

      scp -i ${local_file.private_key.filename} -o StrictHostKeyChecking=no \
          ubuntu@${aws_eip.vpn_eip.public_ip}:/usr/local/openvpn_as/etc/client/openvpn.ovpn \
          ./openvpn.ovpn

      sed -i.bak "s/remote .*/remote ${aws_eip.vpn_eip.public_ip} 1194/" ./openvpn.ovpn
      echo "OpenVPN config downloaded successfully"
    EOT
  }
}