#!/bin/bash
set -e 

ENV_FILE="/opt/csye6225/webapp/.env"

if [ ! -d "/opt/csye6225/webapp" ]; then
  echo "Directory /opt/csye6225/webapp does not exist, exiting..."
  exit 1
fi

sudo chown -R csye6225:csye6225 /opt/csye6225/webapp
sudo chmod -R 755 /opt/csye6225
sudo chmod -R 755 /opt/csye6225/webapp

# Create the .env file properly
echo "Creating .env file..."
cat <<EOF | sudo tee "$ENV_FILE" > /dev/null
DB_HOST=${DB_HOST}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=${DB_NAME}
DB_PORT=${DB_PORT}
DB_DIALECT=${DB_DIALECT}
DB_FORCE_CHANGES=${DB_FORCE_CHANGES}
S3_BUCKET_NAME=${S3_BUCKET_NAME}
AWS_REGION=${AWS_REGION}
EOF

if [ -f "$ENV_FILE" ]; then
  sudo chmod 600 /opt/csye6225/webapp/.env
  sudo chown -R csye6225:csye6225 /opt/csye6225/webapp/.env
  ls -l /opt/csye6225/webapp/.env
  echo ".env file created successfully:"
  cat "$ENV_FILE"
else
  echo "Failed to create .env file"
  exit 1
fi


CLOUDWATCH_CONFIG_PATH="/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json"
 
 if [ -f "$CLOUDWATCH_CONFIG_PATH" ]; then
     sudo systemctl enable amazon-cloudwatch-agent
 
     sudo systemctl restart amazon-cloudwatch-agent
 
     echo "CloudWatch agent configured and restarted successfully."
 else
     echo "CloudWatch configuration file not found at $CLOUDWATCH_CONFIG_PATH."
     exit 1
 fi