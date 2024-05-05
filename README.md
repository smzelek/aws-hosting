# aws-hosting

This repo represents my new theory of service management (as opposed to Appflow work):
* Code/secrets/infra will not be atomically committed together.
* Code will be in its own service repo.
* Secrets will be versioned purely by secrets manager, not bound to a deploy version.
* Service repo will have no knowledge of task definition/terraform.

Reasoning:
* While it may make sense in theory to atomically update secrets, code, and infra all via a single git commit and subsequent deploy, this has problems:
    * You may want to rollback code without rolling back secrets. (i.e: A problematic code change was made, at the same time as an API key was correctly rotated and the old API key linked to the rollback commit is actually invalid now).
    * Theoretically, the code does not need to have any knowledge of the infra that is running it in most cases. Simple services don't need to control anything more than their own Docker container - this lets them draw an abstraction boundary.
    * The Code-as-Dockerfile output could be consumed in various places, it doesn't need to know how it gets run.
    * Terraform and task-definition JSON files are out of place in a service repo from a language and domain standpoint. Someone working on that service repo may have no familiarity with that kind of DevOps tool or AWS concept.
    * Using task definitions inside the service repo means hard coding resources (IAMs, etc) that are only known to the Terraform repo. It's easier to keep these things in sync if they are referenced using terraform resource identifiers.
* Admittedly there are some pitfalls to watch out for in this new model:
    * Changes involving secrets must be made in a backwards/forwards compatible way. Rollback deploys must not rollback to a version dependent on a deleted secret.
    * Infra resource provisioning changes should be made mindfully based on changes to the needs of the service, but this is not too unexpected -- infra changes are usually made in retrospect based on observed changes rather than adding pre-planned capacity.

At the very least, this makes a lot more sense as a go-to for boilerplate webapp services --- if a service has way more need for dealing with AWS hands on, it could bring in Terraform at that point when it makes sense for the repo's domain.

## Start local CLI ssh session on instance
```bash
bash ./scripts/ssh.sh <instance_id>
```

## Build and push docker default-image
```bash
ECR_URL="590184101838.dkr.ecr.us-east-1.amazonaws.com" \
ECR_TAG="${ECR_URL}/default-image:latest" \
aws --profile kerukion-admin ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "${ECR_URL}" && \
sudo docker build default_image/ -t "${ECR_TAG}" && \
sudo docker push "${ECR_TAG}"
```

## Connect to RDS DB
```bash
bash ./scripts/tunnel.sh <instance-id>
# open PGAdmin and connect to 127.0.0.1:9999
```
