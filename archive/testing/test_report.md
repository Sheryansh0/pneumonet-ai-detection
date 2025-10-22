# 🏥 Pneumonia Detection API - Comprehensive Test Report

**Test Date**: 2025-09-09 21:16:40
**API Endpoint**: http://pneumonia-detection-sheryansh.hah5ghbxfdeabpcw.centralindia.azurecontainer.io:5000/predict

## 📊 Overall Performance

- **Total Images Tested**: 865
- **Successful Predictions**: 865
- **Failed Predictions**: 0
- **Overall Accuracy**: 88.90%
- **Average Response Time**: 1.36 seconds

## 🎯 Per-Class Performance

### BACTERIAL PNEUMONIA
- **Accuracy**: 94.60%
- **Total Samples**: 278
- **Correct Predictions**: 263
- **Average Confidence**: 91.3%
- **Confidence Range**: 49.5% - 97.2%

### NORMAL
- **Accuracy**: 91.01%
- **Total Samples**: 278
- **Correct Predictions**: 253
- **Average Confidence**: 91.1%
- **Confidence Range**: 41.0% - 97.3%

### VIRAL PNEUMONIA
- **Accuracy**: 81.88%
- **Total Samples**: 309
- **Correct Predictions**: 253
- **Average Confidence**: 86.5%
- **Confidence Range**: 42.0% - 97.8%

## 🔥 Confusion Matrix

| True \ Predicted | NORMAL | BACTERIAL PNEUMONIA | VIRAL PNEUMONIA |
|------------------|--------|-------------------|-----------------|
| **NORMAL** | 253 | 5 | 20 |
| **BACTERIAL PNEUMONIA** | 4 | 263 | 11 |
| **VIRAL PNEUMONIA** | 12 | 44 | 253 |

## ⚠️ Risk Level Distribution

- **High Risk**: 273 (31.6%)
- **Indeterminate (Low Confidence)**: 118 (13.6%)
- **Medium Risk**: 233 (26.9%)
- **No Risk**: 241 (27.9%)

## 🚀 Deployment Summary

✅ **Status**: Production Ready
✅ **Accuracy**: 88.9% across all classes
✅ **Speed**: 1.36s average response time
✅ **Reliability**: 100.0% success rate

---
*Report generated automatically by comprehensive test suite*
