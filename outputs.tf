output "amd64_instance_id" {
  description = "EC2 instance ID for AMD64"
  value       = var.enable_amd64_instance ? aws_instance.consensus_node_amd64[0].id : null
}

output "amd64_public_ip" {
  description = "Public IP address for AMD64 instance"
  value       = var.enable_amd64_instance ? aws_instance.consensus_node_amd64[0].public_ip : null
}

output "arm64_instance_id" {
  description = "EC2 instance ID for ARM64"
  value       = var.enable_arm64_instance ? aws_instance.consensus_node_arm64[0].id : null
}

output "arm64_public_ip" {
  description = "Public IP address for ARM64 instance"
  value       = var.enable_arm64_instance ? aws_instance.consensus_node_arm64[0].public_ip : null
}

output "ssh_command_amd64" {
  description = "SSH command for AMD64 instance"
  value = var.enable_amd64_instance ? format(
    "ssh -i ~/.ssh/lean-consensus-aws ubuntu@%s",
    aws_instance.consensus_node_amd64[0].public_ip
  ) : null
}

output "ssh_command_arm64" {
  description = "SSH command for ARM64 instance"
  value = var.enable_arm64_instance ? format(
    "ssh -i ~/.ssh/lean-consensus-aws ubuntu@%s",
    aws_instance.consensus_node_arm64[0].public_ip
  ) : null
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.consensus_node.id
}

output "metrics_urls_amd64" {
  description = "Prometheus metrics URLs for AMD64 instance"
  value = var.enable_amd64_instance ? {
    zeam_0  = format("http://%s:8080/metrics", aws_instance.consensus_node_amd64[0].public_ip)
    ream_0  = format("http://%s:8081/metrics", aws_instance.consensus_node_amd64[0].public_ip)
    qlean_0 = format("http://%s:8082/metrics", aws_instance.consensus_node_amd64[0].public_ip)
  } : null
}

output "metrics_urls_arm64" {
  description = "Prometheus metrics URLs for ARM64 instance"
  value = var.enable_arm64_instance ? {
    zeam_0  = format("http://%s:8080/metrics", aws_instance.consensus_node_arm64[0].public_ip)
    ream_0  = format("http://%s:8081/metrics", aws_instance.consensus_node_arm64[0].public_ip)
    qlean_0 = format("http://%s:8082/metrics", aws_instance.consensus_node_arm64[0].public_ip)
  } : null
}
