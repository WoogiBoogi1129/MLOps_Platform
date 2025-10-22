# 🚀 MLOps Platform Technical Overview

The **MLOps Platform** delivers on-demand, GPU-accelerated development environments on top of a Kubeflow-powered Kubernetes cluster. This document consolidates the platform vision, architecture, and operational practices to help engineers, operators, and stakeholders align on how the system is built and evolved.

---

## 1. Platform Objectives

- **Self-service GPU Access**: Allow researchers and data scientists to launch pre-configured environments (Jupyter Notebook, VS Code, shell) with minimal friction.
- **Efficient Resource Utilization**: Dynamically allocate and reclaim GPU/CPU/memory resources to avoid idle capacity.
- **Reliability & Continuity**: Preserve user sessions and persistent volumes so that experiments can be resumed without manual intervention.
- **Operational Transparency**: Provide monitoring, auditing, and administrative tooling to keep the platform observable and compliant.

---

## 2. Key Capabilities

| Capability | Description |
|------------|-------------|
| **Environment Catalog** | Curated container images (PyTorch, TensorFlow, custom stacks) exposed through Kubeflow Notebooks and VS Code Web UI. |
| **GPU Lifecycle Management** | On-demand provisioning, automatic shutdown, and policy-driven scheduling of GPU workloads. |
| **Session Persistence** | PersistentVolumeClaims (PVC) mounted to each workspace so that notebooks, datasets, and checkpoints survive restarts. |
| **Multi-tenancy & Security** | Namespace isolation, Kubernetes RBAC, and Dex (OIDC) integration for authenticated access. Optional OPA/Gatekeeper policies reinforce governance. |
| **Observability** | Prometheus + Grafana dashboards, Fluentd log shipping, and NVIDIA DCGM metrics for GPU health. |
| **Automation Tooling** | Kustomize/Helm-based deployment pipelines with a roadmap toward Argo Workflows for CI/CD of ML pipelines. |

---

## 3. End-to-End User Journey

1. **Authenticate**: Users sign in through Dex (OIDC) and reach the Kubeflow central dashboard via VPN or other secure network paths.
2. **Select Workspace**: An appropriate container image (e.g., PyTorch + Jupyter) is launched from the environment catalog.
3. **Run Experiments**: Kubeflow spawns a pod with requested GPU/CPU/memory, mounts the user’s PVCs, and exposes IDEs or terminals.
4. **Persist Artifacts**: Checkpoints, notebooks, and datasets are written to mounted storage for resilience across restarts.
5. **Recycle Resources**: Idle detection or manual shutdown reclaims resources so the GPU pool can be shared efficiently.

---

## 4. Component Reference Guide

The following sections group platform components by their core responsibilities so that readers can quickly understand the
concepts behind each part of the system and how they interact.

### 4.1 Identity & Access
- **Dex (OIDC Provider)**: Centralizes authentication, integrates with institutional identity providers, and issues tokens for Kubeflow.
- **Kubernetes RBAC & Namespaces**: Enforces least-privilege access; namespaces provide tenancy boundaries for teams or courses.
- **Provisioning Scripts**: `dex/dex-user-add.sh`, `user-add/RGAP_user_add.sh`, and `user-del/RGAP_user_del.sh` standardize onboarding and offboarding.

### 4.2 Workspace Orchestration
- **Kubeflow Notebooks & VS Code**: Offer self-service IDEs that connect to GPU resources and pre-installed ML libraries.
- **Environment Catalog**: Curated images with common frameworks (PyTorch, TensorFlow) plus custom stacks for specialized workloads.
- **Session Policies**: Automatic shutdown timers and image version pinning preserve reproducibility while avoiding idle GPUs.

### 4.3 Compute Layer
- **Kubernetes Control Plane**: Schedules pods, manages node health, and exposes APIs for automation.
- **GPU-Enabled Nodes**: NVIDIA drivers and device plugins register GPU capacity; CUDA MPS and Kueue-based policies are planned for sharing.
- **Resource Quotas**: Enforced at namespace or user level to prevent noisy-neighbor issues.

