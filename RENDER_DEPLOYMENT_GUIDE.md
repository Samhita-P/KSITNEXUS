# KSIT Nexus - Render Deployment Guide

This guide will help you deploy the Django backend to Render and configure the Flutter app to use the stable HTTPS URL.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Deployment (Django to Render)](#backend-deployment)
3. [Frontend Configuration (Flutter)](#frontend-configuration)
4. [Testing](#testing)
5. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- GitHub account
- Render account (free tier available at https://render.com)
- Git installed on your computer
- Flutter SDK installed
- Django backend code ready

---

## Backend Deployment (Django to Render)

### Step 1: Prepare Your Repository

1. **Push your code to GitHub** (if not already done):
   ```bash
   cd backend
   git init  # if not already initialized
   git add .
   git commit -m "Prepare for Render deployment"
   git remote add origin https://github.com/YOUR_USERNAME/ksit-nexus-backend.git
   git push -u origin main
   ```

2. **Ensure these files exist in your backend directory**:
   - `requirements.txt` ✅ (already updated)
   - `render.yaml` ✅ (already created)
   - `manage.py`
   - `ksit_nexus/wsgi.py`

### Step 2: Create Render Account and Web Service

1. Go to https://render.com and sign up/login
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repository
4. Select your repository containing the Django backend

### Step 3: Configure Render Service

**Option A: Using render.yaml (Recommended)**

1. Render will automatically detect `render.yaml` in your repository
2. It will use the configuration from the file
3. Review and confirm the settings

**Option B: Manual Configuration**

If not using render.yaml, configure manually:

- **Name**: `ksit-nexus-backend`
- **Environment**: `Python 3`
- **Build Command**: 
  ```bash
  pip install -r requirements.txt && python manage.py collectstatic --noinput && python manage.py migrate
  ```
- **Start Command**: 
  ```bash
  gunicorn ksit_nexus.wsgi:application
  ```
- **Plan**: `Free` (or upgrade if needed)

### Step 4: Set Environment Variables

In Render dashboard, go to **Environment** tab and add:

| Key | Value | Notes |
|-----|-------|-------|
| `SECRET_KEY` | Generate a secure key | Use: `python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"` |
| `DEBUG` | `False` | Always False in production |
| `RENDER_EXTERNAL_HOSTNAME` | Auto-set by Render | Leave as is |
| `ALLOWED_HOSTS` | `${RENDER_EXTERNAL_HOSTNAME},localhost,127.0.0.1` | Comma-separated |
| `CORS_ALLOWED_ORIGINS` | `https://${RENDER_EXTERNAL_HOSTNAME},https://ksit-nexus.onrender.com` | For Flutter app |
| `DATABASE_URL` | Auto-set if using Render PostgreSQL | Or set manually |

**Optional Environment Variables** (if using):
- `REDIS_URL` - If using Redis
- `FCM_SERVER_KEY` - For Firebase Cloud Messaging
- `KEYCLOAK_SERVER_URL` - If using Keycloak

### Step 5: Create PostgreSQL Database (Optional but Recommended)

1. In Render dashboard, click **"New +"** → **"PostgreSQL"**
2. Name: `ksit-nexus-db`
3. Plan: `Free`
4. Copy the **Internal Database URL**
5. Add it as `DATABASE_URL` environment variable in your web service

**Note**: If you skip PostgreSQL, the app will use SQLite (not recommended for production).

### Step 6: Deploy

1. Click **"Create Web Service"** or **"Save Changes"**
2. Render will start building and deploying
3. Wait for deployment to complete (5-10 minutes)
4. Once deployed, you'll get a URL like: `https://ksit-nexus-backend.onrender.com`

### Step 7: Run Initial Migrations

After first deployment, run migrations:

1. Go to **Shell** tab in Render dashboard
2. Run:
   ```bash
   python manage.py migrate
   python manage.py createsuperuser  # Create admin user
   ```

### Step 8: Verify Deployment

1. Visit your Render URL: `https://ksit-nexus-backend.onrender.com/api/docs/`
2. You should see the API documentation (Swagger UI)
3. Test an endpoint: `https://ksit-nexus-backend.onrender.com/api/auth/`

---

## Frontend Configuration (Flutter)

### Step 1: Install Dependencies

```bash
cd ksit_nexus_app
flutter pub get
```

This will install `flutter_dotenv` and `http` packages.

### Step 2: Create .env File

1. **Copy the example file**:
   ```bash
   # On Windows (PowerShell)
   Copy-Item .env.example .env
   
   # On Mac/Linux
   cp .env.example .env
   ```

2. **Edit `.env` file** and add your Render URL:
   ```env
   API_BASE_URL=https://ksit-nexus-backend.onrender.com
   ```

   **Important**: Replace `ksit-nexus-backend.onrender.com` with your actual Render URL!

### Step 3: Verify .env File Location

Make sure `.env` is in the `ksit_nexus_app/` directory (same level as `pubspec.yaml`).

### Step 4: Build APK

```bash
flutter build apk --release
```

The APK will be generated at: `ksit_nexus_app/build/app/outputs/flutter-apk/app-release.apk`

### Step 5: Test the APK

1. Install the APK on your Android device
2. Open the app
3. Check the console/logs - you should see:
   ```
   ✅ Environment variables loaded successfully
   📡 API Base URL: https://ksit-nexus-backend.onrender.com
   ```
4. Try logging in or making an API call

---

## Testing

### Test Backend

1. **Health Check**:
   ```bash
   curl https://ksit-nexus-backend.onrender.com/api/docs/
   ```

2. **API Endpoint Test**:
   ```bash
   curl https://ksit-nexus-backend.onrender.com/api/auth/
   ```

### Test Flutter App

1. **Check Environment Variables**:
   - Look for console output showing API Base URL
   - Should show your Render URL, not localhost

2. **Test API Calls**:
   - Try logging in
   - Check if data loads from backend
   - Verify images/media load correctly

---

## Troubleshooting

### Backend Issues

**Problem**: Build fails on Render
- **Solution**: Check build logs, ensure all dependencies are in `requirements.txt`
- **Solution**: Verify Python version matches (3.11.0)

**Problem**: Database connection errors
- **Solution**: Ensure `DATABASE_URL` is set correctly
- **Solution**: Check if PostgreSQL database is created and running

**Problem**: Static files not loading
- **Solution**: Ensure `collectstatic` runs in build command
- **Solution**: Check `STATIC_ROOT` and `STATIC_URL` settings

**Problem**: CORS errors
- **Solution**: Verify `CORS_ALLOWED_ORIGINS` includes your Render URL
- **Solution**: Check `ALLOWED_HOSTS` includes your Render domain

### Frontend Issues

**Problem**: `.env` file not found
- **Solution**: Ensure `.env` exists in `ksit_nexus_app/` directory
- **Solution**: Check `pubspec.yaml` includes `.env` in assets

**Problem**: API calls fail
- **Solution**: Verify `API_BASE_URL` in `.env` is correct
- **Solution**: Check network security config allows HTTPS
- **Solution**: Ensure backend CORS settings allow your app

**Problem**: App still uses old IP address
- **Solution**: Clean build: `flutter clean && flutter pub get && flutter build apk --release`
- **Solution**: Verify `.env` file is included in assets in `pubspec.yaml`

**Problem**: HTTPS certificate errors
- **Solution**: Render provides valid SSL certificates automatically
- **Solution**: If using custom domain, ensure SSL is configured

---

## Important Notes

### Render Free Tier Limitations

- **Spins down after 15 minutes of inactivity**
- **First request after spin-down takes 30-60 seconds** (cold start)
- **Consider upgrading** if you need:
  - Always-on service
  - Faster response times
  - More resources

### Environment Variables

- **Never commit `.env` file** to Git (it's in .gitignore)
- **Always use `.env.example`** as a template
- **Update `.env`** when deploying to different environments

### Security

- **Keep `SECRET_KEY` secret** - never commit it
- **Set `DEBUG=False`** in production
- **Use HTTPS** for all production URLs
- **Restrict `ALLOWED_HOSTS`** to your domain

---

## Next Steps

1. ✅ Backend deployed to Render
2. ✅ Flutter app configured with Render URL
3. ✅ APK built and tested
4. 🔄 **Optional**: Set up custom domain on Render
5. 🔄 **Optional**: Configure CI/CD for automatic deployments
6. 🔄 **Optional**: Set up monitoring and logging

---

## Summary of Changes Made

### Backend Changes

1. ✅ Updated `settings.py`:
   - Environment-based `ALLOWED_HOSTS`
   - Production-ready CORS configuration
   - PostgreSQL database support
   - HTTPS/CSRF settings

2. ✅ Created `render.yaml` for Render deployment

3. ✅ Updated `requirements.txt`:
   - Added `dj-database-url` for PostgreSQL
   - Removed duplicate `django-environ`

### Frontend Changes

1. ✅ Added `flutter_dotenv` and `http` to `pubspec.yaml`

2. ✅ Created `.env.example` template

3. ✅ Updated `api_config.dart`:
   - Uses environment variables from `.env`
   - Supports both HTTPS (production) and HTTP (development)

4. ✅ Updated `main.dart`:
   - Loads `.env` file on app startup

5. ✅ Updated Android network security config:
   - Allows HTTPS by default
   - Allows HTTP only for local development

---

## Support

If you encounter issues:

1. Check Render deployment logs
2. Check Flutter build logs
3. Verify environment variables are set correctly
4. Test API endpoints directly using curl/Postman

For Render-specific issues: https://render.com/docs

For Flutter issues: https://flutter.dev/docs

---

**🎉 Congratulations! Your backend is now deployed and your Flutter app is configured to use a stable URL!**

