# Working SCV Project

- [ ] 서울리전
- [ ] 일본리전

### 실행
- .tfvars 파일 만들어 참조해야 함.
```sh
terraform init
terraform validate
terraform plan

terraform apply -var-file={{ YOUR_ENV_FILE_NAME }}.tfvars -auto-approve

terraform destroy -var-file={{ YOUR_ENV_FILE_NAME }}.tfvars
```

### 1. Infra
---
- [x] Infra
  - [x] vpc 생성
  - [x] Internet Gateway 생성
  - [x] 퍼블릭 서브넷 생성
    - [x] 라우팅 테이블 생성
  - [x] webserver-was 프라이빗 서브넷 생성
    - [x] 라우팅 테이블 생성
  - [x] db 프라이빗 서브넷 생성
    - [x] 라우팅 테이블 생성
  - [x] NAT Gateway 생성
    - [x] EIP 생성

### 2. Servers
---
- [ ] Servers
  - [ ] OpenVPN
    - [x] 보안 그룹
    - [x] 구독관련된 내용이라 일단 BastionHost로 진행


  - [ ] Web Server
    - [x] 보안 그룹
    - [x] ALB
        - [x] 보안그룹
        - [x] SSL
        - [ ] Autoscaling
            - [ ] Templete
            - [x] policy


  - [ ] WAS
    - [x] 보안 그룹 
    - [x] ALB
        - [x] 보안그룹
        - [x] SSL
        - [ ] Autoscaling
            - [ ] Templete
            - [x] policy


  - [ ] DB
    - [x] 보안 그룹
    - [ ] 정책 및 세팅 설정
      - [ ] Master-slave 구현

### 3. Services
---
- [ ] Service
  - [ ] Route53
    - [x] 인증서
      - [x] 생성
      - [x] 도메인 검증
    - [x] 레코드 등록
      - [ ] openVPN..?
      - [x] WebServer
      - [x] WAS
    - [ ] 장애조치 라우팅
    - [ ] 지역기반 라우팅

