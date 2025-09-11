# PneumoNet Frontend - Vercel Deployment

## 🚀 Quick Deployment to Vercel

### Method 1: GitHub Integration (Recommended)

1. **Push your code to GitHub:**

   ```bash
   git add .
   git commit -m "Prepare for Vercel deployment"
   git push origin main
   ```

2. **Deploy to Vercel:**
   - Go to [vercel.com](https://vercel.com)
   - Click "New Project"
   - Import your GitHub repository
   - Vercel will automatically detect it's a React app
   - Click "Deploy"

### Method 2: Vercel CLI

1. **Install Vercel CLI:**

   ```bash
   npm i -g vercel
   ```

2. **Login to Vercel:**

   ```bash
   vercel login
   ```

3. **Deploy:**
   ```bash
   cd frontend
   vercel
   ```

## 🔧 Environment Variables

Set these environment variables in your Vercel dashboard:

- `REACT_APP_API_URL`: Your backend API URL (e.g., https://your-backend.azurewebsites.net)

## 📁 Project Structure

```
frontend/
├── public/
├── src/
├── vercel.json          # Vercel configuration
├── .env.production      # Production environment variables
└── package.json
```

## ⚙️ Configuration Files

- **vercel.json**: Configures Vercel deployment settings
- **.env.production**: Production environment variables
- **package.json**: Updated with correct project name and dependencies

## 🔗 Backend Integration

Update your backend URL in the Vercel environment variables:

1. Go to your Vercel project dashboard
2. Click "Settings" → "Environment Variables"
3. Add `REACT_APP_API_URL` with your backend URL

## 📝 Notes

- The app will automatically handle routing for React Router
- Static assets are cached for optimal performance
- Source maps are disabled in production for security

## 🌐 Custom Domain

After deployment, you can add a custom domain in your Vercel project settings.

## 🚨 Pre-deployment Checklist

✅ Fixed unused imports and ESLint warnings
✅ Created production build successfully
✅ Environment variables configured
✅ API endpoints use environment variables
✅ Vercel configuration added
✅ Package.json cleaned up
