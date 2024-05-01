## Manual setup:
1. Create github repo and add ci/cd job
2. Create domain in Cloudflare
3. Terraform apply with `bootstrap = true`
4. Change `bootstrap = false` for the future
5. Add secrets at `secrets_link`
6. Add CNAMEs for validation from `certificate_link` to Cloudflare (DNS only)
7. Add CNAMEs for webapp_domain => `cloudfront_domain` in Cloudflare (DNS only)
8. Add CNAMEs for service_domain => `load_balancer_domain` in Cloudflare (Proxied)
9. Push repo / Rerun github ci/cd job
