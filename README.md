# aws-hosting

service = 
    the code
    the secrets
    the infra settings (task def)

    --- these 3 things should change atomically (in 1 commit + pipeline actions)

* dockerize the code
* secrets => AWS SM as a single k=v file; upload with commit as version stage
* task definition: has mem, cpu, etc... 
    also needs to have TF identifiers hardcoded (👎🏼)

    conflict: want to have in TF repo to avoid hardcoded identifiers
    but want to have in Service repo to properly use commit hash in version stage for secrets manager...

    although, do you actually want to use commit-versioned secrets?

    arguably you might want to rollback the code without rolling back (for example) a revoked+rotated Sentry Token
    it's likely better for secrets to exist independent of the code, and to manually fix secrets if there's an issue, 
    or separately rollback the secretsmanager version of those secrets
* 

## Start local CLI ssh session on instance
```bash
aws --profile kerukion-admin ssm start-session --target i-0ce55fd178fc85fe9

TOKEN=`curl --no-progress-meter -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl --no-progress-meter -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/info && echo
```


## Build and push docker default-image
```bash
ECR_URL="590184101838.dkr.ecr.us-east-1.amazonaws.com" \
ECR_TAG="${ECR_URL}/default-image:latest" \
aws --profile kerukion-admin ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "${ECR_URL}" && \
sudo docker build default_image/ -t "${ECR_TAG}" && \
sudo docker push "${ECR_TAG}"
```