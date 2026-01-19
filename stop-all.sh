#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${YELLOW}Stopping HAI Intel Platform${NC}"
echo "=================================================="
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Stop Keycloak infrastructure
echo -e "${YELLOW}Stopping Keycloak infrastructure...${NC}"
cd "$SCRIPT_DIR/keycloak-infra"
make stop
echo ""

# Stop shared infrastructure
echo -e "${YELLOW}Stopping shared infrastructure...${NC}"
cd "$SCRIPT_DIR/shared-infra"
make stop
echo ""

echo -e "${GREEN}✓ HAI Intel Platform stopped${NC}"

