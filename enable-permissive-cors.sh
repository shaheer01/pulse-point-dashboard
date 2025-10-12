#!/bin/bash
# Temporarily enable permissive CORS for testing
# ⚠️ DO NOT use this in production!

echo "⚠️  WARNING: This enables CORS for ALL origins (for testing only)"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Cancelled."
    exit 1
fi

echo "Updating CORS to allow all origins..."

# Backup original main.py
cp backend/main.py backend/main.py.backup

# Replace CORS config
python3 << 'EOF'
import re

with open('backend/main.py', 'r') as f:
    content = f.read()

# Replace the allow_origins list with ["*"]
content = re.sub(
    r'allow_origins=\[.*?\]',
    'allow_origins=["*"]',
    content,
    flags=re.DOTALL
)

with open('backend/main.py', 'w') as f:
    f.write(content)

print("✅ CORS updated to allow all origins")
EOF

echo ""
echo "Restarting backend..."
docker-compose restart backend

echo ""
echo "✅ Done! Test your analytics now."
echo ""
echo "⚠️  To restore original CORS settings:"
echo "   cp backend/main.py.backup backend/main.py"
echo "   docker-compose restart backend"
