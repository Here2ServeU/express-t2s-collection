# Detect your current public IP from a simple endpoint
data "http" "admin_ip" {
  url = "https://checkip.amazonaws.com"
  # If you’re behind a corporate proxy and need headers, you can add:
  # request_headers = { "User-Agent" = "terraform" }
}

locals {
  detected_ip_raw = trimspace(try(data.http.admin_ip.response_body, ""))
  ipv4_regex      = "^([0-9]{1,3}\\.){3}[0-9]{1,3}$"

  # Prefer override if valid; else use detected IP if valid; else empty
  chosen_ip = (
    length(var.admin_ip_override) > 0 && length(regexall(local.ipv4_regex, var.admin_ip_override)) > 0
    ? var.admin_ip_override
    : (length(regexall(local.ipv4_regex, local.detected_ip_raw)) > 0 ? local.detected_ip_raw : "")
  )

  # Final CIDR list for your EKS public endpoint protection
  admin_cidrs = local.chosen_ip != "" ? ["${local.chosen_ip}/32"] : []
}

# Guard-rail: fail early if we couldn’t determine an IP
resource "null_resource" "assert_admin_ip" {
  lifecycle {
    precondition {
      condition     = length(local.admin_cidrs) > 0
      error_message = "Admin IP could not be determined. Set var.admin_ip_override or ensure data.http.admin_ip works."
    }
  }
}
