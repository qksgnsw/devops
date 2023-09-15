# 재해 복구 개인 프로젝트

### 재해 복구
- 재해에 대비하고 재해를 복구하는 프로세스
- 재해 복구는 복원성 전략의 중요한 부분
- 고객은 클라우드 환경에서 **애플리케이션의 가용성**애 대한 책임이 존재
- 가용성 vs 복원성
  - 가용성
    - 시스템이 사용 가능한 상태를 유지
  - 복원성
    - 장애 및 문제가 생겼을 때 시스템이 빠르게 회복하고 복구

### 책임 모델
- AWS
  - 클라우드 서비스를 실행하는 하드웨어, 소프트웨어, 네트워킹 및 시설
- 고객
  - 백업, 버전 관리 및 복제 전략

### AWS 클라우드의 재해 복구
- 이점
  - 복잡성을 줄이면서 재해로부터 신속하게 복구
  - 간단하고 반복 가능한 테스트를 통해 보다 쉽고 잦은 테스트 가능
  - 관리 오버헤드 감소로 운영 부담 경감
  - 자동화를 통해 오류 발생 가능성을 줄이고 복구 시간 단축
- 단일 AWS 리전
  - 단일 AWS 리전 내의 여러 가용 영역에 고가용성 워크로드를 구현
  - 재해의 위험을 완화하고 데이터 손실을 야기할 수 있는 오류 또는 무단 활동과 같은 인적 위협의 위험을 줄일 수 있음.
  - 가용 영역은 물리적 중복성을 위해 설계. 복원성을 제공
- 다중 AWS 리전
  - 서로 멀리 떨어져 있는 여러 데이터 센터에 손실이 발생할 수 있는 위험이 포함된 재해 이벤트의 경우, 
  - AWS 내 전체 리전에 영향을 미치는 자연 재해 및 기술 재해에 대비할 수 있는 재해 복구 옵션을 고려.

### [재해 복구 전략 아키텍처](https://docs.aws.amazon.com/ko_kr/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html)
- 백업 및 복원
  - 데이터 손실 또는 손상을 완화하는 데 적합한 방식
  - 데이터를 다른 AWS 리전으로 복제
  - 복구 리전에 인프라, 구성 및 애플리케이션 코드를 재배포해야 함.
  - 코드형 인프라(IaC)를 사용하여 배포
    - 이를 사용하지 않으면 복구가 복잡해 질 수 있음.
    - RTO 증가
- 파일럿 라이트
  - 한 리전에서 다른 리전으로 데이터를 복제하고 핵심 워크로드 인프라의 복사본을 프로비저닝할 수 있음.
  - 핵심 인프라는 항상 켜져있음.
  - 데이터 복제 및 백업을 지원하는 데 필요한 리소스는 항상 켜져 있음.
  - 애플리케이션은 꺼져있으며 복구 장애 조치가 호출될 때만 사용.
- 웜 스탠바이
  -  완전히 작동하는 프로덕션 환경의 복사본이 다른 리전에 있는지 확인하는 작업이 포함
  -  워크로드가 다른 리전에서 항상 켜져 있기 때문에 파일럿 라이트 개념을 확장하고 **복구 시간을 단축**
  -  파일럿 라이트는 먼저 추가 조치를 취하지 않으면 요청을 처리할 수 없는 반면, 
  - 웜 스탠바이는 트래픽을 (감소된 용량 수준에서) 즉시 처리
- 다중 사이트 활성/활성
  - 워크로드를 여러 리전에서 동시에 실행
  - 가장 복잡하고 비용이 많이 드는 재해 복구 방식이지만 
    - 올바른 기술 선택 및 구현을 통해 대부분의 재해에 대한 복구 시간을 거의 제로
  - 사용자 트래픽을 처리하는 데 두 리전을 모두 사용하지 않으려는 경우 
    - 웜 스탠바이는 경제적이며 운영 면에서 덜 복잡한 방식을 제공

