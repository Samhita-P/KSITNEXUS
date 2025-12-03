# KSIT Nexus - Deployment Setup Checklist

Use this checklist to ensure everything is set up correctly.

## ✅ Pre-Deployment Checklist

### Backend Files
- [x] `backend/ksit_nexus/settings.py` - Updated for production
- [x] `backend/render.yaml` - Created
- [x] `backend/requirements.txt` - Updated with dj-database-url
- [x] Code pushed to GitHub

### Frontend Files
- [x] `ksit_nexus_app/pubspec.yaml` - Added flutter_dotenv
- [x] `ksit_nexus_app/lib/config/api_config.dart` - Uses .env
- [x] `ksit_nexus_app/lib/main.dart` - Loads .env
- [x] `ksit_nexus_app/android/app/src/main/res/xml/network_security_config.xml` - HTTPS ready
- [ ] `.env` file created (see CREATE_ENV_FILE.md)

---

## 🚀 Deployment Steps

### Step 1: Deploy Backend to Render
- [ ] Create Render account at https://render.com
- [ ] Connect GitHub repository
- [ ] Create new Web Service
- [ ] Render auto-detects `render.yaml` ✅
- [ ] Set environment variables:
  - [ ] `SECRET_KEY` (generate secure key)
  - [ ] `DEBUG=False`
- [ ] Create PostgreSQL database (optional but recommended)
- [ ] Deploy and wait for completion
- [ ] Copy your Render URL: `https://your-app.onrender.com`

### Step 2: Configure Flutter App
- [ ] Create `.env` file in `ksit_nexus_app/` directory
- [ ] Add `API_BASE_URL=https://your-app.onrender.com`
- [ ] Run `flutter pub get`
- [ ] Verify `.env` is loaded (check console output)

### Step 3: Build and Test
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Build APK: `flutter build apk --release`
- [ ] Install APK on device
- [ ] Test login/API calls
- [ ] Verify it works on different networks (Wi-Fi, mobile data)

---

## 🧪 Testing Checklist

### Backend Tests
- [ ] API docs accessible: `https://your-app.onrender.com/api/docs/`
- [ ] Health check endpoint works
- [ ] CORS allows Flutter app requests
- [ ] Database migrations completed

### Frontend Tests
- [ ] App starts without errors
- [ ] Console shows correct API Base URL
- [ ] Login works
- [ ] API calls succeed
- [ ] Images/media load correctly
- [ ] Works on Wi-Fi network
- [ ] Works on mobile data
- [ ] Works on different devices

---

## 📝 Post-Deployment

- [ ] Share APK with test users
- [ ] Monitor Render logs for errors
- [ ] Set up monitoring (optional)
- [ ] Document any custom configurations
- [ ] Update team on new deployment process

---

## ⚠️ Common Issues

### Backend Issues
- **Build fails**: Check `requirements.txt` has all dependencies
- **Database errors**: Verify `DATABASE_URL` is set correctly
- **CORS errors**: Check `CORS_ALLOWED_ORIGINS` includes your Render URL

### Frontend Issues
- **`.env` not found**: Ensure file is in `ksit_nexus_app/` directory
- **API calls fail**: Verify `API_BASE_URL` in `.env` is correct
- **HTTPS errors**: Check network security config allows Render domain

---

## 📚 Documentation Files

- `RENDER_DEPLOYMENT_GUIDE.md` - Detailed deployment guide
- `DEPLOYMENT_CHANGES_SUMMARY.md` - All changes explained
- `QUICK_START_DEPLOYMENT.md` - Quick reference
- `CREATE_ENV_FILE.md` - How to create .env file
- `SETUP_CHECKLIST.md` - This file

---

**Status**: ✅ All code changes complete. Ready for deployment!

