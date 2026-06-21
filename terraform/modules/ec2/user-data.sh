#!/bin/bash
# User Data Script for EC2 Instance
# Installs Docker, git, and SSM agent

set -e

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install git
yum install git -y

# Install SSM agent (for SSH alternative)
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Create apps directory
mkdir -p /home/ec2-user/apps
chown ec2-user:ec2-user /home/ec2-user/apps

# Create deploy script helper
cat > /home/ec2-user/deploy.sh << 'EOF'
#!/bin/bash
# Deploy helper script
set -e

REPO_URL=$1
APP_DIR=$2
PORT=${3:-3000}

if [ -z "$REPO_URL" ] || [ -z "$APP_DIR" ]; then
    echo "Usage: deploy.sh <repo_url> <app_dir> [port]"
    exit 1
fi

cd /home/ec2-user/apps

if [ -d "$APP_DIR" ]; then
    echo "Updating existing app..."
    cd "$APP_DIR"
    git pull
    docker build -t "${APP_DIR}:latest" .
    docker stop "$APP_DIR" 2>/dev/null || true
    docker rm "$APP_DIR" 2>/dev/null || true
    docker run -d --name "$APP_DIR" -p "${PORT}:${PORT}" --restart unless-stopped "${APP_DIR}:latest"
else
    echo "First time deploy..."
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
    docker build -t "${APP_DIR}:latest" .
    docker run -d --name "$APP_DIR" -p "${PORT}:${PORT}" --restart unless-stopped "${APP_DIR}:latest"
fi

echo "Deploy complete!"
docker ps | grep "$APP_DIR"
EOF

chmod +x /home/ec2-user/deploy.sh
chown ec2-user:ec2-user /home/ec2-user/deploy.sh

# Log completion
echo "Blink EC2 setup complete at $(date)" >> /var/log/blink-setup.log
