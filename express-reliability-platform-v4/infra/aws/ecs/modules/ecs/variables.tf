variable "name" { type = string }
variable "aws_region" { type = string }
variable "vpc_id" { type = string }
variable "public_subnets" { type = list(string) }
variable "node_image" { type = string }
variable "flask_image" { type = string }
variable "node_port" { type = number }
variable "flask_port" { type = number }
