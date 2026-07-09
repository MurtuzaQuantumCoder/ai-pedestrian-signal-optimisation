#!/bin/bash
# Run this in Cursor's terminal after logging into GitHub (gh auth login)
set -e
cd "$(dirname "$0")"
git add README.md
git commit -m "Merge remote README and finalize Klik branding" 2>/dev/null || true
git push -u origin main
echo ""
echo "Done! Open https://github.com/MurtuzaQuantumCoder/klik"
