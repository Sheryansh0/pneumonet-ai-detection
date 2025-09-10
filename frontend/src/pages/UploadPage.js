import React, { useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/ui/button";
import { Card } from "../components/ui/card";
import {
  Upload,
  FileImage,
  ArrowLeft,
  Scan,
  CheckCircle,
  AlertCircle,
} from "lucide-react";
import { useToast } from "../hooks/use-toast";
import pneumoniaAPI from "../services/api";
import ConnectionStatus from "../components/ConnectionStatus";

const UploadPage = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [selectedFile, setSelectedFile] = useState(null);
  const [dragOver, setDragOver] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [elapsedTime, setElapsedTime] = useState(0);
  const fileInputRef = useRef(null);
  const intervalRef = useRef(null);

  const handleFileSelect = (file) => {
    if (file && file.type.startsWith("image/")) {
      setSelectedFile(file);
      toast({
        title: "File Selected",
        description: `Selected: ${file.name}`,
        duration: 2000,
      });
    } else {
      toast({
        title: "Invalid File",
        description: "Please select a valid image file.",
        variant: "destructive",
        duration: 3000,
      });
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    const file = e.dataTransfer.files[0];
    handleFileSelect(file);
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    setDragOver(true);
  };

  const handleDragLeave = () => {
    setDragOver(false);
  };

  const handleFileInputChange = (e) => {
    const file = e.target.files[0];
    handleFileSelect(file);
  };

  const handleAnalyze = async () => {
    if (!selectedFile) {
      toast({
        title: "No File Selected",
        description: "Please select a chest X-ray image first.",
        variant: "destructive",
        duration: 3000,
      });
      return;
    }

    setUploading(true);
    setElapsedTime(0);

    // Record start time for processing time calculation
    const startTime = Date.now();

    // Start elapsed time counter
    intervalRef.current = setInterval(() => {
      const currentElapsed = ((Date.now() - startTime) / 1000).toFixed(1);
      setElapsedTime(parseFloat(currentElapsed));
    }, 100);

    try {
      toast({
        title: "Starting Analysis",
        description: "Uploading image to AI server...",
        duration: 3000,
      });

      // Call the real API
      const result = await pneumoniaAPI.predictPneumonia(selectedFile);

      // Calculate actual processing time
      const endTime = Date.now();
      const processingTimeMs = endTime - startTime;
      const processingTimeSec = (processingTimeMs / 1000).toFixed(2);

      // Clear the interval
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }

      if (result.success) {
        const apiData = result.data;

        // Create GradCAM image URL if available
        const gradcamUrl = apiData.gradcam_image
          ? pneumoniaAPI.createImageUrl(apiData.gradcam_image)
          : null;

        // Also store the raw base64 for PDF generation
        const gradcamBase64 = apiData.gradcam_image
          ? `data:image/png;base64,${apiData.gradcam_image}`
          : null;

        // Navigate to results with real API data and actual processing time
        navigate("/results", {
          state: {
            fileName: selectedFile.name,
            fileUrl: URL.createObjectURL(selectedFile),
            apiResult: {
              prediction: apiData.prediction,
              confidence: parseFloat(apiData.confidence.replace("%", "")),
              riskLevel: apiData.risk_level,
              gradcamImage: gradcamUrl,
              gradcamBase64: gradcamBase64, // Store base64 for PDF generation
              processingTime: parseFloat(processingTimeSec), // Real processing time
              processingTimeMs: processingTimeMs, // Also store milliseconds for detailed display
              modelVersion: "ConvNeXt + EfficientNet Ensemble",
              algorithm: "Deep Learning Ensemble",
              dataset: "Custom Pneumonia Dataset",
              modelAccuracy: 94.2,
            },
          },
        });

        toast({
          title: "Analysis Complete!",
          description: `Prediction: ${apiData.prediction} (${apiData.confidence}) - Processed in ${processingTimeSec}s`,
          duration: 5000,
        });
      }
    } catch (error) {
      console.error("API Error:", error);

      // Calculate processing time even for errors
      const endTime = Date.now();
      const processingTimeMs = endTime - startTime;
      const processingTimeSec = (processingTimeMs / 1000).toFixed(2);

      // Clear the interval
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }

      toast({
        title: "Analysis Failed",
        description: `${
          error.message || "An error occurred during analysis."
        } (Failed after ${processingTimeSec}s)`,
        variant: "destructive",
        duration: 5000,
      });
    } finally {
      setUploading(false);
      setElapsedTime(0);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-800 p-6">
      {/* Animated Background Elements */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-32 left-16 w-40 h-40 bg-cyan-500/5 rounded-full blur-2xl animate-pulse"></div>
        <div
          className="absolute bottom-32 right-20 w-56 h-56 bg-blue-500/5 rounded-full blur-3xl animate-bounce"
          style={{ animationDuration: "4s" }}
        ></div>
        <div
          className="absolute top-1/3 right-1/4 w-32 h-32 bg-indigo-500/5 rounded-full blur-xl animate-ping"
          style={{ animationDuration: "3s" }}
        ></div>
      </div>

      <div className="relative z-10 max-w-4xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <Button
            onClick={() => navigate("/")}
            variant="ghost"
            className="text-slate-300 hover:text-white hover:bg-white/10 transition-all duration-300"
          >
            <ArrowLeft className="h-5 w-5 mr-2" />
            Back to Home
          </Button>

          <div className="text-center">
            <h1 className="text-4xl font-bold bg-gradient-to-r from-white to-cyan-100 bg-clip-text text-transparent">
              Upload Chest X-Ray
            </h1>
            <p className="text-slate-400 mt-2">
              Upload your chest X-ray image for AI analysis
            </p>
          </div>

          <div className="w-32"></div>
        </div>

        {/* Upload Section */}
        <ConnectionStatus className="mb-6" />

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {/* Upload Card */}
          <Card className="p-8 bg-white/5 backdrop-blur-md border border-white/10 hover:bg-white/10 transition-all duration-500 transform hover:scale-105">
            <div
              className={`relative border-2 border-dashed rounded-2xl p-12 transition-all duration-300 ${
                dragOver
                  ? "border-cyan-400 bg-cyan-500/10"
                  : selectedFile
                  ? "border-green-400 bg-green-500/10"
                  : "border-slate-600 hover:border-slate-500"
              }`}
              onDrop={handleDrop}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onClick={() => fileInputRef.current?.click()}
            >
              <input
                ref={fileInputRef}
                type="file"
                className="hidden"
                accept="image/*"
                onChange={handleFileInputChange}
              />

              <div className="text-center">
                {selectedFile ? (
                  <div className="space-y-4">
                    <div className="mx-auto w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center">
                      <CheckCircle className="h-8 w-8 text-green-400" />
                    </div>
                    <div>
                      <p className="text-green-400 font-semibold text-lg">
                        {selectedFile.name}
                      </p>
                      <p className="text-slate-400 text-sm mt-1">
                        Size: {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
                      </p>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div className="mx-auto w-16 h-16 bg-gradient-to-r from-cyan-500/20 to-blue-500/20 rounded-full flex items-center justify-center">
                      <Upload className="h-8 w-8 text-cyan-400" />
                    </div>
                    <div>
                      <p className="text-white font-semibold text-lg">
                        Upload Chest X-Ray
                      </p>
                      <p className="text-slate-400 text-sm mt-2">
                        Drag and drop your image here, or click to browse
                      </p>
                      <p className="text-slate-500 text-xs mt-2">
                        Supported formats: JPG, PNG, JPEG (Max 10MB)
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </Card>

          {/* Preview Card */}
          <Card className="p-8 bg-white/5 backdrop-blur-md border border-white/10">
            <h3 className="text-xl font-semibold text-white mb-4 flex items-center gap-3">
              <FileImage className="h-6 w-6 text-cyan-400" />
              Image Preview
            </h3>

            {selectedFile ? (
              <div className="space-y-4">
                <div className="relative group">
                  <img
                    src={URL.createObjectURL(selectedFile)}
                    alt="Chest X-Ray Preview"
                    className="w-full h-64 object-cover rounded-xl border border-white/20 group-hover:scale-105 transition-transform duration-500"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent rounded-xl"></div>
                </div>

                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div className="p-3 bg-slate-800/50 rounded-lg">
                    <p className="text-slate-400">File Type</p>
                    <p className="text-white font-medium">
                      {selectedFile.type}
                    </p>
                  </div>
                  <div className="p-3 bg-slate-800/50 rounded-lg">
                    <p className="text-slate-400">File Size</p>
                    <p className="text-white font-medium">
                      {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
                    </p>
                  </div>
                </div>
              </div>
            ) : (
              <div className="flex items-center justify-center h-64 bg-slate-800/30 rounded-xl border border-slate-700">
                <div className="text-center text-slate-500">
                  <FileImage className="h-12 w-12 mx-auto mb-3 opacity-50" />
                  <p>No image selected</p>
                </div>
              </div>
            )}
          </Card>
        </div>

        {/* Guidelines */}
        <Card className="p-6 bg-white/5 backdrop-blur-md border border-white/10 mb-8">
          <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-3">
            <AlertCircle className="h-5 w-5 text-amber-400" />
            Guidelines for Best Results
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-sm">
            <div className="space-y-3">
              <div className="flex items-center gap-3">
                <div className="w-1.5 h-1.5 bg-cyan-400 rounded-full"></div>
                <p className="text-slate-300">Ensure the X-ray image is clear and high quality</p>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-1.5 h-1.5 bg-cyan-400 rounded-full"></div>
                <p className="text-slate-300">Image should be properly oriented (not rotated)</p>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-1.5 h-1.5 bg-cyan-400 rounded-full"></div>
                <p className="text-slate-300">Avoid images with excessive noise or artifacts</p>
              </div>
            </div>
            <div className="space-y-3">
              <div className="flex items-center gap-3">
                <div className="w-1.5 h-1.5 bg-cyan-400 rounded-full"></div>
                <p className="text-slate-300">Use chest X-rays taken from the front (PA view preferred)</p>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-1.5 h-1.5 bg-cyan-400 rounded-full"></div>
                <p className="text-slate-300">Ensure proper exposure (not too dark or bright)</p>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-1.5 h-1.5 bg-cyan-400 rounded-full"></div>
                <p className="text-slate-300">Remove any personal information from the image</p>
              </div>
            </div>
          </div>
        </Card>

        {/* Analyze Button */}
        <div className="text-center">
          <Button
            onClick={handleAnalyze}
            disabled={!selectedFile || uploading}
            className={`px-12 py-6 text-xl font-semibold rounded-2xl shadow-2xl transition-all duration-500 ${
              selectedFile && !uploading
                ? "bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-500 hover:to-blue-500 text-white hover:shadow-cyan-500/25 transform hover:scale-110"
                : "bg-slate-700 text-slate-400 cursor-not-allowed"
            }`}
          >
            {uploading ? (
              <div className="flex items-center gap-3">
                <div className="w-6 h-6 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                <div className="text-center">
                  <div>Analyzing X-Ray...</div>
                  {elapsedTime > 0 && (
                    <div className="text-sm opacity-80 mt-1">
                      {elapsedTime}s elapsed
                    </div>
                  )}
                </div>
              </div>
            ) : (
              <div className="flex items-center gap-3">
                <Scan className="h-6 w-6" />
                Analyze X-Ray
              </div>
            )}
          </Button>
        </div>
      </div>
    </div>
  );
};

export default UploadPage;
