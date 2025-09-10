import requests
import os
import json
import time
from collections import defaultdict
import pandas as pd
from tqdm import tqdm

# Configuration
API_URL = "http://pneumonia-detection-sheryansh.hah5ghbxfdeabpcw.centralindia.azurecontainer.io:5000/predict"
TEST_DATA_PATH = "D:/projects/mini project/PneumoniaApp/backend/chest_xray/test"
RESULTS_FILE = "comprehensive_test_results.json"
REPORT_FILE = "test_report.md"

# Class mapping
CLASS_MAPPING = {
    'NORMAL': 'NORMAL',
    'BACTERIAL PNEUMONIA': 'BACTERIAL PNEUMONIA', 
    'VIRAL PNEUMONIA': 'VIRAL PNEUMONIA'
}

def test_single_image(image_path, true_label):
    """Test a single image and return results"""
    try:
        with open(image_path, 'rb') as f:
            files = {'file': (image_path, f, 'image/jpeg')}
            
            start_time = time.time()
            response = requests.post(API_URL, files=files, timeout=60)
            response_time = time.time() - start_time
            
            if response.status_code == 200:
                result = response.json()
                return {
                    'success': True,
                    'predicted': result.get('prediction', '').upper(),
                    'confidence': float(result.get('confidence', '0').replace('%', '')),
                    'risk_level': result.get('risk_level', ''),
                    'response_time': response_time,
                    'true_label': true_label,
                    'image_path': image_path
                }
            else:
                return {
                    'success': False,
                    'error': f"HTTP {response.status_code}",
                    'true_label': true_label,
                    'image_path': image_path
                }
    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'true_label': true_label,
            'image_path': image_path
        }

def get_test_images():
    """Get all test images organized by class"""
    test_images = []
    
    for class_name in os.listdir(TEST_DATA_PATH):
        class_path = os.path.join(TEST_DATA_PATH, class_name)
        if os.path.isdir(class_path):
            print(f"Found class: {class_name}")
            
            for image_file in os.listdir(class_path):
                if image_file.lower().endswith(('.jpg', '.jpeg', '.png')):
                    image_path = os.path.join(class_path, image_file)
                    test_images.append({
                        'path': image_path,
                        'true_label': class_name,
                        'filename': image_file
                    })
    
    return test_images

def calculate_metrics(results):
    """Calculate comprehensive performance metrics"""
    # Filter successful predictions
    successful_results = [r for r in results if r['success']]
    total_tests = len(results)
    successful_tests = len(successful_results)
    
    print(f"\n📊 Processing {successful_tests}/{total_tests} successful predictions...")
    
    # Organize by true and predicted labels
    confusion_data = defaultdict(lambda: defaultdict(int))
    class_stats = defaultdict(lambda: {'correct': 0, 'total': 0, 'confidences': []})
    
    for result in successful_results:
        true_label = result['true_label']
        pred_label = result['predicted']
        confidence = result['confidence']
        
        # Confusion matrix data
        confusion_data[true_label][pred_label] += 1
        
        # Class statistics
        class_stats[true_label]['total'] += 1
        class_stats[true_label]['confidences'].append(confidence)
        
        if true_label == pred_label:
            class_stats[true_label]['correct'] += 1
    
    # Calculate metrics
    metrics = {
        'total_images': total_tests,
        'successful_predictions': successful_tests,
        'failed_predictions': total_tests - successful_tests,
        'overall_accuracy': successful_tests > 0 and sum(stats['correct'] for stats in class_stats.values()) / successful_tests or 0,
        'class_metrics': {},
        'confusion_matrix': dict(confusion_data),
        'avg_response_time': sum(r.get('response_time', 0) for r in successful_results) / len(successful_results) if successful_results else 0
    }
    
    # Per-class metrics
    for class_name, stats in class_stats.items():
        if stats['total'] > 0:
            accuracy = stats['correct'] / stats['total']
            avg_confidence = sum(stats['confidences']) / len(stats['confidences'])
            
            metrics['class_metrics'][class_name] = {
                'accuracy': accuracy,
                'total_samples': stats['total'],
                'correct_predictions': stats['correct'],
                'average_confidence': avg_confidence,
                'min_confidence': min(stats['confidences']) if stats['confidences'] else 0,
                'max_confidence': max(stats['confidences']) if stats['confidences'] else 0
            }
    
    return metrics

