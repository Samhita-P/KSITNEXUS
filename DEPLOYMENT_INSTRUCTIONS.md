# KSIT Nexus - Remote Server Deployment Instructions

## Server Information
- **Server IP:** 100.87.200.4
- **SSH User:** mvpi_backend
- **SSH Command:** `ssh mvpi_backend@100.87.200.4`
- **Project Path:** `~/ksit_nexus`
- **Backend Port:** 8002

---

## Quick Deployment Steps

### 1. Copy Project to Server

From your **local machine** (Windows PowerShell or Command Prompt):

```powershell
# Using SCP
scp -r "KSIT NEXUS - Copy" mvpi_backend@100.87.200.4:~/ksit_nexus/

# OR using rsync (if available on Windows via WSL)
wsl rsync -avz --progress "KSIT NEXUS - Copy"/ mvpi_backend@100.87.200.4:~/ksit_nexus/
```

**Note:** You may be prompted for SSH password. The copy may take 5-15 minutes depending on project size.

---

### 2. Connect to Server

```bash
ssh mvpi_backend@100.87.200.4
```

---

### 3. Navigate to Project

```bash
cd ~/ksit_nexus
# If folder name is different, check with: ls -la
# Then navigate: cd "KSIT NEXUS - Copy"
```

---

### 4. Run Deployment Script (Recommended)

```bash
cd backend
chmod +x deploy.sh
./deploy.sh
```

