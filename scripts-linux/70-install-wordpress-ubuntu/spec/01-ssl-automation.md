# 01 — SSL automation (Let's Encrypt + DNS-01 + wildcard)

let's start now 2026-04-27 12:25 (UTC+8)

## Scope

Script 70 (`70-install-wordpress-ubuntu`) automates Let's Encrypt SSL for
the WordPress vhost on **Ubuntu 20.04 / 22.04 / 24.04**. Two challenge
types are supported, auto-selected based on flags:

| Flag combo                              | Challenge | Wildcard | Port 80 needed |
|-----------------------------------------|-----------|----------|----------------|
| `--https` (no `--dns`, no `--wildcard`) | HTTP-01   | no       | YES            |
| `--https --dns <provider>`              | DNS-01    | no       | no             |
| `--https --wildcard --dns <provider>`   | DNS-01    | YES      | no             |
| `--wildcard` without `--dns`            | rejected  | --       | --             |

**macOS is intentionally NOT supported.** Production WordPress runs on
Linux; macOS users should run script 70 on a remote Ubuntu host instead.

## Supported DNS providers

| Provider     | `--dns` value | Plugin package                 | Credentials              |
|--------------|---------------|--------------------------------|--------------------------|
| Cloudflare   | `cloudflare`  | `python3-certbot-dns-cloudflare` | INI file with `dns_cloudflare_api_token = ...` (Zone:DNS:Edit on the zone) |
| AWS Route53  | `route53`     | `python3-certbot-dns-route53`  | `~/.aws/credentials` OR `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` env (IAM permission: `route53:ChangeResourceRecordSets`) |
| DigitalOcean | `digitalocean`| `python3-certbot-dns-digitalocean` | INI file with `dns_digitalocean_token = ...` |
| Other / "I'll do it by hand" | `manual` | (built into certbot core) | none — certbot prompts for TXT records on stdin (NOT auto-renewable) |

For providers not in the table (Linode, Gandi, OVH, Namecheap, Hetzner,
…): a `certbot-dns-<provider>` plugin almost certainly exists on PyPI;
operators can `pip install` it and then pass its flags via the
`--manual` escape hatch or wrap script 70's component to add a new
case to `_https_certbot_install` and `_https_dns_authenticator_flags`.

## CLI flags

```
--https                obtain a Let's Encrypt cert + redirect HTTP->HTTPS
--email <addr>         contact email (omit -> --register-unsafely-without-email)
--https-staging        use LE staging endpoint (cert NOT browser-trusted)
--dns <provider>       cloudflare | route53 | digitalocean | manual
--dns-credentials <f>  INI file (chmod 600). Required for cloudflare/digitalocean.
--dns-propagation <s>  TXT record propagation wait, default 60s
--wildcard             *.<apex> + apex. Forces DNS-01.
```

`--dns` and `--wildcard` both implicitly set `WP_HTTPS=1` so the operator
can write `./run.sh install --dns cloudflare --dns-credentials …
--server-name example.com` without also passing `--https`.

## Credentials file format

### Cloudflare (`/etc/letsencrypt/cloudflare.ini`)

```ini
# Cloudflare scoped API token (Zone:DNS:Edit on the zone you're issuing for)
dns_cloudflare_api_token = abc123_your_scoped_token_here
```

Get the token at:
**Cloudflare dashboard → My Profile → API Tokens → Create Token →
"Edit zone DNS" template → restrict to the zone**.

```bash
sudo install -m 600 -o root -g root your-cloudflare.ini /etc/letsencrypt/cloudflare.ini
sudo ./run.sh install \
  --server-name example.com \
  --wildcard \
  --dns cloudflare \
  --dns-credentials /etc/letsencrypt/cloudflare.ini \
  --email you@example.com
```

### Route53

No file needed if the host has an IAM role with
`route53:ChangeResourceRecordSets` on the relevant hosted zone. Otherwise:

```bash
mkdir -p /root/.aws
cat > /root/.aws/credentials <<'AWS'
[default]
aws_access_key_id = AKIA...
aws_secret_access_key = ...
AWS
chmod 600 /root/.aws/credentials

sudo ./run.sh install \
  --server-name example.com \
  --wildcard \
  --dns route53 \
  --email you@example.com
```

