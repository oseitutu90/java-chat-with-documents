#!/bin/bash

# 🚀 Deploy Java Chat with Documents to Minikube (Self-Contained)
# This script sets up the complete application with local Ollama models and host-mounted storage

set -e

# Configuration
NAMESPACE="doc-chat"
STORAGE_DIR="$HOME/minikube-storage"
APP_NAME="Java Chat with Documents"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    echo_info "Checking prerequisites..."
    
    # Check if minikube is installed
    if ! command -v minikube &> /dev/null; then
        echo_error "Minikube is not installed. Please install it first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        echo_error "Docker is not running. Please start Docker Desktop first."
        exit 1
    fi
    
    # Check if Maven wrapper exists
    if [[ ! -f "./mvnw" ]]; then
        echo_error "Maven wrapper not found. Please run this script from the project root."
        exit 1
    fi
    
    echo_success "All prerequisites satisfied"
}

# Function to setup Minikube
setup_minikube() {
    echo_info "Setting up Minikube..."
    
    # Create storage directory on host
    mkdir -p "$STORAGE_DIR"/{documents,ollama,qdrant,prometheus,grafana}
    echo_success "Created storage directories at $STORAGE_DIR"
    
    # Check if Minikube is running
    if ! minikube status &> /dev/null; then
        echo_info "Starting Minikube with host mount..."
        minikube start --memory=7000 --cpus=4 --driver=docker \
            --mount=true \
            --mount-string="$STORAGE_DIR:/mnt/storage"
    else
        echo_warning "Minikube is already running"
        # Add mount if not already mounted
        minikube mount "$STORAGE_DIR:/mnt/storage" &
    fi
    
    # Enable required addons
    echo_info "Enabling required addons..."
    minikube addons enable ingress
    minikube addons enable default-storageclass
    minikube addons enable storage-provisioner
    
    echo_success "Minikube setup complete"
}

# Function to build application
build_application() {
    echo_info "Building application..."
    
    # Build the JAR file (skip tests for now)
    ./mvnw clean package -DskipTests
    
    if [[ ! -f "target/doc-chat-1.0.jar" ]]; then
        echo_error "JAR file not found after build"
        exit 1
    fi
    
    echo_success "Application built successfully"
}

# Function to build Docker image
build_docker_image() {
    echo_info "Building Docker image..."
    
    # Set docker environment to use minikube's docker daemon
    eval $(minikube docker-env)
    
    # Build the Docker image
    docker build -t doc-chat:latest .
    
    echo_success "Docker image built successfully"
}

# Function to deploy storage
deploy_storage() {
    echo_info "Deploying storage components..."
    
    # Create namespace
    kubectl apply -f k8s/namespace.yaml
    
    # Deploy host-mounted storage
    kubectl apply -f k8s/storage-with-host-mount.yaml
    
    # Wait for PVs to be available
    echo_info "Waiting for persistent volumes to be ready..."
    kubectl wait --for=condition=Available --timeout=60s pv/documents-pv-host pv/ollama-pv-host pv/qdrant-pv-host pv/prometheus-pv-host pv/grafana-pv-host || true
    
    echo_success "Storage components deployed"
}

# Function to deploy dependencies
deploy_dependencies() {
    echo_info "Deploying dependencies..."
    
    # Deploy Qdrant
    kubectl apply -f k8s/qdrant-deployment.yaml
    
    # Deploy Ollama
    kubectl apply -f k8s/ollama-deployment.yaml
    
    # Deploy configuration
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/secret-qdrant.yaml
    
    # Deploy monitoring stack
    kubectl apply -f k8s/prometheus-deployment.yaml
    kubectl apply -f k8s/grafana-deployment.yaml
    
    echo_success "Dependencies and monitoring deployed"
}

# Function to wait for dependencies
wait_for_dependencies() {
    echo_info "Waiting for dependencies to be ready..."
    
    # Wait for Qdrant
    echo_info "Waiting for Qdrant..."
    kubectl wait --for=condition=available --timeout=300s deployment/qdrant -n $NAMESPACE
    
    # Wait for Ollama (this takes longer due to model downloads)
    echo_info "Waiting for Ollama (this may take several minutes for model downloads)..."
    kubectl wait --for=condition=available --timeout=1200s deployment/ollama -n $NAMESPACE
    
    # Wait for monitoring stack
    echo_info "Waiting for monitoring stack..."
    kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n $NAMESPACE
    kubectl wait --for=condition=available --timeout=300s deployment/grafana -n $NAMESPACE
    
    echo_success "Dependencies and monitoring are ready"
}

# Function to deploy application
deploy_application() {
    echo_info "Deploying application..."
    
    # Deploy the application
    kubectl apply -f k8s/app-deployment.yaml
    
    # Deploy ingress
    kubectl apply -f k8s/ingress.yaml
    
    # Wait for application to be ready
    echo_info "Waiting for application to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/doc-chat-app -n $NAMESPACE
    
    echo_success "Application deployed successfully"
}

# Function to setup access
setup_access() {
    echo_info "Setting up access..."
    
    # Get minikube IP
    MINIKUBE_IP=$(minikube ip)
    
    # Check if hosts entry exists
    if grep -q "doc-chat.local" /etc/hosts; then
        echo_warning "Host entry already exists in /etc/hosts"
    else
        echo_info "Adding host entry to /etc/hosts..."
        echo "To add the host entry, run:"
        echo "echo '$MINIKUBE_IP doc-chat.local' | sudo tee -a /etc/hosts"
    fi
    
    echo_success "Access setup complete"
}

# Function to show deployment info
show_deployment_info() {
    echo ""
    echo_success "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Application Information:"
    echo "   Name: $APP_NAME"
    echo "   Namespace: $NAMESPACE"
    echo "   URL: http://doc-chat.local"
    echo "   Minikube IP: $(minikube ip)"
    echo ""
    echo "📁 Storage Locations:"
    echo "   Host Storage: $STORAGE_DIR"
    echo "   Qdrant Vector DB: $STORAGE_DIR/qdrant"
    echo "   Documents: $STORAGE_DIR/documents"
    echo "   Ollama Models: $STORAGE_DIR/ollama"
    echo "   Prometheus Data: $STORAGE_DIR/prometheus"
    echo "   Grafana Data: $STORAGE_DIR/grafana"
    echo ""
    echo "🔧 Useful Commands:"
    echo "   Check status: kubectl get pods -n $NAMESPACE"
    echo "   View logs: kubectl logs -f deployment/doc-chat-app -n $NAMESPACE"
    echo "   Port forward: kubectl port-forward service/doc-chat-service 8080:8080 -n $NAMESPACE"
    echo "   Add documents: cp /path/to/docs/* $STORAGE_DIR/documents/"
    echo ""
    echo "📊 Monitoring Access:"
    echo "   Prometheus: kubectl port-forward service/prometheus-service 9090:9090 -n $NAMESPACE"
    echo "   Grafana: kubectl port-forward service/grafana-service 3000:3000 -n $NAMESPACE"
    echo "   Grafana Login: admin/admin123"
    echo ""
    echo "🧹 Cleanup:"
    echo "   Run: ./scripts/cleanup.sh"
    echo ""
}

# Main execution
main() {
    echo_info "Starting deployment of $APP_NAME to Minikube..."
    echo ""
    
    check_prerequisites
    setup_minikube
    build_application
    build_docker_image
    deploy_storage
    deploy_dependencies
    wait_for_dependencies
    deploy_application
    setup_access
    show_deployment_info
}

# Run main function
main "$@"