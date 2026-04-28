resource "aws_instance" "jenkins" {
  ami                    = var.jenkins_ami_id
  instance_type          = var.jenkins_instance_type   # t3.medium
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name               = var.jenkins_key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # Bootstrap: install Java + Jenkins on first boot
  user_data = <<-EOF
    #!/bin/bash
    set -e
    yum update -y

    # Java 21 (required by Jenkins 2.555+)
    yum install -y java-21-amazon-corretto-headless

    # Jenkins repo + install
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    yum install -y jenkins

    # Docker
    yum install -y docker
    systemctl enable --now docker
    usermod -aG docker jenkins
    usermod -aG docker ec2-user

    # Git
    yum install -y git

    # AWS CLI v2
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install

    # kubectl
    curl -sLO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
    chmod +x kubectl && mv kubectl /usr/local/bin/

    # Terraform
    curl -sLO "https://releases.hashicorp.com/terraform/1.6.4/terraform_1.6.4_linux_amd64.zip"
    unzip -q terraform_1.6.4_linux_amd64.zip
    mv terraform /usr/local/bin/

    # Ansible
    dnf install -y python3-pip
    pip3 install --quiet ansible

    # Start Jenkins
    systemctl enable --now jenkins

    echo "Bootstrap complete" > /var/log/shopnow-bootstrap.log
  EOF

  tags = {
    Name        = "${var.project_name}-jenkins"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Elastic IP so the Jenkins URL doesn't change on stop/start
resource "aws_eip" "jenkins" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-jenkins-eip"
  }
}
