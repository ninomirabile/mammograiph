#!/bin/bash

# Comprehensive Test Script for AI Medical Imaging - Starter Kit
# Tests all endpoints, uploads, and AI analysis workflow

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="http://localhost:8000"
FRONTEND_URL="http://localhost:3000"
API_BASE="$BACKEND_URL/api"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_info "Running test: $test_name"
    
    if eval "$test_command"; then
        log_success "$test_name passed"
    else
        log_error "$test_name failed"
    fi
    echo
}

# Wait for services to be ready
wait_for_services() {
    log_info "Waiting for services to be ready..."
    
    # Wait for backend
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$BACKEND_URL/api/health" > /dev/null 2>&1; then
            log_success "Backend is ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "Backend failed to start within $max_attempts seconds"
            exit 1
        fi
        
        log_info "Waiting for backend... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    # Wait for frontend
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$FRONTEND_URL" > /dev/null 2>&1; then
            log_success "Frontend is ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "Frontend failed to start within $max_attempts seconds"
            exit 1
        fi
        
        log_info "Waiting for frontend... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
}

# Create test images
create_test_images() {
    log_info "Creating test images..."
    
    # Create uploads directory
    mkdir -p uploads
    
    # Create a simple test PNG image (1x1 pixel)
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > uploads/test_image.png
    
    # Create a simple test JPEG image
    echo "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/8A" | base64 -d > uploads/test_image.jpg
    
    log_success "Test images created"
}

# Test functions
test_health_endpoints() {
    log_info "Testing health endpoints..."
    
    # Test basic health
    run_test "Basic Health Check" "curl -s '$API_BASE/health' | jq -e '.status == \"healthy\"'"
    
    # Test detailed health
    run_test "Detailed Health Check" "curl -s '$API_BASE/health/detailed' | jq -e '.status == \"healthy\"'"
    
    # Test model info
    run_test "Model Info" "curl -s '$API_BASE/inference/model/info' | jq -e '.name'"
}

test_upload_endpoints() {
    log_info "Testing upload endpoints..."
    
    # Test upload with PNG
    local upload_response=$(curl -s -X POST -F "file=@uploads/test_image.png" "$API_BASE/upload")
    local study_id=$(echo "$upload_response" | jq -r '.study_id')
    
    if [ "$study_id" != "null" ] && [ "$study_id" != "" ]; then
        log_success "PNG upload successful - Study ID: $study_id"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        
        # Test get upload status
        run_test "Get Upload Status" "curl -s '$API_BASE/upload/$study_id' | jq -e '.study_id == \"$study_id\"'"
        
        # Store study ID for later tests
        echo "$study_id" > /tmp/test_study_id.txt
    else
        log_error "PNG upload failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    # Test upload with JPEG
    local upload_response2=$(curl -s -X POST -F "file=@uploads/test_image.jpg" "$API_BASE/upload")
    local study_id2=$(echo "$upload_response2" | jq -r '.study_id')
    
    if [ "$study_id2" != "null" ] && [ "$study_id2" != "" ]; then
        log_success "JPEG upload successful - Study ID: $study_id2"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "JPEG upload failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

test_inference_endpoints() {
    log_info "Testing inference endpoints..."
    
    # Get study ID from previous test
    if [ -f /tmp/test_study_id.txt ]; then
        local study_id=$(cat /tmp/test_study_id.txt)
        
        # Test AI analysis
        local analysis_response=$(curl -s -X POST "$API_BASE/inference/$study_id")
        local status=$(echo "$analysis_response" | jq -r '.status')
        
        if [ "$status" = "analyzed" ]; then
            log_success "AI analysis successful"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            
            # Test get analysis results
            run_test "Get Analysis Results" "curl -s '$API_BASE/inference/$study_id' | jq -e '.status == \"analyzed\"'"
            
        else
            log_error "AI analysis failed - Status: $status"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        log_warning "No study ID available for inference test"
    fi
}

test_error_handling() {
    log_info "Testing error handling..."
    
    # Test invalid study ID
    run_test "Invalid Study ID" "curl -s -w '%{http_code}' '$API_BASE/upload/invalid-id' | tail -1 | grep -q '404'"
    
    # Test invalid file upload (text file)
    echo "This is not an image" > uploads/invalid.txt
    run_test "Invalid File Upload" "curl -s -X POST -F 'file=@uploads/invalid.txt' '$API_BASE/upload' | jq -e '.detail'"
}

test_frontend_accessibility() {
    log_info "Testing frontend accessibility..."
    
    # Test frontend main page
    run_test "Frontend Main Page" "curl -s '$FRONTEND_URL' | grep -q 'AI Medical Imaging'"
    
    # Test frontend assets
    run_test "Frontend Assets" "curl -s -I '$FRONTEND_URL' | grep -q '200 OK'"
}

# Main test execution
main() {
    echo "=========================================="
    echo "AI Medical Imaging - Comprehensive Tests"
    echo "=========================================="
    echo
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install jq to run tests."
        exit 1
    fi
    
    # Wait for services
    wait_for_services
    
    # Create test data
    create_test_images
    
    # Run tests
    test_health_endpoints
    test_upload_endpoints
    test_inference_endpoints
    test_error_handling
    test_frontend_accessibility
    
    # Print summary
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All tests passed! 🎉${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed! ❌${NC}"
        exit 1
    fi
}

# Run main function
main "$@" 