Minimum IAM policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:GetChange"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ChangeResourceRecordSets",
      "Resource": "arn:aws:route53:::hostedzone/<YOUR_ZONE_ID>"
    }
  ]
}
```

### DigitalOcean (`/etc/letsencrypt/digitalocean.ini`)

```ini
dns_digitalocean_token = dop_v1_your_token_here
```

Get the token at: **DigitalOcean → API → Personal access tokens → "Write"
scope**. Store with `chmod 600`.

### Manual (`--dns manual`)

certbot pauses, prints the TXT record value, and waits for you to create
it at your DNS provider's UI before pressing Enter. **Renewals require
the same manual interaction**, so this is unsuitable for unattended hosts.
Use only for one-shot issuance you'll redo by hand.

## Wildcard expansion rules

When `--wildcard` is set, every server_name token is reduced to its apex
and gets BOTH the apex and a wildcard SAN:

| Input `--server-name`                       | Cert SANs |
|---------------------------------------------|-----------|
| `example.com`                               | `example.com`, `*.example.com` |
| `example.com www.example.com`               | `example.com`, `*.example.com` (www merged into wildcard) |
| `example.com www.example.com blog.foo.io`   | `example.com`, `*.example.com`, `blog.foo.io`, `*.blog.foo.io` |

A single wildcard cert covers ONE level of subdomain only -- `*.example.com`
matches `www.example.com` and `api.example.com` but NOT `a.b.example.com`.
For multi-level coverage, add `--server-name "example.com foo.example.com"`
and rely on per-zone wildcards.

## Renewal

certbot's apt package ships `certbot.timer` (systemd) which fires twice
daily and renews any cert within 30 days of expiry. The `_https_install`
stage enables it via `systemctl enable --now certbot.timer`.

DNS-01 renewals reuse the credentials file path stored in
`/etc/letsencrypt/renewal/<primary>.conf` (certbot writes it during the
first issuance). So as long as the INI file stays at the same path with
mode 600, renewals are unattended.

To verify renewal works:
```bash
sudo certbot renew --dry-run
```

## Markers (in `.installed/`)

| File                          | Meaning |
|-------------------------------|---------|
| `70-https.ok`                 | HTTPS successfully provisioned |
| `70-https.primary`            | First server_name token (= cert lineage on disk) |
| `70-https.dns`                | DNS provider used (`cloudflare`/`route53`/…); absent for HTTP-01 |
| `70-https.wildcard`           | Present when issued with `--wildcard` |

## Failure modes & remediation

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `--wildcard requires --dns <provider>` | Forgot `--dns` | Add `--dns cloudflare` (or other) |
| `unsupported --dns provider: 'X'` | Typo or unsupported provider | Use `cloudflare`/`route53`/`digitalocean`/`manual` |
| `--dns cloudflare requires --dns-credentials` | Missing flag | Pass `--dns-credentials /path/to/cloudflare.ini` |
| `DNS credentials file '...' has mode 644 -- chmod 600` | Wrong perms | Script auto-fixes, but pre-set `chmod 600` |
| `certbot certonly (DNS-01) failed` | Bad token, wrong zone, or provider rate-limit | `tail /var/log/letsencrypt/letsencrypt.log` |
| `'certbot install --nginx --cert-name X' failed` | nginx vhost missing for that server_name | Run `./run.sh install nginx` first |
| `HTTP verify failed before certbot run` (HTTP-01 only) | Port 80 unreachable / firewall / DNS not pointing here | `dig example.com`, check UFW/cloud firewall |

## Manual recovery

```bash
# Inspect what certbot has on disk
sudo certbot certificates

# Force-renew now (e.g. to test a credential rotation)
sudo certbot renew --force-renewal --cert-name example.com

# Revoke + delete a cert
sudo certbot revoke --cert-name example.com
sudo certbot delete --cert-name example.com

# Or use script 70's wrapper
sudo ./run.sh uninstall https
```

## Out of scope (deferred to suggestions)

* macOS support (user-confirmed: skip)
* HSTS + OCSP stapling in the rewritten nginx vhost
* Automatic A/AAAA record creation pointing the domain at the host's
  public IP (would need a separate DNS-write phase before the cert step)
* Plugins beyond cloudflare/route53/digitalocean/manual (PRs welcome)

