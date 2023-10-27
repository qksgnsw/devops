#! /usr/bin/env bash

# sshpass -p vagrant ssh -T -o StrictHostKeyChecking=no vagrant@172.16.74.101
# sshpass -p vagrant ssh -T -o StrictHostKeyChecking=no vagrant@172.16.74.102
# sshpass -p vagrant ssh -T -o StrictHostKeyChecking=no vagrant@172.16.74.103
ssh-keyscan 172.16.74.101 >> ~/.ssh/known_hosts
ssh-keyscan 172.16.74.102 >> ~/.ssh/known_hosts
ssh-keyscan 172.16.74.111 >> ~/.ssh/known_hosts
ssh-keyscan 172.16.74.112 >> ~/.ssh/known_hosts


cp /root/.ssh/known_hosts /home/vagrant/.ssh/known_hosts