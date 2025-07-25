from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.orm import Session
import os
import uuid
import logging
from datetime import datetime
from typing import List
import shutil

from backend.storage.database import get_db, save_study

logger = logging.getLogger(__name__)

router = APIRouter()

# Allowed file types
ALLOWED_EXTENSIONS = {'.png', '.jpg', '.jpeg', '.dcm', '.dicom'}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB

@router.post("/upload")
async def upload_mammogram(
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """Upload a mammogram image for analysis"""
    logger.info(f"📤 Upload request received for file: {file.filename}")
    
    try:
        # Validate file type
        file_extension = os.path.splitext(file.filename)[1].lower()
        if file_extension not in ALLOWED_EXTENSIONS:
            logger.warning(f"❌ Invalid file type: {file_extension} for file: {file.filename}")
            raise HTTPException(
                status_code=400,
                detail=f"Invalid file type. Allowed: {', '.join(ALLOWED_EXTENSIONS)}"
            )
        
        logger.info(f"✅ File type validated: {file_extension}")
        
        # Validate file size
        file.file.seek(0, 2)  # Seek to end
        file_size = file.file.tell()
        file.file.seek(0)  # Reset to beginning
        
        if file_size > MAX_FILE_SIZE:
            logger.warning(f"❌ File too large: {file_size} bytes for file: {file.filename}")
            raise HTTPException(
                status_code=400,
                detail=f"File too large. Maximum size: {MAX_FILE_SIZE // (1024*1024)}MB"
            )
        
        logger.info(f"✅ File size validated: {file_size} bytes")
        
        # Generate unique study ID
        study_id = str(uuid.uuid4())
        logger.info(f"🆔 Generated study ID: {study_id}")
        
        # Create uploads directory if it doesn't exist
        os.makedirs("uploads", exist_ok=True)
        
        # Save file
        file_path = f"uploads/{study_id}_{file.filename}"
        logger.info(f"💾 Saving file to: {file_path}")
        
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        logger.info(f"✅ File saved successfully: {file_path}")
        
        # Save to database
        logger.info(f"💾 Saving study metadata to database")
        study_data = await save_study(
            db=db,
            study_id=study_id,
            filename=file.filename,
            file_path=file_path,
            content_type=file.content_type,
            file_size=file_size
        )
        
        logger.info(f"✅ Study saved to database: {study_id}")
        
        return {
            "study_id": study_id,
            "filename": file.filename,
            "file_size": file_size,
            "content_type": file.content_type,
            "status": "uploaded",
            "message": "File uploaded successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Upload failed for file {file.filename}: {str(e)}")
        raise HTTPException(status_code=500, detail="Upload failed")

@router.get("/upload/{study_id}")
async def get_upload_status(
    study_id: str,
    db: Session = Depends(get_db)
):
    """Get upload status for a study"""
    logger.info(f"📋 Status request for study: {study_id}")
    
    try:
        study = await get_study(db, study_id)
        if not study:
            logger.warning(f"❌ Study not found: {study_id}")
            raise HTTPException(status_code=404, detail="Study not found")
        
        logger.info(f"✅ Study status retrieved: {study_id}")
        return study
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to get status for study {study_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get status") 