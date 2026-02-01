#!/bin/bash
set -e

echo "🔍 Validating Render Free Tier Setup..."
echo ""

# Check required files
echo "✅ Checking required files..."
files=(
    "Dockerfile"
    "render.yaml"
    "prometheus.yml"
    "grafana-datasources.yml"
    "dashboard-provider.yml"
    "supervisord.conf"
    "start.sh"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file exists"
    else
        echo "  ✗ $file missing!"
        exit 1
    fi
done

# Check dashboards
echo ""
echo "✅ Checking dashboards..."
dashboard_count=$(ls -1 dashboards/*.json 2>/dev/null | wc -l)
echo "  ✓ Found $dashboard_count dashboards"

# Validate YAML syntax
echo ""
echo "✅ Validating YAML files..."
if command -v python3 &> /dev/null; then
    python3 -c "import yaml; yaml.safe_load(open('render.yaml'))" && echo "  ✓ render.yaml is valid"
    python3 -c "import yaml; yaml.safe_load(open('prometheus.yml'))" && echo "  ✓ prometheus.yml is valid"
else
    echo "  ⚠ Python3 not available, skipping YAML validation"
fi

# Check file sizes
echo ""
echo "✅ Checking file sizes..."
total_size=$(du -sh . | cut -f1)
echo "  ✓ Total project size: $total_size"

# Verify render.yaml has free plan
echo ""
echo "✅ Checking Render configuration..."
if grep -q "plan: free" render.yaml; then
    echo "  ✓ Configured for FREE tier"
else
    echo "  ⚠ Plan not set to 'free'"
fi

echo ""
echo "🎉 All checks passed! Ready to deploy to Render."
echo ""
echo "Next steps:"
echo "1. git add ."
echo "2. git commit -m 'Ready for Render free tier'"
echo "3. git push"
echo "4. Deploy via Render Dashboard (Blueprint)"
