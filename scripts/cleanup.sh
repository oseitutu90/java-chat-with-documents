#!/bin/bash

# 🧹 Cleanup Java Chat with Documents deployment

set -e

NAMESPACE="doc-chat"
STORAGE_DIR="$HOME/minikube-storage"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Function to show cleanup options
show_options() {
    echo "🧹 Java Chat with Documents Cleanup Options:"
    echo ""
    echo "1. Clean application only (keep data)"
    echo "2. Clean everything (including data)"
    echo "3. Clean Minikube completely"
    echo "4. Cancel"
    echo ""
    read -p "Choose an option (1-4): " choice
    
    case $choice in
        1) cleanup_application;;
        2) cleanup_everything;;
        3) cleanup_minikube;;
        4) echo "Cleanup cancelled"; exit 0;;
        *) echo_error "Invalid option"; exit 1;;
    esac
}

# Function to cleanup application only
cleanup_application() {
    echo_info "Cleaning up application (keeping data)..."
    
    # Delete application resources
    kubectl delete deployment doc-chat-app -n $NAMESPACE --ignore-not-found=true
    kubectl delete service doc-chat-service -n $NAMESPACE --ignore-not-found=true
    kubectl delete ingress doc-chat-ingress -n $NAMESPACE --ignore-not-found=true
    kubectl delete configmap doc-chat-config -n $NAMESPACE --ignore-not-found=true
    kubectl delete secret doc-chat-secret -n $NAMESPACE --ignore-not-found=true
    
    # Delete dependencies
    kubectl delete deployment mongodb -n $NAMESPACE --ignore-not-found=true
    kubectl delete service mongodb-service -n $NAMESPACE --ignore-not-found=true
    kubectl delete deployment ollama -n $NAMESPACE --ignore-not-found=true
    kubectl delete service ollama-service -n $NAMESPACE --ignore-not-found=true
    
    echo_success "Application cleaned up (data preserved)"
    echo_info "Data is still available at: $STORAGE_DIR"
}

# Function to cleanup everything
cleanup_everything() {
    echo_warning "This will delete ALL application data!"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        echo "Cleanup cancelled"
        exit 0
    fi
    
    echo_info "Cleaning up everything..."
    
    # Delete namespace (this removes everything inside)
    kubectl delete namespace $NAMESPACE --ignore-not-found=true
    
    # Delete persistent volumes
    kubectl delete pv mongodb-pv-host --ignore-not-found=true
    kubectl delete pv documents-pv-host --ignore-not-found=true
    kubectl delete pv ollama-pv-host --ignore-not-found=true
    
    # Remove storage directory
    if [[ -d "$STORAGE_DIR" ]]; then
        echo_warning "Removing storage directory: $STORAGE_DIR"
        rm -rf "$STORAGE_DIR"
    fi
    
    # Remove hosts entry
    if grep -q "doc-chat.local" /etc/hosts; then
        echo_info "To remove hosts entry, run:"
        echo "sudo sed -i '' '/doc-chat.local/d' /etc/hosts"
    fi
    
    echo_success "Everything cleaned up"
}

# Function to cleanup Minikube completely
cleanup_minikube() {
    echo_warning "This will delete the entire Minikube cluster!"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        echo "Cleanup cancelled"
        exit 0
    fi
    
    echo_info "Stopping and deleting Minikube..."
    
    # Stop and delete minikube
    minikube stop || true
    minikube delete || true
    
    # Remove storage directory
    if [[ -d "$STORAGE_DIR" ]]; then
        echo_warning "Removing storage directory: $STORAGE_DIR"
        rm -rf "$STORAGE_DIR"
    fi
    
    # Remove hosts entry
    if grep -q "doc-chat.local" /etc/hosts; then
        echo_info "To remove hosts entry, run:"
        echo "sudo sed -i '' '/doc-chat.local/d' /etc/hosts"
    fi
    
    echo_success "Minikube completely cleaned up"
}

# Function to show what will be cleaned
show_current_state() {
    echo_info "Current deployment state:"
    
    # Check if Minikube is running
    if minikube status &> /dev/null; then
        echo "✓ Minikube is running"
        
        # Check namespace
        if kubectl get namespace $NAMESPACE &> /dev/null; then
            echo "✓ Namespace '$NAMESPACE' exists"
            
            # List resources
            echo ""
            echo "Resources in namespace:"
            kubectl get all -n $NAMESPACE 2>/dev/null || echo "  No resources found"
            
            echo ""
            echo "Persistent Volumes:"
            kubectl get pv | grep -E "(mongodb|documents|ollama)" || echo "  No PVs found"
        else
            echo "✗ Namespace '$NAMESPACE' does not exist"
        fi
    else
        echo "✗ Minikube is not running"
    fi
    
    # Check storage directory
    if [[ -d "$STORAGE_DIR" ]]; then
        echo "✓ Storage directory exists at: $STORAGE_DIR"
        echo "  Size: $(du -sh "$STORAGE_DIR" 2>/dev/null | cut -f1)"
    else
        echo "✗ Storage directory does not exist"
    fi
    
    echo ""
}

# Main function
main() {
    echo_info "Java Chat with Documents Cleanup Tool"
    echo ""
    
    show_current_state
    show_options
}

main "$@"