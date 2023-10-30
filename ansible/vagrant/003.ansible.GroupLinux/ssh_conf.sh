# 배시로 실행되는 파일임을 명시
#! /usr/bin/env bash

# 현재 시간 변수
now=$(date +"%m_%d_%Y")

# sshd 설정파일 백업
cp /etc/ssh/sshd_config /etc/ssh/sshd_config_$now.backup

# sshd_config 내에 암호를 이용하여 인증하도록 설정 변경
sed -i -e 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# sshd 재시작
systemctl restart sshd