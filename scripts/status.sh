#!/bin/bash

# 🔍 Check status of Java Chat with Documents deployment

set -e

NAMESPACE="doc-chat"
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

# Check Minikube status
check_minikube() {
    echo_info "Checking Minikube status..."
    
    if minikube status &> /dev/null; then
        echo_success "Minikube is running"
        echo "   IP: $(minikube ip)"
        echo "   Profile: $(minikube profile)"
    else
        echo_error "Minikube is not running"
        return 1
    fi
}

# Check namespace
check_namespace() {
    echo_info "Checking namespace..."
    
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        echo_success "Namespace '$NAMESPACE' exists"
    else
        echo_error "Namespace '$NAMESPACE' does not exist"
        return 1
    fi
}

# Check storage
check_storage() {
    echo_info "Checking storage components..."
    
    echo "Persistent Volumes:"
    kubectl get pv | grep -E "(mongodb|documents|ollama)" || echo "  No PVs found"
    
    echo ""
    echo "Persistent Volume Claims:"
    kubectl get pvc -n $NAMESPACE || echo "  No PVCs found"
}

# Check deployments
check_deployments() {
    echo_info "Checking deployments..."
    
    kubectl get deployments -n $NAMESPACE -o wide
    
    echo ""
    echo "Deployment Status:"
    
    # Check MongoDB
    if kubectl get deployment mongodb -n $NAMESPACE &> /dev/null; then
        MONGODB_READY=$(kubectl get deployment mongodb -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
        if [[ "$MONGODB_READY" == "1" ]]; then
            echo_success "MongoDB is ready"
        else
            echo_warning "MongoDB is not ready"
        fi
    else
        echo_error "MongoDB deployment not found"
    fi
    
    # Check Ollama
    if kubectl get deployment ollama -n $NAMESPACE &> /dev/null; then
        OLLAMA_READY=$(kubectl get deployment ollama -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
        if [[ "$OLLAMA_READY" == "1" ]]; then
            echo_success "Ollama is ready"
        else
            echo_warning "Ollama is not ready (may still be downloading models)"
        fi
    else
        echo_error "Ollama deployment not found"
    fi
    
    # Check Application
    if kubectl get deployment doc-chat-app -n $NAMESPACE &> /dev/null; then
        APP_READY=$(kubectl get deployment doc-chat-app -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
        if [[ "$APP_READY" == "1" ]]; then
            echo_success "Application is ready"
        else
            echo_warning "Application is not ready"
        fi
    else
        echo_error "Application deployment not found"
    fi
}

# Check services
check_services() {
    echo_info "Checking services..."
    
    kubectl get services -n $NAMESPACE
}

# Check ingress
check_ingress() {
    echo_info "Checking ingress..."
    
    if kubectl get ingress -n $NAMESPACE &> /dev/null; then
        kubectl get ingress -n $NAMESPACE
        
        # Check if hosts entry exists
        if grep -q "doc-chat.local" /etc/hosts; then
            echo_success "Host entry exists in /etc/hosts"
        else
            echo_warning "Host entry missing from /etc/hosts"
            echo "   Add with: echo '$(minikube ip) doc-chat.local' | sudo tee -a /etc/hosts"
        fi
    else
        echo_error "Ingress not found"
    fi
}

# Check pods
check_pods() {
    echo_info "Checking pods..."
    
    kubectl get pods -n $NAMESPACE -o wide
    
    echo ""
    echo "Pod Logs (last 5 lines):"
    
    # Get pod names
    PODS=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
    
    for pod in $PODS; do
        echo ""
        echo "--- $pod ---"
        kubectl logs $pod -n $NAMESPACE --tail=5 || echo "Could not get logs"
    done
}

# Check application health
check_health() {
    echo_info "Checking application health..."
    
    # Try to access health endpoint
    if kubectl get service doc-chat-service -n $NAMESPACE &> /dev/null; then
        echo "Attempting to check health endpoint..."
        kubectl port-forward service/doc-chat-service 8080:8080 -n $NAMESPACE &
        PF_PID=$!
        sleep 3
        
        if curl -s http://localhost:8080/actuator/health &> /dev/null; then
            echo_success "Health endpoint is accessible"
        else
            echo_warning "Health endpoint not accessible"
        fi
        
        kill $PF_PID 2>/dev/null || true
    else
        echo_error "Application service not found"
    fi
}

# Main function
main() {
    echo_info "Checking Java Chat with Documents deployment status..."
    echo ""
    
    check_minikube || exit 1
    echo ""
    
    check_namespace || exit 1
    echo ""
    
    check_storage
    echo ""
    
    check_deployments
    echo ""
    
    check_services
    echo ""
    
    check_ingress
    echo ""
    
    check_pods
    echo ""
    
    check_health
    echo ""
    
    echo_success "Status check complete!"
    echo ""
    echo "🔗 Access URLs:"
    echo "   Application: http://doc-chat.local"
    echo "   Port Forward: kubectl port-forward service/doc-chat-service 8080:8080 -n $NAMESPACE"
}

main "$@"