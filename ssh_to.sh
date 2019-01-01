#!/usr/bin/env bash
n=`sed "${1}q;d" public_dns.txt`
ssh -t -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -i ~/.ssh/narc_key.pem ubuntu@$n