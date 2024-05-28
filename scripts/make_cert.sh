. .env
aws sts get-caller-identity --query "Account" --profile "${AWS_PROFILE}" > /dev/null || aws sso login --profile "${AWS_PROFILE}"

certbot certonly \
    -d *.guildvaults.com,guildvaults.com \
    -d *.ticmetactoe.com,ticmetactoe.com \
    -m smzelek@gmail.com \
    --manual \
    --preferred-challenges dns \
    --logs-dir ./certs/ \
    --config-dir ~/letsencrypt/config/ \
    --work-dir ~/letsencrypt/work/

cat \
./certs/live/guildvaults.com/fullchain.pem \
./certs/live/guildvaults.com/privkey.pem \
> ./terraform/haproxy/files/haproxy.pem