### 4.4 Storage & Data Management
- **PersistentVolumeClaims (PVCs)**: Provide durable workspace storage for notebooks, datasets, and experiment outputs.
- **Shared Data Repositories**: Optional read-only mounts for common datasets or course materials.
- **Backup & Recovery**: Regular snapshots ensure experiments can be restored after failures or user error.

### 4.5 Networking & Security
- **Istio Gateway**: Routes user traffic into the cluster and applies mTLS between services.
- **VPN / Private Network Access**: Limits dashboard exposure to approved networks or on-prem access paths.
- **Policy Enforcement**: Gatekeeper/OPA policies validate cluster configurations; network policies constrain pod communication.

### 4.6 Observability & Operations
- **Prometheus + Grafana**: Collect metrics on GPU utilization, pod health, and storage consumption; dashboards highlight trends.
- **Fluentd / Logging Pipeline**: Ships logs to centralized storage for audit and debugging.
- **Alerting Integrations**: Optional hooks to Slack or email notify operators about capacity or reliability issues.

### 4.7 Automation & Delivery
- **Kustomize Bases & Overlays**: Manage cluster configuration across environments (dev, staging, prod).
- **Helm Charts**: Package higher-level services or third-party tools with versioned releases.
- **Argo Workflows (Planned)**: Provide CI/CD for ML pipelines, connecting data preparation, training, and deployment steps.

---

## 5. Operational Workflows

### 5.1 User Onboarding
1. Submit user details to administrators.
2. Run provisioning scripts to create Dex accounts and assign Kubernetes namespaces.
3. Confirm VPN access and deliver onboarding documentation.

### 5.2 Workspace Lifecycle
1. User launches a notebook or code-server instance.
2. GPU resources are allocated via Kubernetes scheduling (Kueue/priority-based policies are on the roadmap).
3. Autosave ensures notebooks and checkpoints persist to PVC.
4. Timeouts or explicit shutdown returns resources to the pool.

### 5.3 Monitoring & Incident Response
- Dashboards track GPU utilization, pod health, and storage consumption.
- Alerts notify operators about anomalous usage, failed pods, or nearing quotas.
- Incident runbooks detail steps for scaling nodes, rotating credentials, or draining problematic GPU hosts.

---

## 6. Roadmap

| Phase | Timeline | Focus |
|-------|----------|-------|
| **Phase 1 — Core Service Setup** | May (Weeks 2–4) | Kubeflow notebook deployment, namespace isolation, initial UI mockups. *(Completed)* |
| **Phase 2 — Dynamic GPU Allocation & Session Restore** | May Week 5 – June Week 1 | On-demand GPU provisioning, automatic deallocation, session persistence enhancements, image/version selector integration. |
| **Phase 3 — Resource Scheduling & Sharing** | June Weeks 1–3 | Introduce Kueue policies, enable CUDA MPS for shared GPUs, enforce per-user quotas and concurrency. |
| **Phase 4 — Monitoring & Automation** | June Weeks 3–5 | Expand Grafana dashboards, integrate Prometheus/DCGM, build alerting channels, deliver admin analytics. |

---

## 7. Testing & Validation Plan

- **Pilot Group**: Students from Professor Minhye Kwon’s lab.
- **Evaluation Environments**: Linux-based Jupyter and VS Code images optimized for PyTorch workloads.
- **Feedback Checklist**:
  - Authentication and onboarding friction
  - Responsiveness of GPU-enabled sessions
  - Stability of storage mounts and session recovery
  - Ease of switching between ML frameworks and tooling

---

## 8. Team & Responsibilities

| Member | Role | Responsibilities |
|--------|------|------------------|
| TaeUk Hwang | PM / Lead Engineer | Roadmap execution, architecture decisions, platform reliability. |
| Prof. Younghan Kim | Project Advisor | Technical oversight, strategic alignment, stakeholder communication. |
| Pilot Testers | Early Feedback | Provide usability feedback, report performance and reliability issues. |

---

## 9. Next Steps

- Finalize UI/UX for environment selection and integrate with Kubeflow notebooks.
- Implement automated shutdown policies for idle sessions with notification workflows.
- Extend monitoring to cover cost attribution per user/team and historical GPU usage trends.
- Document incident playbooks and SLAs for platform availability.

