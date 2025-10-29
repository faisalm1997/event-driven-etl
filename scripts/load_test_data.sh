#!/bin/bash
set -e

# Load test data script - generates and uploads JSON events to S3

# Config and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_DATA_DIR="$REPO_ROOT/test-data"

# Get bucket name from Terragrunt output
cd "$REPO_ROOT/infrastructure/terragrunt/dev"
SOURCE_BUCKET=$(terragrunt output -raw source_bucket_name 2>/dev/null || echo "")

if [ -z "$SOURCE_BUCKET" ]; then
    echo "Error: Could not get source bucket name from Terragrunt"
    echo "Make sure you've deployed infrastructure first"
    exit 1
fi

echo "Source bucket: $SOURCE_BUCKET"

# Create test directory to hold data files
mkdir -p "$TEST_DATA_DIR"

# Function to generate random test events
generate_test_events() {
    local filename=$1
    local num_events=$2
    local filepath="$TEST_DATA_DIR/$filename"
    
    echo "Generating $num_events events in $filename..."
    
    cat > "$filepath" <<EOF
[
EOF
    
    for ((i=1; i<=num_events; i++)); do
        # Generate random value between 0-100
        value=$(awk -v min=0 -v max=100 'BEGIN{srand(); print min+rand()*(max-min)}')
        
        # Generate timestamp (current time + random offset)
        offset=$((RANDOM % 3600))
        timestamp=$(date -u -v+${offset}S +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+${offset} seconds" +"%Y-%m-%dT%H:%M:%SZ")
        
        cat >> "$filepath" <<EOF
  {
    "id": $i,
    "ts": "$timestamp",
    "value": $value
  }
EOF
        
        if [ $i -lt $num_events ]; then
            echo "," >> "$filepath"
        else
            echo "" >> "$filepath"
        fi
    done
    
    cat >> "$filepath" <<EOF
]
EOF
    
    echo "Generated $filepath"
}

# Generate test files
echo "Generating test data files..."

generate_test_events "events_001.json" 10
generate_test_events "events_002.json" 25
generate_test_events "events_003.json" 50

# Generate a file with invalid data (for testing validation)
cat > "$TEST_DATA_DIR/events_invalid.json" <<EOF
[
  {
    "id": 999,
    "ts": "2025-01-27T12:00:00Z",
    "value": 42.5
  },
  {
    "id": "not_an_integer",
    "ts": "2025-01-27T12:01:00Z",
    "value": "not_a_number"
  }
]
EOF
echo "Generated $TEST_DATA_DIR/events_invalid.json (intentionally invalid)"

# Upload to S3
echo ""
echo "Uploading test files to S3..."

for file in "$TEST_DATA_DIR"/*.json; do
    filename=$(basename "$file")
    
    echo "Uploading $filename..."
    aws s3 cp "$file" "s3://$SOURCE_BUCKET/incoming/$filename"
    
    if [ $? -eq 0 ]; then
        echo "Uploaded s3://$SOURCE_BUCKET/incoming/$filename"
    else
        echo "Failed to upload $filename"
    fi
done

echo ""
echo "Test data upload complete!"
echo ""
echo "Next steps:"
echo "1. Check Lambda logs:"
echo "   aws logs tail /aws/lambda/ede-dev-validator --follow"
echo ""
echo "2. List curated bucket contents:"
echo "   aws s3 ls s3://\$(cd infrastructure/terragrunt/dev && terragrunt output -raw curated_bucket_name)/validated/ --recursive"
echo ""
echo "3. Query with Athena (if enabled):"
echo "   aws athena start-query-execution \\"
echo "     --query-string \"SELECT * FROM ede_dev.validated_events LIMIT 10\" \\"
echo "     --work-group ede-dev"