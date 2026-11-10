# cloudflare-zt-lab

[![terraform](https://github.com/diamond973/cloudflare-zt-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/diamond973/cloudflare-zt-lab/actions/workflows/ci.yml)

Cloudflare edge and Zero Trust for a small company, as Terraform code:
DNS, TLS, WAF, rate limiting, Cloudflare Tunnel, Access and WARP + Gateway
instead of a classic VPN. Built on the free plan.

## Design

```
                     Internet users                      Admin laptop (WARP)
                           |                                     |
                   Cloudflare edge (anycast)            Cloudflare Gateway
              DNS · TLS · WAF · rate limit · bots       DNS filter · L4 policy
                           |                                     |
            app.<domain>       internal.<domain>                 |
            public             Access: OTP, admin only           |
                           \          |                         /
                            \         |                        /
                         Cloudflare Tunnel (outbound only, QUIC)
                                      |
                        Origin VM · 10.20.0.0/24 · no inbound ports
                        nginx app · nginx internal · cloudflared
```

- **No open ports.** cloudflared dials out to Cloudflare; the origin firewall drops all inbound traffic.
- **Public app** sits behind the managed WAF, custom rules and a rate limit on `/login`.
- **Internal app** is published through the same tunnel but every request goes through Cloudflare Access first.
- **Private network** `10.20.0.0/24` is routed through the tunnel. WARP users reach it by private IP; a Gateway L4 policy lets in only the admin identity. This is the VPN replacement.

## What is in the code

| File | What it does |
|---|---|
| `dns.tf` | CNAMEs to the tunnel, SPF `-all` and DMARC `p=reject` for a no-mail domain, DNSSEC |
| `tls.tf` | SSL Full (strict), Always HTTPS, TLS 1.2 minimum, TLS 1.3 |
| `waf.tf` | Cloudflare Free Managed Ruleset, custom rules (`/admin` by country, dotfile scanners), rate limit on login, Bot Fight Mode |
| `tunnel.tf` | Remotely managed tunnel, ingress rules, private network route, connector token |
| `access.tf` | One-time PIN identity provider, reusable policy, self-hosted Access application |
| `gateway.tf` | DNS block list, L4 allow/deny for the private network by identity |
| `origin/` | docker-compose for the origin VM: two nginx apps and cloudflared |

CI runs `terraform fmt -check` and `terraform validate` on every push.

## Run it

Requirements: a Cloudflare account, a domain added as a zone, Terraform >= 1.6, a Linux VM with Docker.

```bash
export CLOUDFLARE_API_TOKEN=...      # token scoped to the account and the zone
cp terraform.tfvars.example terraform.tfvars   # fill in IDs, domain, email
terraform init
terraform apply

# on the origin VM
cd origin
echo "TUNNEL_TOKEN=$(terraform output -raw tunnel_token)" > .env
docker compose up -d
```

Manual steps the free plan does not expose well in Terraform: Zero Trust team name,
WARP device enrollment rules, installing WARP on the client.

## Checks

| Check | Expected |
|---|---|
| `curl -I https://app.<domain>` | 200 through Cloudflare (`cf-ray` header) |
| `nmap -Pn <origin public IP>` | no open ports |
| `curl "https://app.<domain>/?id=1' OR '1'='1"` | blocked by the managed WAF, event in Security Events |
| 6 POSTs to `/login` in 10 s | 429 / block from the rate limit |
| `https://internal.<domain>` | Access login page, OTP only for the admin email |
| `ping 10.20.0.x` from a WARP laptop | works for the admin, blocked for any other identity |
| `dig example-malware.test` over WARP | blocked by Gateway |

## Status

- [x] Terraform for DNS, TLS, WAF, rate limit, Tunnel, Access, Gateway (validated in CI)
- [x] Origin VM compose file
- [ ] Apply against a live zone and run the checks above
- [ ] Screenshots of Security Events and Gateway logs
- [ ] WARP device enrollment as code

## Beyond the free plan: Magic WAN

Not built here (enterprise only), but the design follows the same model:
branches and datacenters connect to the nearest Cloudflare anycast PoP over GRE or IPsec,
routes are exchanged with BGP or static routes, and the Cloudflare network becomes the WAN backbone
with Gateway policies applied between sites. The provider has `cloudflare_magic_wan_ipsec_tunnel`
and `cloudflare_magic_wan_gre_tunnel` for that.
