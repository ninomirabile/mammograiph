#!/bin/bash

# AI Medical Imaging - Starter Kit - Start Script
# For local development and testing

set -e

echo "🚀 Starting AI Medical Imaging - Starter Kit..."

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
    
    # Check for Docker Compose v2
    if docker compose version >/dev/null 2>&1; then
        print_success "Docker and Docker Compose v2 are installed"
    elif command -v docker-compose &> /dev/null; then
        print_success "Docker and Docker Compose v1 are installed"
    else
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
}

# Get the correct docker compose command
get_compose_cmd() {
    if docker compose version >/dev/null 2>&1; then
        echo "docker compose"
    else
        echo "docker-compose"
    fi
}

# Check if ports are available
check_ports() {
    print_status "Checking port availability..."
    
    COMPOSE_CMD=$(get_compose_cmd)
    
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port 3000 is already in use. Stopping existing process..."
        $COMPOSE_CMD down 2>/dev/null || true
        sleep 2
    fi
    
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port 8000 is already in use. Stopping existing process..."
        $COMPOSE_CMD down 2>/dev/null || true
        sleep 2
    fi
    
    print_success "Ports are available"
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
    
    COMPOSE_CMD=$(get_compose_cmd)
    
    # Build images
    print_status "Building Docker images..."
    $COMPOSE_CMD build
    
    # Start services
    print_status "Starting services..."
    $COMPOSE_CMD up -d
    
    print_success "Services started"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    COMPOSE_CMD=$(get_compose_cmd)
    
    # Wait for backend
    print_status "Waiting for backend..."
    for i in {1..60}; do
        if curl -f http://localhost:8000/api/health >/dev/null 2>&1; then
            print_success "Backend is ready"
            break
        fi
        if [ $i -eq 60 ]; then
            print_error "Backend failed to start within 60 seconds"
            print_status "Checking logs..."
            $COMPOSE_CMD logs backend
            exit 1
        fi
        sleep 1
    done
    
    # Wait for frontend
    print_status "Waiting for frontend..."
    for i in {1..60}; do
        if curl -f http://localhost:3000 >/dev/null 2>&1; then
            print_success "Frontend is ready"
            break
        fi
        if [ $i -eq 60 ]; then
            print_warning "Frontend may not be ready yet"
            print_status "Checking logs..."
            $COMPOSE_CMD logs frontend
            break
        fi
        sleep 1
    done
}

# Run health checks
run_health_checks() {
    print_status "Running health checks..."
    
    # Backend health
    if curl -f http://localhost:8000/api/health >/dev/null 2>&1; then
        print_success "Backend health check passed"
    else
        print_error "Backend health check failed"
        return 1
    fi
    
    # Detailed health
    response=$(curl -s http://localhost:8000/api/health/detailed)
    if echo "$response" | grep -q "status"; then
        print_success "Detailed health check passed"
    else
        print_error "Detailed health check failed"
        return 1
    fi
    
    # Model info
    response=$(curl -s http://localhost:8000/api/inference/model/info)
    if echo "$response" | grep -q "name"; then
        print_success "Model info check passed"
    else
        print_error "Model info check failed"
        return 1
    fi
    
    print_success "All health checks passed"
}

# Display final information
show_final_info() {
    echo ""
    echo "🎉 Application started successfully!"
    echo ""
    echo "📱 Access your application:"
    echo "   Frontend: http://localhost:3000"
    echo "   Backend API: http://localhost:8000"
    echo "   API Documentation: http://localhost:8000/docs"
    echo ""
    echo "🔧 Useful commands:"
    echo "   View logs: $(get_compose_cmd) logs -f"
    echo "   Stop services: ./stop.sh"
    echo "   Restart services: ./stop.sh && ./start.sh"
    echo "   Health check: curl http://localhost:8000/api/health"
    echo ""
    echo "🧪 Test the application:"
    echo "   Run tests: ./scripts/test.sh"
    echo ""
    echo "⚠️  Disclaimer: This is a demonstration system using mock AI."
    echo "   Results are simulated and should not be used for clinical decisions."
    echo ""
    echo "Press Ctrl+C to stop the application"
    echo ""
}

# Main execution
main() {
    echo "=========================================="
    echo "AI Medical Imaging - Starter Kit - START"
    echo "=========================================="
    echo ""
    
    check_docker
    check_ports
    create_directories
    start_services
    wait_for_services
    run_health_checks
    show_final_info
    
    # Keep the script running and show logs
    COMPOSE_CMD=$(get_compose_cmd)
    print_status "Showing logs (press Ctrl+C to stop)..."
    $COMPOSE_CMD logs -f
}

# Handle Ctrl+C gracefully
trap 'echo ""; print_status "Stopping services..."; $(get_compose_cmd) down; print_success "Services stopped"; exit 0' INT

# Run main function
main "$@" 