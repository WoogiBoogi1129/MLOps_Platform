# 🚀 MLOps Platform

The **MLOps Platform** is designed to enable dynamic and efficient utilization of GPU resources in a cloud-native environment.  
Based on Kubeflow, the platform supports user-customized development environments, on-demand GPU allocation, session preservation, resource scheduling, and more.

---

## 🧭 Project Overview

- **Goal**: To build a platform that allows diverse users to easily access GPU resources while minimizing resource waste and maximizing operational efficiency.
- **Key Features**
  - GPU-powered development environments using Jupyter Notebook and VS Code
  - Selection of development environment (e.g., PyTorch, TensorFlow)
  - On-demand GPU allocation and automatic deallocation
  - Session state saving and restoration
  - GPU resource scheduling and sharing
  - Operational automation and dashboard-based monitoring

---

## 🛠 Technology Stack
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
     │  ┌───────────── Ingress/Gateway ────────────┐                       ┌──────────┴────────── Ingress/Gateway ──────────┐
     │  │  OIDC with Dex (중앙 SSO, 토큰만 왕복)    │                       │  OIDC with Dex (중앙 SSO)                         │
     │  └──────────────────────────────────────────┘                       └─────────────────────────────────────────────────┘
     │                                                                                                                   
     │  ┌──────────────── Kubeflow UI ──────────────┐                        (옵션) 경량 Kubeflow UI                           
     │  │ Notebook Server = **CPU Only** (항상 켜짐) │                        (퍼블릭은 필수 아님 — 서빙/버스트만 가능)           
     │  └───────────────────────────────────────────┘                                                                    
     │                                                                                                                   
     │  ┌─────────── “실행 시 GPU Job 서버리스” ────────────┐                 ┌────────── Job 후보(전파) ───────────┐
     │  │  Notebook 셀 실행 → Job 템플릿 생성              │                 │  Karmada PropagationPolicy          │
     │  │   - 요청 등급: BRONZE/SILVER/GOLD                │                 │   - 기본: Private 우선                │
     │  │   - 수량/예산/마감(DDL)/버스트 허용 라벨         │                 │   - 라벨( burtable=true ) 시 Public 포함 │
     │  └──────────────────────────────────────────────────┘                 └──────────────────────────────────────┘
     │                                                                                                                   
     │  ┌───────────── Kueue (대기열/할당) ────────────────┐                 ┌─────────── Kueue (대기열/할당) ───────────────┐
     │  │ ClusterQueue: cq-private-ml                      │                 │ ClusterQueue: cq-public-ml (주로 GOLD)        │
     │  │ ResourceFlavor: gpu-bronze/silver/gold           │                 │ ResourceFlavor: gpu-gold                       │
     │  │ (NFD/GFD 라벨: gpu.tier/칩셋/VRAM 등 매칭)        │                 │                                              │
     │  └──────────────────────────────────────────────────┘                 └──────────────────────────────────────────────┘
     │                                                                                                                   
     │  ┌──────── Storage (작업/데이터 분리) ────────┐                         ┌──────── Storage ──────────────────────┐
     │  │ • NFS/CephFS: RWX 홈/편집/코드/venv/PIP캐시 │                         │ • EBS/PD + S3/GCS (퍼블릭)            │
     │  │ • MinIO(S3): 데이터셋/체크포인트/아티팩트     │◀─── S3 Replication ───▶│ • Object Storage (모델/아티팩트 미러) │
     │  └────────────────────────────────────────────┘                         └───────────────────────────────────────┘
     │                                                                                                                   
     │  ┌────────── Serving (저지연/HA) ──────────┐                           ┌────────── Serving (Edge/HA) ──────────┐
     │  │ KServe / vLLM / Ray Serve              │◀── Mesh/GeoDNS ─────────▶│ KServe / vLLM / Ray Serve              │
     │  └────────────────────────────────────────┘                           └────────────────────────────────────────┘
     │                                                                                                                   
     │  Service Mesh: Istio or Cilium Mesh (mTLS, 멀티클러스터 서비스 디스커버리)                                          
     │  GPU Telemetry: NVIDIA GPU Operator + DCGM Exporter (Xid/OOM 경보)                                                 
     └────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

[사용자 흐름]
1) 사용자는 Private 포털( Kubeflow UI )에 로그인(SSO/Dex). Notebook 서버는 **CPU Only** 로 상시 가동.
2) 노트북 셀 실행 시, UI가 Job 템플릿에 **GPU 등급/수량/예산/버스트/마감**을 주입하여 제출.
3) Karmada가 기본적으로 **Private**에 Job을 전파. (라벨/정책 충족 시 Public도 “후보”에 포함)
4) 각 클러스터의 **Kueue**가 ResourceFlavor( gpu-bronze/silver/gold )와 큐 상태를 기준으로 **실제 할당** 결정.
   - Private에서 충족되면 Private 배치, 임계(대기 시간/마감/예산 정책) 시 Public GOLD로 **조건부 버스트**.
5) Job Pod는 실행 후 **MinIO/S3**에 결과(로그/아티팩트/체크포인트)를 남기고 종료(서버리스 → Idle 낭비 없음).
6) Notebook은 실행 로그/결과를 스트리밍 수신(인터랙티브 경험 유지). 재실행 시 캐시/체크포인트 재사용.
7) 서빙은 Private+Public에 분산 배치, Mesh/GeoDNS로 지역/장애 상황에 따라 트래픽 라우팅.

