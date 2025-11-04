#!/bin/bash
set -e

echo "Packaging Lambda functions and PyArrow layer..."

cd "$(dirname "$0")/../src/lambda"
mkdir -p build layers

# Build PyArrow layer with Docker (Lambda-compatible)
echo ""
echo "Building PyArrow layer with Docker..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is required to build Lambda layers"
    echo "Install Docker Desktop: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Create Dockerfile for layer building
cat > Dockerfile.layer <<'EOF'
FROM public.ecr.aws/lambda/python:3.12

WORKDIR /opt

# Install PyArrow in the layer structure
RUN pip install --no-cache-dir pyarrow==14.0.1 -t python/

# Clean up unnecessary files to reduce size
RUN find python/ -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true
RUN find python/ -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
RUN find python/ -name "*.pyc" -delete
EOF

# Build layer with Docker
echo "Building Docker image..."
docker build -f Dockerfile.layer -t lambda-pyarrow-layer . --quiet

# Extract layer from container
echo "Extracting layer files..."
rm -rf layer_temp
mkdir layer_temp

CONTAINER_ID=$(docker create lambda-pyarrow-layer)
docker cp $CONTAINER_ID:/opt/python layer_temp/
docker rm $CONTAINER_ID > /dev/null

# Zip the layer
echo "Creating layer ZIP..."
cd layer_temp
zip -r -q ../layers/pyarrow-layer.zip python/
cd ..

LAYER_SIZE=$(du -h layers/pyarrow-layer.zip | cut -f1)
echo "PyArrow layer: $LAYER_SIZE"

# Clean up
rm -rf layer_temp
rm Dockerfile.layer

# Package Validator Lambda (without PyArrow)
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
echo "  - PyArrow layer: $LAYER_SIZE (custom built)"
echo "  - Validator Lambda: $VALIDATOR_SIZE"
echo "  - Quality Lambda: $QUALITY_SIZE"