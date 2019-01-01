#!/usr/bin/env bash
dns=`cat public_dns.txt`
ssh -t -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -i ~/.ssh/ssocks_key.pem ubuntu@$dns