[정책 & 거버넌스]
• 데이터 분류: 원본 민감데이터는 Private 상주, 모델/체크포인트만 퍼블릭 동기화(전송비 최소화).  
• RBAC/멀티테넌시: 네임스페이스 격리, ResourceQuota, NetworkPolicy.  
• 시크릿/자격: Vault + External Secrets → 클러스터별 안전 주입.  
• 퍼블릭 버스트 조건: (Queue 지연 > X분) ∧ (burstable=true) ∧ (budget=flex) ∧ (DDL 임박 시 가중).  
• 비용/성능 튜닝: Kubecost로 클러스터·등급·큐별 비용 추적, DCGM/Thanos로 GPU 활용률·대기/실행 시간 분석.

[옵션/확장]
• Kernel 분리(Enterprise Gateway): Notebook=웹/편집기, Kernel=원격 Pod(GPU). PVC에 venv/휠캐시를 두어 설치 지속.  
• GitOps 범위: 플랫폼(인프라/오퍼레이터/정책)은 강한 GitOps, 사용자 노트북 인스턴스는 템플릿 중심의 느슨한 GitOps.  
• 파이프라인: Kubeflow Pipelines/Argo Workflows와 연계해 반복 학습/평가/배포 자동화.

| Category               | Technologies                                                                      |
|------------------------|-----------------------------------------------------------------------------------|
| Cluster Platform       | Kubernetes, Kubeflow                                                              |
| Development Tools      | Jupyter Notebook, VS Code, Terminal-based Access                                  |
| ML Frameworks          | PyTorch, TensorFlow                                                               |
| Infrastructure         | Docker, PersistentVolumeClaim (PVC), Istio, NVIDIA GPU                            |
| Monitoring & Logging   | Prometheus, Grafana, Fluentd *(optional)*                                         |
| Authentication & Security | Dex (OIDC), Kubernetes RBAC *(optional: OPA/Gatekeeper)*                      |
| Automation & Deployment| Kustomize, Helm *(Planned: Argo Workflow)*                                       |

---

## 🧩 System Architecture
[사용 흐름]
1) 사용자는 Private의 Kubeflow 포털에 로그인(SSO). Notebook Server는 CPU 전용으로 상시 가동.
2) 노트북에서 셀 실행 → “GPU Job” 제출(템플릿에 등급/수량/예산/마감 옵션 주입).
3) Karmada가 Job을 Private 우선 전파(필요 시 퍼블릭도 후보). OverridePolicy로 클러스터별 nodeSelector/SC 주입.
4) 각 클러스터의 Kueue가 ResourceFlavor(gpu-bronze/silver/gold)로 실제 슬롯 할당. 임계(지연/예산/DDL) 시 Public으로 버스트.
5) Job Pod는 실행 후 결과/아티팩트를 MinIO/S3에 저장하고 종료(서버리스). Notebook은 결과를 스트리밍/수집.
6) 서빙은 KServe/vLLM을 Private+Public에 분산 배치, Mesh/GeoDNS로 지역별 라우팅.
7) 관측성: Prometheus→Thanos, Loki/Tempo, DCGM, Kubecost로 대기/실행/비용/활용률 가시화.

- **User Flow**
  1. Connect via VPN
  2. Select development environment (e.g., Jupyter + PyTorch)
  3. Launch containerized environment
  4. Perform GPU-accelerated tasks
  5. Automatically return resources and save session upon exit

- **Admin Features**
  - Register and manage environment images
  - Control permissions and monitor resource usage
  - Automate user registration and access control

---

## 🧭 Roadmap

**Phase 1: Core Service Setup (May, Weeks 2–4)**  
- Setup Kubeflow-based notebook environments *(Completed)*  
- Implement Namespace and RBAC-based user isolation *(Completed)*  
- Draft UI for development environment selection *(In progress)*  

**Phase 2: Dynamic GPU Allocation & Session Restoration (May Week 5 – June Week 1)**  
- Implement GPU on-demand allocation and auto-deallocation  
- Develop session saving and restoration features  
- Integrate ML framework/version selection into UI  

**Phase 3: Resource Scheduling & Sharing (June Weeks 1–3)**  
- Introduce priority-based GPU scheduling policies (e.g., Kueue)  
- Apply CUDA MPS for GPU sharing among users  
- Set user-specific resource limits and concurrency control  

**Phase 4: Monitoring & Operational Automation (June Weeks 3–5)**  
- Build a system/resource monitoring dashboard using Grafana + Prometheus + DCGM Exporter  
- Develop anomaly detection and user alert system (e.g., Slack/Email)  
- Provide an admin-only dashboard with usage statistics and historical data  

---

## 🧪 User Testing Plan

- **Test Participants**: Students affiliated with Professor Minhye Kwon  
- **Test Environment**: Linux-based Jupyter Notebook and VS Code (PyTorch image)  
- **Feedback Criteria**
  - Ease of access
  - Usability of development environments
  - Responsiveness of GPU performance
  - Session persistence and restoration

---

## 👥 Team & Roles

| Name            | Role               | Notes                              |
|------------------|--------------------|-------------------------------------|
| TaeUk Hwang      | PM / Lead Developer | Roadmap planning, system architecture |
| Prof. Younghan Kim | Project Advisor     | Technical and strategic guidance    |
| Test Users       | Early Feedback      | Students from Prof. Kwon's lab      |
