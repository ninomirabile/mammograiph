import { useState, useEffect } from 'react';
import { UploadZone } from './components/UploadZone';
import { ResultsView } from './components/ResultsView';
import { Header } from './components/Header';
import { HealthStatus } from './components/HealthStatus';
import { checkDetailedHealth } from './services/api';
import { HealthResponse, AnalysisResult } from './types';

function App() {
  const [currentStudyId, setCurrentStudyId] = useState<string | null>(null);
  const [analysisResult, setAnalysisResult] = useState<AnalysisResult | null>(null);
  const [healthStatus, setHealthStatus] = useState<HealthResponse | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    checkSystemHealth();
  }, []);

  const checkSystemHealth = async () => {
    try {
      const health = await checkDetailedHealth();
      setHealthStatus(health);
    } catch (err) {
      console.error('Health check failed:', err);
      setHealthStatus({
        status: 'unhealthy',
        service: 'AI Medical Imaging - Starter Kit',
        version: '1.0.0'
      });
    }
  };

  const handleUploadComplete = (studyId: string) => {
    setCurrentStudyId(studyId);
    setAnalysisResult(null);
    setError(null);
  };

  const handleAnalysisComplete = (result: AnalysisResult) => {
    setAnalysisResult(result);
    setError(null);
  };

  const handleError = (errorMessage: string) => {
    setError(errorMessage);
    setIsLoading(false);
  };

  const resetApp = () => {
    setCurrentStudyId(null);
    setAnalysisResult(null);
    setError(null);
    setIsLoading(false);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <Header />
      
      <main className="container mx-auto px-4 py-8">
        {/* Health Status */}
        {healthStatus && (
          <HealthStatus health={healthStatus} />
        )}

        {/* Error Display */}
        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <h3 className="text-sm font-medium text-red-800">Error</h3>
                <div className="mt-2 text-sm text-red-700">{error}</div>
              </div>
              <div className="ml-auto pl-3">
                <button
                  onClick={() => setError(null)}
                  className="text-red-400 hover:text-red-600"
                >
                  <svg className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Upload Section */}
          <div className="card">
            <h2 className="text-2xl font-semibold text-gray-900 mb-6">
              Upload Mammogram
            </h2>
            <UploadZone
              onUploadComplete={handleUploadComplete}
              onError={handleError}
              disabled={isLoading}
            />
          </div>

          {/* Results Section */}
          <div className="card">
            <h2 className="text-2xl font-semibold text-gray-900 mb-6">
              AI Analysis Results
            </h2>
            {currentStudyId ? (
              <ResultsView
                studyId={currentStudyId}
                onAnalysisComplete={handleAnalysisComplete}
                onError={handleError}
                isLoading={isLoading}
                setIsLoading={setIsLoading}
              />
            ) : (
              <div className="text-center py-12">
                <div className="text-gray-400 mb-4">
                  <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                </div>
                <p className="text-gray-500">Upload a mammogram to see AI analysis results</p>
              </div>
            )}
          </div>
        </div>

        {/* Reset Button */}
        {(currentStudyId || analysisResult) && (
          <div className="mt-8 text-center">
            <button
              onClick={resetApp}
              className="btn-secondary"
            >
              Start New Analysis
            </button>
          </div>
        )}
      </main>
    </div>
  );
}

export default App; 