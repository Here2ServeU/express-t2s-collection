variable "region"         { type = string default = "us-east-1" }
variable "repo_name"      { type = string }
variable "image_tag"      { type = string default = "latest" }
variable "scan_on_push"   { type = bool   default = true }
variable "lifecycle_keep" { type = number default = 10 }
