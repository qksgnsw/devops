#!/bin/bash

# 테라폼 설치
echo "테라폼 설치 중..."
sudo apt-get update
sudo apt-get install -y terraform

# 테라폼 별칭 설정 및 자동완성 스크립트 다운로드
echo "테라폼 별칭 설정 및 자동완성 스크립트 다운로드 중..."
echo 'alias tf="terraform"' >> ~/.bashrc
curl -L https://raw.githubusercontent.com/bobthecow/terraform-bash-completion/master/terraform > ~/.terraform-completion

# .bashrc 파일 적용
source ~/.bashrc

echo "테라폼 설치와 설정이 완료되었습니다. 'tf' 명령어로 테라폼을 사용할 수 있습니다."
