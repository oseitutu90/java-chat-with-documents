#!/bin/bash

# Deploy Java Chat with Documents to Minikube
set -e

echo "🚀 Starting deployment of Java Chat with Documents to Minikube..."

# Check if minikube is running
if ! minikube status > /dev/null 2>&1; then
    echo "❌ Minikube is not running. Please start minikube first:"
    echo "   minikube start"
    exit 1
fi

# Set docker environment to use minikube's docker daemon
echo "🔧 Setting up Docker environment for Minikube..."
eval $(minikube docker-env)

# Build the Docker image
echo "🏗️  Building Docker image..."
docker build -t doc-chat:latest .

# Enable ingress addon
echo "🌐 Enabling ingress addon..."
minikube addons enable ingress

# Create namespace
echo "📦 Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Deploy MongoDB
echo "🗄️  Deploying MongoDB..."
kubectl apply -f k8s/mongodb-pv.yaml
kubectl apply -f k8s/mongodb-deployment.yaml

# Deploy Ollama
echo "🤖 Deploying Ollama..."
kubectl apply -f k8s/ollama-deployment.yaml

# Create documents storage
echo "📄 Setting up document storage..."
kubectl apply -f k8s/documents-pv.yaml

# Create ConfigMap and Secret
echo "⚙️  Creating configuration..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# Deploy the application
echo "🚀 Deploying the application..."
kubectl apply -f k8s/app-deployment.yaml

# Create ingress
echo "🌐 Setting up ingress..."
kubectl apply -f k8s/ingress.yaml

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n doc-chat
kubectl wait --for=condition=available --timeout=600s deployment/ollama -n doc-chat
kubectl wait --for=condition=available --timeout=300s deployment/doc-chat-app -n doc-chat

# Get minikube IP and add to hosts file
MINIKUBE_IP=$(minikube ip)
echo "📝 Adding entry to /etc/hosts..."
echo "Please add the following line to your /etc/hosts file:"
echo "$MINIKUBE_IP doc-chat.local"

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Access Information:"
echo "   Application URL: http://doc-chat.local"
echo "   Minikube IP: $MINIKUBE_IP"
echo ""
echo "🔍 Useful commands:"
echo "   kubectl get pods -n doc-chat"
echo "   kubectl logs -f deployment/doc-chat-app -n doc-chat"
echo "   kubectl port-forward service/doc-chat-service 8080:8080 -n doc-chat"
echo ""
echo "📄 To add documents for RAG:"
echo "   kubectl cp /path/to/your/documents doc-chat/\$(kubectl get pods -n doc-chat -l app=doc-chat-app -o jsonpath='{.items[0].metadata.name}'):/app/documents"
