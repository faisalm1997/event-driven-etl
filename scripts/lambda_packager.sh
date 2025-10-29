#!/bin/bash
set -e

echo "Packaging Lambda function..."

# Navigate to lambda directory
cd "$(dirname "$0")/../src/lambda"

# Create build directory
mkdir -p build

# Create a temporary package directory
rm -rf package
mkdir package

# Install dependencies
echo "Installing dependencies..."
pip install jsonschema boto3 -t package/ --quiet

# Copy handler
cp lambda_handler.py package/

# Create ZIP
echo "Creating ZIP archive..."
cd package
zip -r ../build/validator.zip . -q
cd ..

# Cleanup
rm -rf package

echo "Lambda package created: src/lambda/build/validator.zip"
ls -lh build/validator.zip