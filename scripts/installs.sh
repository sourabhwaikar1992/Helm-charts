#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Install eksctl
echo "Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install AWS CLI 2
echo "Installing AWS CLI..."
curl -f "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws  # Clean up the downloaded zip file and the extracted directory
echo "AWS CLI is installed. Version: $(aws --version)"

# AWS configure
echo "Configuring AWS CLI..."
# Prompt for AWS configuration details
read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -sp "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo
read -p "Enter your default region (e.g., us-east-1): " AWS_DEFAULT_REGION
read -p "Enter your default output format (json, text, table): " AWS_OUTPUT_FORMAT

# Create AWS CLI configuration directory if it doesn't exist
mkdir -p ~/.aws

# Write the configuration to the credentials and config files
{
    echo "[default]"
    echo "aws_access_key_id = $AWS_ACCESS_KEY_ID"
    echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY"
} > ~/.aws/credentials

{
    echo "[default]"
    echo "region = $AWS_DEFAULT_REGION"
    echo "output = $AWS_OUTPUT_FORMAT"
} > ~/.aws/config

echo "AWS CLI configured successfully."

# Install kubectl
if command -v kubectl &> /dev/null; then
    echo "kubectl is already installed. Version: $(kubectl version)"
else
    echo "Installing kubectl..."
    curl -f -LO "https://s3.us-west-2.amazonaws.com/amazon-eks/1.31.2/2024-11-15/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    echo "kubectl installed successfully. Version: $(kubectl version)"
fi

# Install Git
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    # For Ubuntu
    if [ -f /etc/apt/sources.list ]; then
        sudo apt-get update && sudo apt-get install -y git
    # For Amazon Linux
    elif [ -f /etc/yum.repos.d/amzn2-core.repo ]; then
        sudo yum install -y git
    else
        echo "Unsupported OS. Please install Git manually."
        exit 1
    fi
else
    echo "Git is already installed. Version: $(git --version)"
fi

# Check Helm installation
echo "Checking Helm installation..."
if ! command -v helm &> /dev/null; then
    echo "Helm is not installed. Installing Helm..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm -rf get_helm.sh # Clean up the the directory
else
    echo "Helm version: $(helm version)"
fi
