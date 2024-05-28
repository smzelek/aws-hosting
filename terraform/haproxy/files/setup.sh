#!/bin/bash

sudo yum install -y \
    bind-utils \
    haproxy \
    nano \
    rsyslog \
    amazon-cloudwatch-agent

cd ~
aws s3 cp s3://kerukion-haproxy-config/cw-agent.json ./cw-agent.json
sudo aws s3 cp s3://kerukion-haproxy-config/haproxy.cfg /etc/haproxy/haproxy.cfg
sudo aws s3 cp s3://kerukion-haproxy-config/haproxy-log.conf /etc/rsyslog.d/haproxy.conf
sudo aws s3 cp s3://kerukion-haproxy-config/haproxy.pem /etc/haproxy/certs/haproxy.pem

sudo amazon-cloudwatch-agent-ctl -a fetch-config -s -m ec2 -c file:./cw-agent.json
sudo amazon-cloudwatch-agent-ctl -a start -c ./cw-agent.json
sudo amazon-cloudwatch-agent-ctl -a status

sudo service rsyslog restart
sudo service haproxy restart
