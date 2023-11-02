#! /usr/bin/env bash

apt update -y
apt install net-tools python3 python3-pip ansible -y
pip3 install --upgrade pip
pip3 install awscli
pip3 install boto3
pip3 install boto
