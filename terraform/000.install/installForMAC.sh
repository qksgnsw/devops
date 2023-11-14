#!/bin/bash

# 테라폼 설치 (Homebrew를 사용)
echo "테라폼 설치 중..."
brew install terraform

# 테라폼 별칭 설정 및 자동완성 스크립트 다운로드
echo "테라폼 별칭 설정 및 자동완성 스크립트 다운로드 중..."
echo 'alias tf="terraform"' >> ~/.zshrc # 또는 ~/.bashrc (터미널 셸에 따라 다를 수 있음)
curl -L https://raw.githubusercontent.com/bobthecow/terraform-bash-completion/master/terraform > /usr/local/etc/bash_completion.d/terraform

# 새 셸 세션 시작
exec $SHELL

echo "테라폼 설치와 설정이 완료되었습니다. 'tf' 명령어로 테라폼을 사용할 수 있습니다."
