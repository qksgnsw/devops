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
    "httpd"
    "mariadb-server"
    "php"
    "php-mysqlnd"
    "php-json"
    "php-gd"
    "php-mbstring"
    "php-pecl-zip"
    "php-xml"
    "php-intl"
)

install_package() {
  package_name=$1
  if rpm -q "$package_name" &>/dev/null; then
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

daemons=("httpd" "mariadb")

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

# DB 설정
log "INFO" "###  DB 설정."

db_name="webDB"
db_user="webUser"
db_password="1234"

mysql -e "CREATE DATABASE IF NOT EXISTS $db_name;"
mysql -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';"
mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

log "INFO" "DB 구성 확인."
mysql -e "SHOW databases;"

log "SUCCESS" "MySQL 데이터베이스 및 사용자 생성이 완료되었습니다."

# 방화벽 설정
log "INFO" "###  HTTP/S 방화벽 추가."

firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --reload

log "SUCCESS" "방화벽 구성이 완료되었습니다."

# owncloud
file_url="https://download.owncloud.com/server/stable/owncloud-10.3.2.zip"

download_dir="/var/www/html"
downloaded_file="$download_dir/owncloud-10.3.2.zip"

wget -P "$download_dir" "$file_url"

if [ $? -eq 0 ]; then
  log "INFO" "파일 다운로드 완료."

  unzip "$downloaded_file" -d "$download_dir"
  
  if [ $? -eq 0 ]; then
    log "SUCCESS" "파일 압축 해제 완료."
  else
    log "ERROR" "파일 압축 해제 중 오류 발생."
    exit 1
  fi
else
  log "ERROR" "파일 다운로드 중 오류 발생."
  exit 1
fi

owncloud_path="$download_dir/owncloud"

log "INFO" "하위 data 폴더 생성, 권한 및 소유권 변경."
mkdir -p "$owncloud_path/data"
chmod 755 $owncloud_path
chown -R apache.apache $owncloud_path

systemctl restart httpd