# Simple cluster SG allowing API server & intra-VPC traffic
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "EKS cluster SG"
  vpc_id      = var.vpc_id

  # allow nodes/pods to talk within VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }

  tags = { Name = "${var.cluster_name}-cluster-sg" }
}

output "cluster_sg_id" { value = aws_security_group.cluster.id }
