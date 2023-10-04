#!/bin/bash

# 기본 구성
set -e

source ./defaultConf.sh

if [ -e "./defaultConf.sh" ]; then
  log "SUCCESS" "기본 구성 파일 존재 확인."
else
  log "ERROR" "기본 구성 파일이 존재하지 않습니다."
  exit 1
fi

# 패키지 설치
log "INFO" "###  패키지 설치."

packages=(
    "dhcp-server"
)

install_package() {
  package_name=$1
  if yum list installed "$package_name" &>/dev/null; then
    log "INFO" "$package_name 패키지가 이미 설치되어 있습니다."
  else
    log "INFO" "$package_name 패키지를 설치합니다."
    sudo yum install -y "$package_name"
    log "SUCCESS" "$package_name 패키지 설치가 완료되었습니다."
  fi
}

for package in "${packages[@]}"; do
  install_package "$package"
done

# dhcp 환경 설정
log "INFO" "### dhcp 환경 설정."

cat <<EOL >> /etc/dhcp/dhcpd.conf
ddns-update-style interim;
subnet    172.16.74.0    netmask 255.255.255.0    {
        option    routers    172.16.74.2;
        option    subnet-mask    255.255.255.0;
        range    dynamic-bootp    172.16.74.55    172.16.74.99;
        option    domain-name-servers    8.8.8.8;
        default-lease-time    10000;
        max-lease-time    50000;
EOL

log "SUCCESS" "dhcp 환경 설정이 완료되었습니다."

# 데몬 실행
log "INFO" "###  데몬 실행."

daemons=("dhcpd")

for daemon in "${daemons[@]}"; do
  
  systemctl start "$daemon"
  systemctl enable "$daemon"

  status="$(systemctl is-active "$daemon")"

  if [ "$status" == "active" ]; then
    log "SUCCESS" "$daemon 데몬이 성공적으로 시작되었습니다."
  else
    log "ERROR" "$daemon 데몬을 시작하는 중에 문제가 발생했습니다."
  fi
done

# 서비스 상태 확인
log "INFO" "Service-Enable is: $(systemctl is-enabled dhcpd)"
log "INFO" "Service-Active is: $(systemctl is-active dhcpd)"
