#!/bin/bash

# Setup Storage for Java Chat with Documents on macOS + Minikube
set -e

echo "🗄️  Setting up storage for Java Chat with Documents on macOS + Minikube"

# Configuration
STORAGE_DIR="$HOME/minikube-storage"
MONGODB_DIR="$STORAGE_DIR/mongodb"
DOCUMENTS_DIR="$STORAGE_DIR/documents"
OLLAMA_DIR="$STORAGE_DIR/ollama"

# Create storage directories on host
echo "📁 Creating storage directories on macOS host..."
mkdir -p "$MONGODB_DIR"
mkdir -p "$DOCUMENTS_DIR"
mkdir -p "$OLLAMA_DIR"

echo "Created storage directories:"
echo "  MongoDB: $MONGODB_DIR"
echo "  Documents: $DOCUMENTS_DIR"
echo "  Ollama: $OLLAMA_DIR"

# Start Minikube with mount
echo "🚀 Starting Minikube with storage mount..."
minikube start --memory=8192 --cpus=4 --driver=docker \
  --mount=true \
  --mount-string="$STORAGE_DIR:/mnt/storage"

# Wait for Minikube to be ready
echo "⏳ Waiting for Minikube to be ready..."
minikube status

# Create directories inside Minikube
echo "📁 Creating directories inside Minikube..."
minikube ssh "sudo mkdir -p /mnt/storage/mongodb /mnt/storage/documents /mnt/storage/ollama"
minikube ssh "sudo chmod 777 /mnt/storage/mongodb /mnt/storage/documents /mnt/storage/ollama"

# Check available storage classes
echo "🔍 Checking available storage classes..."
kubectl get storageclass

# Enable default storage class if needed
minikube addons enable default-storageclass
minikube addons enable storage-provisioner

echo "✅ Storage setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Deploy using: kubectl apply -f k8s/storage-dynamic.yaml"
echo "2. Or use static provisioning: kubectl apply -f k8s/mongodb-pv-fixed.yaml"
echo ""
echo "🔍 To verify storage:"
echo "  kubectl get pv,pvc -n doc-chat"
echo ""
echo "📂 Your data will be stored in:"
echo "  $STORAGE_DIR"