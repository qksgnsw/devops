#!/bin/bash

Color_Off='\033[0m'

BGreen='\033[1;32m' 
Blue='\033[0;34m'  

# RAID 레벨 선택 및 디스크 목록 입력 받기
printf ${BGreen}
echo "* [Start] 사용 가능한 RAID levels: linear, 0, 1, 5, 6"
printf ${Color_Off}
read -p "1. RAID name을 입력하세요. (e.g., /dev/md?): " raid_name
read -p "2. RAID level을 입력하세요 (e.g., 1): " raid_level
read -p "3. disk devices를 입력하세요 (e.g., /dev/sd? /dev/sd?): " disk_devices
# 마운트 지점 입력 받기
read -p "4. mount 지점을 입력하세요. (e.g., /mnt/myraid): " mount_point

# 문자열 내의 공백 개수를 세기 위한 변수 초기화
space_count=1

# 문자열의 각 문자를 순회하며 공백 개수를 센다
for (( i=0; i<${#disk_devices}; i++ )); do
  char="${disk_devices:$i:1}"
  if [ "$char" == " " ] || [ "$char" == $'\t' ]; then
    ((space_count++))
  fi
done

printf ${BGreen}
echo "* * * 설정 내용 확인 * * *"
printf ${Color_Off}

echo "RAID 이름: " $raid_name
echo "RAID 레벨: " $raid_level
echo "RAID 디바이스 갯수: " $space_count
echo "RAID 디바이스: " $disk_devices
echo "RAID 마운트 지점: " $mount_point

# 폴더가 존재하는지 확인
printf ${Blue}
if [ -d "$mount_point" ]; then
  echo "* [Info] 폴더 '$mount_point'는 이미 존재합니다."
else
  # 폴더가 존재하지 않으면 폴더 생성
  mkdir -p "$mount_point"
  echo "* [Info] 폴더 '$mount_point'가 생성되었습니다."
fi

# RAID 배열 생성
printf ${Blue}
echo "* [Info] Creating RAID $raid_level array..."
printf ${Color_Off}
mdadm --create $raid_name --level=$raid_level --raid-devices=$space_count $disk_devices --run

# 파일 시스템 포맷
printf ${Blue}
echo "* [Info] Formatting the RAID array..."
printf ${Color_Off}
yes | mkfs.ext4 $raid_name

# 마운트 지점 생성 및 마운트
printf ${Blue}
echo "* [Info] Mounting the RAID array at $mount_point..."
printf ${Color_Off}
mkdir -p $mount_point
mount $raid_name $mount_point

# fstab에 마운트 정보 추가 (부팅 시 자동 마운트)
echo "$raid_name $mount_point ext4 defaults 0 0" >> /etc/fstab
mount -a

# RAID 배열 정보 표시
printf ${Blue}
echo "* [Info] RAID array information:"
printf ${Color_Off}
mdadm --detail $raid_name

printf ${Blue}
echo "* [Info] RAID_$raid_level array has been created and mounted at $mount_point."
printf ${Color_Off}