#!/bin/bash
# This should remain idempotent

set -u
set -e
set -E
set -o pipefail
BLUE="\033[1;34m"
NC="\033[0m"

echo -e "${BLUE}Installing haproxy dependencies:${NC}"
sudo yum install -y \
    bind-utils \
    haproxy \
    nano \
    rsyslog \
    amazon-cloudwatch-agent
echo -e "\n"

# echo -e "${BLUE}Installing telegraf:${NC}"
# cat <<EOF | sudo tee /etc/yum.repos.d/influxdata.repo
# [influxdata]
# name = InfluxData Repository - Stable
# baseurl = https://repos.influxdata.com/stable/\$basearch/main
# enabled = 1
# gpgcheck = 1
# gpgkey = https://repos.influxdata.com/influxdata-archive_compat.key
# EOF

# sudo yum install -y telegraf
# sudo service telegraf start

cd ~

echo -e "${BLUE}Setting up haproxy config file:${NC}"
sudo cp ~/haproxy.cfg /etc/haproxy/haproxy.cfg
cat /etc/haproxy/haproxy.cfg
echo -e "\n"

echo -e "${BLUE}Setting up rsyslog config file for haproxy:${NC}"
sudo cp ~/rsyslog.conf /etc/rsyslog.d/haproxy.conf
cat /etc/rsyslog.d/haproxy.conf
echo -e "\n"

echo -e "${BLUE}Setting up cloudwatch agent for haproxy logs:${NC}"
sudo amazon-cloudwatch-agent-ctl -a fetch-config -s -m ec2 -c file:./cw-agent.json
sudo amazon-cloudwatch-agent-ctl -a start -c ./cw-agent.json
sudo amazon-cloudwatch-agent-ctl -a status
echo -e "\n"

echo -e "${BLUE}Setting up cert pem files for haproxy:${NC}"
sudo cp ~/*.pem /etc/haproxy/certs/
sudo rm /etc/haproxy/certs/haproxy.pem
ls -al /etc/haproxy/certs/
echo -e "\n"

echo -e "${BLUE}Restarting services:${NC}"
sudo service rsyslog restart
sudo service haproxy restart
echo -e "\n"

echo -e "${BLUE}Done.${NC}"

