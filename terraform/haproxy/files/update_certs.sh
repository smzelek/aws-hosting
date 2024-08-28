#!/bin/bash

set -u
set -e
set -E
set -o pipefail
BLUE="\033[1;34m"
NC="\033[0m"

echo -e "${BLUE}Setting up cert pem files for haproxy:${NC}"
sudo cp ~/*.pem /etc/haproxy/certs/
ls -al /etc/haproxy/certs/
echo -e "\n"

echo -e "${BLUE}Restarting services:${NC}"
sudo service rsyslog restart
sudo service haproxy restart
echo -e "\n"
