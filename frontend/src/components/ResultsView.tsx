import React, { useState, useEffect } from 'react';
import { analyzeImage, getAnalysisResult } from '../services/api';
import { AnalysisResult } from '../types';

interface ResultsViewProps {
  studyId: string;
  onAnalysisComplete: (result: AnalysisResult) => void;
  onError: (error: string) => void;
  isLoading: boolean;
  setIsLoading: (loading: boolean) => void;
}

export const ResultsView: React.FC<ResultsViewProps> = ({
  studyId,
  onAnalysisComplete,
  onError,
  isLoading,
  setIsLoading
}) => {
  const [result, setResult] = useState<AnalysisResult | null>(null);
  const [analysisStatus, setAnalysisStatus] = useState<'pending' | 'analyzing' | 'completed' | 'error'>('pending');

  useEffect(() => {
    checkExistingAnalysis();
  }, [studyId]);

  const checkExistingAnalysis = async () => {
    try {
      const response = await getAnalysisResult(studyId);
      
      // Backend returns analysis data directly
      if (response.status === 'analyzed' || response.status === 'completed') {
        const analysisResult: AnalysisResult = {
          prediction: response.prediction || 'unknown',
          confidence: response.confidence || 0,
          processing_time: response.processing_time || 0,
          regions: response.regions || [],
          metadata: {
            model_version: response.model_version || 'unknown',
            processing_date: response.analysis_date || new Date().toISOString(),
            image_quality: response.image_quality || 'unknown',
            lesion_count: response.regions?.length || 0
          }
        };
        
        setResult(analysisResult);
        setAnalysisStatus('completed');
        onAnalysisComplete(analysisResult);
      } else {
        setAnalysisStatus('pending');
      }
    } catch (error) {
      console.error('Failed to check analysis status:', error);
      setAnalysisStatus('pending');
    }
  };

  const startAnalysis = async () => {
    setIsLoading(true);
    setAnalysisStatus('analyzing');

    try {
      const response = await analyzeImage(studyId);
      
      // Backend returns analysis data directly
      if (response.status === 'analyzed' || response.status === 'completed') {
        const analysisResult: AnalysisResult = {
          prediction: response.prediction || 'unknown',
          confidence: response.confidence || 0,
          processing_time: response.processing_time || 0,
          regions: response.regions || [],
          metadata: {
            model_version: response.model_version || 'unknown',
            processing_date: response.analysis_date || new Date().toISOString(),
            image_quality: response.image_quality || 'unknown',
            lesion_count: response.regions?.length || 0
          }
        };
        
        setResult(analysisResult);
        setAnalysisStatus('completed');
        onAnalysisComplete(analysisResult);
      } else {
        throw new Error(response.message || 'Analysis failed');
      }
    } catch (error) {
      setAnalysisStatus('error');
      onError(error instanceof Error ? error.message : 'Analysis failed');
    } finally {
      setIsLoading(false);
    }
  };

  const getPredictionColor = (prediction: string) => {
    return prediction === 'suspicious' ? 'text-red-600' : 'text-green-600';
  };

  const getPredictionIcon = (prediction: string) => {
    return prediction === 'suspicious' ? (
      <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
      </svg>
    ) : (
      <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
      </svg>
    );
  };

  if (analysisStatus === 'pending') {
    return (
      <div className="text-center py-8">
        <div className="mb-4">
          <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">Ready for Analysis</h3>
        <p className="text-gray-500 mb-4">Click the button below to start AI analysis</p>
        <button
          onClick={startAnalysis}
          disabled={isLoading}
          className="btn-primary"
        >
          Start AI Analysis
        </button>
      </div>
    );
  }

  if (analysisStatus === 'analyzing') {
    return (
      <div className="text-center py-8">
        <div className="mb-4">
          <div className="w-16 h-16 mx-auto bg-primary-100 rounded-full flex items-center justify-center">
            <svg className="w-8 h-8 text-primary-600 animate-spin" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </div>
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">Analyzing Mammogram</h3>
        <p className="text-gray-500">AI is processing your image...</p>
      </div>
    );
  }

  if (analysisStatus === 'error') {
    return (
      <div className="text-center py-8">
        <div className="mb-4">
          <svg className="mx-auto h-12 w-12 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h3 className="text-lg font-medium text-gray-900 mb-2">Analysis Failed</h3>
        <p className="text-gray-500 mb-4">There was an error during analysis</p>
        <button
          onClick={startAnalysis}
          disabled={isLoading}
          className="btn-primary"
        >
          Retry Analysis
        </button>
      </div>
    );
  }

  if (!result) {
    return null;
  }

  return (
    <div className="space-y-6">
      {/* Main Result */}
      <div className="bg-gray-50 rounded-lg p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-gray-900">AI Analysis Result</h3>
          <div className={`flex items-center space-x-2 ${getPredictionColor(result.prediction)}`}>
            {getPredictionIcon(result.prediction)}
            <span className="text-lg font-semibold capitalize">{result.prediction}</span>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <p className="text-sm text-gray-600">Confidence</p>
            <p className="text-2xl font-bold text-gray-900">
              {(result.confidence * 100).toFixed(1)}%
            </p>
          </div>
          <div>
            <p className="text-sm text-gray-600">Processing Time</p>
            <p className="text-2xl font-bold text-gray-900">
              {result.processing_time}s
            </p>
          </div>
        </div>
      </div>

      {/* Regions of Interest */}
      {result.regions && result.regions.length > 0 && (
        <div>
          <h4 className="text-md font-semibold text-gray-900 mb-3">Regions of Interest</h4>
          <div className="space-y-3">
            {result.regions.map((region, index) => (
              <div key={region.id} className="bg-white border border-gray-200 rounded-lg p-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-gray-900">
                    Region {index + 1}
                  </span>
                  <span className="text-sm text-gray-500">
                    {(region.confidence * 100).toFixed(1)}% confidence
                  </span>
                </div>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="text-gray-600">Type:</span>
                    <span className="ml-2 font-medium capitalize">{region.type}</span>
                  </div>
                  <div>
                    <span className="text-gray-600">Severity:</span>
                    <span className="ml-2 font-medium capitalize">{region.severity}</span>
                  </div>
                </div>
                {region.description && (
                  <p className="text-sm text-gray-600 mt-2">{region.description}</p>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Metadata */}
      <div>
        <h4 className="text-md font-semibold text-gray-900 mb-3">Analysis Details</h4>
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span className="text-gray-600">Model Version:</span>
              <span className="ml-2 font-medium">{result.metadata.model_version}</span>
            </div>
            <div>
              <span className="text-gray-600">Image Quality:</span>
              <span className="ml-2 font-medium capitalize">{result.metadata.image_quality}</span>
            </div>
            <div>
              <span className="text-gray-600">Lesion Count:</span>
              <span className="ml-2 font-medium">{result.metadata.lesion_count}</span>
            </div>
            <div>
              <span className="text-gray-600">Processing Date:</span>
              <span className="ml-2 font-medium">
                {new Date(result.metadata.processing_date).toLocaleString()}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Disclaimer */}
      <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
        <div className="flex">
          <div className="flex-shrink-0">
            <svg className="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
            </svg>
          </div>
          <div className="ml-3">
            <h3 className="text-sm font-medium text-yellow-800">Demo Disclaimer</h3>
            <div className="mt-2 text-sm text-yellow-700">
              <p>This is a demonstration system using mock AI. Results are simulated and should not be used for clinical decisions.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}; 