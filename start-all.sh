#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 Starting HAI Intel Platform${NC}"
echo "=================================================="
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running${NC}"
    echo "Please start Docker Desktop and try again."
    exit 1
fi

echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Step 1: Start shared infrastructure
echo -e "${CYAN}Step 1/2: Starting Shared Infrastructure${NC}"
echo "---------------------------------------------------"
cd "$SCRIPT_DIR/shared-infra"
make start
echo ""
sleep 3

# Step 2: Start Keycloak infrastructure
echo -e "${CYAN}Step 2/2: Starting Keycloak Infrastructure${NC}"
echo "---------------------------------------------------"
cd "$SCRIPT_DIR/keycloak-infra"
make start
echo ""

# Wait for services
echo -e "${YELLOW}Waiting for services to be healthy...${NC}"

# Wait for Keycloak
echo -n "Waiting for Keycloak... "
timeout=120
counter=0
until curl -sf http://localhost:8080/health/ready > /dev/null 2>&1; do
    sleep 3
    counter=$((counter + 3))
    if [ $counter -ge $timeout ]; then
        echo -e "${RED}✗ Timeout${NC}"
        echo "Keycloak failed to start. Check logs: docker logs haiintel-keycloak"
        exit 1
    fi
done
echo -e "${GREEN}✓${NC}"

echo ""
echo -e "${GREEN}=================================================="
echo "✓ HAI Intel Platform is up and running!"
echo "==================================================${NC}"
echo ""
echo -e "${CYAN}Service URLs:${NC}"
echo -e "  ${GREEN}Keycloak:${NC}    http://localhost:8080 (admin/admin)"
echo -e "  ${GREEN}Grafana:${NC}     http://localhost:3000 (admin/admin)"
echo -e "  ${GREEN}Prometheus:${NC}  http://localhost:9090"
echo ""
echo -e "${CYAN}Useful Commands:${NC}"
echo "  View Keycloak logs:  cd keycloak-infra && make logs"
echo "  View shared logs:    cd shared-infra && make logs"
echo "  Check status:        docker ps --filter 'name=haiintel-'"
echo "  Stop all:            ./stop-all.sh"
echo ""

