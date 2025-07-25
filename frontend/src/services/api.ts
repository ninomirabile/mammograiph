import axios from 'axios';
import { 
  UploadResponse, 
  AnalysisResponse, 
  HealthResponse, 
  ModelInfo 
} from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || '/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Health check
export const checkHealth = async (): Promise<HealthResponse> => {
  const response = await api.get('/health');
  return response.data;
};

export const checkDetailedHealth = async (): Promise<HealthResponse> => {
  const response = await api.get('/health/detailed');
  return response.data;
};

// Upload
export const uploadImage = async (file: File): Promise<UploadResponse> => {
  const formData = new FormData();
  formData.append('file', file);
  
  const response = await api.post('/upload', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  
  return response.data;
};

export const getUploadStatus = async (studyId: string): Promise<UploadResponse> => {
  const response = await api.get(`/upload/${studyId}`);
  return response.data;
};

// Analysis
export const analyzeImage = async (studyId: string): Promise<AnalysisResponse> => {
  const response = await api.post(`/inference/${studyId}`);
  return response.data;
};

export const getAnalysisResult = async (studyId: string): Promise<AnalysisResponse> => {
  const response = await api.get(`/inference/${studyId}`);
  return response.data;
};

export const getModelInfo = async (): Promise<{ model_info: ModelInfo; status: string }> => {
  const response = await api.get('/inference/model/info');
  return response.data;
};

// Error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error);
    
    if (error.response) {
      // Server responded with error status
      const message = error.response.data?.detail || error.response.data?.message || 'An error occurred';
      throw new Error(message);
    } else if (error.request) {
      // Request was made but no response received
      throw new Error('No response from server. Please check your connection.');
    } else {
      // Something else happened
      throw new Error('An unexpected error occurred.');
    }
  }
); 