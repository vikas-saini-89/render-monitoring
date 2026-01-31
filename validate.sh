#!/bin/bash

# Validation Script for Monitoring Stack
# Validates that all components are properly configured and running

set -e

echo "=========================================="
echo "Monitoring Stack Validation"
echo "=========================================="

ERRORS=0
WARNINGS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print results
print_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Check if files exist
echo ""
echo "1. Checking configuration files..."
files=(
    "prometheus.yml"
    "alert-rules.yml"
    "alertmanager.yml"
    "docker-compose.yml"
    "dashboards/attendance-pulse.json"
    "dashboards/leave-reconciliation.json"
    "dashboards/streaming-payroll.json"
    "dashboards/system-health.json"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        print_ok "Found $file"
    else
        print_error "Missing $file"
    fi
done

# Validate YAML syntax
echo ""
echo "2. Validating YAML syntax..."
yaml_files=("prometheus.yml" "alert-rules.yml" "alertmanager.yml" "docker-compose.yml")

for file in "${yaml_files[@]}"; do
    if [ -f "$file" ]; then
        if command -v yamllint &> /dev/null; then
            if yamllint "$file" > /dev/null 2>&1; then
                print_ok "$file syntax is valid"
            else
                print_warning "$file has syntax warnings"
            fi
        else
            print_warning "yamllint not installed, skipping YAML validation"
            break
        fi
    fi
done

# Validate JSON syntax
echo ""
echo "3. Validating JSON syntax..."
json_files=(
    "dashboards/attendance-pulse.json"
    "dashboards/leave-reconciliation.json"
    "dashboards/streaming-payroll.json"
    "dashboards/system-health.json"
)

for file in "${json_files[@]}"; do
    if [ -f "$file" ]; then
        if command -v jq &> /dev/null; then
            if jq empty "$file" > /dev/null 2>&1; then
                print_ok "$file is valid JSON"
            else
                print_error "$file has invalid JSON syntax"
            fi
        else
            if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
                print_ok "$file is valid JSON"
            else
                print_error "$file has invalid JSON syntax"
            fi
        fi
    fi
done

# Check Docker
echo ""
echo "4. Checking Docker..."
if command -v docker &> /dev/null; then
    print_ok "Docker is installed"
    
    if docker ps &> /dev/null; then
        print_ok "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
    fi
else
    print_error "Docker is not installed"
fi

# Check Docker Compose
echo ""
echo "5. Checking Docker Compose..."
if command -v docker-compose &> /dev/null; then
    print_ok "Docker Compose is installed"
    VERSION=$(docker-compose --version)
    print_ok "Version: $VERSION"
else
    print_error "Docker Compose is not installed"
fi

# Check if services are running (if docker-compose.yml is in current directory)
if [ -f "docker-compose.yml" ]; then
    echo ""
    echo "6. Checking running services..."
    
    if docker-compose ps | grep -q "Up"; then
        services=("prometheus" "grafana" "alertmanager" "node-exporter")
        
        for service in "${services[@]}"; do
            if docker-compose ps | grep -q "$service.*Up"; then
                print_ok "$service is running"
            else
                print_warning "$service is not running"
            fi
        done
    else
        print_warning "No services are currently running"
    fi
    
    # Check service endpoints
    echo ""
    echo "7. Checking service endpoints..."
    
    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        print_ok "Prometheus is accessible on port 9090"
    else
        print_warning "Prometheus is not accessible on port 9090"
    fi
    
    if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
        print_ok "Grafana is accessible on port 3000"
    else
        print_warning "Grafana is not accessible on port 3000"
    fi
    
    if curl -s http://localhost:9093/-/healthy > /dev/null 2>&1; then
        print_ok "Alertmanager is accessible on port 9093"
    else
        print_warning "Alertmanager is not accessible on port 9093"
    fi
fi

# Check script permissions
echo ""
echo "8. Checking script permissions..."
scripts=("deploy-1gb-vm.sh" "deploy-vm2.sh" "validate.sh")

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            print_ok "$script is executable"
        else
            print_warning "$script is not executable (run: chmod +x $script)"
        fi
    fi
done

# Summary
echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
print_ok "Checks passed: $(($(ls -1 | wc -l) - ERRORS - WARNINGS))"
if [ $WARNINGS -gt 0 ]; then
    print_warning "Warnings: $WARNINGS"
fi
if [ $ERRORS -gt 0 ]; then
    print_error "Errors: $ERRORS"
fi
echo "=========================================="

# Exit with error if there are errors
if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "Validation failed with $ERRORS error(s)."
    exit 1
else
    echo ""
    echo "✓ Validation completed successfully!"
    exit 0
fi
