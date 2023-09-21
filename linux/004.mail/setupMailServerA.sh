#!/bin/bash

set -e

# 패키지 설치
package_name_sendmail="sendmail"

if ! rpm -q "$package_name_sendmail"; then

    echo "$package_name_sendmail 패키지가 설치되어 있지 않습니다. 설치 중..."
    sudo yum install -y "$package_name_sendmail"
    
    if rpm -q "$package_name_sendmail"; then
        echo "$package_name_sendmail 패키지가 성공적으로 설치되었습니다."
    else
        echo "오류: $package_name_sendmail 패키지 설치에 실패했습니다."
        exit 1
    fi
else
    echo "$package_name_sendmail 패키지가 이미 설치되어 있습니다."
fi

# hostname 변경
hostnamectl set-hostname mail.naver.com
echo "# hostname 변경"

# hosts 파일 변경
cat <<EOL >> /etc/hosts
172.16.74.100 mail.naver.com
EOL
echo "# hosts 파일 변경"

# /etc/mail/local-host-names 파일에 호스트 등록
cat <<EOL >> /etc/mail/local-host-names
mail.naver.com
EOL
echo "# /etc/mail/local-host-names 파일에 호스트 등록"

# 네트워크 호스트 이름 변경 (/etc/sysconfig/network)
cat <<EOL >> /etc/sysconfig/network
HOSTNAME=mail.naver.com
EOL
echo "# 네트워크 호스트 이름 변경 (/etc/sysconfig/network)"