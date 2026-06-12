# ec2.tf - EC2 Instance with CloudWatch Agent

# SSH Key Pair
resource "tls_private_key" "ssh" {
  count     = var.create_new_key_pair ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  count      = var.create_new_key_pair ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ssh[0].public_key_openssh

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-key"
    }
  )
}

# Save private key locally
resource "local_file" "private_key" {
  count           = var.create_new_key_pair ? 1 : 0
  content         = tls_private_key.ssh[0].private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0400"
}

# EC2 Instance
resource "aws_instance" "cloudwatch_lab" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_cloudwatch.name
  key_name               = var.create_new_key_pair ? aws_key_pair.generated[0].key_name : var.key_name
  
  monitoring = var.enable_detailed_monitoring

  user_data = templatefile("${path.module}/user-data.sh", {
    region      = var.aws_region
    config_json = file("${path.module}/../cloudwatch-config.json")
  })

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true

    tags = merge(
      local.common_tags,
      {
        Name = "${var.project_name}-root-volume"
      }
    )
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-instance"
    }
  )

  lifecycle {
    ignore_changes = [user_data]
  }
}
