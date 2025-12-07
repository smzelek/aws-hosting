# aws-hosting

## Setup
```sh
brew install awscli
brew install terraform
# setup aws config: https://github.com/smzelek/CAREER/blob/main/__home/aws-config
# get aws sessionmanager plugin https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-macos-overview.html

brew install certbot

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

## Creating a new app
1. Register domain in Cloudflare
2. Run `bash scripts/make_cert.sh NEWDOMAIN.com`
3. Add the two TXT entries in Cloudflare
4. Add entry in `terraform/main.tf` with `bootstrap` true for the first run
5. Add entries in `terraform/haproxy/files/haproxy.cfg`
6. Run `bash scripts/apply.sh`
7. `apply` will hang on validating -- get validation CNAME [here](https://us-east-1.console.aws.amazon.com/acm/home?region=us-east-1#/certificates/list)
8. Add validation CNAME to Cloudflare (DNS only)
9. `apply` should pick up the valid CNAME; re-run if needed
10. Change `bootstrap = false` for the future
11. Copy `cloudfront_domain` into Cloudflare as `@` CNAME (DNS only)
12. Copy `cloudfront_domain` into Cloudflare as `www` CNAME (DNS only)
13. Copy `haproxy_domain` into Cloudflare as `api` CNAME (DNS only)
14. Run `bash scripts/upload.sh`
15. Run `bash scripts/ssh.sh haproxy`
16. Run `cd ~ && aws s3 sync s3://kerukion-haproxy-config/ ~`
17. Run `bash ~/setup.sh`
18. Add secrets at `secrets_link`
19. Add ci/cd jobs to Github Repo, deploys are now automatic (https://github.com/smzelek/aws-hosting/tree/main/.github/workflows)
20. Add `CLOUDFLARE_TOKEN` to Github Repo secrets, modify CI/CD Jobs to include AWS App name
