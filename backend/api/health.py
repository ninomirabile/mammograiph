from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from storage.database import get_db
from ai.mock import MockMammographyClassifier
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/health")
async def health_check():
    """Basic health check endpoint"""
    return {
        "status": "healthy",
        "service": "AI Medical Imaging - Starter Kit",
        "version": "1.0.0"
    }

@router.get("/health/detailed")
async def detailed_health_check(db: Session = Depends(get_db)):
    """Detailed health check with database and AI model status"""
    try:
        # Test database connection
        db.execute("SELECT 1")
        db_status = "healthy"
    except Exception as e:
        logger.error(f"Database health check failed: {str(e)}")
        db_status = "unhealthy"
    
    # Test AI model
    try:
        classifier = MockMammographyClassifier()
        model_info = classifier.get_model_info()
        ai_status = "healthy"
    except Exception as e:
        logger.error(f"AI model health check failed: {str(e)}")
        ai_status = "unhealthy"
        model_info = None
    
    return {
        "status": "healthy" if db_status == "healthy" and ai_status == "healthy" else "degraded",
        "components": {
            "database": db_status,
            "ai_model": ai_status
        },
        "ai_model_info": model_info,
        "service": "AI Medical Imaging - Starter Kit",
        "version": "1.0.0"
    } 