#!/bin/bash

Color_Off='\033[0m'

BGreen='\033[1;32m' 
Blue='\033[0;34m'  

BIRed='\033[1;91m'

printf ${BGreen}
read -p "삭제할 RAID name을 입력하세요. (e.g., /dev/*): " raid_name
printf ${Color_Off}

umount $raid_name
mdadm --stop $raid_name

printf ${Blue}
echo "* [Info] $raid_name 삭제되었습니다."
printf ${Color_Off}

printf ${BIRed}
echo "* [Must] /etc/fstab 에서 해당하는 옵션을 반드시 확인하고 삭제하세요."
printf ${Color_Off}