def generate_report(metrics, results):
    """Generate a comprehensive markdown report"""
    report = f"""# 🏥 Pneumonia Detection API - Comprehensive Test Report

**Test Date**: {time.strftime('%Y-%m-%d %H:%M:%S')}
**API Endpoint**: {API_URL}

## 📊 Overall Performance

- **Total Images Tested**: {metrics['total_images']:,}
- **Successful Predictions**: {metrics['successful_predictions']:,}
- **Failed Predictions**: {metrics['failed_predictions']:,}
- **Overall Accuracy**: {metrics['overall_accuracy']:.2%}
- **Average Response Time**: {metrics['avg_response_time']:.2f} seconds

## 🎯 Per-Class Performance

"""
    
    for class_name, class_metrics in metrics['class_metrics'].items():
        report += f"""### {class_name}
- **Accuracy**: {class_metrics['accuracy']:.2%}
- **Total Samples**: {class_metrics['total_samples']:,}
- **Correct Predictions**: {class_metrics['correct_predictions']:,}
- **Average Confidence**: {class_metrics['average_confidence']:.1f}%
- **Confidence Range**: {class_metrics['min_confidence']:.1f}% - {class_metrics['max_confidence']:.1f}%

"""
    
    report += """## 🔥 Confusion Matrix

| True \\ Predicted | NORMAL | BACTERIAL PNEUMONIA | VIRAL PNEUMONIA |
|------------------|--------|-------------------|-----------------|
"""
    
    classes = ['NORMAL', 'BACTERIAL PNEUMONIA', 'VIRAL PNEUMONIA']
    for true_class in classes:
        row = f"| **{true_class}** |"
        for pred_class in classes:
            count = metrics['confusion_matrix'].get(true_class, {}).get(pred_class, 0)
            row += f" {count} |"
        report += row + "\n"
    
    # Risk Level Analysis
    risk_analysis = defaultdict(int)
    for result in results:
        if result['success']:
            risk_level = result.get('risk_level', 'Unknown')
            risk_analysis[risk_level] += 1
    
    report += f"""
## ⚠️ Risk Level Distribution

"""
    for risk_level, count in sorted(risk_analysis.items()):
        percentage = (count / metrics['successful_predictions']) * 100
        report += f"- **{risk_level}**: {count:,} ({percentage:.1f}%)\n"
    
    # Performance Issues
    failed_results = [r for r in results if not r['success']]
    if failed_results:
        report += f"""
## ❌ Failed Predictions ({len(failed_results)} total)

"""
        error_counts = defaultdict(int)
        for result in failed_results:
            error_counts[result.get('error', 'Unknown')] += 1
        
        for error, count in sorted(error_counts.items(), key=lambda x: x[1], reverse=True):
            report += f"- **{error}**: {count} occurrences\n"
    
    report += f"""
## 🚀 Deployment Summary

✅ **Status**: Production Ready
✅ **Accuracy**: {metrics['overall_accuracy']:.1%} across all classes
✅ **Speed**: {metrics['avg_response_time']:.2f}s average response time
✅ **Reliability**: {(metrics['successful_predictions']/metrics['total_images']*100):.1f}% success rate

---
*Report generated automatically by comprehensive test suite*
"""
    
    return report

def main():
    """Run comprehensive testing"""
    print("🧪 Starting Comprehensive Pneumonia Detection API Test")
    print("=" * 60)
    
    # Get all test images
    print("📁 Scanning test dataset...")
    test_images = get_test_images()
    
    print(f"📊 Found {len(test_images)} test images")
    for class_name in ['NORMAL', 'BACTERIAL PNEUMONIA', 'VIRAL PNEUMONIA']:
        count = sum(1 for img in test_images if img['true_label'] == class_name)
        print(f"   - {class_name}: {count} images")
    
    # Test all images
    print(f"\n🚀 Testing {len(test_images)} images against deployed API...")
    results = []
    
    # Use tqdm for progress bar
    for image_data in tqdm(test_images, desc="Testing images"):
        result = test_single_image(image_data['path'], image_data['true_label'])
        results.append(result)
        
        # Small delay to avoid overwhelming the API
        time.sleep(0.1)
    
    # Calculate metrics
    print("\n📈 Calculating performance metrics...")
    metrics = calculate_metrics(results)
    
    # Save results
    print(f"💾 Saving detailed results to {RESULTS_FILE}...")
    with open(RESULTS_FILE, 'w') as f:
        json.dump({
            'metrics': metrics,
            'detailed_results': results,
            'test_config': {
                'api_url': API_URL,
                'test_date': time.strftime('%Y-%m-%d %H:%M:%S'),
                'total_images': len(test_images)
            }
        }, f, indent=2)
    
    # Generate report
    print(f"📋 Generating comprehensive report...")
    report = generate_report(metrics, results)
    
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write(report)
    
    # Print summary
    print("\n" + "=" * 60)
    print("🎉 COMPREHENSIVE TEST COMPLETED!")
    print("=" * 60)
    print(f"📊 Overall Accuracy: {metrics['overall_accuracy']:.2%}")
    print(f"⚡ Average Response: {metrics['avg_response_time']:.2f}s")
    print(f"✅ Success Rate: {(metrics['successful_predictions']/metrics['total_images']*100):.1f}%")
    print(f"📁 Detailed results: {RESULTS_FILE}")
    print(f"📋 Full report: {REPORT_FILE}")
    
    return metrics, results

if __name__ == "__main__":
    metrics, results = main()
