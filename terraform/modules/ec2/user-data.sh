#!/bin/bash
# User Data Script for EC2 Instance
# Installs Docker, docker-compose, git, and SSM agent

set -e

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install docker-compose
DOCKER_COMPOSE_VERSION="v2.24.0"
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

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

if [ -z "$REPO_URL" ] || [ -z "$APP_DIR" ]; then
    echo "Usage: deploy.sh <repo_url> <app_dir>"
    exit 1
fi

cd /home/ec2-user/apps

if [ -d "$APP_DIR" ]; then
    echo "Updating existing app..."
    cd "$APP_DIR"
    git pull
    docker-compose down || true
    docker-compose up --build -d
else
    echo "First time deploy..."
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
    docker-compose up --build -d
fi

echo "Deploy complete!"
docker-compose ps
EOF

chmod +x /home/ec2-user/deploy.sh
chown ec2-user:ec2-user /home/ec2-user/deploy.sh

# Log completion
echo "Blink EC2 setup complete at $(date)" >> /var/log/blink-setup.log
