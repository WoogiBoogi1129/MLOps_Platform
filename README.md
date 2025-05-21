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
