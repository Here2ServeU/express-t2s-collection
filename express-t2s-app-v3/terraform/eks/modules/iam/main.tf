############################
# EKS Cluster Role
############################
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

############################
# Node Group Role
############################
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

############################
# ALB Controller IRSA Role
############################
data "aws_iam_openid_connect_provider" "eks" {
  arn = var.oidc_provider_arn
}
locals {
  oidc_url_no_scheme = replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")
  controller_sa_sub  = "system:serviceaccount:kube-system:aws-load-balancer-controller"
}
resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Federated = var.oidc_provider_arn },
      Action    = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${local.oidc_url_no_scheme}:aud" = "sts.amazonaws.com",
          "${local.oidc_url_no_scheme}:sub" = local.controller_sa_sub
        }
      }
    }]
  })
}
# TEMP: broad policy; swap to least privilege later
resource "aws_iam_role_policy_attachment" "alb_controller_admin" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "cluster_role_arn"        { value = aws_iam_role.cluster.arn }
output "node_role_arn"           { value = aws_iam_role.node.arn }
output "alb_controller_role_arn" { value = aws_iam_role.alb_controller.arn }
