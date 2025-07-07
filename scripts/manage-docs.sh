#!/bin/bash

# 📄 Document Management for Java Chat with Documents

set -e

NAMESPACE="doc-chat"
STORAGE_DIR="$HOME/minikube-storage/documents"
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

# Function to list documents
list_documents() {
    echo_info "Documents in storage:"
    
    if [[ ! -d "$STORAGE_DIR" ]]; then
        echo_error "Documents directory does not exist: $STORAGE_DIR"
        echo "Make sure the application is deployed with host mount storage"
        exit 1
    fi
    
    if [[ -z "$(ls -A "$STORAGE_DIR" 2>/dev/null)" ]]; then
        echo_warning "No documents found in $STORAGE_DIR"
    else
        echo "📁 $STORAGE_DIR"
        find "$STORAGE_DIR" -type f | while read file; do
            size=$(du -h "$file" | cut -f1)
            echo "  📄 $(basename "$file") ($size)"
        done
        
        echo ""
        total_files=$(find "$STORAGE_DIR" -type f | wc -l)
        total_size=$(du -sh "$STORAGE_DIR" | cut -f1)
        echo "Total: $total_files files, $total_size"
    fi
}

# Function to add documents
add_documents() {
    echo_info "Adding documents to storage..."
    
    if [[ ! -d "$STORAGE_DIR" ]]; then
        echo_info "Creating documents directory: $STORAGE_DIR"
        mkdir -p "$STORAGE_DIR"
    fi
    
    echo "Enter the path to documents to add (file or directory):"
    read -p "Path: " doc_path
    
    if [[ ! -e "$doc_path" ]]; then
        echo_error "Path does not exist: $doc_path"
        exit 1
    fi
    
    if [[ -f "$doc_path" ]]; then
        # Single file
        cp "$doc_path" "$STORAGE_DIR/"
        echo_success "Added file: $(basename "$doc_path")"
    elif [[ -d "$doc_path" ]]; then
        # Directory
        cp -r "$doc_path"/* "$STORAGE_DIR/" 2>/dev/null || true
        echo_success "Added documents from directory: $doc_path"
    fi
    
    # Restart application to pick up new documents
    restart_application
}

# Function to remove documents
remove_documents() {
    echo_info "Available documents:"
    list_documents
    
    echo ""
    echo_warning "Enter the filename to remove (or 'all' to remove everything):"
    read -p "Filename: " filename
    
    if [[ "$filename" == "all" ]]; then
        echo_warning "This will remove ALL documents!"
        read -p "Are you sure? (y/N): " confirm
        
        if [[ $confirm == [yY] ]]; then
            rm -rf "$STORAGE_DIR"/*
            echo_success "All documents removed"
        else
            echo "Operation cancelled"
            exit 0
        fi
    else
        if [[ -f "$STORAGE_DIR/$filename" ]]; then
            rm "$STORAGE_DIR/$filename"
            echo_success "Removed: $filename"
        else
            echo_error "File not found: $filename"
            exit 1
        fi
    fi
    
    # Restart application to reflect changes
    restart_application
}

# Function to restart application
restart_application() {
    echo_info "Restarting application to pick up document changes..."
    
    if kubectl get deployment doc-chat-app -n $NAMESPACE &> /dev/null; then
        kubectl rollout restart deployment/doc-chat-app -n $NAMESPACE
        echo_info "Waiting for restart to complete..."
        kubectl rollout status deployment/doc-chat-app -n $NAMESPACE --timeout=300s
        echo_success "Application restarted"
    else
        echo_warning "Application not found - documents will be processed on next startup"
    fi
}

# Function to check document processing status
check_processing_status() {
    echo_info "Checking document processing status..."
    
    # Get application logs
    if kubectl get deployment doc-chat-app -n $NAMESPACE &> /dev/null; then
        echo "Recent application logs:"
        kubectl logs deployment/doc-chat-app -n $NAMESPACE --tail=20 | grep -E "(document|import|embed)" || echo "No document processing logs found"
    else
        echo_error "Application deployment not found"
    fi
}

# Function to show sample documents
show_samples() {
    echo_info "Sample documents you can add:"
    echo ""
    echo "📄 Text Files:"
    echo "  - README.md, *.txt, *.md files"
    echo "  - Configuration files"
    echo "  - Log files"
    echo ""
    echo "📄 Office Documents:"
    echo "  - *.docx, *.xlsx, *.pptx files"
    echo "  - PDF files"
    echo ""
    echo "📄 Code Files:"
    echo "  - *.java, *.py, *.js, etc."
    echo "  - Project documentation"
    echo ""
    echo "💡 Tips:"
    echo "  - Smaller files (< 10MB) work best"
    echo "  - Clear, well-structured content improves AI responses"
    echo "  - Group related documents in subdirectories"
    echo ""
    echo "Example commands:"
    echo "  # Add project README"
    echo "  cp README.md $STORAGE_DIR/"
    echo ""
    echo "  # Add all PDFs from Downloads"
    echo "  cp ~/Downloads/*.pdf $STORAGE_DIR/"
    echo ""
    echo "  # Add documentation directory"
    echo "  cp -r /path/to/docs/* $STORAGE_DIR/"
}

# Function to show document statistics
show_statistics() {
    echo_info "Document Statistics:"
    
    if [[ ! -d "$STORAGE_DIR" ]] || [[ -z "$(ls -A "$STORAGE_DIR" 2>/dev/null)" ]]; then
        echo_warning "No documents found"
        return
    fi
    
    # Count by file type
    echo ""
    echo "📊 Files by type:"
    find "$STORAGE_DIR" -type f | sed 's/.*\.//' | sort | uniq -c | while read count ext; do
        echo "  .$ext: $count files"
    done
    
    echo ""
    echo "📊 Size distribution:"
    find "$STORAGE_DIR" -type f -exec du -h {} \; | awk '{print $1}' | sort -h | uniq -c | while read count size; do
        echo "  $size: $count files"
    done
    
    echo ""
    echo "📊 Total:"
    total_files=$(find "$STORAGE_DIR" -type f | wc -l)
    total_size=$(du -sh "$STORAGE_DIR" | cut -f1)
    echo "  Files: $total_files"
    echo "  Size: $total_size"
}

# Function to show menu
show_menu() {
    echo "📄 Document Management for Java Chat with Documents"
    echo ""
    echo "1. List documents"
    echo "2. Add documents"
    echo "3. Remove documents"
    echo "4. Check processing status"
    echo "5. Show sample document types"
    echo "6. Show statistics"
    echo "7. Restart application"
    echo "8. Exit"
    echo ""
    read -p "Choose an option (1-8): " choice
    
    case $choice in
        1) list_documents;;
        2) add_documents;;
        3) remove_documents;;
        4) check_processing_status;;
        5) show_samples;;
        6) show_statistics;;
        7) restart_application;;
        8) echo "Goodbye!"; exit 0;;
        *) echo_error "Invalid option"; exit 1;;
    esac
}

# Main function
main() {
    echo_info "Document Management Tool"
    echo "Storage location: $STORAGE_DIR"
    echo ""
    
    show_menu
}

main "$@"