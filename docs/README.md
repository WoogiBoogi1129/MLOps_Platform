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
┌──────────────────────────── Control / Mgmt (Private, Portal) ────────────────────────────┐
│ • Karmada Control Plane (APIServer/CM/Scheduler, Webhooks)                               │
│ • Argo CD (App-of-Apps / GitOps)   • Dex/Keycloak (OIDC/SSO)   • Vault + ExternalSecrets │
│ • Kubeflow Core (UI/Profiles/Pipelines)  • Notebook = CPU Only                           │
│ • Storage: MinIO(S3, 중앙 아티팩트) + NFS/CephFS(RWX 홈/코드/venv)                          │
│ • Observability: Thanos/Grafana/Loki/Tempo  • Cost: Kubecost                             │
└───────────────▲──────────────────────────────────────────────────────────────────▲────────┘
                │ (mTLS/API: 전파/상태수집)                                       │
                │                                                                  │
     ┌──────────┴───────────────┐                                      ┌───────────┴──────────────┐
     │     Private Member        │                                      │     Public Member (AWS)  │
     │  • Karmada Agent          │                                      │  • Karmada Agent         │
     │  • Kueue (CQ/LQ, Flavor)  │                                      │  • Kueue (CQ/LQ, Flavor) │
     │  • Training Operator      │                                      │  • Training Operator     │
     │  • GPU Operator + DCGM    │                                      │  • GPU Operator          │
     │  • NFD/GFD (gpu 라벨)     │                                      │  • NFD/GFD (gpu 라벨)    │
     │  • (옵션) KServe/vLLM     │                                      │  • KServe/vLLM           │
     │  • (옵션) S3 게이트웨이/캐시│                                      │  • AWS S3 (오브젝트 스토리지) │
     └───────────────────────────┘                                      └──────────────────────────┘

[데이터 경로]  MinIO(S3, 중앙)  ⇄  (선택) Private 캐시/미러  ⇄  AWS S3 (모델/체크포인트 동기화)
[서비스 경로]  필요 시 Istio/Cilium 멀티클러스터(L7 게이트웨이, mTLS) — Pod CIDR 라우팅 불필요
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