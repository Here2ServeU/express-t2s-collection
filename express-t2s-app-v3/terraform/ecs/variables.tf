variable "region" {}
variable "cluster_name" {}
variable "task_family" {}
variable "cpu" {}
variable "memory" {}
variable "execution_role_arn" {}
variable "task_role_arn" {}
variable "container_name" {}
variable "image_url" {}
variable "image_tag" {}
variable "container_port" {}
variable "desired_count" {}
variable "subnet_ids" {
  type = list(string)
}
variable "security_group_id" {}