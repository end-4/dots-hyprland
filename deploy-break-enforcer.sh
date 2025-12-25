#!/usr/bin/env bash
# ==============================================================================
# Break Enforcer - Deployment Script
# ==============================================================================
# 
# This script deploys the Break Enforcer system files from the repository
# to your active configuration directories.
#
# What it does:
# 1. Creates necessary directories in ~/.local/share
# 2. Copies Break Enforcer QML files and Python scripts
# 3. Updates digital-wellbeing.py with database support
# 4. Adds Hyprland layer rules for fullscreen break overlay
# 5. Creates backups of modified files
#
# Usage: ./deploy-break-enforcer.sh
#
# ==============================================================================

set -e

echo "🚀 Break Enforcer Deployment Script"
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Paths
REPO_ROOT="$HOME/DotFiles/dots-hyprland"
CONFIG_ROOT="$HOME/.config"
SHARE_ROOT="$HOME/.local/share"

echo -e "${BLUE}Step 1: Creating necessary directories${NC}"
mkdir -p "$SHARE_ROOT/digital-wellbeing"
echo "✓ Created $SHARE_ROOT/digital-wellbeing"
echo ""

echo -e "${BLUE}Step 2: Copying new Break Enforcer files${NC}"
cp -v "$REPO_ROOT/dots/.config/hypr/productivity/break-enforcer.qml" \
   "$CONFIG_ROOT/hypr/productivity/break-enforcer.qml"

cp -v "$REPO_ROOT/dots/.config/hypr/productivity/break-questions.json" \
   "$CONFIG_ROOT/hypr/productivity/break-questions.json"

cp -v "$REPO_ROOT/dots/.config/hypr/productivity/save-break-response.py" \
   "$CONFIG_ROOT/hypr/productivity/save-break-response.py"

chmod +x "$CONFIG_ROOT/hypr/productivity/save-break-response.py"
echo "✓ Made save-break-response.py executable"
echo ""

echo -e "${BLUE}Step 3: Backing up and updating digital-wellbeing.py${NC}"
if [ -f "$CONFIG_ROOT/hypr/productivity/digital-wellbeing.py" ]; then
    cp -v "$CONFIG_ROOT/hypr/productivity/digital-wellbeing.py" \
       "$CONFIG_ROOT/hypr/productivity/digital-wellbeing.py.backup-$(date +%Y%m%d-%H%M%S)"
    echo "✓ Backup created"
fi

cp -v "$REPO_ROOT/dots/.config/hypr/productivity/digital-wellbeing.py" \
   "$CONFIG_ROOT/hypr/productivity/digital-wellbeing.py"
echo ""

echo -e "${BLUE}Step 4: Backing up and updating Hyprland rules${NC}"
if [ -f "$CONFIG_ROOT/hypr/custom/rules.conf" ]; then
    cp -v "$CONFIG_ROOT/hypr/custom/rules.conf" \
       "$CONFIG_ROOT/hypr/custom/rules.conf.backup-$(date +%Y%m%d-%H%M%S)"
    echo "✓ Backup created"
fi

cp -v "$REPO_ROOT/dots/.config/hypr/custom/rules.conf" \
   "$CONFIG_ROOT/hypr/custom/rules.conf"
echo ""

echo -e "${BLUE}Step 5: Copying documentation${NC}"
cp -v "$REPO_ROOT/dots/.config/hypr/productivity/BREAK_ENFORCER_IMPLEMENTATION_PLAN.md" \
   "$CONFIG_ROOT/hypr/productivity/" 2>/dev/null || true
cp -v "$REPO_ROOT/dots/.config/hypr/productivity/BREAK_ENFORCER_QUICKSTART.md" \
   "$CONFIG_ROOT/hypr/productivity/" 2>/dev/null || true
echo ""

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Reload Hyprland: hyprctl reload"
echo "2. Restart digital-wellbeing service: systemctl --user restart digital-wellbeing.service"
echo "3. Test the break enforcer: qs -p ~/.config/hypr/productivity/break-enforcer.qml -- 10 eye_care"
echo ""
echo -e "${YELLOW}Files deployed:${NC}"
echo "  • break-enforcer.qml (NEW)"
echo "  • break-questions.json (NEW)"
echo "  • save-break-response.py (NEW)"
echo "  • digital-wellbeing.py (MODIFIED - added database tables)"
echo "  • custom/rules.conf (MODIFIED)"
echo ""
echo -e "${YELLOW}Database changes:${NC}"
echo "  • Added break_responses table (stores question/answer IDs)"
echo "  • Added break_stats table (daily statistics)"
echo "  • Responses are now in SQLite, not JSONL"
echo ""
echo -e "${YELLOW}Backup files created in:${NC}"
echo "  • ~/.config/hypr/productivity/*.backup-*"
echo "  • ~/.config/hypr/custom/*.backup-*"
