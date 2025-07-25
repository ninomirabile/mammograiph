from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
import os
import logging
from typing import AsyncGenerator
from .models import Base

logger = logging.getLogger(__name__)

# Database configuration
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./medical_ai.db")
ASYNC_DATABASE_URL = os.getenv("ASYNC_DATABASE_URL", "sqlite+aiosqlite:///./medical_ai.db")

# Create engines
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
)

# Session factories
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db() -> Session:
    """Get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def init_db():
    """Initialize database tables"""
    try:
        # Create tables
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables created successfully")
        
        # Create uploads directory if it doesn't exist
        os.makedirs("uploads", exist_ok=True)
        logger.info("Uploads directory created successfully")
        
    except Exception as e:
        logger.error(f"Database initialization failed: {str(e)}")
        raise

async def save_study(
    db: Session,
    study_id: str,
    filename: str,
    file_path: str,
    content_type: str,
    file_size: int,
    prediction: str = None,
    confidence: float = None,
    processing_time: float = None,
    regions: list = None,
    model_version: str = None,
    image_quality: str = None
) -> dict:
    """Save study to database"""
    try:
        from .models import Study
        
        study = Study(
            study_id=study_id,
            filename=filename,
            file_path=file_path,
            content_type=content_type,
            file_size=file_size,
            prediction=prediction,
            confidence=confidence,
            processing_time=processing_time,
            regions=regions,
            model_version=model_version,
            image_quality=image_quality
        )
        
        db.add(study)
        db.commit()
        db.refresh(study)
        
        logger.info(f"Study saved successfully: {study_id}")
        return study.to_dict()
        
    except Exception as e:
        db.rollback()
        logger.error(f"Failed to save study: {str(e)}")
        raise

async def get_study(db: Session, study_id: str) -> dict:
    """Get study by ID"""
    try:
        from .models import Study
        
        study = db.query(Study).filter(Study.study_id == study_id).first()
        if study:
            return study.to_dict()
        return None
        
    except Exception as e:
        logger.error(f"Failed to get study: {str(e)}")
        raise

async def get_all_studies(db: Session, limit: int = 100) -> list:
    """Get all studies with limit"""
    try:
        from .models import Study
        
        studies = db.query(Study).order_by(Study.created_at.desc()).limit(limit).all()
        return [study.to_dict() for study in studies]
        
    except Exception as e:
        logger.error(f"Failed to get studies: {str(e)}")
        raise 