# 🚀 Quick Reference Card

## One-Line Commands

### Backend Deployment
```bash
# 1. Push to GitHub
cd backend && git add . && git commit -m "Render ready" && git push

# 2. Go to https://render.com → New Web Service → Connect Repo → Deploy
```

### Flutter Setup
```bash
# 1. Create .env file
cd ksit_nexus_app
echo API_BASE_URL=https://your-app.onrender.com > .env

# 2. Install dependencies
flutter pub get

# 3. Build APK
flutter build apk --release
```

---

## File Locations

| File | Location | Status |
|------|----------|--------|
| `.env` | `ksit_nexus_app/.env` | ⚠️ **YOU CREATE THIS** |
| Backend config | `backend/render.yaml` | ✅ Ready |
| API config | `ksit_nexus_app/lib/config/api_config.dart` | ✅ Updated |
| Main entry | `ksit_nexus_app/lib/main.dart` | ✅ Updated |

---

## Environment Variables

### Backend (Render Dashboard)
- `SECRET_KEY` = Generate secure key
- `DEBUG` = `False`
- `DATABASE_URL` = Auto-set if using PostgreSQL

### Frontend (.env file)
- `API_BASE_URL` = `https://your-app.onrender.com`

---

## Testing

```bash
# Test backend
curl https://your-app.onrender.com/api/docs/

# Test Flutter
flutter run
# Check console for: ✅ Environment variables loaded successfully
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `.env` not found | Create file in `ksit_nexus_app/` directory |
| API calls fail | Check `API_BASE_URL` in `.env` |
| Build fails | Run `flutter clean && flutter pub get` |

---

**📖 Full Guide**: See `RENDER_DEPLOYMENT_GUIDE.md`

