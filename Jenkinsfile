pipeline {
    agent any

    environment {
        AWS_REGION     = "eu-west-2"
        AWS_ACCOUNT_ID = "975050024946"
        AWS_CREDS      = credentials('aws-cred')

        ECR_BASE       = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        BACKEND_REPO   = "shopnow-backend"
        FRONTEND_REPO  = "shopnow-frontend"
        ADMIN_REPO     = "shopnow-admin"

        EKS_CLUSTER    = "shopnow-eks"
        K8S_NAMESPACE  = "shopnow"
        KUBECONFIG     = "/var/lib/jenkins/.kube/config"

        IMAGE_TAG      = "${env.BUILD_NUMBER}"
    }

    options {
        timeout(time: 60, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        // ── Sprint 1 — Checkout & ECR Login ────────────────────────────────
        stage('Checkout') {
            steps {
                checkout scm
                echo "Branch: ${env.GIT_BRANCH} | Commit: ${env.GIT_COMMIT?.take(7)}"
            }
        }

        stage('Configure AWS & ECR Login') {
            steps {
                sh """
                aws configure set aws_access_key_id     \$AWS_CREDS_USR
                aws configure set aws_secret_access_key \$AWS_CREDS_PSW
                aws configure set default.region        \$AWS_REGION

                aws ecr get-login-password --region \$AWS_REGION \
                  | docker login --username AWS --password-stdin \$ECR_BASE
                """
            }
        }

        // ── Sprint 1 — Build & Push images (sequential to conserve memory) ───
        stage('Build & Push Backend') {
            steps {
                sh """
                docker build -t \$BACKEND_REPO:latest ./backend
                docker tag  \$BACKEND_REPO:latest \$ECR_BASE/\$BACKEND_REPO:\$IMAGE_TAG
                docker tag  \$BACKEND_REPO:latest \$ECR_BASE/\$BACKEND_REPO:latest
                docker push \$ECR_BASE/\$BACKEND_REPO:\$IMAGE_TAG
                docker push \$ECR_BASE/\$BACKEND_REPO:latest
                docker rmi  \$BACKEND_REPO:latest || true
                """
            }
        }

        stage('Build & Push Frontend') {
            steps {
                sh """
                docker build -t \$FRONTEND_REPO:latest ./frontend
                docker tag  \$FRONTEND_REPO:latest \$ECR_BASE/\$FRONTEND_REPO:\$IMAGE_TAG
                docker tag  \$FRONTEND_REPO:latest \$ECR_BASE/\$FRONTEND_REPO:latest
                docker push \$ECR_BASE/\$FRONTEND_REPO:\$IMAGE_TAG
                docker push \$ECR_BASE/\$FRONTEND_REPO:latest
                docker rmi  \$FRONTEND_REPO:latest || true
                """
            }
        }

        stage('Build & Push Admin') {
            steps {
                sh """
                docker build -t \$ADMIN_REPO:latest ./admin
                docker tag  \$ADMIN_REPO:latest \$ECR_BASE/\$ADMIN_REPO:\$IMAGE_TAG
                docker tag  \$ADMIN_REPO:latest \$ECR_BASE/\$ADMIN_REPO:latest
                docker push \$ECR_BASE/\$ADMIN_REPO:\$IMAGE_TAG
                docker push \$ECR_BASE/\$ADMIN_REPO:latest
                docker rmi  \$ADMIN_REPO:latest || true
                docker system prune -f || true
                """
            }
        }

        // ── Sprint 2 — Terraform (infra already provisioned — verify only) ───
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init -input=false -reconfigure'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan -input=false -detailed-exitcode || true'
                }
            }
        }

        // ── Sprint 3 — Ansible: configure EKS access ────────────────────────
        stage('Ansible: Configure EKS Access') {
            steps {
                sh """
                ansible-playbook \
                  -i ansible/inventory.ini \
                  ansible/playbooks/02-configure-eks-access.yml
                """
            }
        }

        // ── Sprint 4 — Deploy shopNow to EKS ───────────────────────────────
        stage('Update kubeconfig') {
            steps {
                sh """
                mkdir -p /var/lib/jenkins/.kube
                aws eks update-kubeconfig \
                  --region \$AWS_REGION \
                  --name   \$EKS_CLUSTER \
                  --kubeconfig \$KUBECONFIG
                """
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh """
                # Namespace + secrets
                kubectl apply -f k8s/namespace.yaml           --kubeconfig \$KUBECONFIG
                kubectl apply -f k8s/mongodb-secret.yaml      --kubeconfig \$KUBECONFIG

                # MongoDB StatefulSet — wait before starting the app
                kubectl apply -f k8s/mongodb-statefulset.yaml --kubeconfig \$KUBECONFIG
                kubectl rollout status statefulset/mongodb -n \$K8S_NAMESPACE \
                  --timeout=300s --kubeconfig \$KUBECONFIG

                # Update images to the current build tag
                kubectl set image deployment/backend  backend=\$ECR_BASE/\$BACKEND_REPO:\$IMAGE_TAG  -n \$K8S_NAMESPACE --kubeconfig \$KUBECONFIG 2>/dev/null || true
                kubectl set image deployment/frontend frontend=\$ECR_BASE/\$FRONTEND_REPO:\$IMAGE_TAG -n \$K8S_NAMESPACE --kubeconfig \$KUBECONFIG 2>/dev/null || true
                kubectl set image deployment/admin    admin=\$ECR_BASE/\$ADMIN_REPO:\$IMAGE_TAG       -n \$K8S_NAMESPACE --kubeconfig \$KUBECONFIG 2>/dev/null || true

                # Apply all app manifests
                kubectl apply -f k8s/backend-deployment.yaml  --kubeconfig \$KUBECONFIG
                kubectl apply -f k8s/frontend-deployment.yaml --kubeconfig \$KUBECONFIG
                kubectl apply -f k8s/admin-deployment.yaml    --kubeconfig \$KUBECONFIG
                kubectl apply -f k8s/hpa.yaml                 --kubeconfig \$KUBECONFIG
                kubectl apply -f k8s/ingress.yaml             --kubeconfig \$KUBECONFIG
                """
            }
        }

        stage('Wait for Rollout') {
            steps {
                sh """
                kubectl rollout status deployment/backend  -n \$K8S_NAMESPACE --timeout=180s --kubeconfig \$KUBECONFIG
                kubectl rollout status deployment/frontend -n \$K8S_NAMESPACE --timeout=120s --kubeconfig \$KUBECONFIG
                kubectl rollout status deployment/admin    -n \$K8S_NAMESPACE --timeout=120s --kubeconfig \$KUBECONFIG
                """
            }
        }

        // ── Sprint 4 — Smoke test via ALB ───────────────────────────────────
        stage('Smoke Test') {
            steps {
                sh """
                ALB_HOST=\$(kubectl get ingress shopnow-ingress -n \$K8S_NAMESPACE \
                  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' \
                  --kubeconfig \$KUBECONFIG)

                echo "ALB: \$ALB_HOST"
                sleep 30

                HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" http://\$ALB_HOST/api/health)
                if [ "\$HTTP_CODE" != "200" ]; then
                  echo "Smoke test FAILED (HTTP \$HTTP_CODE)"
                  exit 1
                fi
                echo "Smoke test PASSED — HTTP \$HTTP_CODE"
                """
            }
        }

        // ── Sprint 5 — Deploy Prometheus + Grafana ──────────────────────────
        stage('Deploy Monitoring') {
            steps {
                sh """
                kubectl apply -f k8s/monitoring/prometheus-config.yaml     --kubeconfig \$KUBECONFIG
                kubectl apply -f k8s/monitoring/prometheus-deployment.yaml --kubeconfig \$KUBECONFIG
                kubectl apply -f k8s/monitoring/grafana-deployment.yaml    --kubeconfig \$KUBECONFIG

                kubectl rollout status deployment/prometheus -n \$K8S_NAMESPACE --timeout=120s --kubeconfig \$KUBECONFIG
                kubectl rollout status deployment/grafana    -n \$K8S_NAMESPACE --timeout=120s --kubeconfig \$KUBECONFIG
                """
            }
        }

        stage('Ansible: Configure Monitoring') {
            steps {
                sh """
                ansible-playbook \
                  -i ansible/inventory.ini \
                  ansible/playbooks/03-deploy-monitoring.yml
                """
            }
        }

        // ── Sprint 6 — Summary ───────────────────────────────────────────────
        stage('Deployment Summary') {
            steps {
                sh """
                echo "============ ShopNow EKS Deployment #\$BUILD_NUMBER ============"
                kubectl get pods     -n \$K8S_NAMESPACE --kubeconfig \$KUBECONFIG
                kubectl get services -n \$K8S_NAMESPACE --kubeconfig \$KUBECONFIG
                kubectl get ingress  -n \$K8S_NAMESPACE --kubeconfig \$KUBECONFIG
                kubectl get hpa      -n \$K8S_NAMESPACE --kubeconfig \$KUBECONFIG
                echo "============================================================"
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline #${env.BUILD_NUMBER} succeeded — shopNow is live on EKS."
        }

        failure {
            echo "Pipeline #${env.BUILD_NUMBER} failed — rolling back deployments."
            sh """
            kubectl rollout undo deployment/backend  -n \$K8S_NAMESPACE --kubeconfig \$KUBECONFIG || true
            kubectl rollout undo deployment/frontend -n \$K8S_NAMESPACE --kubeconfig \$KUBECONFIG || true
            kubectl rollout undo deployment/admin    -n \$K8S_NAMESPACE --kubeconfig \$KUBECONFIG || true
            """
        }

        always {
            sh """
            docker rmi \$ECR_BASE/\$BACKEND_REPO:\$IMAGE_TAG  || true
            docker rmi \$ECR_BASE/\$FRONTEND_REPO:\$IMAGE_TAG || true
            docker rmi \$ECR_BASE/\$ADMIN_REPO:\$IMAGE_TAG    || true
            docker rmi \$BACKEND_REPO:latest                  || true
            docker rmi \$FRONTEND_REPO:latest                 || true
            docker rmi \$ADMIN_REPO:latest                    || true
            """
        }
    }
}
