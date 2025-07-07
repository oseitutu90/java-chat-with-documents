#!/bin/bash

# 🔑 Create MongoDB Atlas Secret for Kubernetes

echo "🔑 MongoDB Atlas Secret Creator"
echo "============================================"
echo ""

# Get Atlas connection string from user
echo "📝 Please enter your MongoDB Atlas connection string:"
echo "Format: mongodb+srv://username:password@cluster.mongodb.net/database"
echo ""
read -p "Atlas URI: " ATLAS_URI

if [[ -z "$ATLAS_URI" ]]; then
    echo "❌ Atlas URI is required"
    exit 1
fi

# Validate format
if [[ ! "$ATLAS_URI" =~ ^mongodb\+srv:// ]]; then
    echo "❌ Invalid format. Should start with 'mongodb+srv://'"
    exit 1
fi

echo ""
echo "✅ Creating Kubernetes secret configuration..."

# Encode values
ENCODED_URI=$(echo -n "$ATLAS_URI" | base64)
ENCODED_DOCS_LOCATION=$(echo -n "/app/documents" | base64)
ENCODED_OLLAMA_URL=$(echo -n "http://ollama-service:11434" | base64)
ENCODED_MODEL_NAME=$(echo -n "llama3.2" | base64)
ENCODED_EMBEDDING_MODEL=$(echo -n "nomic-embed-text" | base64)

# Create secret file
cat > k8s/secret-atlas-configured.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: doc-chat-secret
  namespace: doc-chat
type: Opaque
data:
  # MongoDB Atlas connection string
  MONGODB_URI: ${ENCODED_URI}
  
  # Documents location
  AI_DOCS_LOCATION: ${ENCODED_DOCS_LOCATION}
  
  # Ollama configuration  
  OPENAI_API_BASE_URL: ${ENCODED_OLLAMA_URL}
  OPENAI_API_MODEL_NAME: ${ENCODED_MODEL_NAME}
  OPENAI_API_EMBEDDING_MODEL_NAME: ${ENCODED_EMBEDDING_MODEL}
EOF

echo "✅ Secret created: k8s/secret-atlas-configured.yaml"
echo ""
echo "📋 Next steps:"
echo "1. kubectl apply -f k8s/secret-atlas-configured.yaml"
echo "2. Update k8s/app-deployment.yaml to use 'atlas' profile"
echo "3. kubectl rollout restart deployment/doc-chat-app -n doc-chat"