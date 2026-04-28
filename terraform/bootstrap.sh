#!/bin/bash
# bootstrap.sh — run ONCE before the main terraform init/apply
# Solves the chicken-and-egg: S3 bucket must exist before terraform can use it as a backend.
#
# Usage:
#   chmod +x bootstrap.sh
#   ./bootstrap.sh

set -e

AWS_REGION="eu-west-2"
AWS_ACCOUNT_ID="975050024946"
STATE_BUCKET="shopnow-terraform-state-${AWS_ACCOUNT_ID}"
LOCK_TABLE="shopnow-terraform-locks"

echo "===> Checking AWS credentials..."
aws sts get-caller-identity

echo ""
echo "===> Step 1: Create S3 state bucket (if it does not exist)..."
if aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
  echo "     Bucket $STATE_BUCKET already exists — skipping."
else
  aws s3api create-bucket \
    --bucket "$STATE_BUCKET" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION"

  aws s3api put-bucket-versioning \
    --bucket "$STATE_BUCKET" \
    --versioning-configuration Status=Enabled

  aws s3api put-bucket-encryption \
    --bucket "$STATE_BUCKET" \
    --server-side-encryption-configuration \
      '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

  aws s3api put-public-access-block \
    --bucket "$STATE_BUCKET" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

  echo "     Bucket $STATE_BUCKET created."
fi

echo ""
echo "===> Step 2: Create DynamoDB lock table (if it does not exist)..."
if aws dynamodb describe-table --table-name "$LOCK_TABLE" --region "$AWS_REGION" 2>/dev/null; then
  echo "     Table $LOCK_TABLE already exists — skipping."
else
  aws dynamodb create-table \
    --table-name "$LOCK_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION"

  echo "     Table $LOCK_TABLE created."
fi

echo ""
echo "===> Bootstrap complete. Now run:"
echo "     terraform init"
echo "     terraform plan"
echo "     terraform apply"
