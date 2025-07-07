#!/bin/bash

# Java Chat with Documents - Quick Start Script
# This script sets up the entire application with one command

set -e

echo "🚀 Java Chat with Documents - Quick Start"
echo "=========================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command_exists docker; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command_exists docker-compose; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    
    # Prompt for documents path
    read -p "Enter the path to your documents directory: " DOCUMENTS_PATH
    
    if [ ! -d "$DOCUMENTS_PATH" ]; then
        echo "❌ Directory does not exist: $DOCUMENTS_PATH"
        exit 1
    fi
    
    # Create .env file
    cat > .env << EOF
# Path to your documents directory
DOCUMENTS_PATH=$DOCUMENTS_PATH

# Optional: Override default models
# OPENAI_API_MODEL_NAME=llama3.2
# OPENAI_API_EMBEDDING_MODEL_NAME=nomic-embed-text
EOF
    
    echo "✅ Created .env file with your documents path"
else
    echo "✅ Found existing .env file"
fi

# Ask user about Ollama preference
echo ""
echo "🤖 Ollama Setup Options:"
echo "1. Use containerized Ollama (recommended for simplicity)"
echo "2. Use external Ollama installation"
echo ""
read -p "Choose option (1 or 2): " OLLAMA_OPTION

case $OLLAMA_OPTION in
    1)
        COMPOSE_FILE="docker-compose.yml"
        echo "Using containerized Ollama..."
        ;;
    2)
        COMPOSE_FILE="docker-compose.external-ollama.yml"
        echo "Using external Ollama..."
        
        # Check if Ollama is running
        if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
            echo "❌ Ollama is not running on localhost:11434"
            echo "Please start Ollama first:"
            echo "  ollama serve"
            echo "And ensure these models are available:"
            echo "  ollama pull llama3.2"
            echo "  ollama pull nomic-embed-text"
            exit 1
        fi
        
        echo "✅ Ollama is running and accessible"
        ;;
    *)
        echo "❌ Invalid option. Please choose 1 or 2."
        exit 1
        ;;
esac

# Build and start services
echo ""
echo "🏗️  Building and starting services..."
docker-compose -f $COMPOSE_FILE up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."

# Wait for MongoDB
echo "  Waiting for MongoDB..."
while ! docker-compose -f $COMPOSE_FILE exec mongodb mongo --eval "db.adminCommand('ismaster')" >/dev/null 2>&1; do
    sleep 2
done
echo "  ✅ MongoDB is ready"

# Wait for Ollama (if containerized)
if [ "$COMPOSE_FILE" = "docker-compose.yml" ]; then
    echo "  Waiting for Ollama and model download..."
    # This might take a while for first run
    while ! docker-compose -f $COMPOSE_FILE exec ollama ollama list >/dev/null 2>&1; do
        sleep 5
    done
    echo "  ✅ Ollama is ready"
fi

# Wait for main application
echo "  Waiting for application..."
while ! curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; do
    sleep 5
done
echo "  ✅ Application is ready"

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Access Information:"
echo "   Application URL: http://localhost:8080"
echo "   MongoDB: localhost:27017"
echo "   Ollama API: http://localhost:11434"
echo ""
echo "📄 Your documents are being processed from: $(grep DOCUMENTS_PATH .env | cut -d'=' -f2)"
echo ""
echo "🔧 Useful commands:"
echo "   View logs: docker-compose -f $COMPOSE_FILE logs -f"
echo "   Stop services: docker-compose -f $COMPOSE_FILE down"
echo "   Restart app: docker-compose -f $COMPOSE_FILE restart doc-chat-app"
echo ""
echo "Open your browser and navigate to http://localhost:8080 to start chatting with your documents!"