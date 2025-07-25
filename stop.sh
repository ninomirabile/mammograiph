#!/bin/bash

# AI Medical Imaging - Starter Kit - Stop Script
# For local development and testing

set -e

echo "🛑 Stopping AI Medical Imaging - Starter Kit..."

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

# Check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed."
        exit 1
    fi
}

# Check if docker-compose.yml exists
check_compose_file() {
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found in current directory."
        exit 1
    fi
}

# Stop services
stop_services() {
    print_status "Stopping Docker services..."
    
    # Stop services gracefully
    if docker-compose down; then
        print_success "Services stopped successfully"
    else
        print_warning "Some services may not have stopped cleanly"
    fi
}

# Clean up containers (optional)
cleanup_containers() {
    print_status "Cleaning up containers..."
    
    # Remove stopped containers
    if docker container prune -f >/dev/null 2>&1; then
        print_success "Stopped containers cleaned up"
    else
        print_warning "No containers to clean up"
    fi
}

# Clean up networks (optional)
cleanup_networks() {
    print_status "Cleaning up networks..."
    
    # Remove unused networks
    if docker network prune -f >/dev/null 2>&1; then
        print_success "Unused networks cleaned up"
    else
        print_warning "No networks to clean up"
    fi
}

# Check if services are still running
check_services_status() {
    print_status "Checking if services are still running..."
    
    # Check if containers are still running
    if docker-compose ps | grep -q "Up"; then
        print_warning "Some services are still running"
        print_status "Current service status:"
        docker-compose ps
        return 1
    else
        print_success "All services are stopped"
        return 0
    fi
}

# Force stop if needed
force_stop() {
    print_warning "Attempting force stop..."
    
    # Force stop all containers
    if docker-compose down --remove-orphans; then
        print_success "Services force stopped"
    else
        print_error "Failed to force stop services"
        return 1
    fi
}

# Display final information
show_final_info() {
    echo ""
    echo "✅ Application stopped successfully!"
    echo ""
    echo "📁 Data preserved:"
    echo "   - Uploaded files: ./uploads/"
    echo "   - Database: ./medical_ai.db"
    echo "   - Logs: ./logs/"
    echo ""
    echo "🔧 Useful commands:"
    echo "   Start again: ./start.sh"
    echo "   View logs: docker-compose logs"
    echo "   Clean everything: docker-compose down -v --remove-orphans"
    echo "   Remove images: docker-compose down --rmi all"
    echo ""
}

# Main execution
main() {
    echo "=========================================="
    echo "AI Medical Imaging - Starter Kit - STOP"
    echo "=========================================="
    echo ""
    
    check_docker_compose
    check_compose_file
    stop_services
    
    # Check if services stopped properly
    if ! check_services_status; then
        print_warning "Some services may still be running"
        read -p "Do you want to force stop them? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            force_stop
        fi
    fi
    
    # Optional cleanup
    read -p "Do you want to clean up stopped containers and networks? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_containers
        cleanup_networks
    fi
    
    show_final_info
}

# Run main function
main "$@" 