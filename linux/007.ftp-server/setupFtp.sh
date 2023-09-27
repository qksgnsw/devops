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
    "vsftpd"
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

daemons=("vsftpd")

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

# 방화벽 설정
log "INFO" "###  HTTP/S 방화벽 추가."

firewall-cmd --zone=public --add-service=ftp --permanent
firewall-cmd --reload

log "SUCCESS" "방화벽 구성이 완료되었습니다."

# vsftpd 환경설정
log "INFO" "### vsftpd 환경설정."

sed -i "s/anonymous_enable=NO/anonymous_enable=YES/" /etc/vsftpd/vsftpd.conf
sed -i "s/#anon_upload_enable=YES/anon_upload_enable=YES/" /etc/vsftpd/vsftpd.conf
sed -i "s/#anon_mkdir_write_enable=YES/anon_mkdir_write_enable=YES/" /etc/vsftpd/vsftpd.conf

log "SUCCESS" "vsftpd 환경설정이 완료되었습니다."

# 권한 및 소유권 변경.
log "INFO" "### 권한 및 소유권 변경."

chown -R ftp.ftp /var/ftp/pub
chmod 777 /var/ftp/pub

log "SUCCESS" "권한 및 소유권 변경이 완료되었습니다."

systemctl restart vsftpd

log "SUCCESS" "vsftpd 재시작 되었습니다."

# 서비스 상태 확인
log "INFO" "Service-Enable is: ${systemctl is-enabled vsftpd}"
log "INFO" "Service-Active is: ${systemctl is-active vsftpd}"