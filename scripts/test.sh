#!/bin/bash

# AI Medical Imaging - Starter Kit Test Script

set -e

echo "🧪 Testing AI Medical Imaging - Starter Kit..."

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

# Test backend health
test_backend_health() {
    print_status "Testing backend health..."
    
    if curl -f http://localhost:8000/api/health >/dev/null 2>&1; then
        print_success "Backend health check passed"
        return 0
    else
        print_error "Backend health check failed"
        return 1
    fi
}

# Test detailed health
test_detailed_health() {
    print_status "Testing detailed health..."
    
    response=$(curl -s http://localhost:8000/api/health/detailed)
    if echo "$response" | grep -q "status"; then
        print_success "Detailed health check passed"
        return 0
    else
        print_error "Detailed health check failed"
        return 1
    fi
}

# Test model info
test_model_info() {
    print_status "Testing model info..."
    
    response=$(curl -s http://localhost:8000/api/inference/model/info)
    if echo "$response" | grep -q "model_info"; then
        print_success "Model info check passed"
        return 0
    else
        print_error "Model info check failed"
        return 1
    fi
}

# Test frontend accessibility
test_frontend() {
    print_status "Testing frontend accessibility..."
    
    if curl -f http://localhost:3000 >/dev/null 2>&1; then
        print_success "Frontend is accessible"
        return 0
    else
        print_warning "Frontend may not be ready yet"
        return 1
    fi
}

# Test file upload (mock)
test_upload() {
    print_status "Testing file upload endpoint..."
    
    # Create a mock image file
    echo "fake image content" > /tmp/test_image.png
    
    response=$(curl -s -X POST \
        -F "file=@/tmp/test_image.png" \
        http://localhost:8000/api/upload)
    
    if echo "$response" | grep -q "study_id"; then
        print_success "File upload test passed"
        STUDY_ID=$(echo "$response" | grep -o '"study_id":"[^"]*"' | cut -d'"' -f4)
        echo "Study ID: $STUDY_ID"
        return 0
    else
        print_error "File upload test failed"
        return 1
    fi
}

# Test AI analysis
test_analysis() {
    print_status "Testing AI analysis..."
    
    if [ -z "$STUDY_ID" ]; then
        print_warning "No study ID available for analysis test"
        return 1
    fi
    
    response=$(curl -s -X POST \
        http://localhost:8000/api/inference/$STUDY_ID)
    
    if echo "$response" | grep -q "analysis"; then
        print_success "AI analysis test passed"
        return 0
    else
        print_error "AI analysis test failed"
        return 1
    fi
}

# Main test execution
main() {
    echo "=========================================="
    echo "AI Medical Imaging - Starter Kit Tests"
    echo "=========================================="
    echo ""
    
    local tests_passed=0
    local tests_total=0
    
    # Run tests
    test_backend_health && ((tests_passed++))
    ((tests_total++))
    
    test_detailed_health && ((tests_passed++))
    ((tests_total++))
    
    test_model_info && ((tests_passed++))
    ((tests_total++))
    
    test_frontend && ((tests_passed++))
    ((tests_total++))
    
    test_upload && ((tests_passed++))
    ((tests_total++))
    
    test_analysis && ((tests_passed++))
    ((tests_total++))
    
    # Summary
    echo ""
    echo "=========================================="
    echo "Test Results: $tests_passed/$tests_total tests passed"
    echo "=========================================="
    
    if [ $tests_passed -eq $tests_total ]; then
        print_success "All tests passed! 🎉"
        exit 0
    else
        print_warning "Some tests failed. Check the logs above."
        exit 1
    fi
}

# Run main function
main "$@" 