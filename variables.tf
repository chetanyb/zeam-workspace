# General settings
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

# Compute settings
variable "instance_type_amd64" {
  description = "EC2 instance type for AMD64 architecture"
  type        = string
  default     = "t3.medium"
}

variable "instance_type_arm64" {
  description = "EC2 instance type for ARM64 architecture"
  type        = string
  default     = "t4g.medium"
}

variable "enable_amd64_instance" {
  description = "Whether to create the AMD64 instance"
  type        = bool
  default     = true
}

variable "enable_arm64_instance" {
  description = "Whether to create the ARM64 instance"
  type        = bool
  default     = false
}

variable "root_volume_size_gb" {
  description = "Size of root EBS volume in GB"
  type        = number
  default     = 30

  validation {
    condition     = var.root_volume_size_gb >= 30
    error_message = "Root volume must be at least 30 GB."
  }
}

# Networking and security
variable "ssh_public_key" {
  description = "SSH public key content for EC2 access"
  type        = string
}

variable "ssh_allowed_ips" {
  description = "List of IP addresses allowed to SSH (CIDR notation)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "metrics_allowed_ips" {
  description = "IPs allowed to access metrics ports (8080-8082)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Monitoring
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}
