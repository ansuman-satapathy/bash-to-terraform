#!/bin/bash

# ==================================================================
# Level 1: Monolithic Infrastructure with Bash Script
# ==================================================================

# 1. Fail-Fast
set -euo pipefail

echo "Starting Server Provisioning..."

# 2. Non-Interactive Mode
export DEBIAN_FRONTEND=noninteractive

# 3. System Updates and Core Packages
echo "--> Updating OS and installing core utilities..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl git vim ufw nginx htop

# 4. Firewall Configuration
echo "--> Configuring ufw firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# 5. Install Node.js via NVM
echo "--> Installing NVM and Node v24..."
# Download and install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash

# Load NVM into the current script session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node 24 and PM2
nvm install 24
nvm use 24
npm install -g pm2

# 6. Install Redis from Official Packages
echo "--> Installing Redis (Official Repo)..."
apt-get install -y lsb-release gpg curl
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list

apt-get update -y
apt-get install -y redis
systemctl enable redis-server
systemctl start redis-server

# 7. Install PostgreSQL from Official Apt Repository
echo "--> Installing PostgreSQL (Official Repo)..."
install -d /usr/share/postgresql-common/pgdg
curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

apt-get update -y
apt-get install -y postgresql postgresql-contrib

echo "--> Waiting for Postgres to initialize..."
sleep 3

echo "--> Seeding the Database..."
# Reset the default postgres user password so our app can connect
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';" || true

# Create the database (ignore error if it already exists)
sudo -u postgres psql -c "CREATE DATABASE testdb;" || true

# Connect to testdb and create the users table
sudo -u postgres psql -d testdb -c "
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);
INSERT INTO users (name) VALUES ('Alice (Monolith)'), ('Bob (Monolith)') ON CONFLICT DO NOTHING;
"

# 8. Application Deployment Simulation
echo "--> Deploying the Node.js application..."
mkdir -p /var/www/dummy-node-app

# Copy the app from the Vagrant synced folder to the web directory
cp -r /vagrant/dummy-node-app/* /var/www/dummy-node-app/
cd /var/www/dummy-node-app

# Ensure NVM is loaded in this sub-shell step
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Clean install to ensure Linux-specific binaries are built correctly inside the VM
rm -rf node_modules
npm install

# Start the app with PM2
echo "--> Starting the app with PM2..."
pm2 start server.js --name "dummy-node-app" || pm2 restart "dummy-node-app"
pm2 save

# Configure PM2 to start on boot via systemd
env PATH=$PATH:/usr/bin pm2 startup systemd -u root --hp /root

# 9. Configure Nginx Reverse Proxy
echo "--> Configuring Nginx..."
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Restart Nginx to apply the new configuration
systemctl restart nginx

echo "=============================================================================="
echo "✅ Provisioning Complete! The Monolith is live on Port 80."
echo "=============================================================================="