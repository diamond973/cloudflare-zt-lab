resource "cloudflare_zero_trust_gateway_policy" "block_domains" {
  account_id  = var.account_id
  name        = "block lab domains"
  description = "DNS filtering for WARP users"
  precedence  = 10
  action      = "block"
  filters     = ["dns"]
  traffic     = "any(dns.domains[*] in {${join(" ", formatlist("\"%s\"", var.blocked_domains))}})"
  enabled     = true
}

# Private network: admin in, everyone else out. Replaces the VPN ACL.
resource "cloudflare_zero_trust_gateway_policy" "private_allow_admin" {
  account_id = var.account_id
  name       = "private net: allow admin"
  precedence = 20
  action     = "allow"
  filters    = ["l4"]
  traffic    = "net.dst.ip in {${var.private_cidr}}"
  identity   = "identity.email == \"${var.admin_email}\""
  enabled    = true
}

resource "cloudflare_zero_trust_gateway_policy" "private_block_rest" {
  account_id = var.account_id
  name       = "private net: block everyone else"
  precedence = 30
  action     = "block"
  filters    = ["l4"]
  traffic    = "net.dst.ip in {${var.private_cidr}}"
  enabled    = true
}
