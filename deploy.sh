#!/bin/bash

# KSIT Nexus Production Deployment Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="ksit-nexus"
BACKUP_DIR="./backups"
LOG_DIR="./logs"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    log_info "Docker and Docker Compose are installed."
}

# Check if .env file exists
check_env() {
    if [ ! -f .env ]; then
        log_error ".env file not found. Please create a .env file with required environment variables."
        log_info "Required variables:"
        log_info "  SECRET_KEY=your-secret-key"
        log_info "  POSTGRES_PASSWORD=your-postgres-password"
        log_info "  FCM_SERVER_KEY=your-fcm-server-key"
        log_info "  FCM_PROJECT_ID=your-fcm-project-id"
        log_info "  EMAIL_HOST=your-email-host"
        log_info "  EMAIL_HOST_USER=your-email-user"
        log_info "  EMAIL_HOST_PASSWORD=your-email-password"
        exit 1
    fi
    
    log_info ".env file found."
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    mkdir -p $BACKUP_DIR
    mkdir -p $LOG_DIR
    mkdir -p nginx/ssl
    mkdir -p monitoring/grafana/dashboards
    mkdir -p monitoring/grafana/datasources
    mkdir -p monitoring/rules
}

# Backup existing data
backup_data() {
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR)" ]; then
        log_info "Backing up existing data..."
        tar -czf "$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz" \
            --exclude='./backups' \
            --exclude='./logs' \
            --exclude='./node_modules' \
            --exclude='./.git' \
            .
        log_info "Backup completed."
    fi
}

# Build and start services
deploy_services() {
    log_info "Building and starting services..."
    
    # Stop existing services
    docker-compose -f docker-compose.production.yml down
    
    # Build and start services
    docker-compose -f docker-compose.production.yml up -d --build
    
    log_info "Services started successfully."
}

# Wait for services to be ready
wait_for_services() {
    log_info "Waiting for services to be ready..."
    
    # Wait for database
    log_info "Waiting for database..."
    until docker-compose -f docker-compose.production.yml exec -T db pg_isready -U ksit_nexus; do
        sleep 2
    done
    
    # Wait for Redis
    log_info "Waiting for Redis..."
    until docker-compose -f docker-compose.production.yml exec -T redis redis-cli ping; do
        sleep 2
    done
    
    # Wait for backend
    log_info "Waiting for backend..."
    until curl -f http://localhost:8000/health/ > /dev/null 2>&1; do
        sleep 5
    done
    
    log_info "All services are ready."
}

# Run database migrations
run_migrations() {
    log_info "Running database migrations..."
    docker-compose -f docker-compose.production.yml exec backend python manage.py migrate
    log_info "Migrations completed."
}

# Collect static files
collect_static() {
    log_info "Collecting static files..."
    docker-compose -f docker-compose.production.yml exec backend python manage.py collectstatic --noinput
    log_info "Static files collected."
}

# Create superuser
create_superuser() {
    log_info "Creating superuser..."
    docker-compose -f docker-compose.production.yml exec backend python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@ksitnexus.com', 'admin123')
    print('Superuser created: admin/admin123')
else:
    print('Superuser already exists')
"
    log_info "Superuser setup completed."
}

# Setup monitoring
setup_monitoring() {
    log_info "Setting up monitoring..."
    
    # Create Grafana datasource
    cat > monitoring/grafana/datasources/prometheus.yml << EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

    # Create basic dashboard
    cat > monitoring/grafana/dashboards/dashboard.yml << EOF
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

    log_info "Monitoring setup completed."
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    # Check if all services are running
    if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
        log_info "All services are running."
    else
        log_error "Some services are not running."
        docker-compose -f docker-compose.production.yml ps
        exit 1
    fi
    
    # Check if application is responding
    if curl -f http://localhost:8000/health/ > /dev/null 2>&1; then
        log_info "Application is responding."
    else
        log_error "Application is not responding."
        exit 1
    fi
    
    log_info "Health check passed."
}

# Show deployment information
show_info() {
    log_info "Deployment completed successfully!"
    echo ""
    log_info "Application URLs:"
    log_info "  Main Application: http://localhost:8000"
    log_info "  Admin Interface: http://localhost:8000/admin"
    log_info "  API Documentation: http://localhost:8000/api/docs/"
    log_info "  Monitoring (Grafana): http://localhost:3000"
    log_info "  Monitoring (Prometheus): http://localhost:9090"
    log_info "  Celery Flower: http://localhost:5555"
    echo ""
    log_info "Default credentials:"
    log_info "  Admin: admin/admin123"
    log_info "  Grafana: admin/admin"
    echo ""
    log_info "To view logs:"
    log_info "  docker-compose -f docker-compose.production.yml logs -f"
    echo ""
    log_info "To stop services:"
    log_info "  docker-compose -f docker-compose.production.yml down"
}

# Main deployment function
main() {
    log_info "Starting KSIT Nexus deployment..."
    
    check_docker
    check_env
    create_directories
    backup_data
    deploy_services
    wait_for_services
    run_migrations
    collect_static
    create_superuser
    setup_monitoring
    health_check
    show_info
}

# Run main function
main "$@"
