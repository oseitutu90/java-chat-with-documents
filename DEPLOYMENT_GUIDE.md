# 🚀 Deployment Guide - Java Chat with Documents

## Overview

This guide provides a streamlined approach to deploying the Java Chat with Documents application in a Minikube cluster with local Ollama models and host-mounted storage.

## Quick Start

### 1. One-Command Deployment
```bash
./scripts/deploy-local.sh
```

This single script handles everything:
- ✅ Prerequisites checking
- ✅ Minikube setup with host mounts
- ✅ Application building
- ✅ Docker image creation
- ✅ Storage provisioning
- ✅ All service deployments
- ✅ Access configuration

### 2. Add Documents
```bash
./scripts/manage-docs.sh
```

### 3. Check Status
```bash
./scripts/status.sh
```

### 4. Cleanup When Done
```bash
./scripts/cleanup.sh
```

## Script Organization

### 📁 scripts/
```
scripts/
├── deploy-local.sh     # 🚀 Main deployment script
├── status.sh           # 🔍 Check deployment status
├── cleanup.sh          # 🧹 Clean up resources
└── manage-docs.sh      # 📄 Document management
```

## Detailed Script Functions

### 🚀 deploy-local.sh
**Purpose**: Complete self-contained deployment

**What it does**:
1. Checks prerequisites (Docker, Minikube, kubectl, Maven)
2. Sets up Minikube with 8GB RAM, 4 CPUs, and host mount
3. Builds the Java application JAR
4. Creates Docker image in Minikube's registry
5. Deploys storage with host mounts to `~/minikube-storage/`
6. Deploys MongoDB, Ollama, and the application
7. Waits for all services to be ready
8. Sets up ingress and provides access information

**Storage Layout**:
```
~/minikube-storage/
├── mongodb/     # MongoDB data
├── documents/   # Your documents for RAG
└── ollama/      # Ollama models
```

### 🔍 status.sh
**Purpose**: Comprehensive deployment status check

**What it checks**:
- Minikube status and IP
- Namespace existence
- Storage components (PVs, PVCs)
- Deployment status (MongoDB, Ollama, Application)
- Services and ingress
- Pod health and logs
- Application health endpoint

### 🧹 cleanup.sh
**Purpose**: Flexible cleanup options

**Cleanup modes**:
1. **Application only**: Removes deployments but keeps data
2. **Everything**: Removes all resources and data
3. **Complete Minikube**: Deletes entire Minikube cluster

### 📄 manage-docs.sh
**Purpose**: Document management for RAG

**Features**:
- List documents in storage
- Add new documents (files or directories)
- Remove documents
- Check document processing status
- Show document statistics
- Restart application to reprocess documents

## Architecture

### Storage Strategy
- **Host Mount**: `~/minikube-storage/` mounted to `/mnt/storage/` in Minikube
- **Persistent Volumes**: Use `hostPath` with static provisioning
- **Access Mode**: `ReadWriteOnce` (compatible with hostPath)
- **Storage Class**: Empty string `""` for static provisioning

### Network Access
- **Ingress**: `doc-chat.local` → Application
- **Port Forward**: Alternative access via `kubectl port-forward`
- **Health Checks**: `/actuator/health` endpoint

### Resource Allocation
```yaml
MongoDB:  512Mi RAM, 0.25 CPU
Ollama:   2Gi RAM,   1 CPU (models: llama3.2, nomic-embed-text)
App:      1Gi RAM,   0.5 CPU
```

## Prerequisites

### Required Software
- **Docker Desktop**: For containerization
- **Minikube**: Kubernetes local development
- **kubectl**: Kubernetes CLI
- **Java 17+**: For building the application
- **Maven**: Build tool (included as `./mvnw`)

### System Requirements
- **Memory**: 8GB+ available for Minikube
- **CPU**: 4+ cores recommended
- **Storage**: 20GB+ free space
- **OS**: macOS (optimized for, but adaptable)

## Common Usage Patterns

### Initial Deployment
```bash
# Deploy everything
./scripts/deploy-local.sh

# Add some documents
cp ~/Downloads/*.pdf ~/minikube-storage/documents/

# Check if documents are processed
./scripts/status.sh
```

### Development Workflow
```bash
# Check current status
./scripts/status.sh

# Add more documents
./scripts/manage-docs.sh

# Clean up and redeploy
./scripts/cleanup.sh
./scripts/deploy-local.sh
```

### Troubleshooting
```bash
# Check detailed status
./scripts/status.sh

# View application logs
kubectl logs -f deployment/doc-chat-app -n doc-chat

# Check Ollama model download progress
kubectl logs -f deployment/ollama -n doc-chat
```

## Access Methods

### Primary (Ingress)
1. Add to `/etc/hosts`: `$(minikube ip) doc-chat.local`
2. Access: http://doc-chat.local

### Alternative (Port Forward)
```bash
kubectl port-forward service/doc-chat-service 8080:8080 -n doc-chat
# Access: http://localhost:8080
```

## Data Persistence

### Storage Locations
- **Host**: `~/minikube-storage/`
- **MongoDB**: `~/minikube-storage/mongodb/`
- **Documents**: `~/minikube-storage/documents/`
- **Ollama**: `~/minikube-storage/ollama/`

### Backup
```bash
# Backup all data
tar -czf backup-$(date +%Y%m%d).tar.gz ~/minikube-storage/

# Restore
tar -xzf backup-YYYYMMDD.tar.gz -C ~/
```

## Troubleshooting

### Common Issues

#### 1. Minikube Won't Start
```bash
# Check Docker
docker info

# Restart Minikube
minikube delete && minikube start --memory=8192 --cpus=4
```

#### 2. PVCs Stuck in Pending
```bash
# Check PV status
kubectl get pv

# Check storage class
kubectl get storageclass
```

#### 3. Ollama Taking Too Long
```bash
# Check Ollama logs
kubectl logs -f deployment/ollama -n doc-chat

# Models are large (~2GB each), first download takes time
```

#### 4. Application Won't Start
```bash
# Check application logs
kubectl logs -f deployment/doc-chat-app -n doc-chat

# Check if dependencies are ready
kubectl get pods -n doc-chat
```

### Recovery Commands
```bash
# Full reset
./scripts/cleanup.sh  # Choose option 3
./scripts/deploy-local.sh

# Partial reset (keep data)
./scripts/cleanup.sh  # Choose option 1
./scripts/deploy-local.sh
```

## Performance Tuning

### For Better Performance
- Increase Minikube memory: `--memory=12288`
- Use faster storage: SSD recommended
- Pre-download Ollama models to avoid startup delays

### For Resource-Constrained Systems
- Reduce Ollama memory in `k8s/ollama-deployment.yaml`
- Use smaller models or OpenAI API instead
- Reduce replica counts if needed

## Next Steps

1. **Deploy**: Run `./scripts/deploy-local.sh`
2. **Add Documents**: Use `./scripts/manage-docs.sh`
3. **Test**: Access http://doc-chat.local
4. **Monitor**: Use `./scripts/status.sh`
5. **Clean Up**: Use `./scripts/cleanup.sh` when done