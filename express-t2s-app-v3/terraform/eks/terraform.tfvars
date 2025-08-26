cluster_name       = "prod-cluster"
instance_count     = 1
instance_size      = "t2.micro"
region             = "us-east-1"
cluster_version    = "1.27"
ami_id             = "ami-04e5276ebb8451442"
vpc-cni-version    = "v1.18.0-eksbuild.1"
kube-proxy-version = "v1.27.10-eksbuild.2"