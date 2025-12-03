# PowerShell script to transfer project excluding virtual environments
# Using rsync via WSL or manual exclusion

$source = ".\KSIT NEXUS - Copy"
$dest = "mvpi_backend@100.87.200.4:~/ksit_nexus/"

Write-Host "Transferring project to server (excluding virtual environments)..."

# Try using rsync via WSL if available
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Write-Host "Using rsync via WSL..."
    wsl rsync -avz --progress --exclude='venv' --exclude='new_venv' --exclude='test_venv' --exclude='test_env' --exclude='__pycache__' --exclude='*.pyc' --exclude='.git' --exclude='node_modules' --exclude='build' --exclude='.dart_tool' "$source/" "$dest"
} else {
    Write-Host "WSL not available. Using SCP with tar (slower but works)..."
    # Create a tar archive excluding venv directories
    Write-Host "Creating archive..."
    tar --exclude='venv' --exclude='new_venv' --exclude='test_venv' --exclude='test_env' --exclude='__pycache__' --exclude='*.pyc' --exclude='.git' --exclude='node_modules' --exclude='build' --exclude='.dart_tool' -czf ksit_nexus_backup.tar.gz -C "KSIT NEXUS - Copy" .
    
    Write-Host "Transferring archive..."
    scp ksit_nexus_backup.tar.gz mvpi_backend@100.87.200.4:~/ksit_nexus/
    
    Write-Host "Extracting on server..."
    ssh mvpi_backend@100.87.200.4 "cd ~/ksit_nexus && tar -xzf ksit_nexus_backup.tar.gz && rm ksit_nexus_backup.tar.gz"
    
    Write-Host "Cleaning up local archive..."
    Remove-Item ksit_nexus_backup.tar.gz
}

Write-Host "Transfer completed!"





