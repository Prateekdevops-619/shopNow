# 🚀 ShopNow: End-to-End Automated CI/CD Pipeline on AWS EKS

## 📖 Project Overview
[cite_start]This project demonstrates a production-grade CI/CD pipeline for the ShopNow MERN stack application[cite: 1, 15]. [cite_start]It automates infrastructure provisioning, configuration management, containerized deployment, and real-time monitoring on AWS[cite: 9, 16].

### 🏗 Architecture Highlights
* [cite_start]**Cloud Platform:** AWS (VPC, EKS, ECR, S3)[cite: 18].
* [cite_start]**Infrastructure as Code:** Terraform with remote S3 state management[cite: 19, 91].
* [cite_start]**Configuration Management:** Ansible for idempotent environment setup[cite: 13, 20].
* [cite_start]**CI/CD Orchestration:** Jenkins (Declarative Multi-stage Pipelines)[cite: 21].
* [cite_start]**Observability:** Prometheus & Grafana stack for cluster and application health[cite: 23, 323].

---

## 📂 Sprint Breakdown

### 🔹 Sprint 1: Application Containerization
* [cite_start]**Objective:** Dockerize the MERN stack components[cite: 11, 24].
* [cite_start]**Frontend:** Multi-stage build using Nginx to serve assets under the `/aryan/` sub-path[cite: 84, 86].
* [cite_start]**Pipeline:** Automated build and push to Amazon ECR[cite: 49, 53].

### 🔹 Sprint 2: Infrastructure with Terraform
* [cite_start]**Objective:** Provision a custom VPC and a managed EKS cluster[cite: 12, 128].
* [cite_start]**State Management:** Used an S3 bucket for remote state to ensure team consistency[cite: 91].
* [cite_start]**Execution:** Jenkins pipeline stage to `init`, `plan`, and `apply` infrastructure[cite: 116, 125].

### 🔹 Sprint 3: Ansible Server Configuration
* [cite_start]**Objective:** Standardize the Jenkins management node[cite: 165].
* [cite_start]**Playbook:** Automated installation of Docker, AWS CLI, kubectl, and jq[cite: 168].
* [cite_start]**Permissions:** Configured `jenkins` user with necessary Docker group access[cite: 13].

### 🔹 Sprint 4 & 5: EKS Deployment & Monitoring
* [cite_start]**Deployment:** Orchestrated the rollout of frontend and backend services to the EKS cluster[cite: 14].
* [cite_start]**Critical Fix:** Implemented an **Nginx Rewrite Rule** to resolve sub-path routing and "blank screen" issues[cite: 321, 322].
* [cite_start]**Observability:** Deployed Prometheus and Grafana for real-time performance tracking.

### 🔹 Sprint 6: Final Automation & Hardening
* **Automation:** Configured GitHub Webhooks for automatic pipeline triggering upon code push.
* [cite_start]**Integrity:** Automated workspace cleanup and final end-to-end testing of the CI/CD flow[cite: 80].

---

## 🛠 Troubleshooting & Key Solutions
| Problem | Root Cause | Solution |
| :--- | :--- | :--- |
| **Apt Database Lock** | [cite_start]Background system updates [cite: 328] | [cite_start]Implemented Ansible lock-clearing and retry logic[cite: 328]. |
| **404 / Blank Assets** | [cite_start]Missing sub-path prefix [cite: 328] | [cite_start]Applied Nginx regex rewrite rule in `default.conf`[cite: 322, 328]. |
| **Docker Permission Denied** | [cite_start]Missing user groups [cite: 328] | [cite_start]Added `jenkins` user to the `docker` group via Ansible[cite: 328]. |

---

## 🚀 How to Run

### 1. Infrastructure Setup
Navigate to the terraform directory and initialize the environment:
```bash
cd terraform
terraform init
terraform apply -auto-approve
