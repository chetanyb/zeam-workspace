terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "lean-consensus"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Data sources
data "aws_ami" "ubuntu_amd64" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "ubuntu_arm64" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

# Security group
resource "aws_security_group" "consensus_node" {
  name_prefix = "${var.environment}-consensus-node-"
  description = "Security group for lean consensus nodes"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_ips
  }

  ingress {
    description = "QUIC P2P - zeam_0"
    from_port   = 9000
    to_port     = 9000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "QUIC P2P - ream_0"
    from_port   = 9001
    to_port     = 9001
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "QUIC P2P - qlean_0"
    from_port   = 9002
    to_port     = 9002
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Metrics ports"
    from_port   = 8080
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = var.metrics_allowed_ips
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.environment}-consensus-node-sg"
  }
}

# SSH key pair
resource "aws_key_pair" "consensus_node" {
  key_name_prefix = "${var.environment}-consensus-node-"
  public_key      = var.ssh_public_key

  tags = {
    Name = "${var.environment}-consensus-node-key"
  }
}

# IAM role for EC2
resource "aws_iam_role" "consensus_node" {
  name_prefix = "${var.environment}-consensus-node-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.environment}-consensus-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "consensus_node_cloudwatch" {
  role       = aws_iam_role.consensus_node.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "consensus_node" {
  name_prefix = "${var.environment}-consensus-node-"
  role        = aws_iam_role.consensus_node.name

  tags = {
    Name = "${var.environment}-consensus-node-profile"
  }
}

# AMD64 instance
resource "aws_instance" "consensus_node_amd64" {
  count = var.enable_amd64_instance ? 1 : 0

  ami           = data.aws_ami.ubuntu_amd64.id
  instance_type = var.instance_type_amd64

  key_name                    = aws_key_pair.consensus_node.key_name
  vpc_security_group_ids      = [aws_security_group.consensus_node.id]
  iam_instance_profile        = aws_iam_instance_profile.consensus_node.name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size_gb
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.environment}-consensus-amd64-root"
    }
  }

  user_data = file("${path.module}/user-data.sh")

  monitoring = var.enable_detailed_monitoring

  disable_api_termination = var.environment == "prod" ? true : false

  tags = {
    Name         = "${var.environment}-consensus-node-amd64"
    Architecture = "amd64"
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
    ]
  }
}

# ARM64 instance
resource "aws_instance" "consensus_node_arm64" {
  count = var.enable_arm64_instance ? 1 : 0

  ami           = data.aws_ami.ubuntu_arm64.id
  instance_type = var.instance_type_arm64

  key_name                    = aws_key_pair.consensus_node.key_name
  vpc_security_group_ids      = [aws_security_group.consensus_node.id]
  iam_instance_profile        = aws_iam_instance_profile.consensus_node.name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size_gb
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.environment}-consensus-arm64-root"
    }
  }

  user_data = file("${path.module}/user-data.sh")

  monitoring = var.enable_detailed_monitoring

  disable_api_termination = var.environment == "prod" ? true : false

  tags = {
    Name         = "${var.environment}-consensus-node-arm64"
    Architecture = "arm64"
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
    ]
  }
}
