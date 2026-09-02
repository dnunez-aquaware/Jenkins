#!/bin/bash

set -e

# Update system
dnf update -y

# Install required tools
dnf install -y java-21-amazon-corretto awscli git wget unzip

# Install Terraform
TERRAFORM_VERSION="1.13.3"

wget \
  "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
  -O /tmp/terraform.zip

unzip /tmp/terraform.zip -d /usr/local/bin

rm -f /tmp/terraform.zip

# Add Jenkins repository
wget \
  -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2026.key

# Install Jenkins
dnf install -y jenkins

# Download Jenkins Configuration as Code
mkdir -p /var/lib/jenkins

wget \
  "https://raw.githubusercontent.com/TU_USUARIO/TU_REPOSITORIO/main/jenkins/jenkins.yaml" \
  -O /var/lib/jenkins/jenkins.yaml

chown jenkins:jenkins /var/lib/jenkins/jenkins.yaml

# Configure Jenkins Configuration as Code
mkdir -p /etc/systemd/system/jenkins.service.d

cat > /etc/systemd/system/jenkins.service.d/casc.conf <<'EOF'
[Service]
Environment="CASC_JENKINS_CONFIG=/var/lib/jenkins/jenkins.yaml"
EOF

# Enable and start Jenkins
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins