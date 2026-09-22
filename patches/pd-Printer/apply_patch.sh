#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCH_FILE="$SCRIPT_DIR/vn_link_cli.patch"
RC_DIR="$SCRIPT_DIR/trunk/user/rc"

echo "=== vn-link-cli patch installer ==="

if [ ! -f "$PATCH_FILE" ]; then
    echo "Error: Patch file not found: $PATCH_FILE"
    exit 1
fi

if [ ! -d "$RC_DIR" ]; then
    echo "Error: RC directory not found: $RC_DIR"
    exit 1
fi

cd "$SCRIPT_DIR"

echo "[1/4] Applying patch..."
patch -p1 < "$PATCH_FILE"

echo "[2/4] Checking vn_link_cli.c..."
if [ -f "$RC_DIR/vn_link_cli.c" ]; then
    echo "  - vn_link_cli.c: OK"
else
    echo "Error: vn_link_cli.c not found after patch"
    exit 1
fi

echo "[3/4] Verifying modifications..."
for f in Makefile rc.h rc.c net_wan.c; do
    if [ -f "$RC_DIR/$f" ]; then
        echo "  - $f: OK"
    else
        echo "Error: $f not found"
        exit 1
    fi
done

echo "[4/4] Summary:"
echo "  - Makefile: added vn_link_cli.o and symlinks"
echo "  - rc.h: added function declarations"
echo "  - rc.c: added command handlers"
echo "  - net_wan.c: added internet state callback"
echo "  - vn_link_cli.c: new file (pure C implementation)"

echo ""
echo "=== Done! ==="
echo ""
echo "To build the firmware, run:"
echo "  cd trunk && ./build"
echo ""
echo "After flashing, enable the service:"
echo "  nvram set vn_link_cli_enable=1"
echo "  nvram commit"
echo ""
echo "Control commands:"
echo "  rc start_vn_link_cli   # start"
echo "  rc stop_vn_link_cli    # stop"
echo "  rc restart_vn_link_cli # restart"