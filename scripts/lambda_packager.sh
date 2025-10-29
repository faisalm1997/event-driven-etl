#!/bin/bash
set -e

echo "Packaging Lambda functions..."

# Navigate to lambda directory
cd "$(dirname "$0")/../src/lambda"

# Create build directory
mkdir -p build

# Package Validator Lambda
echo "Packaging validator Lambda..."
rm -rf package
mkdir package

python3 -m pip install jsonschema boto3 -t package/ --quiet
cp lambda_handler.py package/

cd package
zip -r ../build/validator.zip . -q
cd ..
rm -rf package

echo "Validator Lambda: src/lambda/build/validator.zip"
ls -lh build/validator.zip

# Package Quality Checker Lambda
echo "Packaging quality checker Lambda..."
rm -rf package
mkdir package

python3 -m pip install jsonschema boto3 -t package/ --quiet
cp quality_checker.py package/

cd package
zip -r ../build/quality.zip . -q
cd ..
rm -rf package

echo "Quality Lambda: src/lambda/build/quality.zip"
ls -lh build/quality.zip

echo ""
echo "All Lambda packages created successfully!"