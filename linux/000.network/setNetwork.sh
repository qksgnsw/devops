#!/bin/bash

# 기본 구성
set -e

source ./defaultConf.sh

if [ -e "./defaultConf.sh" ]; then
  log "SUCCESS" "기본 구성 파일이 존재 확인."
else
  log "ERROR" "기본 구성 파일이 존재하지 않습니다."
  exit 1
fi

log "INFO" "현재 사용할 수 있는 Device 목록입니다."
nmcli device

# 사용자로부터 네트워크 인터페이스와 IP 설정을 입력 받음
read -p "네트워크 인터페이스 이름을 입력하세요 (예: eth0): " INTERFACE
read -p "IP 주소를 입력하세요 (예: 192.168.1.100): " IP_ADDRESS
read -p "서브넷 마스크를 입력하세요 (예: 0-32): " SUBNET_MASK
read -p "게이트웨이 주소를 입력하세요 (예: 192.168.1.1): " GATEWAY
read -p "주 DNS 서버를 입력하세요 (예: 8.8.8.8): " DNS1
read -p "보조 DNS 서버를 입력하세요 (예: 8.8.4.4): " DNS2

# 네트워크 설정을 nmcli를 사용하여 업데이트
nmcli con mod "$INTERFACE" ipv4.address "$IP_ADDRESS/$SUBNET_MASK"
nmcli con mod "$INTERFACE" ipv4.gateway "$GATEWAY"
nmcli con mod "$INTERFACE" ipv4.dns "$DNS1 $DNS2"
nmcli con up "$INTERFACE"

# 설정 결과 확인
if [ $? -eq 0 ]; then
    log "SUCCESS" "IP 주소 설정이 완료되었습니다."
else
    log "ERROR" "IP 주소 설정에 실패했습니다."
    exit 1
fi

log "INFO" "설정 상태 확인."
nmcli