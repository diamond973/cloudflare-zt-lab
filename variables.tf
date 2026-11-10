variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "zone_id" {
  description = "Zone ID of the lab domain (zone is added in the dashboard, NS changed at the registrar)"
  type        = string
}

variable "domain" {
  description = "Lab domain, e.g. example.com"
  type        = string
}

variable "admin_email" {
  description = "The only identity allowed into internal apps and the private network"
  type        = string
}

variable "private_cidr" {
  description = "Private subnet behind the tunnel, reachable over WARP instead of a VPN"
  type        = string
  default     = "10.20.0.0/24"
}

variable "allowed_admin_countries" {
  description = "Countries allowed to open /admin on the public app"
  type        = list(string)
  default     = ["KZ"]
}

variable "blocked_domains" {
  description = "Domains blocked for WARP users by Gateway DNS policy"
  type        = list(string)
  default     = ["example-malware.test", "example-phishing.test"]
}
