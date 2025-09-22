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

> 📌 Detailed architecture documentation is in progress. Below is a high-level user flow.
                           ┌───────────────────────────── Control / Mgmt Cluster (Private DC, HA) ──────────────────────────────┐
 Git (Infra+Apps) ───────▶ │  Argo CD (App-of-Apps, GitOps)   Dex/IdP (OIDC SSO)   Vault+ESO   Thanos/Grafana   Kubecost       │
                           │  Karmada APIServer/CM/Scheduler + Webhooks (ResourceInterpreter)   Policy/OPA (opt)             │
                           └───────────────▲───────────────────────────────▲───────────────────────────────▲────────────────────┘
                                           │                               │                               │ mTLS
                              Karmada Control-Plane                         │                               │
                                           │                               │                               │
                   ┌───────────────────────┴──────────────────────┐        │                    ┌──────────┴───────────────────┐
                   │                 Private GPU Cluster          │        │                    │         Public GPU Cluster   │
                   │ (On-Prem: V100 / TITAN D6 / A30 / 6000 SE)  │        │                    │   (Cloud: A100/H100 etc.)   │
                   │                                              │        │                    │                              │
   Users ──HTTPS──▶│  Ingress/Gateway + OIDC (Dex)                │        │                    │  Ingress/Gateway + OIDC     │
 (Jupyter/VSCode)  │  Kubeflow UI (Notebook Server = CPU only)    │        │                    │  (옵션) 경량 Kubeflow UI     │
                   │  K8s API + Karmada Agent                     │        │                    │  K8s API + Karmada Agent    │
                   │                                              │        │                    │                              │
                   │  Kueue: LocalQueue/ClusterQueue              │◀───────┼──────── Job CRDs ─▶│  Kueue: LocalQueue/CQ       │
                   │  ResourceFlavor: gpu-bronze/silver/gold      │        │   (PyTorchJob/     │  ResourceFlavor: gpu-gold   │
                   │  NVIDIA GPU Operator + DCGM Exporter         │        │    TFJob/Job)      │  NVIDIA GPU Operator        │
                   │  NFD/GFD → nodeLabels(gpu.tier, chip, mem)   │        │                    │  NFD/GFD labels             │
                   │                                              │        │                    │                              │
                   │  Storage (RWX Home) : NFS/CephFS             │        │                    │  Storage: EBS/PD + S3/GCS   │
                   │  Object Store (Data/Artifacts): MinIO (S3)   │◀──Replicate/Sync──▶ Cloud Object Storage (S3/GCS)         │
                   │  (venv/whl cache PVC for kernels)            │        │                    │  (Artifacts/ckpt mirror)    │
                   │                                              │        │                    │                              │
                   │  Service Mesh: Istio or Cilium Mesh          │◀─── mTLS / Multi-Cluster ─▶│  Service Mesh (federated)   │
                   │                                              │        │                    │                              │
                   │  Serving: KServe/vLLM/Ray Serve              │◀── Global LB/GeoDNS ──────▶│  Serving (edge/HA/burst)    │
                   │                                              │                             │                              │
                   └──────────────────────────────────────────────┘                             └──────────────────────────────┘


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
