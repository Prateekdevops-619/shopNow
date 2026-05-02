# ShopNow — End-to-End CI/CD on AWS EKS

> A production-grade MERN e-commerce application deployed via a fully automated Jenkins pipeline on Amazon EKS — from `git push` to a live, monitored deployment.

[![Jenkins](https://img.shields.io/badge/Jenkins-Declarative%20Pipeline-D24939?logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![Docker](https://img.shields.io/badge/Docker-Multi--stage-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS%201.31-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/Terraform-1.6+-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-2.15+-EE0000?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![AWS](https://img.shields.io/badge/AWS-eu--west--2-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/)

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Sprint Breakdown](#sprint-breakdown)
- [CI/CD Pipeline — 15 Stages](#cicd-pipeline--15-stages)
- [Kubernetes Workloads](#kubernetes-workloads)
- [Monitoring & Observability](#monitoring--observability)
- [Jenkins Access](#jenkins-access)
- [Author](#author)

---

## Overview

**ShopNow** is a full-stack MERN (MongoDB, Express, React, Node.js) e-commerce application that demonstrates the complete DevOps lifecycle. Every `git push` to `main` triggers a 15-stage Jenkins declarative pipeline that:

1. **Builds** multi-stage Docker images for `frontend`, `backend`, and `admin`, pushing them to **Amazon ECR**
2. **Verifies** infrastructure with **Terraform** (S3 remote state, DynamoDB locking)
3. **Configures** the Jenkins node with **Ansible** (Docker, kubectl, AWS CLI, Helm)
4. **Deploys** all workloads to **Amazon EKS** via `kubectl apply`
5. **Smoke-tests** the live ALB endpoint at `/api/health`
6. **Monitors** with **Prometheus** (metrics scraping) and **Grafana** (dashboards)
7. **Rolls back** all three deployments automatically on any pipeline failure

---

## Architecture

```
  Developer
     │  git push
     ▼
  GitHub ──── webhook ────► Jenkins EC2 (52.56.79.23:8080)
                                    │
              ┌─────────────────────┼──────────────────────┐
              │                     │                      │
         Terraform              Ansible               Docker Build
      (VPC, EKS, IAM,       (kubectl, awscli,      (frontend, backend,
       ECR, S3, DynamoDB)     Helm, Terraform)           admin)
                                                          │
                                                    docker push
                                                          │
                              ╔═══════════════════════════▼═══════════════╗
                              ║        AWS  eu-west-2                     ║
                              ║                                           ║
                              ║  Amazon ECR (975050024946)                ║
                              ║  ├── shopnow-backend                      ║
                              ║  ├── shopnow-frontend                     ║
                              ║  └── shopnow-admin                        ║
                              ║                                           ║
                              ║  VPC  10.0.0.0/16  (eu-west-2a/2b)       ║
                              ║  └── EKS Cluster: shopnow-eks (v1.31)     ║
                              ║       ├── Namespace: shopnow              ║
                              ║       │   ├── frontend   (2 replicas)     ║
                              ║       │   ├── backend    (2 replicas)     ║
                              ║       │   ├── admin      (2 replicas)     ║
                              ║       │   ├── mongodb    (StatefulSet)    ║
                              ║       │   ├── prometheus (metrics)        ║
                              ║       │   └── grafana    (dashboards)     ║
                              ║       └── Node Group: 2× t3.medium        ║
                              ║                                           ║
                              ║  ALB Ingress ◄── shopnow-ingress          ║
                              ╚═══════════════════════════════════════════╝
```

---

## Tech Stack

| Layer | Technology | Details |
|---|---|---|
| **Cloud** | AWS (eu-west-2) | VPC, EKS, ECR, EC2, S3, DynamoDB, ALB |
| **IaC** | Terraform ≥ 1.6 | Flat file structure, S3 remote state + DynamoDB locking |
| **Config Mgmt** | Ansible | 3 playbooks: install deps, configure EKS, deploy monitoring |
| **CI/CD** | Jenkins (EC2 t3.medium) | Declarative pipeline, 15 stages, AWS credentials binding |
| **Containers** | Docker multi-stage | Node 18 Alpine build → Nginx Alpine runtime |
| **Orchestration** | Kubernetes (EKS 1.31) | Deployments, StatefulSet, HPA, ConfigMap, Secrets, Ingress |
| **Frontend** | React + Nginx | Served under `/aryan/` sub-path with nginx API proxy |
| **Backend** | Node.js / Express | REST API on port 5000, `/api/health` endpoint |
| **Admin** | React | Admin panel, port 80 |
| **Database** | MongoDB 6.0 | StatefulSet with headless service |
| **Registry** | Amazon ECR | shopnow-backend, shopnow-frontend, shopnow-admin |
| **Monitoring** | Prometheus + Grafana | ClusterRole RBAC, 15d retention, pod annotation scraping |
| **Autoscaling** | HPA (autoscaling/v2) | CPU + Memory metrics, scale-up/down stabilization windows |

---

## Repository Structure

```
shopNow/
├── frontend/                        # React SPA
│   ├── Dockerfile                   # Multi-stage: Node 18 build → Nginx Alpine
│   ├── nginx/
│   │   └── default.conf             # /aryan/ rewrite + /aryan/api/ proxy
│   └── src/
├── backend/                         # Node.js / Express REST API
│   ├── Dockerfile
│   └── server.js
├── admin/                           # React admin panel
│   ├── Dockerfile
│   ├── nginx/default.conf
│   └── src/
├── terraform/                       # Flat IaC (no nested modules)
│   ├── backend.tf                   # S3 backend + DynamoDB locking
│   ├── main.tf                      # Provider + S3 bucket + DynamoDB table
│   ├── vpc.tf                       # VPC, public subnets (2 AZs), IGW, route tables
│   ├── eks.tf                       # EKS cluster + managed node group
│   ├── iam.tf                       # IAM roles for EKS, node group, Jenkins
│   ├── ecr.tf                       # ECR repositories
│   ├── jenkins-ec2.tf               # Jenkins EC2 + security group
│   ├── variables.tf
│   └── outputs.tf
├── ansible/
│   ├── inventory.ini                # Jenkins host: 52.56.79.23
│   └── playbooks/
│       ├── 01-install-dependencies.yml   # Git, Docker, kubectl, Terraform, AWS CLI
│       ├── 02-configure-eks-access.yml   # kubeconfig + namespace + Helm ALB controller
│       └── 03-deploy-monitoring.yml      # Apply Prometheus + Grafana manifests
├── k8s/
│   ├── namespace.yaml
│   ├── mongodb-secret.yaml          # Base64-encoded credentials
│   ├── mongodb-statefulset.yaml     # MongoDB 6.0 + headless service
│   ├── backend-deployment.yaml      # 2 replicas, /api/health probes, Prometheus annotations
│   ├── frontend-nginx-configmap.yaml
│   ├── frontend-deployment.yaml     # 2 replicas, LoadBalancer service
│   ├── admin-deployment.yaml        # 2 replicas
│   ├── hpa.yaml                     # autoscaling/v2 for backend + frontend
│   ├── ingress.yaml                 # ALB ingress for shopnow-ingress
│   └── monitoring/
│       ├── prometheus-config.yaml
│       ├── prometheus-deployment.yaml
│       └── grafana-deployment.yaml
├── docs/
│   ├── APPLICATION-ARCHITECTURE.md
│   ├── K8S-CONCEPTS.md
│   ├── TOOLS-SETUP-GUIDE.md
│   └── TROUBLESHOOTING.md
├── docker-compose.yml               # Local development
├── Jenkinsfile                      # Declarative pipeline (15 stages)
└── README.md
```

---

## Prerequisites

**AWS account** with permissions to create VPC, EKS, ECR, IAM, EC2, S3, DynamoDB in `eu-west-2`.

**Jenkins EC2** (`t3.medium`, Amazon Linux 2):
- IAM instance profile `prateek-jenkins-profile` with permissions for EKS, ECR, S3, EC2
- Jenkins credential `aws-cred` of type *AWS Credentials*
- Ports open: `22` (SSH), `8080` (Jenkins UI)
- Running as Docker container: `jenkins/jenkins:lts-jdk17`

**Local tooling:**

```bash
aws --version           # AWS CLI v2
terraform -version      # >= 1.6
ansible --version       # >= 2.15
kubectl version         # 1.28+
helm version            # >= 3.x
docker --version        # >= 24
```

**Terraform remote state** (create once before first pipeline run):

```bash
aws s3 mb s3://shopnow-terraform-state-975050024946 --region eu-west-2

aws dynamodb create-table \
  --table-name shopnow-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-2
```

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/Prateekdevops-619/shopNow.git
cd shopNow

# 2. Bootstrap infrastructure (first time only)
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# 3. Install Jenkins node dependencies
ansible-playbook -i ansible/inventory.ini \
  ansible/playbooks/01-install-dependencies.yml

# 4. Configure EKS access on Jenkins node
ansible-playbook -i ansible/inventory.ini \
  ansible/playbooks/02-configure-eks-access.yml

# 5. Apply MongoDB secret (update values first)
kubectl apply -f k8s/mongodb-secret.yaml -n shopnow

# 6. Trigger the full pipeline
#    Open Jenkins at http://52.56.79.23:8080
#    → ShopNow-CI-CD → Build Now
#    (or push a commit to main to trigger via webhook)

# 7. Get the application URL
kubectl get svc frontend-service -n shopnow \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

## Sprint Breakdown

### Sprint 1 — Application Containerization

Build slim multi-stage Docker images for all three services.

**Frontend Dockerfile** (React → Nginx, sub-path `/aryan/`):
```dockerfile
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
ARG REACT_APP_API_BASE_URL=/aryan/api
ENV REACT_APP_API_BASE_URL=$REACT_APP_API_BASE_URL
RUN npm run build

FROM nginx:stable-alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

**nginx proxy config** — the `/aryan/api/` block must come *before* the `/aryan/` rewrite, otherwise API calls get served as static files:
```nginx
location /aryan/api/ {
    proxy_pass http://backend-service:5000/api/;
    proxy_set_header Host $host;
}

location /aryan/ {
    rewrite ^/aryan/(.*)$ /$1 break;
    try_files $uri $uri/ /index.html;
}
```

---

### Sprint 2 — Infrastructure as Code (Terraform)

All AWS resources are defined in flat `.tf` files — no nested modules.

**backend.tf** — remote state:
```hcl
backend "s3" {
  bucket         = "shopnow-terraform-state-975050024946"
  key            = "shopnow/eks/terraform.tfstate"
  region         = "eu-west-2"
  encrypt        = true
  dynamodb_table = "shopnow-terraform-locks"
}
```

| File | Resource |
|---|---|
| `main.tf` | AWS provider, S3 state bucket, DynamoDB lock table |
| `vpc.tf` | VPC (10.0.0.0/16), 2 public subnets, IGW, route tables |
| `eks.tf` | EKS cluster `shopnow-eks` (v1.31), node group (2× t3.medium) |
| `iam.tf` | IAM roles for EKS control plane, node group, Jenkins EC2 |
| `ecr.tf` | ECR repos: shopnow-backend, shopnow-frontend, shopnow-admin |
| `jenkins-ec2.tf` | Jenkins t3.medium EC2, security group (ports 22, 8080) |

---

### Sprint 3 — Configuration Management (Ansible)

Three idempotent playbooks target `hosts: jenkins` in `ansible/inventory.ini` (Jenkins at `52.56.79.23`).

| Playbook | What it does |
|---|---|
| `01-install-dependencies.yml` | Installs git, Docker, AWS CLI v2, kubectl v1.28, Terraform v1.6.4 |
| `02-configure-eks-access.yml` | Creates `.kube/`, runs `aws eks update-kubeconfig`, creates `shopnow` namespace, installs AWS Load Balancer Controller via Helm |
| `03-deploy-monitoring.yml` | Applies Prometheus + Grafana manifests, waits for rollout |

---

### Sprint 4 — Kubernetes Deployment

All manifests live in `k8s/` and are applied by the Jenkins pipeline.

**Key design decisions:**

- **MongoDB** StatefulSet with headless service (`clusterIP: None`) for stable DNS (`mongodb-service.shopnow.svc.cluster.local`)
- **Frontend service** type `LoadBalancer` — cloud controller provisions a Classic ELB automatically
- **nginx config** delivered via ConfigMap volume — survives pod restarts without image rebuilds
- **HPA** uses `autoscaling/v2` with both CPU and Memory metrics

```yaml
# backend HPA: min 2 → max 8 pods
scaleUp:   stabilizationWindowSeconds: 60,  2 pods / 60s
scaleDown: stabilizationWindowSeconds: 300, 1 pod / 120s
```

---

### Sprint 5 — Monitoring & Observability

Prometheus scrapes all pods annotated with:
```yaml
prometheus.io/scrape: "true"
prometheus.io/port:   "5000"
prometheus.io/path:   "/metrics"
```

| Component | Image | Port |
|---|---|---|
| Prometheus | `prom/prometheus:v2.47.0` | 9090 |
| Grafana | `grafana/grafana:latest` | 3000 |

---

## CI/CD Pipeline — 15 Stages

```
 #1  Checkout
 #2  Configure AWS & ECR Login
 #3  Build & Push Backend       ─┐
 #4  Build & Push Frontend       ├── Sequential (conserves t3.medium memory)
 #5  Build & Push Admin         ─┘
 #6  Terraform Init
 #7  Terraform Plan
 #8  Ansible: Configure EKS Access
 #9  Update kubeconfig
#10  Deploy to EKS              (namespace, secrets, MongoDB, deployments, HPA, ingress)
#11  Wait for Rollout           (backend 180s, frontend 120s, admin 120s)
#12  Smoke Test                 (polls 30× for ALB hostname → curl /api/health)
#13  Deploy Monitoring          (Prometheus + Grafana)
#14  Ansible: Configure Monitoring
#15  Deployment Summary         (kubectl get pods/svc/ingress/hpa)

post:
  success → echo "shopNow is live on EKS"
  failure → kubectl rollout undo (backend + frontend + admin)
  always  → docker rmi cleanup
```

**Environment variables:**

| Variable | Value |
|---|---|
| `AWS_REGION` | `eu-west-2` |
| `AWS_ACCOUNT_ID` | `975050024946` |
| `ECR_BASE` | `975050024946.dkr.ecr.eu-west-2.amazonaws.com` |
| `EKS_CLUSTER` | `shopnow-eks` |
| `K8S_NAMESPACE` | `shopnow` |
| `KUBECONFIG` | `/var/lib/jenkins/.kube/config` |
| `IMAGE_TAG` | `${BUILD_NUMBER}` |

**Jenkins credentials required:**

| ID | Type | Usage |
|---|---|---|
| `aws-cred` | AWS Credentials | ECR login, EKS access, Terraform state |

---

## Kubernetes Workloads

| Workload | Kind | Replicas | Image | Service |
|---|---|---|---|---|
| backend | Deployment | 2 | `shopnow-backend:${BUILD_NUMBER}` | ClusterIP :5000 |
| frontend | Deployment | 2 | `shopnow-frontend:${BUILD_NUMBER}` | LoadBalancer :80 |
| admin | Deployment | 2 | `shopnow-admin:${BUILD_NUMBER}` | ClusterIP :80 |
| mongodb | StatefulSet | 1 | `mongo:6.0` | Headless (ClusterIP: None) :27017 |
| prometheus | Deployment | 1 | `prom/prometheus:v2.47.0` | ClusterIP :9090 |
| grafana | Deployment | 1 | `grafana/grafana:latest` | ClusterIP :3000 |

**Resource limits:**

| Workload | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---|---|---|---|---|
| backend | 100m | 500m | 128Mi | 256Mi |
| frontend | 50m | 200m | 64Mi | 128Mi |
| prometheus | 100m | 500m | 256Mi | 512Mi |

---

## Monitoring & Observability

```bash
# Prometheus targets
kubectl port-forward svc/prometheus-service 9090:9090 -n shopnow
# Open http://localhost:9090/targets

# Grafana dashboards
kubectl port-forward svc/grafana-service 3000:3000 -n shopnow
# Open http://localhost:3000
# Add data source: http://prometheus-service:9090
```

---

## Jenkins Access

| Item | Value |
|---|---|
| **URL** | http://52.56.79.23:8080 |
| **Username** | `admin` |
| **Job** | `ShopNow-CI-CD` |
| **EC2 Instance** | `i-0b81d91b39deff4b8` (eu-west-2) |
| **Instance Type** | t3.medium |
| **IAM Profile** | `prateek-jenkins-profile` |

---

## Author

**Prateek Tiwari**

- GitHub: [@Prateekdevops-619](https://github.com/Prateekdevops-619)
- Repository: [github.com/Prateekdevops-619/shopNow](https://github.com/Prateekdevops-619/shopNow)

---

<p align="center">
  <sub>Built with Terraform · Ansible · Jenkins · Docker · Kubernetes · Prometheus · Grafana on AWS EKS</sub>
</p>
