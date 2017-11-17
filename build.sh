#!/bin/bash
set -xe

time terraform apply -var myip=$2 -parallelism=20
ati --list --root ./ | jq . > inventory.json
cp inventory.json $1
