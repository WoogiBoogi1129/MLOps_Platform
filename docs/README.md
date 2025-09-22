```markdown
# ML Platform: Multi-Cloud Initial Architecture

> 🚀 멀티클라우드 환경(Private + Public Cloud)에 구축하는 **ML Platform 초기 아키텍처 디자인**  
> Private에서는 학습용 GPU(V100, A30, RTX 시리즈 등)를 활용하고, Public에서는 고성능 GPU(A100/H100)를 필요 시 버스트로 사용하는 구조입니다.  

---

## 🎯 설계 목표
- **GPU 자원 활용 극대화**: Notebook은 CPU Only로 상시 실행, 셀 실행 시에만 GPU Job이 서버리스 형태로 스핀업 → 종료 시 자원 해제  
- **Private 우선, Public 조건부 버스트**: Private의 Bronze/Silver GPU 풀을 최대 활용 후, SLA/예산/마감 조건 충족 시 Public Gold(A100/H100)로 확장  
- **데이터 주권 + 비용 최적화**: 민감 데이터는 Private에 상주, 모델/체크포인트만 퍼블릭과 동기화  
- **일관된 사용자 경험**: Kubeflow UI + OIDC(SSO) 기반 접근  
- **GitOps 기반 관리**: Argo CD로 플랫폼/워크로드 정의 및 배포 자동화  

---

## 🏗 전체 구조도 (Text-based)

```

┌────────────────────────────── Control / Mgmt Cluster (Private DC, HA) ──────────────────────────────┐
│  • Karmada (APIServer/CM/Scheduler, Webhooks/ResourceInterpreter)                                    │
│  • Argo CD (GitOps, App-of-Apps)      • Dex/IdP (OIDC SSO)        • Vault + External Secrets         │
│  • Policy/OPA (옵션)                   • Thanos/Grafana/Loki/Tempo  • Kubecost (비용 가시화)             │
└───────────────▲───────────────────────────────────────────────────────────────────────────────▲──────┘
│                                                                                 │ mTLS
│ Karmada Control-Plane                                                           │
│                                                                                 │
┌──────────┴───────────────────────────┐                                         ┌───────────┴─────────────────────────┐
│         Private GPU Cluster          │                                         │        Public GPU Cluster           │
│  (On-Prem: V100 / TITAN D6 / A30 /   │                                         │   (Cloud: A100/H100 등)             │
│   RTX 6000 SE …)                     │                                         │                                      │
│                                      │                                         │                                      │
│  • Kubeflow UI (Notebook=CPU Only)   │                                         │  (옵션) 경량 Kubeflow UI             │
│  • Kueue: gpu-bronze/silver/gold     │                                         │  Kueue: gpu-gold                     │
│  • GPU Operator + DCGM Exporter      │                                         │  GPU Operator                        │
│  • NFS/CephFS (RWX 홈/코드)          │◀─── S3 Replication ───▶                 │  Cloud Object Storage (S3/GCS)       │
│  • MinIO(S3: 데이터/체크포인트)       │                                         │                                      │
│  • Serving: KServe / vLLM / RayServe │◀── Mesh/GeoDNS ────────▶                 │  Serving: KServe / vLLM / RayServe   │
│  • Service Mesh: Istio/Cilium (mTLS) │                                         │  Service Mesh: Istio/Cilium (mTLS)  │
└──────────────────────────────────────┘                                         └──────────────────────────────────────┘

```

---

## 👩‍💻 사용자 흐름
1. 사용자는 Private 포털(Kubeflow UI)에 로그인 (Dex/SSO). Notebook 서버는 **CPU Only**로 항상 실행.
2. 노트북 셀 실행 시, Job 템플릿에 **GPU 등급/개수/예산/버스트/마감** 정보가 주입됨.
3. Karmada가 Job을 기본적으로 **Private**에 전파. (라벨/정책 충족 시 Public도 후보에 포함)
4. 각 클러스터의 **Kueue**가 ResourceFlavor(gpu-bronze/silver/gold)와 큐 상태를 기반으로 **실제 할당** 결정  
   - Private 충족 → Private 배치  
   - 지연/마감 임박/예산 정책 충족 → Public Gold로 조건부 버스트
5. Job Pod는 실행 후 **MinIO/S3**에 로그·체크포인트·아티팩트를 저장 후 종료 (서버리스 → Idle 낭비 없음).
6. Notebook은 실행 로그/결과를 실시간 스트리밍 수신 → 캐시/체크포인트 기반 재실행 가능.
7. 모델 서빙은 Private+Public 양쪽에 배포, Istio Mesh/GeoDNS로 트래픽을 지역·장애 상황에 따라 라우팅.

---

## 🛡 정책 & 거버넌스
- **데이터 분류**: 민감 데이터는 Private 전용, 모델/체크포인트만 퍼블릭 동기화 (Egress 비용 최소화)
- **RBAC/멀티테넌시**: 네임스페이스 격리, ResourceQuota, NetworkPolicy
- **시크릿/자격**: Vault + External Secrets → 클러스터별 안전 주입
- **퍼블릭 버스트 조건**:  
  `(큐 지연 > X분) ∧ (burstable=true) ∧ (budget=flex) ∧ (마감 임박 시 가중)`
- **비용/성능 튜닝**: Kubecost로 비용 추적, DCGM/Thanos로 GPU 활용률/대기/실행시간 분석

---

## 🔧 옵션/확장
- **Kernel 분리 (Enterprise Gateway)**: Notebook=웹/편집기, Kernel=원격 Pod(GPU). PVC에 venv/휠캐시 유지.
- **GitOps 범위**:  
  - 인프라/오퍼레이터/정책 → **강한 GitOps**  
  - 사용자 노트북 인스턴스 → **템플릿 중심 느슨한 GitOps**
- **ML 파이프라인**: Kubeflow Pipelines/Argo Workflows와 연계, 반복 학습/평가/배포 자동화

---

## 📌 향후 작업
- [ ] Draw.io 기반 아키텍처 다이어그램 추가  
- [ ] GPU Flavor(ResourceFlavor) 정책 샘플 YAML 정리  
- [ ] Gatekeeper ConstraintTemplate (GPU 요청 검증) 예시 추가  
- [ ] CI/CD: 모델 빌드·배포 워크플로우 템플릿화  
- [ ] 비용/ETA 예측 엔진 PoC  

---

## 📚 참고 링크
- [Karmada 공식 문서](https://karmada.io/)  
- [Kubeflow Training Operator](https://www.kubeflow.org/docs/components/training/)  
- [Kueue Scheduling](https://kueue.sigs.k8s.io/)  
- [Argo CD GitOps](https://argo-cd.readthedocs.io/)  
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/overview.html)  
- [Istio Multi-Cluster](https://istio.io/latest/docs/setup/install/multicluster/)  
- [Kubecost](https://www.kubecost.com/)  

---
```