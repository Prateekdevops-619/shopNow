# 🚀 ShopNow: End-to-End Automated CI/CD Pipeline on AWS EKS

<details>
<summary><b>📑 Table of Contents (Click to expand)</b></summary>

- [Project Overview](#-project-overview)
- [Technology Stack](#-technology-stack)
- [Sprint Breakdown](#-sprint-breakdown)
- [Technical Deep Dives](#-technical-deep-dives)
- [Troubleshooting & Key Solutions](#-troubleshooting--key-solutions)
- [How to Run](#-how-to-run)
</details>

---

## 📖 Project Overview
This project establishes a production-grade CI/CD pipeline for the **ShopNow** MERN stack application. It automates the entire lifecycle—from infrastructure provisioning and configuration management to containerized deployment and real-time monitoring on AWS.

The primary goal is to reduce manual intervention, improve deployment efficiency, and ensure infrastructure resilience using an industry-standard DevOps toolchain.

## 🛠 Technology Stack
* **Cloud Infrastructure:** AWS (VPC, EKS, ECR, S3)
* **Infrastructure as Code:** Terraform with remote S3 state management
* **Configuration Management:** Ansible (Idempotent Server Setup)
* **CI/CD Orchestration:** Jenkins (Declarative Multi-stage Pipelines)
* **Orchestration:** Kubernetes (AWS EKS Managed Node Groups)
* **Observability:** Prometheus & Grafana Stack

---

## 📂 Sprint Breakdown
- [x] **Sprint 1:** Application Containerization & ECR Image Push
- [x] **Sprint 2:** Infrastructure Provisioning with Terraform
- [x] **Sprint 3:** Configuration Management with Ansible
- [x] **Sprint 4:** Kubernetes Deployment on AWS EKS
- [x] **Sprint 5:** Monitoring Setup with Prometheus/Grafana
- [x] **Sprint 6:** Final Pipeline Automation & Webhooks

---

## 💡 Technical Deep Dives

### 🔧 Nginx Routing Solution
A critical challenge addressed was the sub-path routing of the React application. Because the application is served under the `/aryan/` path, we implemented a regex-based rewrite rule to handle asset resolution and prevent 404 "Blank Screen" errors.

```nginx
location /aryan/ {
    rewrite ^/aryan/(.*)$ /$1 break;
    try_files $uri $uri/ /index.html;
}

---jenkins

pipeline {
    agent any
    environment {
        AWS_CRED_ID = "aws-cred"
        CLUSTER_NAME = "prateekshopnow-eks"
    }
    stages {
        stage('Infra') { steps { sh 'terraform apply -auto-approve' } }
        stage('Config') { steps { ansiblePlaybook(playbook: 'ansible/setup.yml') } }
        stage('Deploy') { steps { sh 'kubectl apply -f kubernetes/' } }
    }
    post {
        failure { mail to: 'admin@example.com', subject: 'Build Failed' }
        always { cleanWs() }
    }
}
