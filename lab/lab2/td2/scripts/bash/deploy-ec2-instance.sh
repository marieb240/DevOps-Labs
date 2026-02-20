#!/usr/bin/env bash
set -e

export AWS_DEFAULT_REGION="eu-north-1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Number of instances to launch (can be passed as first arg or via env)
COUNT="${1:-2}"

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

# Launch instances (compact handling of multiple instances)
instance_ids=$(aws ec2 run-instances \
  --image-id "ami-0836abe45b78b6960" \
  --instance-type "t3.micro" \
  --security-group-ids "$security_group_id" \
  --user-data "$user_data_b64" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sample-app}]' \
  --count "$COUNT" \
  --output text \
  --query 'Instances[*].InstanceId')

# Wait for all instances
aws ec2 wait instance-running --instance-ids $instance_ids

# Print InstanceId + PublicIp for each instance
aws ec2 describe-instances --instance-ids $instance_ids \
  --output text --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress]' \
| while read id ip; do
    echo "Instance ID = $id"
    echo "Security Group ID = $security_group_id"
    echo "Public IP = ${ip:-<pending>}"
    echo "Test: http://${ip:-<pending>}"
  done
