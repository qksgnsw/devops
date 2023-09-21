#!/bin/bash

set -e

# 해당 네트워크인터페이스에서 dns 설정 변경
echo "# 해당 네트워크인터페이스에서 dns 설정 변경"
nmcli connection modify ens160 ipv4.dns 172.16.74.100

# 재부팅
echo "# 재부팅"
init 6