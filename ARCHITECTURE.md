# Architecture
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

## Cost-saving notes
* got rid of NAT gateway ($33/mo). it was required to allow the private subnet to hit the internet
* so, got rid of private subnet, moved vpc into public subnet
* added a public IP to the EC2 cluster ($3.50/mo)

* got rid of AWS ALB, target groups ($17/mo)
* ALB also requires 2 subnets, only have 1 now
* setup HAProxy in the EC2 cluster as a stand-in for AWS ALB ($0)

## Current cost to run:
> Total: $47.19/mo

| Resource                     | Cost                  | Description |
|------------------------------|-----------------------|-------------|
| 1 RDS db.t3.micro instance   | $13.39/mo             | database    |
| 1 EC2 t4g.micro instance     | $6.24/mo              | haproxy     |
| 1 EC2 t4g.small instance     | $12.49/mo             | cluster     |
| 2 ENI public IPv4            | $3.72/mo => $7.44/mo  |             |
| 2 EBS gp3 volumes            | $1.45/mo => $2.90/mo  |             |
| 33 Cloudwatch custom metrics | $0.30/mo => $9.90/mo  |             |
