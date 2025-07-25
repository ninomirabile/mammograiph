from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import Dict, Any
import os
import logging
from backend.ai.mock import MockMammographyClassifier
from backend.storage.database import get_db, get_study, save_study

logger = logging.getLogger(__name__)
router = APIRouter()

@router.post("/inference/{study_id}")
async def analyze_mammogram(
    study_id: str,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Analyze mammogram with AI"""
    try:
        # Get study from database
        study = await get_study(db, study_id)
        if not study:
            raise HTTPException(status_code=404, detail="Study not found")
        
        # Check if file exists
        file_path = study.get("file_path")
        if not file_path or not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="Image file not found")
        
        # Run AI analysis
        try:
            classifier = MockMammographyClassifier()
            result = classifier.classify(file_path)
            
            # Update study with AI results
            updated_study = await save_study(
                db=db,
                study_id=study_id,
                filename=study.get("filename"),
                file_path=file_path,
                content_type=study.get("content_type"),
                file_size=study.get("file_size"),
                prediction=result["prediction"],
                confidence=result["confidence"],
                processing_time=result["processing_time"],
                regions=result["regions"],
                model_version=result["metadata"]["model_version"],
                image_quality=result["metadata"]["image_quality"]
            )
            
            logger.info(f"AI analysis completed for study: {study_id}")
            
            return {
                "study_id": study_id,
                "status": "completed",
                "analysis": result,
                "message": "AI analysis completed successfully"
            }
            
        except Exception as e:
            logger.error(f"AI analysis failed for study {study_id}: {str(e)}")
            raise HTTPException(status_code=500, detail="AI analysis failed")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error during analysis: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error during analysis")

@router.get("/inference/{study_id}")
async def get_analysis_result(
    study_id: str,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Get AI analysis result for a study"""
    try:
        study = await get_study(db, study_id)
        if not study:
            raise HTTPException(status_code=404, detail="Study not found")
        
        # Check if analysis exists
        if not study.get("prediction"):
            return {
                "study_id": study_id,
                "status": "pending",
                "message": "Analysis not yet performed. Use POST to start analysis."
            }
        
        # Return analysis results
        return {
            "study_id": study_id,
            "status": "completed",
            "analysis": {
                "prediction": study.get("prediction"),
                "confidence": study.get("confidence"),
                "processing_time": study.get("processing_time"),
                "regions": study.get("regions"),
                "metadata": {
                    "model_version": study.get("model_version"),
                    "image_quality": study.get("image_quality"),
                    "processing_date": study.get("processing_date")
                }
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get analysis result: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/inference/model/info")
async def get_model_info() -> Dict[str, Any]:
    """Get AI model information"""
    try:
        classifier = MockMammographyClassifier()
        return {
            "model_info": classifier.get_model_info(),
            "status": "available"
        }
    except Exception as e:
        logger.error(f"Failed to get model info: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get model information") 