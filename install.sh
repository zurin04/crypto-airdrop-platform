#!/bin/bash

# Crypto Airdrop Platform - VPS Installation Script
# Compatible with Ubuntu/Debian systems with Webmin & LAMP

set -e

echo "=== Crypto Airdrop Platform Installation ==="
echo "Setting up on VPS with LAMP stack..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root"
    exit 1
fi

# Update system
echo "Updating system packages..."
apt update && apt upgrade -y

# Install Node.js 20 (required for the application)
echo "Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install PM2 for process management
echo "Installing PM2..."
npm install -g pm2

# Install PostgreSQL if not already installed
if ! command -v psql &> /dev/null; then
    echo "Installing PostgreSQL..."
    apt install -y postgresql postgresql-contrib
    systemctl start postgresql
    systemctl enable postgresql
fi

# Create application directory
APP_DIR="/var/www/crypto-airdrop"
echo "Setting up application directory at $APP_DIR..."
mkdir -p $APP_DIR
cp -r . $APP_DIR/
cd $APP_DIR

# Set proper permissions
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR

# Install application dependencies
echo "Installing application dependencies..."
npm install --production

# Build the application
echo "Building application..."
npm run build

# Create uploads directory
mkdir -p public/uploads
chown -R www-data:www-data public/uploads

# Setup PostgreSQL database
echo "Setting up PostgreSQL database..."
DB_NAME="crypto_airdrop"
DB_USER="crypto_user"
DB_PASS=$(openssl rand -base64 32)

sudo -u postgres psql <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
\q
EOF

# Create environment file
echo "Creating environment configuration..."
cat > .env <<EOF
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME
SESSION_SECRET=$(openssl rand -base64 64)
EOF

# Set environment file permissions
chown root:www-data .env
chmod 640 .env

# Setup database schema
echo "Setting up database schema..."
npm run db:push
npm run db:seed

# Create PM2 ecosystem file
echo "Creating PM2 configuration..."
cat > ecosystem.config.js <<EOF
module.exports = {
  apps: [{
    name: 'crypto-airdrop',
    script: 'dist/index.js',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    error_file: '/var/log/crypto-airdrop/error.log',
    out_file: '/var/log/crypto-airdrop/out.log',
    log_file: '/var/log/crypto-airdrop/combined.log',
    time: true
  }]
}
EOF

# Create log directory
mkdir -p /var/log/crypto-airdrop
chown www-data:www-data /var/log/crypto-airdrop

# Start application with PM2
echo "Starting application..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Setup Apache virtual host
echo "Configuring Apache virtual host..."
cat > /etc/apache2/sites-available/crypto-airdrop.conf <<EOF
<VirtualHost *:80>
    ServerName your-domain.com
    ServerAlias www.your-domain.com
    
    ProxyRequests Off
    ProxyPreserveHost On
    
    ProxyPass / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/
    
    # Enable WebSocket support
    ProxyPass /ws ws://localhost:3000/ws
    ProxyPassReverse /ws ws://localhost:3000/ws
    
    # Static file serving
    Alias /uploads $APP_DIR/public/uploads
    <Directory "$APP_DIR/public/uploads">
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/crypto-airdrop_error.log
    CustomLog \${APACHE_LOG_DIR}/crypto-airdrop_access.log combined
</VirtualHost>
EOF

# Enable Apache modules
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_wstunnel
a2enmod rewrite

# Enable site
a2ensite crypto-airdrop.conf
a2dissite 000-default.conf
systemctl reload apache2

# Create update script
cat > update.sh <<'EOF'
#!/bin/bash
cd /var/www/crypto-airdrop
git pull origin main
npm install --production
npm run build
pm2 restart crypto-airdrop
echo "Application updated successfully!"
EOF

chmod +x update.sh

# Create backup script
cat > backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/crypto-airdrop"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
sudo -u postgres pg_dump crypto_airdrop > $BACKUP_DIR/database_$DATE.sql

# Backup uploads
tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz -C /var/www/crypto-airdrop/public uploads

# Backup environment
cp /var/www/crypto-airdrop/.env $BACKUP_DIR/env_$DATE.backup

# Keep only last 30 days of backups
find $BACKUP_DIR -type f -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x backup.sh

# Setup daily backup cron
echo "0 2 * * * root /var/www/crypto-airdrop/backup.sh" >> /etc/crontab

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "Database Details:"
echo "  Name: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASS"
echo ""
echo "Application is running on: http://localhost:3000"
echo ""
echo "Next Steps:"
echo "1. Update Apache virtual host with your domain name:"
echo "   Edit /etc/apache2/sites-available/crypto-airdrop.conf"
echo "2. Configure SSL certificate (recommended)"
echo "3. Access Webmin to manage the server"
echo ""
echo "Management Commands:"
echo "  pm2 status           - Check application status"
echo "  pm2 restart crypto-airdrop - Restart application"
echo "  pm2 logs crypto-airdrop    - View logs"
echo "  ./update.sh          - Update application"
echo "  ./backup.sh          - Create backup"
echo ""