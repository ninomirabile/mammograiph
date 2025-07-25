from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
import logging
import time
from typing import Dict, Any

from backend.ai.mock import MockMammographyClassifier
from backend.storage.database import get_db, get_study, update_study_analysis

logger = logging.getLogger(__name__)

router = APIRouter()

# Initialize AI classifier
classifier = MockMammographyClassifier()

@router.post("/inference/{study_id}")
async def analyze_mammogram(
    study_id: str,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Analyze a mammogram using AI"""
    logger.info(f"🤖 AI analysis request for study: {study_id}")
    
    try:
        # Get study from database
        logger.info(f"📋 Retrieving study data: {study_id}")
        study = await get_study(db, study_id)
        
        if not study:
            logger.warning(f"❌ Study not found: {study_id}")
            raise HTTPException(status_code=404, detail="Study not found")
        
        logger.info(f"✅ Study found: {study_id} - {study.get('filename', 'Unknown')}")
        
        # Check if already analyzed
        if study.get("prediction"):
            logger.info(f"⚠️ Study already analyzed: {study_id}")
            return {
                "study_id": study_id,
                "status": "already_analyzed",
                "prediction": study.get("prediction"),
                "confidence": study.get("confidence"),
                "message": "Study already analyzed"
            }
        
        # Perform AI analysis
        logger.info(f"🧠 Starting AI analysis for study: {study_id}")
        start_time = time.time()
        
        try:
            # Simulate AI processing
            result = classifier.classify(study.get("file_path", ""))
            processing_time = time.time() - start_time
            
            logger.info(f"✅ AI analysis completed in {processing_time:.3f}s")
            logger.info(f"📊 Results - Prediction: {result['prediction']}, Confidence: {result['confidence']:.2f}")
            
        except Exception as ai_error:
            logger.error(f"❌ AI analysis failed for study {study_id}: {str(ai_error)}")
            raise HTTPException(status_code=500, detail="AI analysis failed")
        
        # Update database with results
        logger.info(f"💾 Updating database with AI results: {study_id}")
        try:
            updated_study = await update_study_analysis(
                db=db,
                study_id=study_id,
                prediction=result.get("prediction"),
                confidence=result.get("confidence"),
                processing_time=processing_time,
                regions=result.get("regions", []),
                model_version=result.get("model_version"),
                image_quality=result.get("image_quality")
            )
            logger.info(f"✅ Database updated successfully: {study_id}")
            
        except Exception as db_error:
            logger.error(f"❌ Failed to update database for study {study_id}: {str(db_error)}")
            # Continue without database update for demo
            updated_study = study
        
        return {
            "study_id": study_id,
            "status": "analyzed",
            "prediction": result["prediction"],
            "confidence": result["confidence"],
            "processing_time": processing_time,
            "regions": result["regions"],
            "model_version": result["model_version"],
            "image_quality": result.get("image_quality"),
            "message": "Analysis completed successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Unexpected error during analysis for study {study_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Analysis failed")

@router.get("/inference/{study_id}")
async def get_analysis_result(
    study_id: str,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Get analysis results for a study"""
    logger.info(f"📋 Analysis results request for study: {study_id}")
    
    try:
        study = await get_study(db, study_id)
        
        if not study:
            logger.warning(f"❌ Study not found: {study_id}")
            raise HTTPException(status_code=404, detail="Study not found")
        
        if not study.get("prediction"):
            logger.info(f"⚠️ Study not yet analyzed: {study_id}")
            return {
                "study_id": study_id,
                "status": "not_analyzed",
                "message": "Study not yet analyzed. Use POST to trigger analysis."
            }
        
        logger.info(f"✅ Analysis results retrieved: {study_id}")
        return {
            "study_id": study_id,
            "status": "analyzed",
            "prediction": study.get("prediction"),
            "confidence": study.get("confidence"),
            "processing_time": study.get("processing_time"),
            "regions": study.get("regions"),
            "model_version": study.get("model_version"),
            "image_quality": study.get("image_quality"),
            "analysis_date": study.get("updated_at")
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to get analysis results for study {study_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get results")

@router.get("/inference/model/info")
async def get_model_info() -> Dict[str, Any]:
    """Get AI model information"""
    logger.info("📊 Model info request")
    
    try:
        model_info = classifier.get_model_info()
        logger.info(f"✅ Model info retrieved: {model_info['name']} v{model_info['version']}")
        return model_info
        
    except Exception as e:
        logger.error(f"❌ Failed to get model info: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get model info") 