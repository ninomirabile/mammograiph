from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import logging
import logging.handlers
import os
import sys
from datetime import datetime

# Import routers
from backend.api import upload, inference, health
from backend.storage.database import init_db

# Configure comprehensive logging
def setup_logging():
    """Setup comprehensive logging configuration"""
    # Create logs directory if it doesn't exist
    os.makedirs("logs", exist_ok=True)
    
    # Configure root logger
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    # Clear existing handlers
    logger.handlers.clear()
    
    # Console handler with colored output
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)
    
    # File handler for all logs
    file_handler = logging.handlers.RotatingFileHandler(
        'logs/app.log',
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5
    )
    file_handler.setLevel(logging.DEBUG)
    file_formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    file_handler.setFormatter(file_formatter)
    logger.addHandler(file_handler)
    
    # Error file handler
    error_handler = logging.handlers.RotatingFileHandler(
        'logs/error.log',
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5
    )
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(file_formatter)
    logger.addHandler(error_handler)
    
    # API specific logger
    api_logger = logging.getLogger('api')
    api_logger.setLevel(logging.INFO)
    
    return logger

# Setup logging
logger = setup_logging()

# Create FastAPI app
app = FastAPI(
    title="AI Medical Imaging - Starter Kit",
    description="AI-assisted mammography screening demo with scalable architecture",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Include routers
app.include_router(health.router, prefix="/api", tags=["Health"])
app.include_router(upload.router, prefix="/api", tags=["Upload"])
app.include_router(inference.router, prefix="/api", tags=["Inference"])

# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all incoming requests"""
    start_time = datetime.now()
    
    # Log request details
    logger.info(f"Request: {request.method} {request.url.path} - Client: {request.client.host if request.client else 'unknown'}")
    
    # Process request
    response = await call_next(request)
    
    # Log response details
    process_time = (datetime.now() - start_time).total_seconds()
    logger.info(f"Response: {response.status_code} - Duration: {process_time:.3f}s")
    
    return response

@app.on_event("startup")
async def startup_event():
    """Application startup event"""
    logger.info("🚀 Starting AI Medical Imaging application...")
    logger.info(f"Environment: {os.getenv('ENVIRONMENT', 'development')}")
    logger.info(f"Database URL: {os.getenv('DATABASE_URL', 'sqlite:///:memory:')}")
    
    try:
        await init_db()
        logger.info("✅ Database initialized successfully")
    except Exception as e:
        logger.error(f"❌ Database initialization failed: {str(e)}")
        raise

@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown event"""
    logger.info("🛑 Shutting down AI Medical Imaging application...")

# Root endpoint
@app.get("/")
async def root():
    """Root endpoint with basic info"""
    logger.info("Root endpoint accessed")
    return {
        "message": "AI Medical Imaging - Starter Kit",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs",
        "health": "/api/health"
    } 