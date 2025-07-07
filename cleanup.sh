#!/bin/bash

# Cleanup Java Chat with Documents deployment from Minikube
set -e

echo "🧹 Starting cleanup of Java Chat with Documents from Minikube..."

# Delete the namespace (this will delete all resources in the namespace)
echo "🗑️  Deleting namespace and all resources..."
kubectl delete namespace doc-chat --ignore-not-found=true

# Wait for namespace deletion
echo "⏳ Waiting for namespace deletion to complete..."
kubectl wait --for=delete namespace/doc-chat --timeout=120s || true

# Clean up Docker images (optional)
read -p "Do you want to remove the Docker image as well? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🐳 Removing Docker image..."
    eval $(minikube docker-env)
    docker rmi doc-chat:latest || true
fi

# Clean up host entry reminder
echo ""
echo "📝 Don't forget to remove the following line from your /etc/hosts file:"
echo "$(minikube ip) doc-chat.local"

echo ""
echo "✅ Cleanup completed successfully!"
echo ""
echo "💡 To completely reset Minikube:"
echo "   minikube delete"
echo "   minikube start"
