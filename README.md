# ShopNow

> **End-to-End Automated CI/CD Pipeline on AWS EKS**
> A production-grade reference implementation that takes a MERN-stack e-commerce app from `git push` to a healthy, monitored deployment on Amazon EKS — with zero manual infrastructure steps.

[![Terraform](https://img.shields.io/badge/Terraform-1.6%2B-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-2.15%2B-EE0000?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Jenkins](https://img.shields.io/badge/Jenkins-Declarative-D24939?logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![Docker](https://img.shields.io/badge/Docker-Multi--stage-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![AWS](https://img.shields.io/badge/AWS-eu--west--2-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Metrics-E6522C?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-Dashboards-F46800?logo=grafana&logoColor=white)](https://grafana.com/)

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Repository Layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Sprint Walkthrough](#sprint-walkthrough)
  - [Sprint 1 — Application Containerization](#sprint-1--application-containerization)
  - [Sprint 2 — Infrastructure as Code (Terraform)](#sprint-2--infrastructure-as-code-terraform)
  - [Sprint 3 — Configuration Management (Ansible)](#sprint-3--configuration-management-ansible)
  - [Sprint 4 — Kubernetes Deployment](#sprint-4--kubernetes-deployment)
  - [Sprint 5 — Monitoring & Alerting](#sprint-5--monitoring--alerting)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Observability](#monitoring--observability)
- [Troubleshooting](#troubleshooting)
- [Author](#author)

---

## Overview

**ShopNow** demonstrates the complete DevOps lifecycle — source control, infrastructure provisioning, configuration management, image build & registry, deployment orchestration, and observability — wired together as one reproducible pipeline.

A single Jenkins run will:

1. Provision AWS infrastructure with **Terraform** (VPC, subnets, EKS, IAM, S3 backend)
2. Configure runtime nodes with **Ansible** (Docker, kubectl, awscli, retries against apt locks)
3. Build slim, multi-stage **Docker** images for the React frontend and Node.js backend
4. Push images to **Amazon ECR**
5. Roll out to **EKS** via `kubectl apply`
6. Verify pod health and scrape metrics with **Prometheus + Grafana**
7. Send failure alerts via email / Jenkins post-block

> **Why?** DevOps teams need a CI/CD pipeline that streamlines development and deployment so changes are consistently tested, built, and deployed across environments. ShopNow treats the entire delivery system — infrastructure, configuration, application, monitoring — as code.

---

## Architecture

A high-level view of the end-to-end flow:

```
                  ┌─────────────┐    push      ┌────────────┐  webhook    ┌────────────────┐
                  │  Developer  │ ───────────► │  GitHub    │ ──────────► │ Jenkins (EC2)  │
                  └─────────────┘              └────────────┘             └───────┬────────┘
                                                                                  │
                          ┌───────────────────────────────────────────────────────┴───────┐
                          │                                                                 │
                  ┌───────▼─────┐  ┌──────────┐  ┌──────────────┐                          │
                  │  Terraform  │  │  Ansible │  │ Docker Build │                          │
                  └─────────────┘  └──────────┘  └──────┬───────┘                          │
                                                         │ docker push                      │ kubectl apply
                          ╔══════════════════════════════▼══════════════════════════════════▼══════╗
                          ║                          AWS Cloud  (eu-west-2)                         ║
                          ║                                                                         ║
                          ║   ┌────────────┐   ┌──────────────────────────────────────────────┐    ║
                          ║   │ Amazon ECR │   │  VPC 10.0.0.0/16                              │    ║
                          ║   └─────┬──────┘   │  ┌─────────────────────────────────────────┐  │    ║
                          ║         │ pull     │  │  Public subnet — ALB, IGW, EKS API      │  │    ║
                          ║         ▼          │  └────────────────────┬────────────────────┘  │    ║
                          ║   ┌──────────────┐ │  ┌────────────────────▼────────────────────┐  │    ║
                          ║   │ EKS Cluster  │ │  │  Public subnet — EKS worker nodes      │  │    ║
                          ║   │ Frontend Pod │ │  │  Frontend  ─►  Backend  ─►  MongoDB     │  │    ║
                          ║   │ Backend  Pod │ │  │              Prometheus  ─►  Grafana    │  │    ║
                          ║   │ MongoDB Pod  │ │  └─────────────────────────────────────────┘  │    ║
                          ║   └──────────────┘ └──────────────────────────────────────────────┘    ║
                          ╚═════════════════════════════════════════════════════════════════════════╝
```

> **Editable diagram:** open [`docs/ShopNow_Architecture.drawio`](docs/ShopNow_Architecture.drawio) in [app.diagrams.net](https://app.diagrams.net) for the full multi-page architecture (solution overview, pipeline flow, monitoring stack).

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Cloud** | AWS (eu-west-2) | Hosting region, managed services |
| **Networking** | VPC, IGW, NAT, ALB | Public/private subnet topology, layer-7 routing |
| **Compute** | EKS (managed node groups) | Container orchestration |
| **Registry** | Amazon ECR | Private Docker image store |
| **State** | S3 (remote backend) | Terraform state with locking |
| **IaC** | Terraform `>= 1.6` | Declarative infra provisioning |
| **Config Mgmt** | Ansible | Idempotent node configuration |
| **CI/CD** | Jenkins (declarative) | Pipeline orchestration |
| **Containers** | Docker, multi-stage | Image packaging |
| **Frontend** | React + Nginx (Alpine) | SPA with `/aryan/` sub-path routing |
| **Backend** | Node.js / Express | REST API |
| **Database** | MongoDB | Document store for catalog & orders |
| **Monitoring** | Prometheus + Grafana | Metrics, dashboards, alerts |


---

## Repository Layout

This repo uses a **branch-per-sprint** layout — each branch is one well-scoped concern.

| Branch | Contents |
|---|---|
| [`main`](https://github.com/Prateekdevops-619/shopNow/tree/main) | Application source — `frontend/` (React) and `backend/` (Node.js) |
| [`sprint2-terraform`](https://github.com/Prateekdevops-619/shopNow/tree/sprint2-terraform/terraform) | Terraform modules for VPC and EKS, S3 backend configuration |
| [`sprint3-ansible`](https://github.com/Prateekdevops-619/shopNow/tree/sprint3-ansible/ansible) | Ansible playbook (`ansible/setup.yml`) and inventory |
| [`sprint4-kubernetes`](https://github.com/Prateekdevops-619/shopNow/tree/sprint4-kubernetes/kubernetes) | Kubernetes manifests for deployments, services, ingress |

```
shopNow/
├── frontend/             # React SPA (served at /aryan/ via Nginx)
│   ├── Dockerfile
│   ├── nginx/
│   │   └── default.conf
│   └── src/
├── backend/              # Node.js / Express REST API
│   ├── Dockerfile
│   └── src/
├── terraform/            # (sprint2-terraform branch) IaC modules
│   ├── main.tf
│   └── modules/
│       ├── vpc/
│       └── eks/
├── ansible/              # (sprint3-ansible branch) node config
│   └── setup.yml
├── kubernetes/           # (sprint4-kubernetes branch) manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── Jenkinsfile           # Declarative pipeline
└── README.md
```

---

## Prerequisites

Before running the pipeline, make sure you have:

- An **AWS account** with permissions to create VPC, EKS, ECR, IAM, S3 resources in `eu-west-2`
- An **EC2 instance** (`t3.medium` or larger) with:
  - Jenkins LTS installed
  - Docker installed (`jenkins` user added to the `docker` group)
  - An IAM role attached granting access to ECR, EKS, S3
- An **ECR repository** named `shopnow-frontend` and `shopnow-backend`
- An **S3 bucket** named `prateek-shopnow-tfstate` (or update the backend config)
- A **Jenkins credential** named `aws-cred` of type *AWS Credentials*

Local tooling (for manual ops):

```bash
aws --version          # AWS CLI v2
terraform -version     # >= 1.6
ansible --version      # >= 2.15
docker --version       # >= 24
kubectl version        # client matching EKS version
```

---

## Quick Start

> **Heads up:** running this end-to-end provisions billable AWS resources (EKS, NAT GW, ALB). Tear them down with `terraform destroy` when done.

```bash
# 1. Clone the repo
git clone https://github.com/Prateekdevops-619/shopNow.git
cd shopNow

# 2. Trigger the full pipeline from Jenkins
#    (or run stages manually below)

# --- Manual run ---

# 2a. Provision infrastructure
git checkout sprint2-terraform
cd terraform
terraform init
terraform apply -auto-approve

# 2b. Configure the Jenkins / runner node
git checkout sprint3-ansible
ansible-playbook ansible/setup.yml

# 2c. Build & push images
git checkout main
docker build -t <ecr-url>/shopnow-frontend:latest ./frontend
docker build -t <ecr-url>/shopnow-backend:latest  ./backend
docker push <ecr-url>/shopnow-frontend:latest
docker push <ecr-url>/shopnow-backend:latest

# 2d. Deploy to EKS
aws eks update-kubeconfig --name prateekshopnow-eks --region eu-west-2
git checkout sprint4-kubernetes
kubectl apply -f kubernetes/

# 2e. Verify
kubectl get pods -A
kubectl get svc -n app
```

---

## Sprint Walkthrough

### Sprint 1 — Application Containerization

Bootstrap Jenkins on EC2, attach an IAM role, and produce slim multi-stage Docker images.

**Frontend Dockerfile** (Nginx-optimized):

```dockerfile
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:stable-alpine
COPY --from=build /app/build /usr/share/nginx/html/aryan
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

> **Why multi-stage:** the build stage carries the full Node toolchain only long enough to produce static assets. The final image ships only Nginx + the compiled bundle.

---

### Sprint 2 — Infrastructure as Code (Terraform)

Code the AWS footprint declaratively with state held remotely in S3.

**`terraform/main.tf`**

```hcl
terraform {
  backend "s3" {
    bucket = "prateek-shopnow-tfstate"
    key    = "eks/terraform.tfstate"
    region = "eu-west-2"
  }
}

module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = "prateekshopnow-eks"
  subnets      = module.vpc.public_subnets
}
```

Apply:

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Branch: [`sprint2-terraform`](https://github.com/Prateekdevops-619/shopNow/tree/sprint2-terraform/terraform)

---

### Sprint 3 — Configuration Management (Ansible)

Idempotent setup of the Jenkins runner. The playbook is safe to re-run — no changes on a clean node.

**`ansible/setup.yml`**

```yaml
---
- name: Configure Jenkins Node
  hosts: localhost
  become: true
  tasks:
    - name: Kill stale apt processes
      shell: fuser -vki /var/lib/dpkg/lock-frontend || true

    - name: Install Tools
      apt:
        name: [docker.io, curl, unzip, jq]
        update_cache: yes
      register: res
      until: res is success
      retries: 5
```

> **Why the apt-lock dance:** Ubuntu's `unattended-upgrades` sometimes hold the dpkg lock at boot. The `fuser` kill plus retry block keeps the playbook resilient instead of failing the whole pipeline.

Branch: [`sprint3-ansible`](https://github.com/Prateekdevops-619/shopNow/tree/sprint3-ansible/ansible)

---

### Sprint 4 — Kubernetes Deployment

Manifests live on the [`sprint4-kubernetes`](https://github.com/Prateekdevops-619/shopNow/tree/sprint4-kubernetes/kubernetes) branch and are applied with a single `kubectl apply -f kubernetes/`.

**Critical Nginx fix** for the SPA sub-path (`/aryan/`):

```nginx
location /aryan/ {
  rewrite ^/aryan/(.*)$ /$1 break;
  try_files $uri $uri/ /index.html;
}
```

This strips the prefix before falling back to `index.html` for client-side routing — resolves the blank-screen issue on deep links.

---

### Sprint 5 — Monitoring & Alerting

Prometheus + Grafana run in-cluster (`monitoring` namespace) and surface failures back into the pipeline.

**Jenkins post-block — alert on failure:**

```groovy
post {
  failure {
    echo "ALERT: Deployment Failed! Checking Monitoring Metrics..."
    mail to:      'your-email@example.com',
         subject: "Pipeline Failure: ${env.JOB_NAME}",
         body:    "Build #${env.BUILD_NUMBER} failed. Check Grafana for resource health."
  }
}
```

---

## CI/CD Pipeline

The full Jenkinsfile is a declarative pipeline with 8 stages and a `post` block:

```
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌──────────┐
│ Checkout │─►│Provision │─►│Configure │─►│ Build  │─►│  Push  │─►│ Deploy │─►│ Verify │─►│ Monitor  │
└──────────┘  └──────────┘  └──────────┘  └────────┘  └────────┘  └────────┘  └────────┘  └──────────┘
                                                                                              │
                                                                  ┌───────────────────────────┘
                                                                  ▼
                                              ┌─────────────┬──────────────┬───────────────┐
                                              │  success    │  failure     │  always       │
                                              │ echo OK     │ email + log  │ cleanWs()     │
                                              └─────────────┴──────────────┴───────────────┘
```

**Distilled Jenkinsfile:**

```groovy
pipeline {
  agent any
  environment {
    AWS_REGION     = "eu-west-2"
    AWS_ACCOUNT_ID = "975050024946"
    ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    AWS_CRED_ID    = "aws-cred"
    CLUSTER_NAME   = "prateekshopnow-eks"
    GIT_URL        = "https://github.com/Prateekdevops-619/shopNow.git"
  }
  stages {
    stage('Infrastructure (Sprint 2)') {
      steps {
        git branch: 'sprint2-terraform', url: "${GIT_URL}"
        dir('terraform') { sh 'terraform init && terraform apply -auto-approve' }
      }
    }
    stage('Configuration (Sprint 3)') {
      steps {
        dir('ansible-config') {
          git branch: 'sprint3-ansible', url: "${GIT_URL}"
          ansiblePlaybook(playbook: 'ansible/setup.yml', inventory: 'localhost,')
        }
      }
    }
    stage('Application Build (Sprint 1)') {
      steps {
        cleanWs()
        git branch: 'main', url: "${GIT_URL}"
        script {
          docker.withRegistry("https://${ECR_URL}", "ecr:${AWS_REGION}:${AWS_CRED_ID}") {
            dir('backend')  { docker.build("${ECR_URL}/shopnow-backend:latest").push() }
            dir('frontend') { docker.build("${ECR_URL}/shopnow-frontend:latest").push() }
          }
        }
      }
    }
    stage('Deploy (Sprint 4)') {
      steps { sh 'kubectl apply -f kubernetes/' }
    }
    stage('Monitor (Sprint 5)') {
      steps { sh 'kubectl get pods -n monitoring' }
    }
  }
  post {
    success { echo "Pipeline succeeded." }
    failure { echo "Pipeline failed — check Grafana." }
    always  { cleanWs() }
  }
}
```

---

## Monitoring & Observability

Prometheus scrapes:

- Application pods (`/metrics` endpoint)
- Node Exporter (host metrics)
- kube-state-metrics (K8s object state)
- cAdvisor (container CPU/mem/I/O)

Grafana visualizes them; Alertmanager fans failures out to email, Jenkins, and (optionally) Slack.

| Setting | Default |
|---|---|
| Scrape interval | `15s` |
| Retention | `15d` |
| Alert routing | Alertmanager → Email + Jenkins post-block |

---

## Troubleshooting

| Problem | Root Cause | Fix |
|---|---|---|
| `apt` database lock | Background `unattended-upgrades` held `/var/lib/dpkg/lock-frontend` at boot | Ansible task `fuser`-kills the lock holder, then `apt` task uses `retries: 5` with `until: res is success` |
| 404 on static assets | SPA served under `/aryan/`, but build assets requested at `/` | Nginx `rewrite ^/aryan/(.*)$ /$1 break;` plus `try_files` fallback to `/index.html` |
| Docker permission denied | `jenkins` user not in `docker` group | Ansible adds `jenkins` to `docker` group; restart Jenkins agent |
| ECR login drift | Stale temporary credentials on long-running agent | `docker.withRegistry(...)` wrapper with `ecr:<region>:<credId>` refreshes tokens per build |
| Terraform state conflict | Two simultaneous applies racing on local state | Migrated to S3 backend; locking handled by S3 conditional writes |



---


---


---

## Author

**Prateek Tiwari** 

- GitHub: [@Prateekdevops-619](https://github.com/Prateekdevops-619)
- Project: [shopNow](https://github.com/Prateekdevops-619/shopNow)



---

<p align="center">
  <sub>Built with Terraform · Ansible · Jenkins · Docker · Kubernetes · Prometheus · Grafana</sub>
</p>
