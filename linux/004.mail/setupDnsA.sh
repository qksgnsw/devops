#!/bin/bash

set -e

# 패키지 설치
echo "# 패키지 설치"
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
echo "# 파일 검사"
file_path="/etc/named.conf" 

if [ -e "$file_path" ]; then
    echo "파일이 존재합니다: $file_path"
else
    echo "파일이 존재하지 않습니다: $file_path"
    exit 1
fi

# 구성 파일 백업
echo "# 구성 파일 백업"
cp "$file_path" "$file_path.backup"

# 구성 파일 설정
echo "# 구성 파일 설정"
sed -i "s/listen-on port 53 { 127.0.0.1; };/listen-on port 53 { any; };/g" "$file_path"
sed -i "s/listen-on-v6 port 53 { ::1; }/listen-on-v6 port 53 { none; }/g" "$file_path"
sed -i "s/allow-query     { localhost; };/allow-query     { any; };/g" "$file_path"
sed -i "s/dnssec-validation yes;/dnssec-validation no;/g" "$file_path"

# zone 추가
echo "# zone 추가"
cat <<EOL >> /etc/named.conf
zone "naver.com" IN {
    type master;
    file "naver.com.db";
    allow-update { none; };
};

zone "daum.net" IN {
    type master;
    file "daum.net.db";
    allow-update { none; };
};
EOL

# zone 파일 생성 및 설정
echo "# zone 파일 생성 및 설정"
cat <<EOL >> /var/named/naver.com.db
\$TTL 3H
@ SOA @ root. (2 1D 1H 1W 1H)
	IN NS @
	IN A 172.16.74.100
    IN MX 10 mail.naver.com.

mail IN A 172.16.74.100
EOL
cat <<EOL >> /var/named/daum.net.db
\$TTL 3H
@ SOA @ root. (2 1D 1H 1W 1H)
	IN NS @
	IN A 172.16.74.200
    IN MX 10 mail.daum.net.

mail IN A 172.16.74.200
EOL

# 구성 파일 검사
echo "# 구성 파일 검사"
named-checkconf
named-checkzone naver.com /var/named/naver.com.db
named-checkzone daum.net /var/named/daum.net.db

# named 시작
echo "# named 시작"
systemctl enable named
systemctl restart named

