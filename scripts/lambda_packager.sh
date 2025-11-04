#!/bin/bash
set -e

echo "Packaging Lambda functions..."

cd "$(dirname "$0")/../src/lambda"
mkdir -p build

# Package Validator Lambda (CSV - no dependencies!)
echo ""
echo "Packaging validator Lambda..."
rm -rf package
mkdir package

python3 -m pip install jsonschema==3.2.0 boto3 -t package/ --quiet

cp lambda_handler.py package/

cd package
zip -r ../build/validator.zip . -q
cd ..

VALIDATOR_SIZE=$(du -h build/validator.zip | cut -f1)
echo "Validator Lambda: $VALIDATOR_SIZE"

rm -rf package

# Package Quality Checker Lambda
echo ""
echo "Packaging quality checker Lambda..."
rm -rf package
mkdir package

python3 -m pip install jsonschema==3.2.0 boto3 -t package/ --quiet

cp quality_checker.py package/

cd package
zip -r ../build/quality.zip . -q
cd ..

QUALITY_SIZE=$(du -h build/quality.zip | cut -f1)
echo "Quality Lambda: $QUALITY_SIZE"

rm -rf package

echo ""
echo "All packages created successfully!"
echo ""
echo "Summary:"
echo "  - Validator Lambda: $VALIDATOR_SIZE (outputs CSV.gz)"
echo "  - Quality Lambda: $QUALITY_SIZE"
echo ""
echo "Output format: CSV with gzip compression"