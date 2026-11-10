resource "cloudflare_zero_trust_access_identity_provider" "otp" {
  account_id = var.account_id
  name       = "One-time PIN"
  type       = "onetimepin"
  config     = {}
}

resource "cloudflare_zero_trust_access_policy" "admin_only" {
  account_id       = var.account_id
  name             = "admin only"
  decision         = "allow"
  session_duration = "12h"

  include = [{
    email = { email = var.admin_email }
  }]
}

resource "cloudflare_zero_trust_access_application" "internal" {
  account_id                = var.account_id
  name                      = "internal app"
  type                      = "self_hosted"
  domain                    = "internal.${var.domain}"
  session_duration          = "12h"
  allowed_idps              = [cloudflare_zero_trust_access_identity_provider.otp.id]
  auto_redirect_to_identity = true

  policies = [{
    id         = cloudflare_zero_trust_access_policy.admin_only.id
    precedence = 1
  }]
}
