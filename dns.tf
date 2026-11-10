locals {
  tunnel_cname = "${cloudflare_zero_trust_tunnel_cloudflared.lab.id}.cfargotunnel.com"
}

# Public app and internal app both go through the tunnel: no A records, no open ports.
resource "cloudflare_dns_record" "app" {
  zone_id = var.zone_id
  name    = "app.${var.domain}"
  type    = "CNAME"
  content = local.tunnel_cname
  proxied = true
  ttl     = 1
  comment = "public app via Cloudflare Tunnel"
}

resource "cloudflare_dns_record" "internal" {
  zone_id = var.zone_id
  name    = "internal.${var.domain}"
  type    = "CNAME"
  content = local.tunnel_cname
  proxied = true
  ttl     = 1
  comment = "internal app via Cloudflare Tunnel, behind Access"
}

# Domain sends no mail: say so, so nobody can spoof it.
resource "cloudflare_dns_record" "spf" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "TXT"
  content = "\"v=spf1 -all\""
  ttl     = 3600
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id = var.zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  content = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s\""
  ttl     = 3600
}

resource "cloudflare_zone_dnssec" "lab" {
  zone_id = var.zone_id
  status  = "active"
}
