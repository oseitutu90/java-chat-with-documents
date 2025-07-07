#!/bin/bash

# 🍃 Configure MongoDB Atlas for Java Chat with Documents

set -e

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

echo_info "MongoDB Atlas Configuration for Java Chat with Documents"
echo ""

# Check if user has Atlas credentials
echo_info "Before proceeding, make sure you have:"
echo "1. A MongoDB Atlas account (free tier is sufficient)"
echo "2. A cluster created (M0 Sandbox is fine for testing)"
echo "3. Database user credentials"
echo "4. Network access configured (allow access from anywhere for Minikube)"
echo ""

read -p "Do you have a MongoDB Atlas cluster ready? (y/N): " atlas_ready

if [[ $atlas_ready != [yY] ]]; then
    echo_info "Please complete the MongoDB Atlas setup first:"
    echo ""
    echo "🌐 MongoDB Atlas Setup Steps:"
    echo "1. Go to https://cloud.mongodb.com/"
    echo "2. Create a free account or sign in"
    echo "3. Create a new cluster (choose M0 Sandbox for free tier)"
    echo "4. Create a database user:"
    echo "   - Go to Database Access"
    echo "   - Add new database user"
    echo "   - Choose password authentication"
    echo "   - Grant 'Atlas admin' role"
    echo "5. Configure network access:"
    echo "   - Go to Network Access"
    echo "   - Add IP address: 0.0.0.0/0 (allow from anywhere)"
    echo "   - This is needed because Minikube IPs are dynamic"
    echo "6. Get your connection string:"
    echo "   - Go to Clusters"
    echo "   - Click 'Connect' on your cluster"
    echo "   - Choose 'Connect your application'"
    echo "   - Copy the connection string"
    echo ""
    echo_warning "Come back and run this script when you have your Atlas cluster ready!"
    exit 0
fi

echo ""
echo_info "Great! Let's configure your Atlas connection..."
echo ""

# Get Atlas connection details
echo "📝 Please provide your MongoDB Atlas details:"
echo ""

read -p "Atlas connection string (mongodb+srv://...): " atlas_uri

if [[ -z "$atlas_uri" ]]; then
    echo_error "Connection string is required"
    exit 1
fi

# Validate connection string format
if [[ ! "$atlas_uri" =~ ^mongodb\+srv:// ]]; then
    echo_error "Connection string should start with 'mongodb+srv://'"
    echo_info "Example: mongodb+srv://username:password@cluster.mongodb.net/dbname"
    exit 1
fi

# Extract database name from URI or ask for it
if [[ "$atlas_uri" =~ /([^?]+) ]]; then
    default_db="${BASH_REMATCH[1]}"
else
    default_db="docs"
fi

read -p "Database name [$default_db]: " database_name
database_name=${database_name:-$default_db}

read -p "Collection name [documents]: " collection_name
collection_name=${collection_name:-documents}

read -p "Search index name [default]: " index_name
index_name=${index_name:-default}

echo ""
echo_info "Configuration Summary:"
echo "  Database: $database_name"
echo "  Collection: $collection_name"
echo "  Index: $index_name"
echo ""

# Encode values for Kubernetes secret
encoded_uri=$(echo -n "$atlas_uri" | base64)
encoded_docs_location=$(echo -n "/app/documents" | base64)
encoded_ollama_url=$(echo -n "http://ollama-service:11434" | base64)
encoded_model_name=$(echo -n "llama3.2" | base64)
encoded_embedding_model=$(echo -n "nomic-embed-text" | base64)

# Create the secret file
echo_info "Creating Kubernetes secret configuration..."

cat > k8s/secret-atlas-configured.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: doc-chat-secret
  namespace: doc-chat
type: Opaque
data:
  # MongoDB Atlas connection string
  MONGODB_URI: ${encoded_uri}
  
  # Documents location
  AI_DOCS_LOCATION: ${encoded_docs_location}
  
  # Ollama configuration
  OPENAI_API_BASE_URL: ${encoded_ollama_url}
  OPENAI_API_MODEL_NAME: ${encoded_model_name}
  OPENAI_API_EMBEDDING_MODEL_NAME: ${encoded_embedding_model}
EOF

echo_success "Secret configuration created: k8s/secret-atlas-configured.yaml"

# Update application.yaml for Atlas
echo_info "Updating application configuration for Atlas..."

cat > src/main/resources/application-atlas.yaml << EOF
spring:
  config:
    activate:
      on-profile: atlas
  data:
    mongodb:
      uri: \${MONGODB_URI}
      database: ${database_name}
      collection: ${collection_name}
      index-name: ${index_name}

ai:
  docs:
    location: \${AI_DOCS_LOCATION}
    langchain4j:
      openAi:
        apiKey: ollama
        baseUrl: \${OPENAI_API_BASE_URL}
        modelName: \${OPENAI_API_MODEL_NAME}
        embeddingModelName: \${OPENAI_API_EMBEDDING_MODEL_NAME}

logging:
  level:
    dev:
      langchain4j: DEBUG
    org:
      mongodb: DEBUG
EOF

echo_success "Created Atlas-specific configuration: src/main/resources/application-atlas.yaml"

# Test connection
echo ""
echo_info "Testing connection to MongoDB Atlas..."
echo "This requires mongosh (MongoDB Shell) to be installed."

read -p "Do you want to test the connection now? (y/N): " test_connection

if [[ $test_connection == [yY] ]]; then
    if command -v mongosh &> /dev/null; then
        echo_info "Testing connection..."
        if mongosh "$atlas_uri" --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
            echo_success "✅ Connection to MongoDB Atlas successful!"
        else
            echo_warning "⚠️  Connection test failed. Please verify your connection string and network access."
        fi
    else
        echo_warning "mongosh not found. Skipping connection test."
        echo "You can install mongosh from: https://docs.mongodb.com/mongodb-shell/install/"
    fi
fi

echo ""
echo_info "📋 Next Steps:"
echo "1. Update your app deployment to use 'atlas' profile:"
echo "   Edit k8s/app-deployment.yaml and change SPRING_PROFILES_ACTIVE to 'atlas'"
echo ""
echo "2. Remove local MongoDB dependency:"
echo "   kubectl delete deployment mongodb -n doc-chat"
echo "   kubectl delete service mongodb-service -n doc-chat"
echo ""
echo "3. Apply the new secret:"
echo "   kubectl apply -f k8s/secret-atlas-configured.yaml"
echo ""
echo "4. Restart the application:"
echo "   kubectl rollout restart deployment/doc-chat-app -n doc-chat"
echo ""
echo "5. Create a vector search index in Atlas:"
echo "   - Go to your Atlas cluster"
echo "   - Navigate to Search → Create Search Index"
echo "   - Choose Vector Search"
echo "   - Database: ${database_name}"
echo "   - Collection: ${collection_name}"
echo "   - Index Name: ${index_name}"
echo "   - Use this configuration:"

cat << 'EOF'

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
EOF

echo ""
echo_success "Atlas configuration complete!"
echo_info "The application will now use MongoDB Atlas for vector storage instead of local MongoDB."