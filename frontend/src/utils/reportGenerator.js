import jsPDF from "jspdf";

export const generatePneumoniaReport = async (
  reportData,
  originalImageUrl,
  gradcamImageUrl
) => {
  const pdf = new jsPDF("p", "mm", "a4");
  const pageWidth = pdf.internal.pageSize.getWidth();
  const pageHeight = pdf.internal.pageSize.getHeight();

  // Helper function to convert image to base64
  const imageToBase64 = (url) => {
    return new Promise((resolve) => {
      // If it's already a base64 data URL, return it directly
      if (url && url.startsWith("data:image/")) {
        console.log("Using existing base64 data URL");
        resolve(url);
        return;
      }

      const img = new Image();
      img.crossOrigin = "anonymous";
      img.onload = () => {
        try {
          const canvas = document.createElement("canvas");
          const ctx = canvas.getContext("2d");
          canvas.width = img.width;
          canvas.height = img.height;
          ctx.drawImage(img, 0, 0);
          resolve(canvas.toDataURL("image/jpeg", 0.8));
        } catch (error) {
          console.error("Canvas error:", error);
          // Fallback: try without crossOrigin
          const img2 = new Image();
          img2.onload = () => {
            try {
              const canvas = document.createElement("canvas");
              const ctx = canvas.getContext("2d");
              canvas.width = img2.width;
              canvas.height = img2.height;
              ctx.drawImage(img2, 0, 0);
              resolve(canvas.toDataURL("image/jpeg", 0.8));
            } catch (error2) {
              console.error("Fallback canvas error:", error2);
              resolve(null);
            }
          };
          img2.onerror = () => resolve(null);
          img2.src = url;
        }
      };
      img.onerror = (error) => {
        console.error("Image load error:", error);
        // Try without crossOrigin
        const img2 = new Image();
        img2.onload = () => {
          try {
            const canvas = document.createElement("canvas");
            const ctx = canvas.getContext("2d");
            canvas.width = img2.width;
            canvas.height = img2.height;
            ctx.drawImage(img2, 0, 0);
            resolve(canvas.toDataURL("image/jpeg", 0.8));
          } catch (error2) {
            console.error("Fallback canvas error:", error2);
            resolve(null);
          }
        };
        img2.onerror = () => resolve(null);
        img2.src = url;
      };
      img.src = url;
    });
  };

  try {
    // Header
    pdf.setFillColor(30, 41, 59); // Slate-800
    pdf.rect(0, 0, pageWidth, 25, "F");

    pdf.setTextColor(255, 255, 255);
    pdf.setFontSize(20);
    pdf.setFont("helvetica", "bold");
    pdf.text("PneumoNet Analysis Report", 15, 17);

    // Date and time
    pdf.setFontSize(10);
    pdf.setFont("helvetica", "normal");
    const date = new Date(reportData.analysisDate);
    pdf.text(`Generated: ${date.toLocaleString()}`, pageWidth - 60, 17);

    let yPosition = 35;

    // Patient Information
    pdf.setTextColor(0, 0, 0);
    pdf.setFontSize(14);
    pdf.setFont("helvetica", "bold");
    pdf.text("Patient Information", 15, yPosition);
    yPosition += 8;

    pdf.setFontSize(10);
    pdf.setFont("helvetica", "normal");
    pdf.text(`Patient ID: ${reportData.patientId}`, 15, yPosition);
    yPosition += 5;
    pdf.text(`Image File: ${reportData.fileName}`, 15, yPosition);
    yPosition += 5;
    pdf.text(`Analysis Date: ${date.toLocaleDateString()}`, 15, yPosition);
    yPosition += 5;
    pdf.text(`Processing Time: ${reportData.processingTime}s`, 15, yPosition);
    yPosition += 15;

    // Diagnosis Results
    pdf.setFontSize(14);
    pdf.setFont("helvetica", "bold");
    pdf.text("Diagnosis Results", 15, yPosition);
    yPosition += 8;

    // Create colored box for prediction
    const predictionColor = reportData.prediction
      ?.toLowerCase()
      .includes("pneumonia")
      ? [239, 68, 68]
      : [34, 197, 94]; // Red for pneumonia, green for normal

    pdf.setFillColor(...predictionColor);
    pdf.rect(15, yPosition - 3, 60, 8, "F");
    pdf.setTextColor(255, 255, 255);
    pdf.setFontSize(12);
    pdf.setFont("helvetica", "bold");
    pdf.text(reportData.prediction || "Unknown", 17, yPosition + 2);

    pdf.setTextColor(0, 0, 0);
    pdf.setFont("helvetica", "normal");
    pdf.text(`Confidence: ${reportData.confidence}%`, 85, yPosition + 2);
    yPosition += 12;

    pdf.setFontSize(10);
    pdf.text(`Risk Level: ${reportData.riskLevel}`, 15, yPosition);
    yPosition += 15;

    // Images Section
    if (originalImageUrl || gradcamImageUrl) {
      console.log("Processing images for PDF:", {
        originalImageUrl,
        gradcamImageUrl,
      });

      pdf.setFontSize(14);
      pdf.setFont("helvetica", "bold");
      pdf.text("Medical Images", 15, yPosition);
      yPosition += 10;

      const imageWidth = 75;
      const imageHeight = 60;

      // Original X-ray image
      if (originalImageUrl) {
        console.log("Processing original image:", originalImageUrl);
        try {
          const originalImageBase64 = await imageToBase64(originalImageUrl);
          console.log(
            "Original image base64 generated:",
            originalImageBase64 ? "Success" : "Failed"
          );
          if (originalImageBase64) {
            pdf.addImage(
              originalImageBase64,
              "JPEG",
              15,
              yPosition,
              imageWidth,
              imageHeight
            );
            pdf.setFontSize(10);
            pdf.setFont("helvetica", "bold");
            pdf.text("Original X-Ray", 15, yPosition + imageHeight + 5);
          }
        } catch (error) {
          console.error("Error adding original image:", error);
        }
      }

      // GradCAM image
      if (gradcamImageUrl) {
        console.log("Processing GradCAM image:", gradcamImageUrl);
        try {
          const gradcamImageBase64 = await imageToBase64(gradcamImageUrl);
          console.log(
            "GradCAM image base64 generated:",
            gradcamImageBase64 ? "Success" : "Failed"
          );
          if (gradcamImageBase64) {
            // Use PNG format for GradCAM since it's typically PNG
            const imageFormat = gradcamImageUrl.includes("data:image/png")
              ? "PNG"
              : "JPEG";
            pdf.addImage(
              gradcamImageBase64,
              imageFormat,
              pageWidth - imageWidth - 15,
              yPosition,
              imageWidth,
              imageHeight
            );
            pdf.setFontSize(10);
            pdf.setFont("helvetica", "bold");
            pdf.text(
              "GradCAM Analysis",
              pageWidth - imageWidth - 15,
              yPosition + imageHeight + 5
            );
          } else {
            console.warn("GradCAM image could not be converted to base64");
          }
        } catch (error) {
          console.error("Error adding GradCAM image:", error);
        }
      }

      yPosition += imageHeight + 15;
    } else {
      console.log("No images to process for PDF");
    }

    // Check if we need a new page
    if (yPosition > pageHeight - 60) {
      pdf.addPage();
      yPosition = 20;
    }

    // Recommendations
    pdf.setFontSize(14);
    pdf.setFont("helvetica", "bold");
    pdf.text("Medical Recommendations", 15, yPosition);
    yPosition += 8;

    pdf.setFontSize(10);
    pdf.setFont("helvetica", "normal");

    if (reportData.recommendations && reportData.recommendations.length > 0) {
      reportData.recommendations.forEach((recommendation, index) => {
        // Check if we need a new page
        if (yPosition > pageHeight - 20) {
          pdf.addPage();
          yPosition = 20;
        }

        const bulletPoint = `${index + 1}. `;
        const lines = pdf.splitTextToSize(recommendation, pageWidth - 25);

        pdf.text(bulletPoint, 15, yPosition);
        pdf.text(lines, 20, yPosition);
        yPosition += lines.length * 4 + 2;
      });
    }

    yPosition += 10;

    // Disclaimer
    if (yPosition > pageHeight - 30) {
      pdf.addPage();
      yPosition = 20;
    }

    pdf.setFillColor(252, 211, 77); // Amber background
    pdf.rect(15, yPosition - 3, pageWidth - 30, 20, "F");

    pdf.setTextColor(146, 64, 14); // Amber text
    pdf.setFontSize(12);
    pdf.setFont("helvetica", "bold");
    pdf.text("Important Disclaimer", 20, yPosition + 3);

    pdf.setFontSize(9);
    pdf.setFont("helvetica", "normal");
    const disclaimerText = pdf.splitTextToSize(
      "This AI analysis is for educational and research purposes only. Always consult with qualified healthcare professionals for medical diagnosis and treatment decisions. This report should not be used as a substitute for professional medical advice.",
      pageWidth - 40
    );
    pdf.text(disclaimerText, 20, yPosition + 8);

    // Footer
    pdf.setFillColor(30, 41, 59);
    pdf.rect(0, pageHeight - 15, pageWidth, 15, "F");
    pdf.setTextColor(255, 255, 255);
    pdf.setFontSize(8);
    pdf.text("Generated by PneumoNet", 15, pageHeight - 5);
    pdf.text(
      `Page ${pdf.internal.getNumberOfPages()}`,
      pageWidth - 25,
      pageHeight - 5
    );

    return pdf;
  } catch (error) {
    console.error("Error generating PDF:", error);
    throw error;
  }
};
