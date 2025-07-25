export interface Study {
  id: number;
  study_id: string;
  filename: string;
  file_path: string;
  content_type: string;
  file_size: number;
  prediction?: string;
  confidence?: number;
  processing_time?: number;
  regions?: Region[];
  model_version?: string;
  image_quality?: string;
  processing_date?: string;
  created_at?: string;
}

export interface Region {
  id: string;
  x: number;
  y: number;
  width: number;
  height: number;
  confidence: number;
  type: string;
  severity?: string;
  description?: string;
}

export interface AnalysisResult {
  prediction: string;
  confidence: number;
  processing_time: number;
  regions: Region[];
  metadata: {
    model_version: string;
    processing_date: string;
    image_quality: string;
    lesion_count: number;
  };
}

export interface UploadResponse {
  study_id: string;
  filename: string;
  file_size: number;
  content_type: string;
  upload_time: string;
  status: string;
  message: string;
}

export interface AnalysisResponse {
  study_id: string;
  status: string;
  analysis?: AnalysisResult;
  message?: string;
}

export interface ModelInfo {
  model_version: string;
  model_type: string;
  supported_formats: string[];
  lesion_types: string[];
  description: string;
}

export interface HealthResponse {
  status: string;
  service: string;
  version: string;
  components?: {
    database: string;
    ai_model: string;
  };
  ai_model_info?: ModelInfo;
} 