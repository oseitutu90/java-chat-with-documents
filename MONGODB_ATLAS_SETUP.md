# MongoDB Atlas Setup Guide

## Quick Setup Steps

### 1. Create MongoDB Atlas Account
1. Go to https://cloud.mongodb.com/
2. Create a free account or sign in
3. Create a new project (e.g., "DocumentChat")

### 2. Create a Cluster
1. Click "Create a Cluster"
2. Choose **M0 Sandbox** (free tier)
3. Select a cloud provider and region
4. Name your cluster (e.g., "doc-chat-cluster")
5. Click "Create Cluster" (takes 1-3 minutes)

### 3. Create Database User
1. Go to **Database Access** in the sidebar
2. Click "Add New Database User"
3. Choose **Password** authentication
4. Username: `docadmin`
5. Password: Generate a secure password (save it!)
6. Database User Privileges: **Atlas Admin**
7. Click "Add User"

### 4. Configure Network Access
1. Go to **Network Access** in the sidebar
2. Click "Add IP Address"
3. Click "Allow Access from Anywhere" (0.0.0.0/0)
4. Add comment: "Minikube access"
5. Click "Confirm"

⚠️ **Security Note**: In production, restrict to specific IPs. For Minikube testing, we need 0.0.0.0/0 since Minikube IPs are dynamic.

### 5. Get Connection String
1. Go to **Clusters** in the sidebar
2. Click "Connect" on your cluster
3. Choose "Connect your application"
4. Select "Java" and version "4.3 or later"
5. Copy the connection string (looks like):
   ```
   mongodb+srv://docadmin:<password>@doc-chat-cluster.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
6. Replace `<password>` with your actual password
7. Add database name at the end: `/docs`

Final connection string example:
```
mongodb+srv://docadmin:yourpassword@doc-chat-cluster.xxxxx.mongodb.net/docs?retryWrites=true&w=majority
```

### 6. Create Vector Search Index
1. In your Atlas cluster, go to **Search** tab
2. Click "Create Search Index"
3. Choose **Vector Search**
4. Configuration:
   - **Database**: `docs`
   - **Collection**: `documents`
   - **Index Name**: `default`
5. Use this JSON configuration:
   ```json
   {
     "fields": [
       {
         "numDimensions": 768,
         "path": "embedding", 
         "similarity": "cosine",
         "type": "vector"
       }
     ]
   }
   ```
6. Click "Create Search Index"

⚠️ **Important**: The vector search index creation can take 5-10 minutes.

## Update Kubernetes Configuration

### 1. Create Atlas Secret
Update the MongoDB connection in your Kubernetes secret:

```bash
# Replace with your actual Atlas connection string
ATLAS_URI="mongodb+srv://docadmin:yourpassword@doc-chat-cluster.xxxxx.mongodb.net/docs?retryWrites=true&w=majority"

# Encode for Kubernetes secret
ENCODED_URI=$(echo -n "$ATLAS_URI" | base64)

# Create new secret file
cat > k8s/secret-atlas-configured.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: doc-chat-secret
  namespace: doc-chat
type: Opaque
data:
  MONGODB_URI: ${ENCODED_URI}
  AI_DOCS_LOCATION: L2FwcC9kb2N1bWVudHM=
  OPENAI_API_BASE_URL: aHR0cDovL29sbGFtYS1zZXJ2aWNlOjExNDM0
  OPENAI_API_MODEL_NAME: bGxhbWEzLjI=
  OPENAI_API_EMBEDDING_MODEL_NAME: bm9taWMtZW1iZWQtdGV4dA==
EOF
```

### 2. Update Application Profile
Change the Spring profile to use Atlas configuration:

```bash
# Edit k8s/app-deployment.yaml
# Change this line:
# value: "dev"
# To:
# value: "atlas"
```

### 3. Remove Local MongoDB
Since we're using Atlas, remove the local MongoDB deployment:

```bash
kubectl delete deployment mongodb -n doc-chat
kubectl delete service mongodb-service -n doc-chat
kubectl delete pvc mongodb-pvc-host -n doc-chat
kubectl delete pv mongodb-pv-host
```

### 4. Apply Changes
```bash
# Apply new secret
kubectl apply -f k8s/secret-atlas-configured.yaml

# Restart application
kubectl rollout restart deployment/doc-chat-app -n doc-chat
```

## Validation

### Test Connection
You can test your Atlas connection using mongosh:

```bash
# Install mongosh if needed
# macOS: brew install mongosh
# Then test:
mongosh "mongodb+srv://docadmin:yourpassword@doc-chat-cluster.xxxxx.mongodb.net/docs"

# In mongosh, test basic operations:
> db.adminCommand('ping')
> show dbs
> use docs
> db.documents.countDocuments()
```

### Monitor Application
```bash
# Check pod status
kubectl get pods -n doc-chat

# Check application logs
kubectl logs -f deployment/doc-chat-app -n doc-chat

# Look for successful Atlas connection logs like:
# "MongoClient with metadata ... created with settings MongoClientSettings{...atlas..."
```

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Check username/password in connection string
   - Verify database user exists and has correct permissions

2. **Network Timeout**
   - Verify network access is configured (0.0.0.0/0)
   - Check firewall settings

3. **Index Not Found**
   - Ensure vector search index is created and active
   - Check index name matches configuration (`default`)
   - Wait for index creation to complete (can take 5-10 minutes)

4. **Wrong Database/Collection**
   - Verify database name in connection string (`/docs`)
   - Check collection name in configuration (`documents`)

### Atlas Dashboard Monitoring
- Go to **Metrics** tab in your cluster to see connection activity
- **Real-time** tab shows current operations
- **Profiler** tab shows query performance

## Cost Considerations

- **M0 Sandbox**: Free forever, 512MB storage
- **M2/M5**: Paid tiers with more storage and performance
- **Vector Search**: Free on M0, usage-based pricing on paid tiers
- Monitor usage in Atlas **Billing** section

## Security Best Practices

1. **Rotate passwords** regularly
2. **Use specific IP ranges** instead of 0.0.0.0/0 in production
3. **Enable audit logs** in paid tiers
4. **Use VPC peering** for production deployments
5. **Enable database encryption** (available in paid tiers)

Your MongoDB Atlas setup is now ready for the RAG application! 🎉