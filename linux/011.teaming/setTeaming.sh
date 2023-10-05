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

packages=(
    "teamd"
    "jq"
)

install_package() {
  package_name=$1
  if rpm -q "$package_name"; then
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


# 사용자로부터 팀 인터페이스의 이름 입력 받기
read -p "팀 인터페이스 이름을 입력하세요 (예: team0): " team_name

# 사용자로부터 팀 러너(runner) 선택 받기
echo "팀 러너(runner) 선택:"
select runner in "broadcast" "activebackup" "loadbalance" "roundrobin" "lacp"; do
  case $runner in
    broadcast|activebackup|loadbalance|roundrobin|lacp)
      break
      ;;
    *)
      echo "잘못된 선택입니다. 다시 시도하세요."
      ;;
  esac
done

read -p "IP 주소를 입력하세요 (예: 192.168.1.100): " team_ip4
read -p "게이트웨이 주소를 입력하세요 (예: 192.168.1.1): " team_gw

# 팀링 인터페이스 생성 및 활성화
nmcli con add type team con-name $team_name ifname $team_name ip4 $team_ip4 gw4 $team_gw config '{"runner": {"name": ''"'$runner'"}}'
nmcli con up $team_name

log "INFO" "현재 사용할 수 있는 Device 목록입니다."
nmcli device

# 팀 슬레이브 인터페이스 수 입력 받기
read -p "팀 슬레이브 인터페이스 수를 입력하세요: " slave_count

# 팀 슬레이브 인터페이스 생성 및 연결
for ((i=1; i<=$slave_count; i++)); do
  read -p "팀 슬레이브 #$i의 이름을 입력하세요: " slave_name
  nmcli con add type team-slave con-name $team_name$slave_name ifname $slave_name master $team_name
  nmcli con up $team_name$slave_name
done

# 설정 확인
echo "Teaming 설정이 완료되었습니다."
