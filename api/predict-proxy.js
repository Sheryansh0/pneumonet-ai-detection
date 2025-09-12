// Vercel serverless function to proxy file upload requests to Container Instance
import formidable from 'formidable';
import fs from 'fs';

export const config = {
  api: {
    bodyParser: false, // Disable body parsing to handle multipart/form-data
  },
};

export default async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const AZURE_BACKEND = 'http://pneumonia-detection-sheryansh.centralindia.azurecontainer.io:5000';

  try {
    // Parse the multipart form data
    const form = formidable({
      maxFileSize: 10 * 1024 * 1024, // 10MB limit
      keepExtensions: true,
    });

    const [fields, files] = await form.parse(req);
    
    const file = files.file?.[0];
    if (!file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    // Create FormData to send to backend
    const FormData = require('form-data');
    const formData = new FormData();
    
    // Read file and append to FormData
    const fileStream = fs.createReadStream(file.filepath);
    formData.append('file', fileStream, {
      filename: file.originalFilename,
      contentType: file.mimetype,
    });

    // Add any additional fields
    if (fields.disable_cam) {
      formData.append('disable_cam', fields.disable_cam[0]);
    }

    // Make request to backend
    const response = await fetch(`${AZURE_BACKEND}/predict`, {
      method: 'POST',
      body: formData,
      headers: formData.getHeaders(),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Backend error (${response.status}): ${errorText}`);
    }

    const data = await response.json();
    
    // Clean up temporary file
    fs.unlink(file.filepath, () => {});
    
    res.status(200).json(data);
    
  } catch (error) {
    console.error('Prediction proxy error:', error);
    res.status(500).json({
      error: 'Prediction failed',
      message: error.message,
    });
  }
}