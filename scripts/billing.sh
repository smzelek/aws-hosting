#!/bin/bash
set -e

# source in env vars
. .env

# verify identity
aws sts get-caller-identity --query "Account" --profile "kerukion-admin" > /dev/null || aws sso login --profile=kerukion-admin

echo "--- VPC ---"
echo '$0.005 per In-use public IPv4 address per hour ($3.72/mo):'
aws ec2 describe-network-interfaces \
    --query 'NetworkInterfaces[*].{ id: NetworkInterfaceId, vpc_id: VpcId, subnet_id: SubnetId, status: Status, az: AvailabilityZone, type: InterfaceType, requester: RequesterId, public_ip: Association.PublicIp }' \
    --output table
echo

echo "--- EC2 ---"
echo '$0.045 per NAT Gateway Hour ($33.48/mo):'
aws ec2 describe-nat-gateways \
    --query 'NatGateways[*].{ id: NatGatewayId, state: State }' \
    --output table
echo '$0.0168 per On Demand Linux t4g.small Instance hour ($12.49/mo):'
aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].{ id: InstanceId, type: InstanceType, state: State.Name, public_ip: PublicIpAddress }' \
    --output table
echo

echo "--- ELB ---"
echo '$0.0225 per Application LoadBalancer-hour ($16.74/mo):'
aws elbv2 describe-load-balancers \
    --query 'LoadBalancers[*].{ id: LoadBalancerArn, name: LoadBalancerName, state: State.Code }' \
    --output table
echo

echo "--- RDS ---"
echo '$0.018 per db.t3.micro Single-AZ instance hour running PostgreSQL ($13.39/mo):'
aws rds describe-db-instances \
    --query 'DBInstances[*].{ id: DBInstanceArn, name: DBInstanceIdentifier, status: DBInstanceStatus }' \
    --output table
echo

