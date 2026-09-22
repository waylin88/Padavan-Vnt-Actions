#!/bin/bash
# ============================================================
#  apply_vn_link_cli_patch.sh
#  云编译补丁脚本：将 vn-link-cli 深度集成到 rc 守护进程
#
#  用法: bash apply_vn_link_cli_patch.sh [源码根目录]
#        如果不传参数，默认使用脚本所在目录的父级
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCH_FILE="${SCRIPT_DIR}/vn-link-cli-integrate.patch"

ROOT="${1:-${SCRIPT_DIR}}"
cd "${ROOT}"

if [ ! -f "${PATCH_FILE}" ]; then
    echo "[ERROR] patch not found: ${PATCH_FILE}"
    exit 1
fi

if [ ! -d "trunk" ]; then
    echo "[ERROR] not in rt-n56u source tree (missing ./trunk)"
    echo "        current dir: $(pwd)"
    exit 1
fi

echo "================================================"
echo " vn-link-cli rc integration patch"
echo "   source : ${ROOT}"
echo "   patch  : ${PATCH_FILE}"
echo "================================================"

apply_tool=""
if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
    apply_tool="git"
elif command -v patch >/dev/null 2>&1; then
    apply_tool="patch"
fi

case "${apply_tool}" in
    git)
        echo "[INFO] using 'git apply'"
        if git apply --check "${PATCH_FILE}" 2>&1; then
            echo "[OK]   dry-run passed, applying..."
            git apply --whitespace=nowarn "${PATCH_FILE}"
            echo "[DONE] patch applied successfully."
        else
            echo "[WARN] git apply check failed, try 3-way merge..."
            if git apply --3way --whitespace=nowarn "${PATCH_FILE}" 2>&1; then
                echo "[DONE] patch applied via 3-way merge."
            else
                echo "[ERROR] failed to apply patch."
                git apply --check --verbose "${PATCH_FILE}" || true
                exit 2
            fi
        fi
        ;;
    patch)
        echo "[INFO] using GNU 'patch'"
        if patch --dry-run -p1 < "${PATCH_FILE}" 2>&1; then
            echo "[OK]   dry-run passed, applying..."
            patch -p1 < "${PATCH_FILE}"
            echo "[DONE] patch applied successfully."
        else
            echo "[ERROR] patch dry-run failed."
            exit 2
        fi
        ;;
    *)
        echo "[ERROR] neither 'git' nor 'patch' is available."
        exit 3
        ;;
esac

echo ""
echo "---- verify ----"
for f in \
    trunk/user/rc/Makefile \
    trunk/user/rc/net_wan.c \
    trunk/user/rc/rc.c \
    trunk/user/rc/rc.h \
    trunk/user/rc/vn_link_cli.c
do
    if [ -f "${f}" ]; then
        echo "  [OK]  ${f}"
    else
        echo "  [MISS] ${f}"
    fi
done

if grep -q 'vn_link_cli\.o' trunk/user/rc/Makefile; then
    echo "  [OK]   Makefile references vn_link_cli.o"
else
    echo "  [WARN] Makefile missing vn_link_cli.o"
fi

if grep -q 'start_vn_link_cli' trunk/user/rc/net_wan.c; then
    echo "  [OK]   net_wan.c hooks start_vn_link_cli()"
else
    echo "  [WARN] net_wan.c hook missing"
fi

echo "================================================"
echo " Patch applied. Ready to build."
echo "================================================"