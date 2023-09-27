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

# 환경 설정
log "INFO" "### nfs-server 환경설정."

cat <<EOL >> /etc/exports
/shared 172.16.74.0/24(rw,sync,no_root_squash)
EOL

log "SUCCESS" "nfs-server 환경설정이 완료되었습니다."

# 권한 변경.
log "INFO" "### 권한 변경."

chmod 707 $sharedDir

log "SUCCESS" "권한 변경이 완료되었습니다."

# 방화벽 설정
log "INFO" "###  HTTP/S 방화벽 추가."

firewall-cmd --zone=public --add-service=nfs --permanent
firewall-cmd --zone=public --add-service=mountd --permanent
firewall-cmd --zone=public --add-service=rpc-bind --permanent
firewall-cmd --reload

log "SUCCESS" "방화벽 구성이 완료되었습니다."

# 데몬 재시작
systemctl restart nfs-server
log "SUCCESS" "nfs-server 재시작 되었습니다."

# 서비스 상태 확인
log "INFO" "Service-Enable is: $(systemctl is-enabled nfs-server)"
log "INFO" "Service-Active is: $(systemctl is-active nfs-server)"
log "INFO" "Exportfs is: $(exportfs -v)"
