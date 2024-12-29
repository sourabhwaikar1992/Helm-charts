#!/bin/bash

# Pre-requisites
# For detailed steps, refer to: https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html

# Variables
CLUSTER_NAME="${1:-my-cluster}"  # Default cluster name is 'my-cluster'
NODE_TYPE="${2:-t3.medium}"       # Default node type is 't3.medium'
AWS_ACCOUNT_ID="${3}"              # AWS Account ID must be provided as the third argument
NODES = "${4:-3}"                # Number of nodes required in the cluster
MIN_NODES = "${5:-}"             # Number of minimum nodes required in the cluster
REGION = "${6:-ap-south-1}"     # default region for the cluster( Default is set to 'ap-south-1')
# Check Helm installation
echo "Checking Helm installation..."
if ! command -v helm &> /dev/null
then
    echo "Helm is not installed. Please install Helm first."
    exit 1
fi
echo "Helm version: $(helm version --short)"

# Create EKS cluster
echo "Creating EKS cluster..."
eksctl create cluster --name "${CLUSTER_NAME}" --node-type "${NODE_TYPE}" --nodes "${NODES}" --nodes-min "${MIN_NODES}" --nodes-max 5 --region "${REGION}" --zones=

# Verify EKS cluster creation
echo "Verifying EKS cluster creation..."
eksctl get cluster --name "${CLUSTER_NAME}" --region "${REGION}"

# Create IAM OIDC provider
echo "Creating IAM OIDC provider..."
eksctl utils associate-iam-oidc-provider --region "${REGION}" --cluster "${CLUSTER_NAME}" --approve

# Download IAM policy for the AWS Load Balancer Controller
echo "Downloading IAM policy..."
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

# Create IAM policy
echo "Creating IAM policy AWSLoadBalancerControllerIAMPolicy..."
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json

# Create IAM role and ServiceAccount
echo "Creating IAM service account for AWS Load Balancer Controller..."
eksctl create iamserviceaccount --cluster "${CLUSTER_NAME}" --namespace kube-system --name aws-load-balancer-controller --attach-policy-arn arn:aws:iam::"${AWS_ACCOUNT_ID}":policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --approve

# Install the TargetGroupBinding CRDs
echo "Installing TargetGroupBinding CRDs..."
kubectl apply -k github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master
kubectl get crd

# Deploy the Helm chart
echo "Deploying AWS Load Balancer Controller..."
helm repo add eks https://aws.github.io/eks-charts
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName="${CLUSTER_NAME}" --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set image.tag="v2.2.0"

# Check deployment status
echo "Checking AWS Load Balancer Controller deployment status..."
kubectl -n kube-system rollout status deployment aws-load-balancer-controller

# Optional: Deploy Sample Application
if [ -f "./SampleApp.yaml" ]; then
    echo "Deploying sample application..."
    kubectl apply -f ./SampleApp.yaml
else
    echo "Sample application file not found. Skipping deployment."
fi

# Verify Ingress
INGRESS_NAME="${4:-my-ingress}"  # Default ingress name is 'my-ingress'
echo "Verifying Ingress..."
kubectl get ingress/"${INGRESS_NAME}" -n game-2048

# Get Ingress URL
echo "Getting Ingress URL..."
kubectl get ingress/"${INGRESS_NAME}" -n game-2048 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Get EKS Pod data
echo "Getting EKS Pod data..."
kubectl get pods --all-namespaces

# Delete EKS cluster
echo "Deleting EKS cluster..."
eksctl delete cluster --name "${CLUSTER_NAME}" --region us-east-1
