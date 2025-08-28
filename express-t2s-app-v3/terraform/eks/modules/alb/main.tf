# IAM Role for Service Account (IRSA) for AWS Load Balancer Controller
# For production, replace AdministratorAccess with the official AWS LB Controller policy JSON and annotate the SA.

resource "aws_iam_role" "alb" {
  name               = "${var.cluster_name}-alb-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = var.oidc_provider_arn
      },
      Action = "sts:AssumeRoleWithWebIdentity"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}

output "alb_controller_installed" {
  value = true
}
