# Cloudflare Free Managed Ruleset, deployed on the zone.
resource "cloudflare_ruleset" "managed_waf" {
  zone_id = var.zone_id
  name    = "managed WAF"
  kind    = "zone"
  phase   = "http_request_firewall_managed"

  rules = [{
    description = "Cloudflare Free Managed Ruleset"
    expression  = "true"
    action      = "execute"
    action_parameters = {
      id = "77454fe2d30c4220b5701f6fdfb893ba"
    }
  }]
}

resource "cloudflare_ruleset" "custom_waf" {
  zone_id = var.zone_id
  name    = "custom WAF"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules = [
    {
      description = "/admin only from allowed countries"
      expression  = "(http.host eq \"app.${var.domain}\" and starts_with(http.request.uri.path, \"/admin\") and not ip.src.country in {${join(" ", formatlist("\"%s\"", var.allowed_admin_countries))}})"
      action      = "block"
    },
    {
      description = "no scanners for dotfiles and backups"
      expression  = "(http.request.uri.path contains \"/.env\" or http.request.uri.path contains \"/.git\" or ends_with(http.request.uri.path, \".bak\"))"
      action      = "block"
    },
  ]
}

# Free plan: one rate limiting rule, 10 s period and 10 s mitigation.
resource "cloudflare_ruleset" "rate_limit" {
  zone_id = var.zone_id
  name    = "rate limit"
  kind    = "zone"
  phase   = "http_ratelimit"

  rules = [{
    description = "login brute force"
    expression  = "(http.request.uri.path eq \"/login\" and http.request.method eq \"POST\")"
    action      = "block"
    ratelimit = {
      characteristics     = ["cf.colo.id", "ip.src"]
      period              = 10
      requests_per_period = 5
      mitigation_timeout  = 10
    }
  }]
}

resource "cloudflare_bot_management" "lab" {
  zone_id    = var.zone_id
  fight_mode = true
}
