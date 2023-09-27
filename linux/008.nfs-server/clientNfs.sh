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

# 패키지 설치
log "INFO" "###  패키지 설치."

packages=(
    "nfs-utils"
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

# 데몬 실행
log "INFO" "###  데몬 실행."

daemons=("nfs-server")

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

# 공유 폴더 생성
log "INFO" "공유 폴더를 확인합니다."

sharedDir="/shared"

if [ ! -d "$sharedDir" ]; then
  log "WARNING" "$sharedDir 폴더가 존재하지 않습니다. 새로운 폴더를 생성합니다."
  mkdir -p "$sharedDir" 
  log "SUCCESS" "$sharedDir 을(를) 생성했습니다."
else
  log "SUCCESS" "$sharedDir 폴더가 이미 존재합니다."
fi

# 서비스 상태 확인
log "INFO" "Service-Enable is: $(systemctl is-enabled nfs-server)"
log "INFO" "Service-Active is: $(systemctl is-active nfs-server)"

# nfs 상태 확인
log "INFO" "$(showmount -e 172.16.74.100)"

# 마운트
mount -t nfs 172.16.74.100:/shared /shared
log "SUCCESS" "$sharedDir 가 성공적으로 마운트 되었습니다."

echo "172.16.74.100:/shared /shared nfs defaults 0 0" >> /etc/fstab 
log "SUCCESS" "$sharedDir 가 /etc/fatab에 등록되었습니다."