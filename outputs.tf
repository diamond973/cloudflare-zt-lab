output "tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.lab.id
}

output "tunnel_token" {
  description = "Put into origin/.env as TUNNEL_TOKEN"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.lab.token
  sensitive   = true
}
