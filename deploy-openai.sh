#!/bin/bash

# Deploy Java Chat with Documents to Minikube using OpenAI API
set -e

echo "🚀 Starting deployment of Java Chat with Documents to Minikube (OpenAI version)..."

# Check if OpenAI API key is provided
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ Please set your OpenAI API key:"
    echo "   export OPENAI_API_KEY='your-api-key-here'"
    echo "   ./deploy-openai.sh"
    exit 1
fi

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

# Create documents storage
echo "📄 Setting up document storage..."
kubectl apply -f k8s/documents-pv.yaml

# Create ConfigMap
echo "⚙️  Creating configuration..."
kubectl apply -f k8s/configmap.yaml

# Create Secret with OpenAI API key
echo "🔑 Creating secret with OpenAI API key..."
ENCODED_API_KEY=$(echo -n "$OPENAI_API_KEY" | base64)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: doc-chat-secret
  namespace: doc-chat
type: Opaque
data:
  MONGODB_URI: bW9uZ29kYjovL2FkbWluOnBhc3N3b3JkMTIzQG1vbmdvZGItc2VydmljZToyNzAxNy9kb2NzP2F1dGhTb3VyY2U9YWRtaW4=
  AI_DOCS_LOCATION: L2FwcC9kb2N1bWVudHM=
  OPENAI_API_BASE_URL: aHR0cHM6Ly9hcGkub3BlbmFpLmNvbS92MQ==
  OPENAI_API_MODEL_NAME: Z3B0LTMuNS10dXJibw==
  OPENAI_API_EMBEDDING_MODEL_NAME: dGV4dC1lbWJlZGRpbmctYWRhLTAwMg==
  OPENAI_API_KEY: $ENCODED_API_KEY
EOF

# Deploy the application (without Ollama dependencies)
echo "🚀 Deploying the application..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: doc-chat-app
  namespace: doc-chat
  labels:
    app: doc-chat-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: doc-chat-app
  template:
    metadata:
      labels:
        app: doc-chat-app
    spec:
      initContainers:
      - name: wait-for-mongodb
        image: busybox:1.35
        command: ['sh', '-c', 'until nc -z mongodb-service 27017; do echo waiting for mongodb; sleep 2; done;']
      containers:
      - name: doc-chat-app
        image: doc-chat:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "test"
        - name: MONGODB_URI
          valueFrom:
            secretKeyRef:
              name: doc-chat-secret
              key: MONGODB_URI
        - name: AI_DOCS_LOCATION
          valueFrom:
            secretKeyRef:
              name: doc-chat-secret
              key: AI_DOCS_LOCATION
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: doc-chat-secret
              key: OPENAI_API_KEY
        - name: OPENAI_API_MODEL_NAME
          valueFrom:
            secretKeyRef:
              name: doc-chat-secret
              key: OPENAI_API_MODEL_NAME
        volumeMounts:
        - name: documents-storage
          mountPath: /app/documents
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
      volumes:
      - name: documents-storage
        persistentVolumeClaim:
          claimName: documents-pvc
EOF

# Create service
kubectl apply -f k8s/app-deployment.yaml --dry-run=client -o yaml | grep -A 20 "kind: Service" | kubectl apply -f -

# Create ingress
echo "🌐 Setting up ingress..."
kubectl apply -f k8s/ingress.yaml

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n doc-chat
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
EOF
