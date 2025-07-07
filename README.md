# 🤖 Java AI Chat with Documents

An intelligent chatbot that answers questions using your own documents as context through **RAG (Retrieval Augmented Generation)**. Built with [LangChain4j](https://github.com/langchain4j/langchain4j), [Vaadin](http://vaadin.com/), and Spring Boot.

## ✨ Features

- 📄 **Document-based AI Chat** - Upload your documents and chat with them
- 🧠 **Multiple LLM Options** - Use OpenAI API or local Ollama models
- 🔍 **Smart Document Search** - Vector-based document retrieval
- 💾 **Persistent Storage** - MongoDB for documents and embeddings
- 🌐 **Modern Web UI** - Clean, responsive Vaadin interface
- 🐳 **Kubernetes Ready** - Deploy to Minikube or any K8s cluster

## 🚀 Quick Start

### 🐳 Docker Compose (Recommended - Fully Portable)

The easiest way to get started! Only requires Docker and your documents:

```bash
# 1. Clone the repository
git clone <repository-url>
cd java-chat-with-documents

# 2. Quick setup with interactive script
./quick-start.sh

# OR manual setup:
# Copy environment template
cp .env.example .env

# Edit .env file and set your documents path
# DOCUMENTS_PATH=/path/to/your/documents

# Start everything with one command
docker-compose up --build
```

**That's it!** Open http://localhost:8080 and start chatting with your documents.

**What gets automatically set up:**
- ✅ MongoDB database
- ✅ Ollama with required models (llama3.2, nomic-embed-text)
- ✅ Application with all configurations
- ✅ Document processing from your specified folder

### Prerequisites

- **Docker & Docker Compose**
- **Your documents folder**

### Alternative: External Ollama

If you prefer to use your own Ollama installation:

```bash
# Make sure Ollama is running and has required models
ollama serve
ollama pull llama3.2
ollama pull nomic-embed-text

# Use the external Ollama compose file
docker-compose -f docker-compose.external-ollama.yml up --build
```

### Option 1: Local Development Setup

1. **Clone and build the project**
   ```bash
   git clone <repository-url>
   cd java-chat-with-documents
   ./mvnw clean package
   ```

2. **Set up MongoDB**
   ```bash
   # Using Docker
   docker run -d --name mongodb -p 27017:27017 mongo:7.0

   # Or install MongoDB locally
   # https://docs.mongodb.com/manual/installation/
   ```

3. **Choose your LLM option:**

   **Option A: OpenAI (Recommended for quality)**
   ```bash
   export OPENAI_API_KEY="your-api-key-here"
   export SPRING_PROFILES_ACTIVE="test"
   ```

   **Option B: Local Ollama (Privacy-focused)**
   ```bash
   # Install Ollama
   curl -fsSL https://ollama.com/install.sh | sh

   # Pull required models
   ollama pull llama3.2
   ollama pull nomic-embed-text

   export SPRING_PROFILES_ACTIVE="dev"
   ```

4. **Configure document location**
   ```bash
   export AI_DOCS_LOCATION="/path/to/your/documents"
   export MONGODB_URI="mongodb://localhost:27017"
   ```

5. **Run the application**
   ```bash
   ./mvnw spring-boot:run
   ```

6. **Open your browser** → http://localhost:8080

### Option 2: Kubernetes Deployment

Deploy to Minikube with everything pre-configured:

```bash
# Start Minikube
minikube start --memory=8192 --cpus=4

# Deploy with local LLM
./deploy.sh

# OR deploy with OpenAI
export OPENAI_API_KEY="your-api-key"
./deploy-openai.sh

# Access at: http://doc-chat.local
```

See [KUBERNETES_DEPLOYMENT.md](KUBERNETES_DEPLOYMENT.md) for detailed instructions.

## 📖 How to Use

### 1. **Add Your Documents**
   - Place documents in your configured folder (`AI_DOCS_LOCATION`)
   - Supported formats: PDF, DOCX, TXT, MD, HTML, and more
   - The app automatically processes and indexes them

### 2. **Start Chatting**
   - Open the web interface
   - Ask questions about your documents
   - The AI will search relevant content and provide contextual answers

### 3. **Example Queries**
   - "What are the main topics covered in the documentation?"
   - "How do I configure the database connection?"
   - "Summarize the installation process"

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `MONGODB_URI` | MongoDB connection string | `mongodb://localhost:27017` |
| `AI_DOCS_LOCATION` | Path to your documents | `/path/to/documents` |
| `OPENAI_API_KEY` | OpenAI API key (if using OpenAI) | `sk-...` |
| `OPENAI_API_MODEL_NAME` | OpenAI model name | `gpt-3.5-turbo` |
| `SPRING_PROFILES_ACTIVE` | Configuration profile | `dev`, `test`, or `prod` |

### Configuration Profiles

- **`dev`** - Uses local Ollama for LLM
- **`test`** - Uses OpenAI API
- **`prod`** - Production configuration

### Supported Document Types

Thanks to Apache Tika integration:
- **Text**: TXT, MD, CSV
- **Office**: DOCX, XLSX, PPTX
- **PDF**: All PDF variants
- **Web**: HTML, XML
- **Code**: Most programming languages

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Vaadin UI     │    │  Spring Boot    │    │    MongoDB      │
│   (Frontend)    │◄──►│   (Backend)     │◄──►│  (Vector DB)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   LangChain4j   │
                       │   (AI Layer)    │
                       └─────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
            ┌─────────────┐    ┌─────────────┐
            │   OpenAI    │    │   Ollama    │
            │    API      │    │  (Local)    │
            └─────────────┘    └─────────────┘
```

## 🛠️ Development

### Building from Source

```bash
# Clone the repository
git clone <repository-url>
cd java-chat-with-documents

# Build the project
./mvnw clean package

# Run tests
./mvnw test

# Run with development profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

### IDE Setup

Import as a Maven project in your favorite IDE:
- **IntelliJ IDEA**: File → Open → Select `pom.xml`
- **Eclipse**: File → Import → Existing Maven Projects
- **VS Code**: Install Java Extension Pack, then open folder

### Adding New Document Types

The application automatically handles most document types through Apache Tika. To add custom parsers:

1. Add dependency to `pom.xml`
2. Configure in `AIConfig.java`
3. Restart the application

## 🐳 Docker & Kubernetes

### Docker Build

```bash
# Build image
docker build -t doc-chat:latest .

# Run container
docker run -p 8080:8080 \
  -e MONGODB_URI="mongodb://host.docker.internal:27017" \
  -e AI_DOCS_LOCATION="/app/documents" \
  -v /path/to/docs:/app/documents \
  doc-chat:latest
```

### Kubernetes Deployment

See [KUBERNETES_DEPLOYMENT.md](KUBERNETES_DEPLOYMENT.md) for complete instructions.

Quick deploy to Minikube:
```bash
./deploy.sh              # With Ollama
./deploy-openai.sh        # With OpenAI
```

## 🔧 Troubleshooting

### Common Issues

**Application won't start**
- Check MongoDB connection
- Verify document path exists
- Ensure LLM service is accessible

**No documents found**
- Check `AI_DOCS_LOCATION` path
- Verify file permissions
- Check application logs

**Poor AI responses**
- Try different LLM models
- Increase document chunk size
- Add more relevant documents

**Memory issues**
- Increase JVM heap size: `-Xmx2g`
- Reduce document batch size
- Use external vector database

### Logs and Monitoring

```bash
# Application logs
./mvnw spring-boot:run --debug

# Kubernetes logs
kubectl logs -f deployment/doc-chat-app -n doc-chat

# Health check
curl http://localhost:8080/actuator/health
```

## 📊 Performance Tips

- **Document Size**: Keep individual documents under 10MB
- **Total Documents**: For >1000 documents, use external vector DB
- **Memory**: Allocate at least 2GB RAM for production
- **Models**: Use smaller models for faster responses

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [LangChain4j Documentation](https://docs.langchain4j.dev/)
- [Vaadin Documentation](https://vaadin.com/docs)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Ollama Models](https://ollama.com/library)
- [OpenAI API](https://platform.openai.com/docs)

---

**Need help?** Open an issue or check the troubleshooting section above.
