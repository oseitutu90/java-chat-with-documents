# Storage Setup Guide for macOS + Minikube

## Overview of Storage Issues

The original storage configuration has several critical issues:

1. **Storage Class Problem**: Uses `storageClassName: standard` which may not exist
2. **Access Mode Conflict**: `ReadWriteMany` is not supported by hostPath
3. **Path Issues**: Hardcoded paths like `/data/mongodb` don't exist in Minikube
4. **No Host Integration**: No way to easily access data from macOS host

## Solution Options

### Option 1: Dynamic Provisioning (Recommended)

**Pros:**
- Simplest setup
- Uses Minikube's built-in storage provisioner
- No manual PV creation needed
- Works out of the box

**Cons:**
- Data stored inside Minikube VM
- Harder to access from macOS host
- Data lost when Minikube is deleted

**Setup:**
```bash
# Enable storage addons
minikube addons enable default-storageclass
minikube addons enable storage-provisioner

# Deploy storage
kubectl apply -f k8s/storage-dynamic.yaml
```

### Option 2: Static Provisioning with Fixed Paths

**Pros:**
- Predictable storage locations
- Data persists in known locations
- Good for development debugging

**Cons:**
- Manual PV creation required
- Still inside Minikube VM
- Requires specific path setup

**Setup:**
```bash
# Create storage directories in Minikube
minikube ssh "sudo mkdir -p /tmp/mongodb-data /tmp/documents-data /tmp/ollama-data"
minikube ssh "sudo chmod 777 /tmp/mongodb-data /tmp/documents-data /tmp/ollama-data"

# Deploy storage
kubectl apply -f k8s/mongodb-pv-fixed.yaml
kubectl apply -f k8s/documents-pv-fixed.yaml
kubectl apply -f k8s/ollama-pv-fixed.yaml
```

### Option 3: Host Mount Storage (Best for Development)

**Pros:**
- Data accessible from macOS host
- Easy to inspect and backup
- Survives Minikube restarts
- Easy document management

**Cons:**
- Requires Minikube mount setup
- More complex initial setup
- Platform-specific

**Setup:**
```bash
# Run the automated setup script
./setup-storage-macos.sh

# Or manual setup:
# 1. Create directories on macOS
mkdir -p ~/minikube-storage/{mongodb,documents,ollama}

# 2. Start Minikube with mount
minikube start --memory=8192 --cpus=4 \
  --mount=true \
  --mount-string="$HOME/minikube-storage:/mnt/storage"

# 3. Deploy storage
kubectl apply -f k8s/storage-with-host-mount.yaml
```

## Recommended Approach

For development on macOS, use **Option 3 (Host Mount Storage)**:

1. **Easy document management**: Add documents directly to `~/minikube-storage/documents/`
2. **Data persistence**: Data survives Minikube restarts and deletions
3. **Easy debugging**: Can inspect MongoDB data, Ollama models, etc.
4. **Backup friendly**: Easy to backup the entire storage directory

## Key Changes Made

### Storage Class
```yaml
# Before (problematic)
storageClassName: standard

# After (fixed)
storageClassName: ""  # Empty string for static provisioning
# OR omit entirely for dynamic provisioning
```

### Access Modes
```yaml
# Before (not supported)
accessModes:
  - ReadWriteMany

# After (supported)
accessModes:
  - ReadWriteOnce
```

### Host Paths
```yaml
# Before (may not exist)
hostPath:
  path: /data/mongodb

# After (guaranteed to exist)
hostPath:
  path: /tmp/mongodb-data  # For fixed paths
  # OR
  path: /mnt/storage/mongodb  # For host mount
```

## Verification Commands

```bash
# Check storage classes
kubectl get storageclass

# Check persistent volumes
kubectl get pv

# Check persistent volume claims
kubectl get pvc -n doc-chat

# Check pod storage mounts
kubectl describe pod <pod-name> -n doc-chat

# Access your data on macOS (for host mount option)
ls -la ~/minikube-storage/
```

## Troubleshooting

### PVC Stuck in Pending
```bash
kubectl describe pvc <pvc-name> -n doc-chat
# Look for events indicating binding issues
```

### Storage Class Not Found
```bash
kubectl get storageclass
# If empty, enable storage addons:
minikube addons enable default-storageclass
minikube addons enable storage-provisioner
```

### Permission Issues
```bash
# Fix permissions in Minikube
minikube ssh "sudo chmod 777 /path/to/storage"
```

## Adding Documents

With host mount storage, you can easily add documents:

```bash
# Copy documents to the mounted directory
cp -r /path/to/your/documents/ ~/minikube-storage/documents/

# Or create a documents directory and add files
mkdir -p ~/minikube-storage/documents/my-docs
cp *.pdf ~/minikube-storage/documents/my-docs/
```

The application will automatically pick up these documents from the `/app/documents` mount point inside the container.