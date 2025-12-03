# Create .env File

## Quick Instructions

1. **Create a new file** named `.env` in the `ksit_nexus_app/` directory (same folder as `pubspec.yaml`)

2. **Add this content** to the `.env` file:
   ```env
   API_BASE_URL=https://ksit-nexus.onrender.com
   ```

3. **Replace** `https://ksit-nexus.onrender.com` with your actual Render URL after deployment

4. **Save the file**

## For Local Development

If you want to test with a local backend, use:
```env
API_BASE_URL=http://192.168.x.x:8002
```
(Replace `192.168.x.x` with your computer's IP address)

## Important

- ✅ The `.env` file is already in `.gitignore` - it won't be committed to Git
- ✅ Never commit `.env` to version control
- ✅ Each developer should create their own `.env` file
- ✅ The `.env` file must be in `ksit_nexus_app/` directory (not in `lib/` or elsewhere)

## Verification

After creating `.env`, run:
```bash
flutter pub get
flutter run
```

Check the console output - you should see:
```
✅ Environment variables loaded successfully
📡 API Base URL: https://your-url.onrender.com
```

