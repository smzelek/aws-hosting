# aws-hosting

## Setup
```sh
brew install awscli
brew install terraform
# setup aws config: https://github.com/smzelek/CAREER/blob/main/__home/aws-config
# get aws sessionmanager plugin https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-macos-overview.html

bash scripts/info.sh
```

## Instructions
### Start local CLI ssh session on instance
```bash
bash ./scripts/ssh.sh <instance_id>
```

### Build and push docker default-image
```bash
(. .env && \
ECR_URL="590184101838.dkr.ecr.us-east-1.amazonaws.com" \
ECR_TAG="${ECR_URL}/default-image:latest" \
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "${ECR_URL}" && \
sudo docker build default_image/ -t "${ECR_TAG}" && \
sudo docker push "${ECR_TAG}")
```

### Connect to RDS DB
```bash
bash ./scripts/db_tunnel.sh
# open PGAdmin and connect to 127.0.0.1:9999
```

### Renew certs
```bash
# per-domain
dig txt _acme-challenge.ticmetactoe.com @8.8.8.8
bash scripts/make_cert.sh ticmetactoe.com

# finally
bash scripts/upload.sh
```

### Add a new app
1. Register domain in Cloudflare
2. Add entry in `terraform/main.tf` with `bootstrap` true for the first run
3. Add entries in `terraform/haproxy/files/haproxy.cfg`
4. Run `bash scripts/apply.sh`
5. Get validation CNAME [here](https://us-east-1.console.aws.amazon.com/acm/home?region=us-east-1#/certificates/list)
6. Add validation CNAME to Cloudflare (DNS only)
7. Wait for `apply` to pick up the valid CNAME
8. Copy `cloudfront_domain` into Cloudflare as `@` CNAME (DNS only)
9. Copy `cloudfront_domain` into Cloudflare as `www` CNAME (DNS only)
10. Copy `haproxy_domain` into Cloudflare as `api` CNAME (DNS only)
11. Change `bootstrap = false` for the future
12. Add secrets at `secrets_link`
13. Add ci/cd jobs to github repo, deploys are now automatic (https://github.com/smzelek/aws-hosting/tree/main/.github/workflows)

