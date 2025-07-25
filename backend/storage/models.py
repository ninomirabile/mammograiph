from sqlalchemy import Column, Integer, String, DateTime, Float, Text, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
from datetime import datetime
from typing import Optional, Dict, Any

Base = declarative_base()

class Study(Base):
    """Database model for medical imaging studies"""
    __tablename__ = "studies"
    
    id = Column(Integer, primary_key=True, index=True)
    study_id = Column(String(50), unique=True, index=True, nullable=False)
    filename = Column(String(255), nullable=False)
    file_path = Column(String(500), nullable=False)
    content_type = Column(String(100), nullable=False)
    file_size = Column(Integer, nullable=False)
    
    # AI Results
    prediction = Column(String(50), nullable=True)  # normal, suspicious
    confidence = Column(Float, nullable=True)
    processing_time = Column(Float, nullable=True)
    regions = Column(JSON, nullable=True)  # List of regions of interest
    
    # Metadata
    model_version = Column(String(50), nullable=True)
    image_quality = Column(String(50), nullable=True)
    processing_date = Column(DateTime, default=func.now())
    
    # Timestamps
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert model to dictionary"""
        return {
            "id": self.id,
            "study_id": self.study_id,
            "filename": self.filename,
            "prediction": self.prediction,
            "confidence": self.confidence,
            "processing_time": self.processing_time,
            "regions": self.regions,
            "model_version": self.model_version,
            "image_quality": self.image_quality,
            "processing_date": self.processing_date.isoformat() if self.processing_date else None,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class ProcessingLog(Base):
    """Database model for processing logs"""
    __tablename__ = "processing_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    study_id = Column(String(50), index=True, nullable=False)
    level = Column(String(20), nullable=False)  # INFO, WARNING, ERROR
    message = Column(Text, nullable=False)
    timestamp = Column(DateTime, default=func.now())
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert model to dictionary"""
        return {
            "id": self.id,
            "study_id": self.study_id,
            "level": self.level,
            "message": self.message,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None
        } 