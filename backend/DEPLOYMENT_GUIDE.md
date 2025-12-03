# KSIT Nexus Backend Deployment Guide

## Remote Server Deployment (100.87.200.4)

### Prerequisites
- SSH access to the server: `mvpi_backend@100.87.200.4`
- Python 3.8+ installed on the server
- Network access from college LAN (10.x.x.x) to server (100.87.200.4)

---

## Step 1: Copy Project to Remote Server

From your local machine, copy the entire project folder:

```bash
# Using SCP (slower but reliable)
scp -r "KSIT NEXUS - Copy" mvpi_backend@100.87.200.4:~/ksit_nexus/

# OR using rsync (faster, resumes on interruption)
rsync -avz --progress "KSIT NEXUS - Copy"/ mvpi_backend@100.87.200.4:~/ksit_nexus/
```

**Note:** This may take several minutes depending on file size and network speed.

---

## Step 2: SSH into the Server

```bash
ssh mvpi_backend@100.87.200.4
```

---

## Step 3: Navigate to Project Directory

```bash
cd ~/ksit_nexus
# If using rsync, the folder structure might be different
# Check: ls -la
# If needed: cd "KSIT NEXUS - Copy"
```

---

## Step 4: Create and Activate Virtual Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Verify Python version (should be 3.8+)
python --version
```

---

## Step 5: Install Dependencies

```bash
# Navigate to backend directory
cd backend

# Upgrade pip
pip install --upgrade pip

# Install all dependencies
pip install -r requirements.txt
```

**Note:** This may take 5-10 minutes depending on server speed.

---

## Step 6: Configure Environment Variables

Create a `.env` file in the `backend` directory:

```bash
cd backend
nano .env
```

Add the following (adjust values as needed):

```env
# Django Settings
SECRET_KEY=your-secret-key-here-change-this-in-production
DEBUG=True

# Database Settings (if using PostgreSQL)
# DB_NAME=ksit_nexus
# DB_USER=ksit_user
# DB_PASSWORD=ksit_password
# DB_HOST=localhost
# DB_PORT=5432

# Redis Settings (if Redis is installed)
# REDIS_URL=redis://localhost:6379/0

# For SQLite (default), no database config needed
```

Save and exit (Ctrl+X, then Y, then Enter).

---

## Step 7: Run Database Migrations

```bash
# Make sure you're in the backend directory
cd ~/ksit_nexus/backend

# Activate virtual environment (if not already active)
source ../venv/bin/activate

# Run migrations
python manage.py migrate
```

---

## Step 8: Create Superuser (Optional)

```bash
python manage.py createsuperuser
```

Follow the prompts to create an admin user.

---

## Step 9: Collect Static Files

```bash
python manage.py collectstatic --noinput
```

---

## Step 10: Start Django Server

```bash
# Start server accessible from all network interfaces
python manage.py runserver 0.0.0.0:8002
```

The server will now be accessible from:
- **Remote server itself**: `http://localhost:8002`
- **College LAN devices**: `http://100.87.200.4:8002`
- **Any device that can reach 100.87.200.4**: `http://100.87.200.4:8002`

---

## Step 11: Verify Configuration

### Check ALLOWED_HOSTS
The current configuration has:
```python
ALLOWED_HOSTS = ['*']  # Allows all hosts
```

This is correct for college LAN deployment.

### Check CORS
The current configuration has:
```python
CORS_ALLOW_ALL_ORIGINS = True  # Allows all origins
```

This is correct for college LAN deployment.

### Test Connection

From a device on the college LAN (10.x.x.x network), test:

1. **Ping the server:**
   ```bash
   ping 100.87.200.4
   ```

2. **Access API in browser:**
   ```
   http://100.87.200.4:8002/api/
   ```

3. **Test from Flutter app:**
   - Update `ksit_nexus_app/lib/config/api_config.dart`
   - Set `localNetworkIp = '100.87.200.4'`
   - Build and test APK

---

## Running Server in Background (Optional)

To keep the server running after disconnecting SSH:

### Option 1: Using nohup
```bash
nohup python manage.py runserver 0.0.0.0:8002 > server.log 2>&1 &
```

### Option 2: Using screen
```bash
# Install screen if not available
sudo apt-get install screen  # Ubuntu/Debian
# or
sudo yum install screen      # CentOS/RHEL

# Start a screen session
screen -S django

# Run the server
python manage.py runserver 0.0.0.0:8002

# Detach: Press Ctrl+A, then D
# Reattach: screen -r django
```

### Option 3: Using systemd (Production)
Create a systemd service file for production deployment.

---

## Troubleshooting

### Port 8002 Already in Use
```bash
# Find process using port 8000
sudo lsof -i :8002
# or
sudo netstat -tulpn | grep 8000

# Kill the process
kill -9 <PID>
```

### Permission Denied
```bash
# Make sure you have write permissions
chmod -R 755 ~/ksit_nexus
```

### Database Errors
```bash
# If using SQLite, check file permissions
ls -la db.sqlite3
chmod 664 db.sqlite3
```

### Static Files Not Loading
```bash
# Re-collect static files
python manage.py collectstatic --noinput --clear
```

---

## Production Recommendations

For production deployment, consider:

1. **Use Gunicorn instead of runserver:**
   ```bash
   pip install gunicorn
   gunicorn --bind 0.0.0.0:8002 ksit_nexus.wsgi:application
   ```

2. **Use Nginx as reverse proxy**

3. **Set up SSL/HTTPS**

4. **Use PostgreSQL instead of SQLite**

5. **Set up proper logging**

6. **Use process manager (systemd, supervisor)**

---

## Quick Reference

**Server IP:** 100.87.200.4  
**Port:** 8000  
**API Base URL:** http://100.87.200.4:8002/api  
**Admin Panel:** http://100.87.200.4:8002/admin  

**SSH Command:**
```bash
ssh mvpi_backend@100.87.200.4
```

**Start Server:**
```bash
cd ~/ksit_nexus/backend
source ../venv/bin/activate
python manage.py runserver 0.0.0.0:8002
```

