#!/bin/bash

set -e

# 패키지 설치
echo "# 패키지 설치"
package_name_sendmail_cf="sendmail-cf"

if ! rpm -q "$package_name_sendmail_cf"; then

    echo "$package_name_sendmail_cf 패키지가 설치되어 있지 않습니다. 설치 중..."
    sudo yum install -y "$package_name_sendmail_cf"
    
    if rpm -q "$package_name_sendmail_cf"; then
        echo "$package_name_sendmail_cf 패키지가 성공적으로 설치되었습니다."
    else
        echo "오류: $package_name_sendmail_cf 패키지 설치에 실패했습니다."
        exit 1
    fi
else
    echo "$package_name_sendmail_cf 패키지가 이미 설치되어 있습니다."
fi

package_name_dovecot="dovecot"

if ! rpm -q "$package_name_dovecot"; then

    echo "$package_name_dovecot 패키지가 설치되어 있지 않습니다. 설치 중..."
    sudo yum install -y "$package_name_dovecot"
    
    if rpm -q "$package_name_dovecot"; then
        echo "$package_name_dovecot 패키지가 성공적으로 설치되었습니다."
    else
        echo "오류: $package_name_dovecot 패키지 설치에 실패했습니다."
        exit 1
    fi
else
    echo "$package_name_dovecot 패키지가 이미 설치되어 있습니다."
fi

# 샌드메일 환경설정 파일 수정 /etc/mail/sendmail.cf
echo "# 샌드메일 환경설정 파일 수정 /etc/mail/sendmail.cf"
sed -i "s/Cwlocalhost/Cwdaum.net/g" /etc/mail/sendmail.cf
sed -i "s/O DaemonPortOptions=Port=smtp,Addr=127.0.0.1, Name=MTA/O DaemonPortOptions=Port=smtp, Name=MTA/g" /etc/mail/sendmail.cf

# 메일 릴레이 설정 /etc/mail/access
echo "# 메일 릴레이 설정 /etc/mail/access"
cat <<EOL >>/etc/mail/access
naver.com                               RELAY
daum.net                                RELAY
172.16.74                               RELAY
EOL

# 샌드메일 환경설정 적용
echo "# 샌드메일 환경설정 적용"
makemap hash /etc/mail/access < /etc/mail/access

# Dovecot 환경설정 /etc/dovecot/dovecot.conf
echo "# Dovecot 환경설정 /etc/dovecot/dovecot.conf"
sed -i "s/#protocols = imap pop3 lmtp submission/protocols = imap pop3 lmtp submission/g" /etc/dovecot/dovecot.conf
sed -i "s/#listen/listen/g" /etc/dovecot/dovecot.conf
sed -i "s/#base_dir/base_dir/g" /etc/dovecot/dovecot.conf

# Dovecot 환경설정 /etc/dovecot/conf.d/10-ssl.conf
echo "# Dovecot 환경설정 /etc/dovecot/conf.d/10-ssl.conf"
sed -i "s/ssl = required/ssl = yes/g" /etc/dovecot/conf.d/10-ssl.conf

# Dovecot 환경설정 /etc/dovecot/conf.d/10-mail.conf
echo "# Dovecot 환경설정 /etc/dovecot/conf.d/10-mail.conf"
sed -i "s/#   mail_location = mbox:~\/mail:/mail_location = mbox:~\/mail:/g" /etc/dovecot/conf.d/10-mail.conf
sed -i "s/#mail_access_groups =/mail_access_groups = mail/g" /etc/dovecot/conf.d/10-mail.conf
sed -i "s/#lock_method/lock_method/g" /etc/dovecot/conf.d/10-mail.conf


systemctl start sendmail
systemctl start dovecot

systemctl enable sendmail
systemctl enable dovecot