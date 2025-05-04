
# 🚀 Remote GPU Access Platform with Kubeflow Notebooks

This project provides a secure and scalable system that enables GPU-less users to remotely run GPU-based experiments using Jupyter Notebooks through a Kubeflow environment. It is designed to address the growing demand for shared GPU access in AI research.

---

## 📌 Overview

High-performance GPUs are essential for modern AI workloads, but access to such resources is often limited. This system solves that problem by allowing users without local GPUs to access shared GPU servers remotely via a web-based Jupyter Notebook interface using Kubeflow Notebooks. It supports isolated multi-user environments with secure authentication, namespace-based resource separation, and pre-assigned GPU resources.

---

## 🎯 Key Features

- ✅ **Multi-user GPU access via Jupyter Notebooks**
- 🔒 **Dex-based secure login with namespace isolation**
- 🌐 **Remote access through OpenVPN + Istio NodePort**
- 🎛️ **Static GPU allocation per user (1 GPU per notebook)**
- 🧪 **Kubeflow v1.19.1 deployed via manifests**
- 🚀 **Runs on a single-node cluster with 3× NVIDIA TITAN GPUs**

---

## 🧱 System Architecture

```text
[ User PC ] 
    ↕ (OpenVPN)
[ Internal Network ]
    ↕
[ Istio Ingress Gateway (NodePort) ]
    ↕
[ Dex Login ]
    ↕
[ Pre-assigned Jupyter Notebook Server ]
    ↕
[ GPU-enabled Kubeflow Notebook (1 GPU) ]
````
---

## ⚙️ Deployment Environment

* **Kubeflow Version**: v1.19.1
* **Deployment Method**: Manifest-based installation
* **Cluster Type**: Single-node Kubernetes cluster
* **GPU Specs**: 3× NVIDIA TITAN D6
* **Authentication**: Dex (via Istio Ingress Gateway)
* **Access Method**: External OpenVPN + NodePort

---

## 🧑‍💼 User Access Flow

1. **VPN 접속**: 사용자는 OpenVPN으로 내부 네트워크에 접근
2. **웹 로그인**: NodePort로 노출된 `istio-ingressgateway`를 통해 Dex 로그인
3. **자동 연결**: 사용자에게 할당된 namespace의 Jupyter Notebook으로 자동 연결
4. **GPU 실험 수행**: 웹에서 실시간 GPU 자원 확인 및 실험 가능

---

## 📓 Sample Jupyter Notebook GPU Test

After login, users can confirm GPU access using:

```python
!nvidia-smi
```

Or with PyTorch:

```python
import torch
print(torch.cuda.is_available())
print(torch.cuda.get_device_name(0))
```
---
## 🧩 Future Work

* ✅ 실험 로그 수집 및 모니터링 도구 연동 (e.g. Prometheus, Loki)
* ✅ 사용자별 자원 사용량 시각화 대시보드 제공
* ✅ 자동 GPU 재할당 및 OOM 대응 기능 추가

---

## 📬 Contact

Maintainer: \[Hwang Tae Uk]
Email: [taeuk.h@dcn.ssu.ac.kr](mailto:taeuk.h@dcn.ssu.ac.kr)

---

## 📚 References

* [Kubeflow Notebooks](https://www.kubeflow.org/docs/components/notebooks/)
* [Dex Authentication](https://dexidp.io/)
* [Istio Ingress Gateway](https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/)
* [NVIDIA GPU Plugin for Kubernetes](https://github.com/NVIDIA/k8s-device-plugin)

```
