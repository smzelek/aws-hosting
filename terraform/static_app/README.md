## Manual setup:
1. Create github repo and add ci/cd job
2. Create domain in Cloudflare
3. Terraform apply 
4. Add CNAMEs for validation from `certificate_link` to Cloudflare (DNS only)
5. Add CNAMEs for webapp_domain => `cloudfront_domain` in Cloudflare (DNS only)
6. Push repo / Rerun github ci/cd job
