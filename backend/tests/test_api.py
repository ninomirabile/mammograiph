import pytest
from fastapi.testclient import TestClient
from main import app
import os

client = TestClient(app)

def test_health_check():
    """Test basic health check endpoint"""
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "AI Medical Imaging - Starter Kit"

def test_detailed_health_check():
    """Test detailed health check endpoint"""
    response = client.get("/api/health/detailed")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "components" in data

def test_model_info():
    """Test model info endpoint"""
    response = client.get("/api/inference/model/info")
    assert response.status_code == 200
    data = response.json()
    assert "model_info" in data
    assert "status" in data

def test_upload_invalid_file():
    """Test upload with invalid file"""
    response = client.post(
        "/api/upload",
        files={"file": ("test.txt", b"invalid content", "text/plain")}
    )
    assert response.status_code == 400

def test_upload_valid_file():
    """Test upload with valid file"""
    # Create a mock image file
    mock_image_content = b"fake image content"
    response = client.post(
        "/api/upload",
        files={"file": ("test.png", mock_image_content, "image/png")}
    )
    assert response.status_code == 200
    data = response.json()
    assert "study_id" in data
    assert data["status"] == "uploaded"

def test_analysis_nonexistent_study():
    """Test analysis with non-existent study ID"""
    response = client.post("/api/inference/nonexistent-id")
    assert response.status_code == 404

def test_get_analysis_nonexistent_study():
    """Test get analysis with non-existent study ID"""
    response = client.get("/api/inference/nonexistent-id")
    assert response.status_code == 404 