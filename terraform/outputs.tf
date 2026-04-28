output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "ecr_backend_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "ecr_admin_url" {
  value = aws_ecr_repository.admin.repository_url
}

output "jenkins_public_ip" {
  description = "Jenkins server public IP (open :8080 in browser)"
  value       = aws_eip.jenkins.public_ip
}

output "jenkins_ssh" {
  description = "SSH command to access Jenkins"
  value       = "ssh -i ~/.ssh/${var.jenkins_key_pair_name}.pem ec2-user@${aws_eip.jenkins.public_ip}"
}

output "jenkins_url" {
  description = "Jenkins web UI"
  value       = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "terraform_state_bucket" {
  value = aws_s3_bucket.terraform_state.bucket
}
