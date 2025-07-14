# Outputs
output "admin_ui_url" {
  description = "OpenVPN Access Server Admin WebGUI URL"
  value       = "https://${aws_instance.OpenVPNAccessServer_Terraform.public_ip}:943/admin"
}

output "client_ui_url" {
  description = "OpenVPN Access Server Client WebGUI URL"
  value       = "https://${aws_instance.OpenVPNAccessServer_Terraform.public_ip}:943"
}

output "openvpnas_user" {
  description = "OpenVPN Access Server Admin Credentials"
  value = {
    admin_account  = var.admin_username
    admin_password = var.admin_password
  }
}
output "aws_security_group_id" {
  description = "Security group ID of the OpenVPN Access Server"
  value       = aws_security_group.vpn-sg.id
  
}
