# Crypto Airdrop Platform

A comprehensive cryptocurrency learning and engagement platform that enables users to explore, learn, and participate in cryptocurrency ecosystems through advanced user management, creator workflows, and Web3 integration.

## Features

- **User Authentication**: Traditional login/register and Web3 wallet integration
- **Airdrop Management**: Browse, save, and track cryptocurrency airdrops
- **Creator System**: Apply to become a creator and manage airdrop listings
- **Admin Panel**: Comprehensive administration tools
- **Real-time Chat**: Global chat system with WebSocket support
- **Crypto Prices**: Live cryptocurrency price tracking
- **Role-based Access**: User, Creator, and Admin permission levels

## Tech Stack

- **Frontend**: React 18, TypeScript, Tailwind CSS, Shadcn/UI
- **Backend**: Node.js, Express, TypeScript
- **Database**: PostgreSQL with Drizzle ORM
- **Authentication**: Passport.js, SIWE (Sign-In with Ethereum)
- **Real-time**: WebSocket for chat functionality
- **Build**: Vite, ESBuild

## VPS Installation

### Prerequisites

- Ubuntu/Debian VPS with root access
- LAMP stack (Apache, MySQL/PostgreSQL, PHP) - Apache will be used as reverse proxy
- Webmin for server management (optional but recommended)

### Quick Installation

1. Upload the project files to your VPS
2. Run the installation script:

```bash
chmod +x install.sh
sudo ./install.sh
```

The script will:
- Install Node.js 20 and PM2
- Setup PostgreSQL database
- Install and build the application
- Configure Apache reverse proxy
- Start the application with PM2
- Setup automated backups

### Manual Configuration

After installation, update the Apache virtual host:

```bash
sudo nano /etc/apache2/sites-available/crypto-airdrop.conf
```

Replace `your-domain.com` with your actual domain name.

### SSL Certificate (Recommended)

Install Certbot for free SSL:

```bash
sudo apt install certbot python3-certbot-apache
sudo certbot --apache -d your-domain.com
```

## Application Management

### PM2 Commands

```bash
pm2 status                    # Check application status
pm2 restart crypto-airdrop    # Restart application
pm2 logs crypto-airdrop       # View logs
pm2 monit                     # Monitor resources
```

### Database Management

```bash
# Access PostgreSQL
sudo -u postgres psql crypto_airdrop

# Run database migrations
cd /var/www/crypto-airdrop
npm run db:push

# Seed database
npm run db:seed
```

### Updates

```bash
cd /var/www/crypto-airdrop
./update.sh
```

### Backups

```bash
./backup.sh  # Manual backup
```

Automated daily backups are configured via cron at 2 AM.

## Environment Variables

Key environment variables (automatically set during installation):

- `NODE_ENV=production`
- `PORT=3000`
- `DATABASE_URL=postgresql://user:pass@localhost:5432/crypto_airdrop`
- `SESSION_SECRET=random_secret`

## Default Admin Access

After installation, access the application and register the first user - they will automatically become an admin.

## File Structure

```
/var/www/crypto-airdrop/
├── client/               # React frontend
├── server/               # Express backend
├── shared/               # Shared schemas and types
├── db/                   # Database configuration
├── public/               # Static files and uploads
├── dist/                 # Built application
├── ecosystem.config.js   # PM2 configuration
├── update.sh            # Update script
├── backup.sh            # Backup script
└── .env                 # Environment variables
```

## Troubleshooting

### Application Won't Start

```bash
pm2 logs crypto-airdrop  # Check logs
pm2 restart crypto-airdrop
```

### Database Connection Issues

```bash
sudo systemctl status postgresql
sudo -u postgres psql -c "\l"  # List databases
```

### Apache Issues

```bash
sudo systemctl status apache2
sudo apache2ctl configtest
sudo tail -f /var/log/apache2/error.log
```

### File Permissions

```bash
sudo chown -R www-data:www-data /var/www/crypto-airdrop
sudo chmod -R 755 /var/www/crypto-airdrop
```

## Support

For technical support or questions about deployment, check the application logs and Apache error logs first. The application includes comprehensive error handling and logging.