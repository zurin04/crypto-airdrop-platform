# VPS Installation Guide

## Quick Start

1. **Upload files to VPS**
   ```bash
   scp -r crypto-airdrop-platform/ root@your-vps-ip:/tmp/
   ```

2. **Run installation**
   ```bash
   ssh root@your-vps-ip
   cd /tmp/crypto-airdrop-platform
   chmod +x install.sh
   ./install.sh
   ```

3. **Configure domain**
   ```bash
   nano /etc/apache2/sites-available/crypto-airdrop.conf
   # Replace 'your-domain.com' with actual domain
   systemctl reload apache2
   ```

## Installation Options

### Option 1: PM2 Process Manager (Recommended)
The install.sh script uses PM2 for process management with automatic startup and monitoring.

### Option 2: Systemd Service
For better VPS integration:
```bash
cp crypto-airdrop.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable crypto-airdrop
systemctl start crypto-airdrop
```

## Post-Installation

1. **SSL Certificate**
   ```bash
   certbot --apache -d your-domain.com
   ```

2. **First Admin User**
   - Visit your domain
   - Register first user (automatically becomes admin)

3. **Webmin Integration**
   - Service appears in Webmin under "System" → "Running Processes"
   - Logs available in "System" → "System Logs"

## Management Commands

```bash
# PM2 Management
pm2 status
pm2 restart crypto-airdrop
pm2 logs crypto-airdrop

# Systemd Management
systemctl status crypto-airdrop
systemctl restart crypto-airdrop
journalctl -u crypto-airdrop -f

# Application Updates
cd /var/www/crypto-airdrop
./update.sh

# Backups
./backup.sh
```

## File Locations

- **Application**: `/var/www/crypto-airdrop/`
- **Logs**: `/var/log/crypto-airdrop/`
- **Uploads**: `/var/www/crypto-airdrop/public/uploads/`
- **Backups**: `/var/backups/crypto-airdrop/`
- **Config**: `/var/www/crypto-airdrop/.env`