resource "random_bytes" "tunnel_secret" {
  length = 32
}

# Remotely managed tunnel: ingress lives here, cloudflared only needs the token.
resource "cloudflare_zero_trust_tunnel_cloudflared" "lab" {
  account_id    = var.account_id
  name          = "cf-zt-lab"
  config_src    = "cloudflare"
  tunnel_secret = random_bytes.tunnel_secret.base64
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "lab" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.lab.id

  config = {
    ingress = [
      {
        hostname = "app.${var.domain}"
        service  = "http://app:80"
      },
      {
        hostname = "internal.${var.domain}"
        service  = "http://internal:80"
      },
      {
        service = "http_status:404"
      },
    ]
  }
}

# Private subnet behind the tunnel, reachable from WARP clients.
resource "cloudflare_zero_trust_tunnel_cloudflared_route" "private" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.lab.id
  network    = var.private_cidr
  comment    = "lab private network"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "lab" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.lab.id
}
