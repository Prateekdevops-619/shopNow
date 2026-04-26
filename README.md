# ShopNow DevOps Capstone Project 🚀

End-to-End Automated **CI/CD Pipeline on AWS EKS**  
Author: Prateek | April 2026  

GitHub Repo: [ShopNow](https://github.com/Prateekdevops-619/shopNow.git)

---

## 📌 Project Overview

The **ShopNow** project implements a fully automated CI/CD pipeline using **Jenkins** as the orchestrator. It integrates **Terraform, Ansible, Docker, Kubernetes, Prometheus, and Grafana** to deliver a scalable, resilient, and observable application deployment on **AWS EKS**.

### 🎯 Objectives
- Design application architecture with load balancing, container orchestration, and monitoring.
- Provision AWS infrastructure (VPC, subnets, EKS) using **Terraform**.
- Automate configuration management with **Ansible**.
- Deploy Dockerized MERN stack application on **Kubernetes (EKS)**.
- Implement **Jenkins CI/CD pipeline** for continuous integration and deployment.
- Set up monitoring with **Prometheus & Grafana**.

---

## 🏗️ Key Architecture Components
- **Infrastructure**: AWS (VPC, EKS, ECR, S3)
- **IaC**: Terraform (Remote State Management)
- **Configuration**: Ansible (Idempotent Server Setup)
- **CI/CD**: Jenkins (Declarative Multi-stage Pipeline)
- **Orchestration**: Kubernetes (Managed EKS Nodes)
- **Observability**: Prometheus & Grafana

---

## 📚 Sprints Breakdown

### Sprint 1: Application Containerization
- Dockerized MERN stack (backend & frontend).
- Jenkins pipeline builds and pushes images to **AWS ECR**.
- Optimized **Nginx Dockerfile** for frontend.

👉 [Backend & Frontend Dockerfiles](https://github.com/Prateekdevops-619/shopNow)

---

### Sprint 2: Infrastructure with Terraform
- Provisioned **VPC & EKS cluster** with Terraform.
- Remote state stored in **S3**.
- Jenkins pipeline automates `terraform init`, `plan`, and `apply`.

👉 [Terraform Code](https://github.com/Prateekdevops-619/shopNow/tree/sprint2-terraform/terraform)

---

### Sprint 3: Ansible Configuration
- Configured Jenkins node with Docker, Kubectl, and essential tools.
- Playbook ensures idempotent setup and retries for apt locks.
- Jenkins pipeline integrates Terraform + Ansible + Docker builds.

👉 [Ansible Playbook](https://github.com/Prateekdevops-619/shopNow/tree/sprint3-ansible/ansible)

---

### Sprint 4: Kubernetes Deployment
- Jenkins pipeline applies Kubernetes manifests (`kubectl apply -f kubernetes/`).
- Fixed frontend blank screen issue with **Nginx rewrite rule**:
  ```nginx
  location /aryan/ {
      rewrite ^/aryan/(.*)$ /$1 break;
      try_files $uri $uri/ /index.html;
  }

### Sprint 5: Monitoring & Alerts
- Integrated Prometheus & Grafana dashboards.
- Jenkins pipeline includes monitoring stage (kubectl get pods -n monitoring).
- Jenkins alerts configured to send email notifications on pipeline failure.

### ✅ Final Outcome
- Automated CI/CD pipeline from GitHub → Jenkins → ECR → EKS.
- Infrastructure provisioned with Terraform.
- Configuration automated with Ansible.
- Application deployed on Kubernetes.
- Monitoring and alerting with Prometheus & Grafana.


### 📂 Repository Structure

shopNow/
├── backend/              # Backend Dockerfile & code
├── frontend/             # Frontend Dockerfile & code
├── terraform/            # IaC for AWS infra
├── ansible/              # Configuration management
├── kubernetes/           # Deployment manifests
├── Jenkinsfile           # CI/CD pipeline definition
└── docker-compose.yml    # Local testing setup

### 🚀 How to Run
- Clone the repo:
git clone https://github.com/Prateekdevops-619/shopNow.git
- Build & push Docker images via Jenkins pipeline.
- Provision infra with Terraform (terraform apply).
- Configure Jenkins node with Ansible (ansible-playbook setup.yml).
- Deploy app with Kubernetes (kubectl apply -f kubernetes/).
- Access monitoring dashboards via Grafana.

### 📧 Alerts
Jenkins pipeline sends alerts on failure:
post {
  failure {
    echo "ALERT: Deployment Failed!"
    mail to: 'your-email@example.com',
         subject: "Pipeline Failure: ${env.JOB_NAME}",
         body: "Build #${env.BUILD_NUMBER} failed. Check Grafana for resource health."
  }
}



### 🌟 Author
Prateek – Solution Architect & DevOps Enthusiast
Focused on CI/CD, Cloud Automation, and Monitoring





