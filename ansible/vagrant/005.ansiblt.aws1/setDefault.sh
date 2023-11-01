#! /usr/bin/env bash

apt update -y
apt install net-tools python3 python3-pip ansible -y
pip3 install --upgrade pip
pip3 install awscli
pip3 install boto3

mkdir -p ~/.aws
cat <<EOF >~/.aws/credentials
[default]
aws_access_key_id = AKIATR3SVK5LUMNXTA5Y
aws_secret_access_key = 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
EOF

cat <<EOF > /root/aws_user_check.py 
import boto3

client = boto3.client("iam")
user_name = client.list_users()
for user in user_name['Users']:
    print(user["UserName"])
EOF

python3 /root/aws_user_check.py