# 🚀 Remote GPU Access Platform
클라우드 환경에서 GPU 자원을 **동적으로 효율적으로 활용**할 수 있도록 설계된 플랫폼입니다.  
Kubeflow 기반의 사용자 맞춤형 개발 환경 제공, GPU on-demand 할당, 상태 보존, 자원 스케줄링 등 다양한 기능을 포함합니다.

---
## 🧭 프로젝트 개요

- **목표**: 다양한 사용자들이 GPU 자원을 손쉽게 활용하면서도, 자원 낭비를 줄이고 시스템 운영 효율을 극대화하는 플랫폼 구축
- **주요 기능**
  - Jupyter, Vscode 기반 GPU 환경 제공
  - 개발 환경 선택 (PyTorch, TensorFlow 등)
  - GPU on-demand 할당 및 자동 해제
  - 사용자 상태(State) 복원 기능
  - 자원 스케줄링 및 공유 기능
  - 운영 자동화 및 대시보드 제공

---
## 🛠 주요 기술 스택

| Category         | Technologies                                               |
|------------------|------------------------------------------------------------|
| Cluster Platform | Kubernetes, Kubeflow                                       |
| Development Tools | Jupyter Notebook, VS Code, Terminal-based Access          |
| ML Frameworks    | PyTorch, TensorFlow                                        |
| Infrastructure   | Docker, PersistentVolumeClaim (PVC), Istio, NVIDIA GPU     |
| Monitoring & Logging | Prometheus, Grafana, Fluentd (optional)                |
| Authentication & Security | Dex (OIDC), Kubernetes RBAC, (Optional: OPA/Gatekeeper) |
| Automation       | Kustomize, Argo Workflow (planned), Helm                   |

---
## 🧩 시스템 아키텍처

> 📌 미정

- 사용자 흐름
  1. VPN 접속
  2. 환경 선택 (Jupyter + PyTorch 등)
  3. 컨테이너 기반 개발 환경 생성
  4. GPU 자원 할당 및 작업 수행
  5. 종료 시 자동 반납 및 상태 저장

- 관리자 기능
  - 환경 이미지 등록
  - 권한 관리 및 자원 모니터링
  - 사용자 등록 자동화

---
## 🗺 프로젝트 로드맵

### 📌 장기 목표 및 세부 단계

#### 1. User Environment Selection UI
- [x] UI Requirement Analysis
- [x] UI Design (Wireframe, UX)
- [ ] Frontend Implementation
- [ ] UI Testing & Feedback

#### 2. Dynamic GPU Allocation & Auto Release
- [ ] GPU Binding Research
- [ ] Idle Detection Module
- [ ] GPU Release Automation
- [ ] Integrated Testing

#### 3. GPU Sharing and Scheduling
- [ ] Scheduler Design
- [ ] Shared GPU Resource Pool Implementation
- [ ] Conflict Resolution & Policy Tuning

#### 4. GPU Usage Monitoring Automation
- [ ] Monitoring Metric Design
- [ ] Prometheus/Grafana Integration
- [ ] Alert/Automation Workflow

---

### 📅 마일스톤 (2025년 기준)

| 기간        | 목표 내용                                      | 진행 상황 |
|-------------|-----------------------------------------------|-----------|
| 05.08~05.15 | UI Requirement & Design                       | ⏳ 진행 중 |
| 05.15~05.30 | UI Implementation & Feedback                  | ⬜ 예정    |
| 06.01~06.15 | Dynamic GPU Binding, Idle Detection, Release  | ⬜ 예정    |
| 06.15~06.29 | GPU Sharing Scheduler & Conflict Policy       | ⬜ 예정    |
| 06.30~07.14 | Monitoring Automation (Prometheus/Grafana)    | ⬜ 예정    |

---
## 🧪 사용자 테스트 계획
- **실험 대상**: 권민혜 교수님 소속 학생
- **실험 환경**: 리눅스 기반 Jupyter Notebook 및 Vscode (PyTorch 이미지)
- **피드백 항목**
  - 접속 편의성
  - 개발 환경 사용성
  - GPU 성능 응답성
  - 작업 상태 보존 여부

---
## 👥 팀 및 역할

| 이름      | 역할         | 비고               |
| ------- | ---------- | ---------------- |
| 황태욱     | PM / 개발 총괄 | 로드맵 관리, 기술 구조 설계 |
| 김영한 교수님 | 총괄 책임자     | 방향성 조율 및 자문      |
| 실험 사용자  | 초기 피드백 제공자 | 권민혜 교수님 학생 등     |
