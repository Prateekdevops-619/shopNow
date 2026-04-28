variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-2"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "975050024946"
}

variable "project_name" {
  description = "Project name — used as a prefix for all resources"
  type        = string
  default     = "shopnow"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "AZs to span (must match public_subnet_cidrs count)"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

# ── EKS ──────────────────────────────────────────────────────────────────────

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  type    = number
  default = 1
}

variable "eks_node_max_size" {
  type    = number
  default = 3
}

# ── Jenkins EC2 ───────────────────────────────────────────────────────────────

variable "jenkins_instance_type" {
  description = "EC2 instance type for the Jenkins server"
  type        = string
  default     = "t3.medium"
}

variable "jenkins_key_pair_name" {
  description = "Name of an existing EC2 key pair to SSH into Jenkins"
  type        = string
  default     = "prateek_key_pair"
}

variable "jenkins_ami_id" {
  description = "Amazon Linux 2 AMI in eu-west-2 (update if outdated)"
  type        = string
  default     = "ami-0b45ae66668865cd6"   # Amazon Linux 2023, eu-west-2
}
