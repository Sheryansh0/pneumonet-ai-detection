import React, { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { Button } from "../components/ui/button";
import { Card } from "../components/ui/card";
import { Progress } from "../components/ui/progress";
import { Badge } from "../components/ui/badge";
import {
  ArrowLeft,
  Download,
  AlertTriangle,
  CheckCircle,
  Activity,
  FileText,
  Eye,
  Stethoscope,
  Clock,
  TrendingUp,
} from "lucide-react";
import { mockResults } from "../utils/mockData";
import { generatePneumoniaReport } from "../utils/reportGenerator";

const ResultsPage = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(true);

  const fileData = location.state;

  useEffect(() => {
    // Check if we have real API results or use mock data
    if (fileData?.apiResult) {
      // Use real API results
      setResults(fileData.apiResult);
      setLoading(false);
    } else {
      // Fallback to mock data with loading delay
      setTimeout(() => {
        setResults(mockResults);
        setLoading(false);
      }, 2000);
    }
  }, [fileData]);

  const handleDownloadReport = async () => {
    try {
      // Prepare comprehensive report data
      const reportData = {
        patientId: "Anonymous",
        analysisDate: new Date().toISOString(),
        fileName: fileData?.fileName || "chest-xray.jpg",
        prediction: results?.prediction,
        confidence: results?.confidence,
        riskLevel: results?.riskLevel,
        processingTime: results?.processingTime,
        processingTimeMs: results?.processingTimeMs,
        modelVersion: results?.modelVersion,
        algorithm: results?.algorithm,
        dataset: results?.dataset,
        modelAccuracy: results?.modelAccuracy,
        recommendations: getRecommendations(
          results?.prediction,
          results?.riskLevel
        ),
        apiEndpoint:
          "pneumonia-detection-sheryansh.centralindia.azurecontainer.io:5000",
      };

      // Get image URLs
      const originalImageUrl = fileData?.fileUrl;
      const gradcamImageUrl = results?.gradcamBase64 || results?.gradcamImage;

      console.log("Image URLs for PDF:", {
        originalImageUrl,
        gradcamImageUrl,
        hasGradcamBase64: !!results?.gradcamBase64,
        hasGradcamImage: !!results?.gradcamImage,
        results: results,
        fileData: fileData,
      });

      // Generate PDF report
      const pdf = await generatePneumoniaReport(
        reportData,
        originalImageUrl,
        gradcamImageUrl
      );

      // Download the PDF
      const fileName = `pneumonia-analysis-report-${Date.now()}.pdf`;
      pdf.save(fileName);

      // Show success message
      console.log("Report downloaded successfully:", fileName);
    } catch (error) {
      console.error("Error generating report:", error);
      // Fallback to JSON download if PDF generation fails
      const reportData = {
        patientId: "Anonymous",
        analysisDate: new Date().toISOString(),
        fileName: fileData?.fileName || "chest-xray.jpg",
        prediction: results?.prediction,
        confidence: results?.confidence,
        riskLevel: results?.riskLevel,
        processingTime: results?.processingTime,
        processingTimeMs: results?.processingTimeMs,
        modelVersion: results?.modelVersion,
        algorithm: results?.algorithm,
        dataset: results?.dataset,
        modelAccuracy: results?.modelAccuracy,
        recommendations: getRecommendations(
          results?.prediction,
          results?.riskLevel
        ),
        apiEndpoint:
          "pneumonia-detection-sheryansh.centralindia.azurecontainer.io:5000",
      };

      const dataStr = JSON.stringify(reportData, null, 2);
      const dataBlob = new Blob([dataStr], { type: "application/json" });
      const url = URL.createObjectURL(dataBlob);
      const link = document.createElement("a");
      link.href = url;
      link.download = `pneumonia-analysis-report-${Date.now()}.json`;
      link.click();
    }
  };

  const getRiskColor = (level) => {
    const levelLower = level?.toLowerCase() || "";
    if (levelLower.includes("low") || levelLower.includes("no risk")) {
      return "text-green-400 bg-green-500/10 border-green-500/20";
    } else if (
      levelLower.includes("moderate") ||
      levelLower.includes("medium")
    ) {
      return "text-amber-400 bg-amber-500/10 border-amber-500/20";
    } else if (levelLower.includes("high")) {
      return "text-red-400 bg-red-500/10 border-red-500/20";
    } else {
      return "text-slate-400 bg-slate-500/10 border-slate-500/20";
    }
  };

  const getRiskIcon = (level) => {
    switch (level?.toLowerCase()) {
      case "low":
      case "no risk":
        return <CheckCircle className="h-5 w-5" />;
      case "moderate":
      case "medium risk":
        return <AlertTriangle className="h-5 w-5" />;
      case "high":
      case "high risk":
        return <AlertTriangle className="h-5 w-5" />;
      default:
        return <Activity className="h-5 w-5" />;
    }
  };

  const getRecommendations = (prediction, riskLevel) => {
    const predictionLower = prediction?.toLowerCase() || "";
    const riskLower = riskLevel?.toLowerCase() || "";

    if (predictionLower.includes("normal")) {
      return [
        "No signs of pneumonia detected in the current X-ray analysis",
        "Continue regular health monitoring and preventive care",
        "Maintain good respiratory hygiene and healthy lifestyle",
        "Schedule routine check-ups as recommended by your healthcare provider",
        "Seek medical attention if respiratory symptoms develop",
      ];
    } else if (predictionLower.includes("pneumonia")) {
      const baseRecommendations = [
        "Pneumonia detected - immediate medical consultation strongly recommended",
        "Contact your healthcare provider or visit emergency services",
        "Monitor symptoms closely including fever, cough, and breathing difficulties",
        "Ensure adequate rest and hydration while awaiting medical evaluation",
        "Avoid strenuous physical activities until cleared by healthcare provider",
      ];

      if (riskLower === "high") {
        return [
          "HIGH RISK: Seek immediate emergency medical attention",
          ...baseRecommendations,
          "Consider follow-up chest CT scan for detailed assessment",
        ];
      } else if (riskLower === "medium") {
        return [
          "MODERATE RISK: Schedule urgent medical consultation within 24 hours",
          ...baseRecommendations,
        ];
      } else {
        return baseRecommendations;
      }
    }

    return [
      "Analysis complete - please review results with a healthcare professional",
      "Follow up with your doctor for proper interpretation of results",
      "Continue monitoring your health and symptoms",
    ];
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-800 flex items-center justify-center">
        <div className="text-center">
          <div className="w-20 h-20 border-4 border-cyan-500/30 border-t-cyan-500 rounded-full animate-spin mx-auto mb-6"></div>
          <h2 className="text-2xl font-semibold text-white mb-2">
            Analyzing X-Ray
          </h2>
          <p className="text-slate-400">AI is processing your image...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-800 p-6">
      {/* Animated Background */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-20 left-20 w-48 h-48 bg-cyan-500/5 rounded-full blur-3xl animate-pulse"></div>
        <div
          className="absolute bottom-40 right-32 w-64 h-64 bg-blue-500/5 rounded-full blur-3xl animate-bounce"
          style={{ animationDuration: "5s" }}
        ></div>
      </div>

      <div className="relative z-10 max-w-7xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <Button
            onClick={() => navigate("/upload")}
            variant="ghost"
            className="text-slate-300 hover:text-white hover:bg-white/10 transition-all duration-300"
          >
            <ArrowLeft className="h-5 w-5 mr-2" />
            New Analysis
          </Button>

          <div className="text-center">
            <h1 className="text-4xl font-bold bg-gradient-to-r from-white to-cyan-100 bg-clip-text text-transparent">
              Analysis Results
            </h1>
            <p className="text-slate-400 mt-2">
              AI-powered PneumoNet analysis complete
            </p>
          </div>

          <Button
            onClick={handleDownloadReport}
            className="bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-500 hover:to-emerald-500 text-white"
          >
            <Download className="h-5 w-5 mr-2" />
            Download Report
          </Button>
        </div>

        {/* Main Results Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
          {/* Original Image */}
          <Card className="p-6 bg-white/5 backdrop-blur-md border border-white/10">
            <h3 className="text-xl font-semibold text-white mb-4 flex items-center gap-3">
              <Eye className="h-6 w-6 text-cyan-400" />
              Original X-Ray
            </h3>
            {fileData?.fileUrl && (
              <img
                src={fileData.fileUrl}
                alt="Original X-Ray"
                className="w-full h-64 object-cover rounded-xl border border-white/20"
              />
            )}
            <div className="mt-4 text-sm text-slate-300">
              <p>File: {fileData?.fileName || "chest-xray.jpg"}</p>
              <p>Processed: {new Date().toLocaleString()}</p>
            </div>
          </Card>

          {/* GradCAM Visualization */}
          <Card className="p-6 bg-white/5 backdrop-blur-md border border-white/10">
            <h3 className="text-xl font-semibold text-white mb-4 flex items-center gap-3">
              <TrendingUp className="h-6 w-6 text-amber-400" />
              GradCAM Analysis
            </h3>
            <div className="relative">
              <img
                src={results?.gradcamImage}
                alt="GradCAM Visualization"
                className="w-full h-64 object-cover rounded-xl border border-white/20"
              />
              <div className="absolute top-2 right-2">
                <Badge className="bg-amber-500/20 text-amber-300 border-amber-500/30">
                  Heat Map
                </Badge>
              </div>
            </div>
            <p className="mt-4 text-sm text-slate-300">
              Highlighted regions show areas of interest detected by the AI
              model
            </p>
          </Card>

          {/* Prediction Results */}
          <Card className="p-6 bg-white/5 backdrop-blur-md border border-white/10">
            <h3 className="text-xl font-semibold text-white mb-6 flex items-center gap-3">
              <Stethoscope className="h-6 w-6 text-blue-400" />
              Diagnosis
            </h3>

            <div className="space-y-6">
              {/* Main Prediction */}
              <div className="text-center">
                <div
                  className={`inline-flex items-center gap-3 px-6 py-4 rounded-2xl border ${getRiskColor(
                    results?.riskLevel
                  )}`}
                >
                  {getRiskIcon(results?.riskLevel)}
                  <span className="text-2xl font-bold">
                    {results?.prediction}
                  </span>
                </div>
              </div>

              {/* Confidence Score */}
              <div>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-slate-300">Confidence Score</span>
                  <span className="text-white font-semibold">
                    {results?.confidence}%
                  </span>
                </div>
                <Progress value={results?.confidence} className="h-3" />
              </div>

              {/* Risk Level */}
              <div>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-slate-300">Risk Level</span>
                  <Badge className={getRiskColor(results?.riskLevel)}>
                    {results?.riskLevel}
                  </Badge>
                </div>
              </div>

              {/* Processing Time */}
              <div className="flex items-center justify-between p-3 bg-slate-800/30 rounded-lg">
                <div className="flex items-center gap-2">
                  <Clock className="h-4 w-4 text-slate-400" />
                  <span className="text-slate-300">Processing Time</span>
                </div>
                <div className="text-right">
                  <span className="text-white font-medium">
                    {results?.processingTime}s
                  </span>
                  {results?.processingTimeMs && (
                    <div className="text-xs text-slate-400">
                      ({results.processingTimeMs}ms)
                    </div>
                  )}
                </div>
              </div>
            </div>
          </Card>
        </div>

        {/* Detailed Analysis */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Recommendations */}
          <Card className="p-6 bg-white/5 backdrop-blur-md border border-white/10">
            <h3 className="text-xl font-semibold text-white mb-4 flex items-center gap-3">
              <FileText className="h-6 w-6 text-green-400" />
              Recommendations
            </h3>
            <div className="space-y-3">
              {getRecommendations(results?.prediction, results?.riskLevel)?.map(
                (rec, index) => (
                  <div
                    key={index}
                    className="flex items-start gap-3 p-3 bg-slate-800/30 rounded-lg"
                  >
                    <div className="w-2 h-2 bg-green-400 rounded-full mt-2 flex-shrink-0"></div>
                    <p className="text-slate-300 text-sm leading-relaxed">
                      {rec}
                    </p>
                  </div>
                )
              )}
            </div>
          </Card>

          {/* Technical Details */}
          <Card className="p-6 bg-white/5 backdrop-blur-md border border-white/10">
            <h3 className="text-xl font-semibold text-white mb-4 flex items-center gap-3">
              <Activity className="h-6 w-6 text-purple-400" />
              Technical Details
            </h3>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div className="p-3 bg-slate-800/30 rounded-lg">
                  <p className="text-slate-400">Model Version</p>
                  <p className="text-white font-medium">
                    {results?.modelVersion}
                  </p>
                </div>
                <div className="p-3 bg-slate-800/30 rounded-lg">
                  <p className="text-slate-400">Algorithm</p>
                  <p className="text-white font-medium">{results?.algorithm}</p>
                </div>
                <div className="p-3 bg-slate-800/30 rounded-lg">
                  <p className="text-slate-400">Dataset</p>
                  <p className="text-white font-medium">{results?.dataset}</p>
                </div>
                <div className="p-3 bg-slate-800/30 rounded-lg">
                  <p className="text-slate-400">Accuracy</p>
                  <p className="text-white font-medium">
                    {results?.modelAccuracy}%
                  </p>
                </div>
              </div>

              {/* Performance Metrics */}
              {results?.processingTime && (
                <div className="p-4 bg-blue-500/10 border border-blue-500/20 rounded-lg">
                  <div className="flex items-center gap-2 mb-2">
                    <Clock className="h-4 w-4 text-blue-400" />
                    <span className="text-blue-300 font-medium">
                      Performance Metrics
                    </span>
                  </div>
                  <div className="grid grid-cols-2 gap-3 text-sm">
                    <div>
                      <p className="text-slate-400">Total Processing Time</p>
                      <p className="text-white font-medium">
                        {results.processingTime}s
                      </p>
                    </div>
                    {results.processingTimeMs && (
                      <div>
                        <p className="text-slate-400">Response Time (ms)</p>
                        <p className="text-white font-medium">
                          {results.processingTimeMs}ms
                        </p>
                      </div>
                    )}
                  </div>
                  <div className="mt-2 text-xs text-blue-200/80">
                    ⚡{" "}
                    {results.processingTime < 5
                      ? "Excellent"
                      : results.processingTime < 10
                      ? "Good"
                      : "Acceptable"}{" "}
                    response time
                  </div>
                </div>
              )}

              <div className="p-4 bg-amber-500/10 border border-amber-500/20 rounded-lg">
                <p className="text-amber-300 text-sm font-medium mb-1">
                  ⚠️ Important Disclaimer
                </p>
                <p className="text-amber-200/80 text-xs leading-relaxed">
                  This AI analysis is for educational and research purposes
                  only. Always consult with qualified healthcare professionals
                  for medical diagnosis and treatment decisions.
                </p>
              </div>
            </div>
          </Card>
        </div>

        {/* Action Buttons */}
        <div className="flex justify-center gap-4 mt-8">
          <Button
            onClick={() => navigate("/upload")}
            className="px-8 py-3 bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-500 hover:to-blue-500 text-white rounded-xl shadow-lg hover:shadow-cyan-500/25 transform hover:scale-105 transition-all duration-300"
          >
            Analyze Another X-Ray
          </Button>
          <Button
            onClick={() => navigate("/")}
            className="px-8 py-3 bg-gradient-to-r from-slate-600 to-slate-700 hover:from-slate-500 hover:to-slate-600 text-white rounded-xl shadow-lg hover:shadow-slate-500/25 transform hover:scale-105 transition-all duration-300"
          >
            Back to Home
          </Button>
        </div>
      </div>
    </div>
  );
};

export default ResultsPage;
