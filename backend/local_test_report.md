# 🏥 Pneumonia Detection API - Local Test Report

**Test Date**: 2025-09-11 01:32:37
**API Endpoint**: http://localhost:5000

## 📊 Overall Performance

- **Total Images Tested**: 9
- **Successful Predictions**: 9
- **Failed Predictions**: 0
- **Overall Accuracy**: 88.89%
- **Average Response Time**: 2.67 seconds

## 🎯 Per-Class Performance

### BACTERIAL PNEUMONIA
- **Accuracy**: 100.00%
- **Total Samples**: 3
- **Correct Predictions**: 3
- **Average Confidence**: 96.6%
- **Confidence Range**: 96.3% - 96.8%

### NORMAL
- **Accuracy**: 100.00%
- **Total Samples**: 3
- **Correct Predictions**: 3
- **Average Confidence**: 96.6%
- **Confidence Range**: 96.4% - 97.0%

### VIRAL PNEUMONIA
- **Accuracy**: 66.67%
- **Total Samples**: 3
- **Correct Predictions**: 2
- **Average Confidence**: 74.1%
- **Confidence Range**: 62.0% - 96.6%

## 🔥 Confusion Matrix

| True \ Predicted | NORMAL | BACTERIAL PNEUMONIA | VIRAL PNEUMONIA |
|------------------|--------|-------------------|-----------------|
| **NORMAL** | 3 | 0 | 0 |
| **BACTERIAL PNEUMONIA** | 0 | 3 | 0 |
| **VIRAL PNEUMONIA** | 0 | 1 | 2 |

## ⚠️ Risk Level Distribution

- **High Risk**: 3 (33.3%)
- **Indeterminate (Low Confidence)**: 2 (22.2%)
- **Medium Risk**: 1 (11.1%)
- **No Risk**: 3 (33.3%)

## 🚀 Local Deployment Summary

✅ **Status**: Running Successfully
✅ **Accuracy**: 88.9% across all classes
✅ **Speed**: 2.67s average response time
✅ **Reliability**: 100.0% success rate

---
*Report generated automatically by local test suite*
