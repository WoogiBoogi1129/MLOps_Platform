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
🚀 로드맵

Phase 1: 핵심 서비스 환경 구성
 Kubeflow 기반 Notebook 환경 구축

 사용자 격리를 위한 Namespace/RBAC 설정

 개발 환경 선택 UI 초안 구현

Phase 2: GPU 동적 할당 및 세션 복원
 GPU On-Demand 할당 및 자동 해제 로직 구현

 사용자 세션 저장 및 복원 기능 개발

 UI를 통한 ML 프레임워크 선택 기능 통합

Phase 3: 자원 스케줄링 및 공유 기능
 우선순위 기반 GPU 스케줄링 정책 도입

 GPU 자원 공유 기능 구현 (MPS 고려)

 사용자 리소스 제한 정책 적용

Phase 4: 모니터링 및 운영 자동화
 GPU 및 시스템 사용량 모니터링 대시보드 구축

 비정상 사용 감지 및 사용자 알림 기능 개발

 운영자용 리소스 통계 및 이력 대시보드 제공

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
