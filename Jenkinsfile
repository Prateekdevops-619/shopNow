pipeline {
    agent any

    environment {
        AWS_REGION = "eu-west-2"   
        AWS_ACCOUNT_ID = "975050024946"   /
        AWS_CREDS = credentials('aws-cred')    
        BACKEND_REPO = "shopnow-backend"
        FRONTEND_REPO = "shopnow-frontend"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Login to AWS ECR') {
            steps {
                script {
                    sh """
                    aws configure set aws_access_key_id $AWS_CREDS_USR
                    aws configure set aws_secret_access_key $AWS_CREDS_PSW
                    aws configure set default.region $AWS_REGION

                    aws ecr get-login-password --region $AWS_REGION \
                      | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                    """
                }
            }
        }

        stage('Build Images with Docker Compose') {
            steps {
                sh 'docker-compose build'
            }
        }

        stage('Tag & Push Backend') {
            steps {
                script {
                    sh """
                    docker tag shopnow-backend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BACKEND_REPO:latest
                    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$BACKEND_REPO:latest
                    """
                }
            }
        }

        stage('Tag & Push Frontend') {
            steps {
                script {
                    sh """
                    docker tag shopnow-frontend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FRONTEND_REPO:latest
                    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FRONTEND_REPO:latest
                    """
                }
            }
        }
    }

    post {
        success {
            echo 'Sprint 1 pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed — check logs.'
        }
    }
}