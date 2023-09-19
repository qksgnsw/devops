#!/bin/bash

set -e

package_name_httpd="httpd"

# 패키지 설치
if ! rpm -q "$package_name_httpd"; then
    echo "$package_name_httpd 패키지가 설치되어 있지 않습니다. 설치 중..."
    sudo yum install -y "$package_name_httpd"
    
    if rpm -q "$package_name_httpd"; then
        echo "$package_name_httpd 패키지가 성공적으로 설치되었습니다."
    else
        echo "오류: $package_name_httpd 패키지 설치에 실패했습니다."
        exit 1
    fi
else
    echo "$package_name_httpd 패키지가 이미 설치되어 있습니다."
fi

echo "<h1>Hello World from $(hostname -I)</h1>" > /var/www/html/index.html

systemctl start httpd
systemctl enable httpd

# 방화벽
port_to_allow=80

systemctl start firewalld
systemctl enable firewalld

firewall-cmd --add-port=$port_to_allow/tcp --permanent

firewall-cmd --reload

echo "포트 $port_to_allow을(를) allow 했습니다."