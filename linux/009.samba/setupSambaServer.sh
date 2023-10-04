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
    "samba"
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

daemons=("smb")

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

# 권한 및 소유권 변경.
log "INFO" "### 권한 및 소유권 변경."
useradd smbGroup
chown -R smbGroup.smbGroup $sharedDir
chmod 770 $sharedDir
log "SUCCESS" "권한 및 소유권 변경이 완료되었습니다."

# 방화벽 설정
log "INFO" "###  SAMBA 방화벽 추가."

firewall-cmd --zone=public --add-service=samba --permanent
firewall-cmd --reload

log "SUCCESS" "방화벽 설정이 완료되었습니다."

# smb 사용자 비밀번호 설정
log "INFO" "###  smb 사용자 비밀번호 설정."

smbpasswd -a smbGroup

log "SUCCESS" "smb 사용자 비밀번호 설정이 완료되었습니다."

# smb 환경 설정
log "INFO" "### smb 환경 설정."

cat <<EOL >> /etc/samba/smb.conf
[Share]
  path = /shared
  writable = yes
  guest ok = no
  create mode = 0777
  directory mode = 0777
  valid users = @smbGroup
EOL
# smb 환경 설정 오류 체크
testparm

log "SUCCESS" "smb 환경 설정이 완료되었습니다."

# 데몬 재시작
systemctl restart smb
log "SUCCESS" "smb 재시작 되었습니다."

# 서비스 상태 확인
log "INFO" "Service-Enable is: $(systemctl is-enabled smb)"
log "INFO" "Service-Active is: $(systemctl is-active smb)"
