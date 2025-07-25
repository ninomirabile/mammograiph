#!/bin/bash

# AI Medical Imaging - Starter Kit Setup Script

set -e

echo "🚀 Setting up AI Medical Imaging - Starter Kit..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    print_status "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Docker and Docker Compose are installed"
}

# Check if ports are available
check_ports() {
    print_status "Checking port availability..."
    
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port 3000 is already in use. Frontend may not start properly."
    fi
    
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port 8000 is already in use. Backend may not start properly."
    fi
    
    print_success "Port check completed"
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p uploads
    mkdir -p logs
    
    print_success "Directories created"
}

# Build and start services
start_services() {
    print_status "Building and starting services..."
    
    # Build images
    docker-compose build
    
    # Start services
    docker-compose up -d
    
    print_success "Services started"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for backend
    print_status "Waiting for backend..."
    for i in {1..30}; do
        if curl -f http://localhost:8000/api/health >/dev/null 2>&1; then
            print_success "Backend is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "Backend failed to start within 30 seconds"
            exit 1
        fi
        sleep 1
    done
    
    # Wait for frontend
    print_status "Waiting for frontend..."
    for i in {1..30}; do
        if curl -f http://localhost:3000 >/dev/null 2>&1; then
            print_success "Frontend is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            print_warning "Frontend may not be ready yet"
            break
        fi
        sleep 1
    done
}

# Display final information
show_final_info() {
    echo ""
    echo "🎉 Setup completed successfully!"
    echo ""
    echo "📱 Access your application:"
    echo "   Frontend: http://localhost:3000"
    echo "   Backend API: http://localhost:8000"
    echo "   API Documentation: http://localhost:8000/docs"
    echo ""
    echo "🔧 Useful commands:"
    echo "   View logs: docker-compose logs -f"
    echo "   Stop services: docker-compose down"
    echo "   Restart services: docker-compose restart"
    echo "   Health check: curl http://localhost:8000/api/health"
    echo ""
    echo "⚠️  Disclaimer: This is a demonstration system using mock AI."
    echo "   Results are simulated and should not be used for clinical decisions."
    echo ""
}

# Main execution
main() {
    echo "=========================================="
    echo "AI Medical Imaging - Starter Kit Setup"
    echo "=========================================="
    echo ""
    
    check_docker
    check_ports
    create_directories
    start_services
    wait_for_services
    show_final_info
}

# Run main function
main "$@" 