The script will:
- Create virtual environment
- Install dependencies
- Create .env file (you'll need to edit it)
- Run migrations
- Collect static files

**OR** follow manual steps below:

---

### 5. Manual Setup (Alternative)

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
cd backend
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file
cp env.example .env
nano .env  # Edit and save (Ctrl+X, Y, Enter)

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput
```

---

### 6. Start Server

```bash
# Make sure virtual environment is activated
source ../venv/bin/activate

# Start server (accessible from all network interfaces)
python manage.py runserver 0.0.0.0:8002
```

---

### 7. Verify Server is Running

From a device on the college LAN (10.x.x.x network):

1. **Test in browser:**
   ```
   http://100.87.200.4:8002/api/
   ```

2. **Test API endpoint:**
   ```
   http://100.87.200.4:8002/api/auth/login/
   ```

3. **Check admin panel:**
   ```
   http://100.87.200.4:8002/admin/
   ```

---

## Configuration Verification

### ✅ ALLOWED_HOSTS
**Status:** Configured
- **File:** `backend/ksit_nexus/settings.py`
- **Line 28:** `ALLOWED_HOSTS = ['*']`
- **Result:** Allows all hosts including 100.87.200.4 and 10.x.x.x

### ✅ CORS Configuration
**Status:** Configured
- **File:** `backend/ksit_nexus/settings.py`
- **Line 212:** `CORS_ALLOW_ALL_ORIGINS = True`
- **Result:** Allows all origins for college LAN access

### ✅ CSRF Configuration
**Status:** Configured
- **File:** `backend/ksit_nexus/settings.py`
- **Lines 236-244:** `CSRF_TRUSTED_ORIGINS` includes:
  - `http://100.87.200.4:8002` ✅
  - `http://10.0.0.0:8002` ✅ (college LAN)
  - Other localhost IPs ✅

### ✅ Server Binding
**Status:** Ready
- Server runs with: `python manage.py runserver 0.0.0.0:8002`
- **Result:** Accessible from all network interfaces

---

## Update Flutter App for Remote Server

After server is running, update Flutter app to use the remote server:

1. **Edit:** `ksit_nexus_app/lib/config/api_config.dart`
2. **Change line 18:**
   ```dart
   static const String localNetworkIp = '100.87.200.4'; // Remote server IP
   ```
3. **Rebuild APK:**
   ```bash
   cd ksit_nexus_app
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

---

## Running Server in Background

### Option 1: Using nohup
```bash
nohup python manage.py runserver 0.0.0.0:8002 > server.log 2>&1 &
```

### Option 2: Using screen
```bash
# Install screen (if not available)
sudo apt-get install screen

# Start screen session
screen -S django

# Run server
python manage.py runserver 0.0.0.0:8002

# Detach: Ctrl+A, then D
# Reattach: screen -r django
```

### Option 3: Using tmux
```bash
# Start tmux session
tmux new -s django

# Run server
python manage.py runserver 0.0.0.0:8002

# Detach: Ctrl+B, then D
# Reattach: tmux attach -t django
```

---

## Troubleshooting

### Port 8002 Already in Use
```bash
# Find process
sudo lsof -i :8002
# or
sudo netstat -tulpn | grep 8000

# Kill process
kill -9 <PID>
```

### Permission Errors
```bash
# Fix permissions
chmod -R 755 ~/ksit_nexus
chmod 664 ~/ksit_nexus/backend/db.sqlite3
```

### Import Errors
```bash
# Make sure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

### Database Errors
```bash
# Reset database (WARNING: Deletes all data)
rm db.sqlite3
python manage.py migrate
python manage.py createsuperuser
```

---

## Production Recommendations

For production, consider:

1. **Use Gunicorn:**
   ```bash
   pip install gunicorn
   gunicorn --bind 0.0.0.0:8002 --workers 4 ksit_nexus.wsgi:application
   ```

2. **Set up Nginx reverse proxy**

3. **Configure SSL/HTTPS**

4. **Use PostgreSQL instead of SQLite**

5. **Set up proper logging and monitoring**

---

## Network Access

### From College LAN (10.x.x.x)
- **API Base URL:** `http://100.87.200.4:8002/api`
- **WebSocket URL:** `ws://100.87.200.4:8001/ws`
- **Media URL:** `http://100.87.200.4:8002/media/`

### Firewall Configuration
Ensure the server firewall allows:
- **Port 8002** (HTTP API)
- **Port 8001** (WebSocket, if used)

```bash
# Ubuntu/Debian
sudo ufw allow 8002/tcp
sudo ufw allow 8001/tcp

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=8002/tcp
sudo firewall-cmd --permanent --add-port=8001/tcp
sudo firewall-cmd --reload
```

---

## Files Modified for Deployment

1. ✅ `backend/ksit_nexus/settings.py`
   - ALLOWED_HOSTS = ['*']
   - CORS_ALLOW_ALL_ORIGINS = True
   - CSRF_TRUSTED_ORIGINS includes 100.87.200.4

2. ✅ `backend/deploy.sh` (new)
   - Automated deployment script

3. ✅ `backend/DEPLOYMENT_GUIDE.md` (new)
   - Detailed deployment documentation

---

## Quick Command Reference

```bash
# SSH to server
ssh mvpi_backend@100.87.200.4

# Navigate to project
cd ~/ksit_nexus/backend

# Activate virtual environment
source ../venv/bin/activate

# Start server
python manage.py runserver 0.0.0.0:8002

# Check server status
curl http://100.87.200.4:8002/api/

# View logs (if using nohup)
tail -f server.log
```

---

## Success Checklist

- [ ] Project copied to server
- [ ] Virtual environment created and activated
- [ ] Dependencies installed
- [ ] .env file created and configured
- [ ] Migrations run successfully
- [ ] Static files collected
- [ ] Server starts on 0.0.0.0:8002
- [ ] Server accessible from college LAN (10.x.x.x)
- [ ] API endpoints respond correctly
- [ ] Flutter app updated with server IP
- [ ] APK rebuilt and tested

---

## Support

If you encounter issues:
1. Check server logs: `tail -f server.log` or check console output
2. Verify network connectivity: `ping 100.87.200.4`
3. Check firewall rules
4. Verify ALLOWED_HOSTS and CORS settings
5. Test API directly: `curl http://100.87.200.4:8002/api/`

