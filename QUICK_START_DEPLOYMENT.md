# Quick Start - Render Deployment

## 🚀 Fast Track Deployment

### Step 1: Backend (5 minutes)

1. **Push to GitHub**:
   ```bash
   cd backend
   git add .
   git commit -m "Ready for Render"
   git push
   ```

2. **Deploy on Render**:
   - Go to https://render.com
   - Click "New +" → "Web Service"
   - Connect GitHub repo
   - Render will auto-detect `render.yaml`
   - Click "Create Web Service"
   - Wait for deployment (5-10 min)

3. **Set Environment Variables** (in Render dashboard):
   ```
   SECRET_KEY = <generate using: python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())">
   DEBUG = False
   ```

4. **Get Your URL**: `https://your-app.onrender.com`

---

### Step 2: Flutter App (2 minutes)

1. **Create `.env` file** in `ksit_nexus_app/`:
   ```env
   API_BASE_URL=https://your-app.onrender.com
   ```

2. **Build APK**:
   ```bash
   cd ksit_nexus_app
   flutter pub get
   flutter build apk --release
   ```

3. **Done!** APK is at: `build/app/outputs/flutter-apk/app-release.apk`

---

## ✅ That's It!

Your app now uses a stable URL that works everywhere!

**See `RENDER_DEPLOYMENT_GUIDE.md` for detailed instructions.**