### 사용할 서비스
- Amazon Aurora
  - 클러스터
    - DB 인스턴스와 3개의 가용 영역에 걸쳐 복사되는 DB 클러스터의 데이터를 
    - 단일 가상 볼륨으로 보유하는 클러스터 볼륨으로 구성
    - 읽기와 쓰기를 수행하는 기본 DB 인스턴스
    - 옵션으로 최대 15개의 Aurora 복제본(리더 DB 인스턴스)이 포함
    - 구성
      - 가용 영역이 최소 2개 이상인 AWS 리전의 VPC에만 생성 가능
  - 스냅샷
  - Amazon Aurora Global Database
- AWS Backup
  - EBS 볼륨
  - EC2 인스턴스
- S3 
  - 객체 버전 관리 활성화
  - 복제
- Auto Scaling
  - Amazon EC2 인스턴스
  - Amazon ECS 작업
  - Amazon DynamoDB 처리량
  - Amazon Aurora 복제본을 포함한 리소스를 확장하는 데 사용
- Route53
  - 트래픽 관리
  - [상태확인](https://docs.aws.amazon.com/ko_kr/Route53/latest/DeveloperGuide/welcome-health-checks.html)
    - 웹 서버 및 이메일 서버 같은 리소스의 상태를 모니터링
    - Amazon CloudWatch 경보를 구성하여 리소스를 사용할 수 없게 될 때 알림을 수신
      - 응답없음 -> 클라우드와치알람 -> AWS SNS
  - [DNS 장애 조치](https://docs.aws.amazon.com/ko_kr/Route53/latest/DeveloperGuide/dns-failover.html)
    - [액티브-패시브 장애 조치](https://docs.aws.amazon.com/ko_kr/Route53/latest/DeveloperGuide/dns-failover-types.html)
- Global Accelerator
  - AnyCast IP를 사용하면 
    - 하나 이상의 AWS 리전에 있는 여러 엔드포인트를 동일한 고정 IP 주소로 연결할 수 있음.
  - [상태 확인 옵션](https://docs.aws.amazon.com/ko_kr/global-accelerator/latest/dg/about-endpoint-groups-health-check-options.html)

### TO DO
- 코드화까지 된 것은 체크되고
- 코드화되지 않은 것은 📌표기한다.
- 고민해야하는 부분은 📍로 표기한다.

- [x] **기본 내용 배포**
  - [x] VPC
  - [x] Subnet
    - [x] Public
    - [x] Private
  - [x] Internet Gateway
  - [x] Nat Gateway
  - [x] Route
  - [x] Multi AZ
  - [x] Security Group
  - [x] Bastion Host
  - [x] Private Instance
  - [x] Target Group
  - [x] Application LoadBalancer
    - [x] Security Group
  - [x] Auto scaling
    - [x] Template
- [x] 📍Active-Passive를 같은 template으로 배포할 것인가?
  - [x] 같은 템플릿으로 배포하되
  - [x] 조건문을 통해 다른 옵션으로 생성 가능하게 함.
- [x] **Route53**
  - [x] 상태 확인 생성
    - [x] Active
    - [x] Passive
  - [x] Failover Routing
    - [x] Active
    - [x] Passive
- [ ] 📍아래 리소스를 바탕으로 추가한다.
  - [ ] AWS Aurora -> 어려워서 좀 나중으로 미룸.
    - [ ] [cloudformation](https://docs.aws.amazon.com/ko_kr/AWSCloudFormation/latest/UserGuide/AWS_RDS.html)
    - [ ] Snapshot
    - [ ] AZ
      - [ ] cluster
    - [ ] Region
      - [ ] global database
  - [ ] S3
  - [ ] AWS Backup
  - [ ] ~~Global Accelertor~~
  - [ ] CloudWatch alram
  - [ ] AWS SNS
  - [ ] 📍상태 검사 -> 클라우트와치 알람 -> 트리거 -> cloudformation 코드 업데이트
