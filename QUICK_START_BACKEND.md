# Quick Start: Backend Server for Mobile

## ⚠️ IMPORTANT: Your backend is currently only listening on localhost!

The server needs to be restarted to accept connections from your mobile device.

## Steps to Fix:

### 1. Stop Current Server
- Find the terminal/command prompt where Django is running
- Press `Ctrl+C` to stop it

### 2. Start Server with Network Access

**Option A: Use the helper script (Easiest)**
- Navigate to the `backend` folder
- Double-click `start_server_mobile.bat`

**Option B: Manual command**
```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

### 3. Verify It's Working

After starting, you should see:
```
Starting development server at http://0.0.0.0:8000/
Quit the server with CTRL-BREAK.
```

**NOT** this (which won't work):
```
Starting development server at http://127.0.0.1:8000/
```

### 4. Test Connection

On your phone's browser, try:
```
http://10.222.10.6:8000/api/
```

If you see a response, the connection works!

## Why This Happens

- `127.0.0.1:8000` = Only accessible from this computer
- `0.0.0.0:8000` = Accessible from any device on your network

Your phone needs `0.0.0.0:8000` to connect!

