#!/usr/bin/env bash
set -e

export AWS_DEFAULT_REGION="us-east-2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# (Fix important) AWS CLI attend du user-data en base64 si on le passe en string
user_data_b64="$(base64 -w0 "$SCRIPT_DIR/user-data.sh")"

# (Fix utile) récupérer le VPC par défaut (sinon create-security-group peut échouer)
vpc_id="$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" \
  --output text)"

# Create a security group (le nom fixe est volontaire → exercice 1)
security_group_id="$(aws ec2 create-security-group \
  --group-name "sample-app" \
  --description "Allow HTTP traffic into the sample app" \
  --vpc-id "$vpc_id" \
  --output text \
  --query GroupId)"

# Allow inbound HTTP traffic (port 80)
aws ec2 authorize-security-group-ingress \
  --group-id "$security_group_id" \
  --protocol tcp \
  --port 80 \
  --cidr "0.0.0.0/0" > /dev/null

# Launch the EC2 instance
instance_id="$(aws ec2 run-instances \
  --image-id "ami-0900fe555666598a2" \
  --instance-type "t3.micro" \
  --security-group-ids "$security_group_id" \
  --user-data "$user_data_b64" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sample-app}]' \
  --output text \
  --query Instances[0].InstanceId)"

# Wait for the instance to be running
aws ec2 wait instance-running --instance-ids "$instance_id"

# Get public IP
public_ip="$(aws ec2 describe-instances \
  --instance-ids "$instance_id" \
  --output text \
  --query 'Reservations[0].Instances[0].PublicIpAddress')"

echo "Instance ID = $instance_id"
echo "Security Group ID = $security_group_id"
echo "Public IP = $public_ip"
echo "Test: http://$public_ip"
