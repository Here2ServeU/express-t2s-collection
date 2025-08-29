data "aws_iam_openid_connect_provider" "eks" {
  arn = var.oidc_provider_arn
}

locals {
  oidc_url_no_scheme = replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")
  controller_sa_sub  = "system:serviceaccount:kube-system:aws-load-balancer-controller"
}

resource "aws_iam_role" "alb" {
  name = "${var.cluster_name}-alb-role"
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

resource "aws_iam_role_policy_attachment" "alb_admin" {
  role       = aws_iam_role.alb.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # swap to least-privilege later
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  set { name = "clusterName"; value = var.cluster_name }
  set { name = "region";      value = var.region }
  set { name = "vpcId";       value = var.vpc_id }

  set { name = "serviceAccount.create"; value = "true" }
  set { name = "serviceAccount.name";   value = "aws-load-balancer-controller" }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb.arn
  }

  depends_on = [aws_iam_role.alb, aws_iam_role_policy_attachment.alb_admin]
}

output "alb_controller_installed" { value = true }
