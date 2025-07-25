from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import Dict, Any
import os
import uuid
import logging
from datetime import datetime
from storage.database import get_db, save_study

logger = logging.getLogger(__name__)
router = APIRouter()

# Supported file types
SUPPORTED_TYPES = {
    'image/png': '.png',
    'image/jpeg': '.jpg',
    'image/jpg': '.jpg',
    'application/dicom': '.dcm'
}

# File size limit (50MB)
MAX_FILE_SIZE = 50 * 1024 * 1024

@router.post("/upload")
async def upload_mammogram(
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Upload mammogram for AI analysis"""
    try:
        # Validate file type
        if file.content_type not in SUPPORTED_TYPES:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported file type. Supported types: {list(SUPPORTED_TYPES.keys())}"
            )
        
        # Validate file size
        if file.size > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=400,
                detail=f"File too large. Maximum size is {MAX_FILE_SIZE // (1024*1024)}MB"
            )
        
        # Generate unique study ID
        study_id = str(uuid.uuid4())
        file_extension = SUPPORTED_TYPES[file.content_type]
        filename = f"{study_id}{file_extension}"
        
        # Create uploads directory if it doesn't exist
        upload_dir = "uploads"
        os.makedirs(upload_dir, exist_ok=True)
        
        # Save file
        file_path = os.path.join(upload_dir, filename)
        try:
            with open(file_path, "wb") as buffer:
                content = await file.read()
                buffer.write(content)
        except Exception as e:
            logger.error(f"Failed to save file: {str(e)}")
            raise HTTPException(status_code=500, detail="Failed to save uploaded file")
        
        # Save to database
        try:
            study_data = await save_study(
                db=db,
                study_id=study_id,
                filename=file.filename,
                file_path=file_path,
                content_type=file.content_type,
                file_size=file.size
            )
        except Exception as e:
            logger.error(f"Failed to save study to database: {str(e)}")
            # Continue without database save for demo
            study_data = {
                "study_id": study_id,
                "filename": file.filename,
                "status": "uploaded"
            }
        
        logger.info(f"File uploaded successfully: {study_id}")
        
        return {
            "study_id": study_id,
            "filename": file.filename,
            "file_size": file.size,
            "content_type": file.content_type,
            "upload_time": datetime.now().isoformat(),
            "status": "uploaded",
            "message": "File uploaded successfully. Use study_id for AI analysis."
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error during upload: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error during upload")

@router.get("/upload/{study_id}")
async def get_upload_status(
    study_id: str,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Get upload status for a study"""
    try:
        study = await get_study(db, study_id)
        if not study:
            raise HTTPException(status_code=404, detail="Study not found")
        
        return {
            "study_id": study_id,
            "status": "uploaded" if study.get("file_path") else "processing",
            "filename": study.get("filename"),
            "upload_time": study.get("created_at"),
            "has_analysis": study.get("prediction") is not None
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get upload status: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error") 