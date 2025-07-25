import React, { useState, useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import { uploadImage } from '../services/api';

interface UploadZoneProps {
  onUploadComplete: (studyId: string) => void;
  onError: (error: string) => void;
  disabled?: boolean;
}

export const UploadZone: React.FC<UploadZoneProps> = ({ 
  onUploadComplete, 
  onError, 
  disabled = false 
}) => {
  const [isUploading, setIsUploading] = useState(false);
  const [progress, setProgress] = useState(0);

  const onDrop = useCallback(async (acceptedFiles: File[]) => {
    if (disabled || isUploading) return;

    const file = acceptedFiles[0];
    if (!file) return;

    // Validate file type
    const validTypes = ['image/png', 'image/jpeg', 'image/jpg', 'application/dicom'];
    if (!validTypes.includes(file.type)) {
      onError('Please upload a valid image file (PNG, JPEG) or DICOM file');
      return;
    }

    // Validate file size (50MB limit)
    const maxSize = 50 * 1024 * 1024;
    if (file.size > maxSize) {
      onError('File size must be less than 50MB');
      return;
    }

    setIsUploading(true);
    setProgress(0);

    try {
      // Simulate upload progress
      const progressInterval = setInterval(() => {
        setProgress(prev => {
          if (prev >= 90) {
            clearInterval(progressInterval);
            return 90;
          }
          return prev + 10;
        });
      }, 200);

      const result = await uploadImage(file);
      
      clearInterval(progressInterval);
      setProgress(100);
      
      setTimeout(() => {
        setIsUploading(false);
        setProgress(0);
        onUploadComplete(result.study_id);
      }, 500);

    } catch (error) {
      setIsUploading(false);
      setProgress(0);
      onError(error instanceof Error ? error.message : 'Upload failed');
    }
  }, [disabled, isUploading, onUploadComplete, onError]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'image/*': ['.png', '.jpg', '.jpeg'],
      'application/dicom': ['.dcm']
    },
    maxFiles: 1,
    disabled: disabled || isUploading
  });

  return (
    <div className="space-y-4">
      {/* Upload Zone */}
      <div
        {...getRootProps()}
        className={`
          border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors
          ${isDragActive 
            ? 'border-primary-400 bg-primary-50' 
            : 'border-gray-300 hover:border-primary-400 hover:bg-gray-50'
          }
          ${disabled || isUploading ? 'opacity-50 cursor-not-allowed' : ''}
        `}
      >
        <input {...getInputProps()} />
        
        {isUploading ? (
          <div className="space-y-4">
            <div className="w-16 h-16 mx-auto bg-primary-100 rounded-full flex items-center justify-center">
              <svg className="w-8 h-8 text-primary-600 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            </div>
            <div>
              <p className="text-sm font-medium text-gray-900">Uploading...</p>
              <p className="text-xs text-gray-500">Please wait</p>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="w-16 h-16 mx-auto bg-gray-100 rounded-full flex items-center justify-center">
              <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
              </svg>
            </div>
            <div>
              <p className="text-sm font-medium text-gray-900">
                {isDragActive ? 'Drop the file here' : 'Drag & drop a mammogram'}
              </p>
              <p className="text-xs text-gray-500">
                PNG, JPEG, or DICOM files up to 50MB
              </p>
            </div>
            <button
              type="button"
              className="btn-primary text-sm"
              disabled={disabled || isUploading}
            >
              Browse Files
            </button>
          </div>
        )}
      </div>

      {/* Progress Bar */}
      {isUploading && (
        <div className="space-y-2">
          <div className="flex justify-between text-sm">
            <span className="text-gray-600">Upload Progress</span>
            <span className="text-gray-900 font-medium">{progress}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div 
              className="bg-primary-600 h-2 rounded-full transition-all duration-300"
              style={{ width: `${progress}%` }}
            ></div>
          </div>
        </div>
      )}

      {/* File Info */}
      {isDragActive && (
        <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
          <p className="text-sm text-blue-800">
            Drop your mammogram file here to start the analysis
          </p>
        </div>
      )}
    </div>
  );
}; 