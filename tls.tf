locals {
  zone_settings = {
    ssl                      = "strict" # Full (strict): origin cert must be valid
    always_use_https         = "on"
    min_tls_version          = "1.2"
    tls_1_3                  = "on"
    automatic_https_rewrites = "on"
  }
}

resource "cloudflare_zone_setting" "lab" {
  for_each = local.zone_settings

  zone_id    = var.zone_id
  setting_id = each.key
  value      = each.value
}
