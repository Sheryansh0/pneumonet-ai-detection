// Mock data for PneumoNet analysis results
export const mockResults = {
  prediction: "Pneumonia Detected",
  confidence: 87.3,
  riskLevel: "Moderate",
  processingTime: 2.3,
  gradcamImage:
    "https://images.unsplash.com/photo-1559757148-5c350d0d3c56?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",

  recommendations: [
    "Immediate medical consultation recommended due to positive pneumonia detection",
    "Consider follow-up chest CT scan for detailed assessment",
    "Monitor symptoms closely including fever, cough, and breathing difficulties",
    "Ensure adequate rest and hydration while awaiting medical evaluation",
    "Avoid strenuous physical activities until cleared by healthcare provider",
  ],

  technicalDetails: {
    modelVersion: "PneumoniaNet v3.2",
    algorithm: "Deep Convolutional Neural Network",
    dataset: "ChestX-ray14 + NIH Clinical",
    modelAccuracy: 94.2,
    sensitivity: 89.1,
    specificity: 96.8,
  },

  // Additional mock data for display
  modelVersion: "PneumoniaNet v3.2",
  algorithm: "ResNet-50 CNN",
  dataset: "ChestX-ray14",
  modelAccuracy: 94.2,
};

// Mock data for alternative results (can be used for testing different scenarios)
export const mockResultsNormal = {
  prediction: "Normal",
  confidence: 92.7,
  riskLevel: "Low",
  processingTime: 1.8,
  gradcamImage:
    "https://images.unsplash.com/photo-1576091160550-2173dba999ef?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",

  recommendations: [
    "No signs of pneumonia detected in the current X-ray analysis",
    "Continue regular health monitoring and preventive care",
    "Maintain good respiratory hygiene and healthy lifestyle",
    "Schedule routine check-ups as recommended by your healthcare provider",
    "Seek medical attention if respiratory symptoms develop",
  ],

  modelVersion: "PneumoniaNet v3.2",
  algorithm: "ResNet-50 CNN",
  dataset: "ChestX-ray14",
  modelAccuracy: 94.2,
};
