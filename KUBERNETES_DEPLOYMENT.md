# Kubernetes Deployment Guide for Java Chat with Documents

This guide explains how to deploy the Java Chat with Documents application to a Minikube cluster.

## Prerequisites

1. **Minikube** installed and running
2. **kubectl** configured to work with Minikube
3. **Docker** installed
4. The application JAR file built (`target/doc-chat-1.0.jar`)

## Quick Start

### 1. Start Minikube
```bash
minikube start --memory=8192 --cpus=4
```

### 2. Deploy the Application
```bash
./deploy.sh
```

### 3. Add Host Entry
Add the following line to your `/etc/hosts` file:
```
<MINIKUBE_IP> doc-chat.local
```
Replace `<MINIKUBE_IP>` with the IP shown by the deployment script.

### 4. Access the Application
Open your browser and navigate to: `http://doc-chat.local`

## Manual Deployment Steps

If you prefer to deploy manually:

### 1. Build Docker Image
```bash
eval $(minikube docker-env)
docker build -t doc-chat:latest .
```

### 2. Enable Ingress
```bash
minikube addons enable ingress
```

### 3. Deploy Components
```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy MongoDB
kubectl apply -f k8s/mongodb-pv.yaml
kubectl apply -f k8s/mongodb-deployment.yaml

# Deploy Ollama
kubectl apply -f k8s/ollama-deployment.yaml

# Create document storage
kubectl apply -f k8s/documents-pv.yaml

# Create configuration
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# Deploy application
kubectl apply -f k8s/app-deployment.yaml

# Create ingress
kubectl apply -f k8s/ingress.yaml
```

## Architecture Overview

The deployment consists of:

- **doc-chat-app**: Main Spring Boot application with Vaadin UI
- **mongodb**: Document storage and vector embeddings
- **ollama**: Local LLM for AI processing
- **Persistent Volumes**: For MongoDB data, Ollama models, and documents

## Configuration

### Environment Variables
The application uses these environment variables (configured in Secret):
- `MONGODB_URI`: MongoDB connection string
- `AI_DOCS_LOCATION`: Path to documents for RAG
- `OPENAI_API_BASE_URL`: Ollama service URL
- `OPENAI_API_MODEL_NAME`: LLM model name
- `OPENAI_API_EMBEDDING_MODEL_NAME`: Embedding model name

### Adding Documents
To add documents for RAG functionality:
```bash
# Copy documents to the application pod
kubectl cp /path/to/your/documents doc-chat/$(kubectl get pods -n doc-chat -l app=doc-chat-app -o jsonpath='{.items[0].metadata.name}'):/app/documents
```

## Monitoring and Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n doc-chat
```

### View Application Logs
```bash
kubectl logs -f deployment/doc-chat-app -n doc-chat
```

### View MongoDB Logs
```bash
kubectl logs -f deployment/mongodb -n doc-chat
```

### View Ollama Logs
```bash
kubectl logs -f deployment/ollama -n doc-chat
```

### Port Forward (Alternative Access)
```bash
kubectl port-forward service/doc-chat-service 8080:8080 -n doc-chat
```
Then access at: `http://localhost:8080`

## Resource Requirements

### Minimum Requirements
- **Memory**: 8GB RAM for Minikube
- **CPU**: 4 cores
- **Storage**: 20GB available disk space

### Pod Resource Allocation
- **doc-chat-app**: 1-2GB RAM, 0.5-1 CPU
- **mongodb**: 0.5-1GB RAM, 0.25-0.5 CPU
- **ollama**: 2-4GB RAM, 1-2 CPU

## Scaling Considerations

### For Production
1. Use external MongoDB (MongoDB Atlas)
2. Use external LLM service (OpenAI API)
3. Implement horizontal pod autoscaling
4. Use proper ingress controller with SSL
5. Implement proper monitoring and logging

### Configuration for OpenAI API
To use OpenAI instead of Ollama, update the Secret:
```yaml
# In k8s/secret.yaml, replace with base64 encoded values:
OPENAI_API_KEY: <your-openai-api-key-base64>
OPENAI_API_BASE_URL: aHR0cHM6Ly9hcGkub3BlbmFpLmNvbS92MQ==  # https://api.openai.com/v1
OPENAI_API_MODEL_NAME: Z3B0LTMuNS10dXJibw==  # gpt-3.5-turbo
```

## Cleanup

To remove the deployment:
```bash
kubectl delete namespace doc-chat
```

## Troubleshooting Common Issues

### 1. Pods Stuck in Pending
- Check if Minikube has enough resources
- Verify PersistentVolumes are created

### 2. Application Not Starting
- Check if MongoDB and Ollama are ready
- Verify environment variables in Secret
- Check application logs

### 3. Ollama Models Not Loading
- Increase memory allocation for Ollama pod
- Check Ollama logs for model download progress

### 4. Cannot Access via Ingress
- Verify ingress addon is enabled
- Check /etc/hosts entry
- Try port-forward as alternative
