#!/bin/bash

# Production Setup for VPS with Webmin & LAMP
# This script prepares the application for production deployment

set -e

APP_DIR="/var/www/crypto-airdrop"
LOG_DIR="/var/log/crypto-airdrop"

echo "Setting up production environment..."

# Create necessary directories
mkdir -p $LOG_DIR
mkdir -p $APP_DIR/public/uploads

# Set proper ownership and permissions
chown -R www-data:www-data $APP_DIR
chown -R www-data:www-data $LOG_DIR
chmod -R 755 $APP_DIR
chmod -R 755 $LOG_DIR

# Install production dependencies only
echo "Installing production dependencies..."
npm ci --only=production

# Build application
echo "Building application for production..."
npm run build

# Create PM2 ecosystem configuration
cat > ecosystem.config.js <<EOF
module.exports = {
  apps: [{
    name: 'crypto-airdrop',
    script: 'dist/index.js',
    cwd: '$APP_DIR',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    instances: 1,
    exec_mode: 'cluster',
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    error_file: '$LOG_DIR/error.log',
    out_file: '$LOG_DIR/out.log',
    log_file: '$LOG_DIR/combined.log',
    time: true,
    node_args: '--max-old-space-size=1024'
  }]
}
EOF

echo "Production setup completed successfully!"