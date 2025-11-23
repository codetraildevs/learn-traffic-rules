#!/bin/bash

# Setup script for upload directories
# This script creates upload directories and sets proper permissions

# Configuration - CHANGE THESE VALUES
PROJECT_DIR="/path/to/your/project/backend"
NODE_USER="node"  # Change to your Node.js user (node, www-data, nginx, etc.)
NODE_GROUP="node" # Change to your Node.js group

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "📁 Setting up upload directories..."

# Navigate to project directory
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ Error: Project directory not found: $PROJECT_DIR${NC}"
    echo "Please update PROJECT_DIR in this script"
    exit 1
fi

cd "$PROJECT_DIR" || exit 1

# Create directories
echo "Creating directories..."
mkdir -p uploads/courses/images
mkdir -p uploads/courses/audio
mkdir -p uploads/courses/video
mkdir -p uploads/question-images

# Check if user exists
if ! id "$NODE_USER" &>/dev/null; then
    echo -e "${YELLOW}⚠️  Warning: User '$NODE_USER' does not exist${NC}"
    echo "Please update NODE_USER in this script or create the user"
    read -p "Continue without changing ownership? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    SKIP_OWNERSHIP=true
fi

# Set ownership (if user exists)
if [ "$SKIP_OWNERSHIP" != "true" ]; then
    echo "Setting ownership to $NODE_USER:$NODE_GROUP..."
    chown -R $NODE_USER:$NODE_GROUP uploads/ || {
        echo -e "${YELLOW}⚠️  Warning: Could not change ownership. You may need to run with sudo.${NC}"
    }
fi

# Set directory permissions (755)
echo "Setting directory permissions to 755..."
find uploads -type d -exec chmod 755 {} \;

# Set file permissions (644) for existing files
echo "Setting file permissions to 644..."
find uploads -type f -exec chmod 644 {} \;

# Verify permissions
echo ""
echo -e "${GREEN}✅ Upload directories configured!${NC}"
echo ""
echo "Verification:"
echo "============="
ls -ld uploads/
ls -ld uploads/courses/
ls -ld uploads/courses/images/
ls -ld uploads/courses/audio/
ls -ld uploads/courses/video/
echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Verify the Node.js process user matches: $NODE_USER"
echo "2. Test file upload functionality"
echo "3. Check server logs for any permission errors"

