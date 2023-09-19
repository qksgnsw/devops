#!/bin/bash

set -e

# 패키지 설치
package_name_bind="bind"

if ! rpm -q "$package_name_bind"; then

    echo "$package_name_bind 패키지가 설치되어 있지 않습니다. 설치 중..."
    sudo yum install -y "$package_name_bind"
    
    if rpm -q "$package_name_bind"; then
        echo "$package_name_bind 패키지가 성공적으로 설치되었습니다."
    else
        echo "오류: $package_name_bind 패키지 설치에 실패했습니다."
        exit 1
    fi
else
    echo "$package_name_bind 패키지가 이미 설치되어 있습니다."
fi

package_name_bind_chroot="bind-chroot"

if ! rpm -q "$package_name_bind_chroot"; then

    echo "$package_name_bind_chroot 패키지가 설치되어 있지 않습니다. 설치 중..."
    sudo yum install -y "$package_name_bind_chroot"
    
    if rpm -q "$package_name_bind_chroot"; then
        echo "$package_name_bind_chroot 패키지가 성공적으로 설치되었습니다."
    else
        echo "오류: $package_name_bind_chroot 패키지 설치에 실패했습니다."
        exit 1
    fi
else
    echo "$package_name_bind_chroot 패키지가 이미 설치되어 있습니다."
fi

# 파일 검사
file_path="/etc/named.conf" 

if [ -e "$file_path" ]; then
    echo "파일이 존재합니다: $file_path"
else
    echo "파일이 존재하지 않습니다: $file_path"
    exit 1
fi

# 구성 파일 백업
cp "$file_path" "$file_path.backup"

sed -i "s/listen-on port 53 { 127.0.0.1; };/listen-on port 53 { any; };/g" "$file_path"
sed -i "s/listen-on-v6 port 53 { ::1; }/listen-on-v6 port 53 { none; }/g" "$file_path"
sed -i "s/allow-query     { localhost; };/allow-query     { any; };/g" "$file_path"
sed -i "s/dnssec-validation yes;/dnssec-validation no;/g" "$file_path"

cat <<EOL >> /etc/named.conf
zone "test.com" IN {
			type master;
			file "test.com.db";
			allow-update { none; };
};
EOL

cat <<EOL >> /var/named/test.com.db
\$TTL 3H
@ SOA @ root. (2 1D 1H 1W 1H)
	IN NS @
	IN A 172.16.74.200

www IN CNAME web.test.com

web 10 IN A 172.16.74.100
    20 IN A 172.16.74.200
EOL

echo "파일 내용이 수정되었습니다."

# dns 실행
systemctl start named
systemctl enable named

# 방화벽 설정
port_to_allow=53

systemctl start firewalld
systemctl enable firewalld

firewall-cmd --add-port=$port_to_allow/tcp --permanent
firewall-cmd --add-port=$port_to_allow/udp --permanent
firewall-cmd --reload

echo "포트 $port_to_allow을(를) allow 했습니다."

