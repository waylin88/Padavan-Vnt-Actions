#!/bin/bash
# =============================================================================
# apply-vn-link-cli.sh
#
# 云编译前置脚本：将 vn-link-cli 深度集成到 rc.c 的补丁应用到源码树。
#
# 使用方法：
#   1. 把 vn-link-cli-rc.patch 放到固件根目录
#   2. 把本脚本放到固件根目录（或 CI 工作目录）
#   3. 构建前执行：  bash apply-vn-link-cli.sh
#
# 脚本会自动检测仓库根目录并应用补丁，已打过补丁会自动跳过。
# =============================================================================

set -e

PATCH_NAME="vn-link-cli-rc.patch"

find_repo_root() {
    local d="$PWD"
    while [ "$d" != "/" ]; do
        if [ -d "$d/.git" ] || [ -f "$d/trunk/user/rc/rc.c" ]; then
            echo "$d"
            return 0
        fi
        d="$(dirname "$d")"
    done
    return 1
}

ROOT="$(find_repo_root)" || {
    echo "[vn-link-cli] ERROR: 找不到仓库根目录（没有 trunk/user/rc/rc.c）"
    exit 1
}

cd "$ROOT"

PATCH_FILE=""
for c in "$PATCH_NAME" "patches/$PATCH_NAME" "patch/$PATCH_NAME"; do
    if [ -f "$c" ]; then
        PATCH_FILE="$c"
        break
    fi
done

if [ -z "$PATCH_FILE" ]; then
    echo "[vn-link-cli] ERROR: 找不到 $PATCH_NAME"
    exit 1
fi

echo "[vn-link-cli] 仓库根: $ROOT"
echo "[vn-link-cli] 补丁:   $PATCH_FILE"

echo "[vn-link-cli] 检查是否已打过补丁..."
if grep -q "start_vnlinkcli" trunk/user/rc/rc.c && \
   grep -q "base64_encode_nopad" trunk/user/rc/services.c; then
    echo "[vn-link-cli] 已打过补丁，跳过。"
    exit 0
fi

echo "[vn-link-cli] 应用补丁..."
if git apply --check "$PATCH_FILE" 2>/dev/null; then
    git apply "$PATCH_FILE"
    echo "[vn-link-cli] git apply 成功 ✓"
elif command -v patch >/dev/null 2>&1; then
    patch -p1 < "$PATCH_FILE"
    echo "[vn-link-cli] patch -p1 成功 ✓"
else
    echo "[vn-link-cli] ERROR: 没有 git 也没有 patch 命令"
    exit 1
fi

echo "[vn-link-cli] 验证补丁..."
grep -q "start_vnlinkcli"   trunk/user/rc/rc.c       && echo "  ✓ rc.c"      || echo "  ✗ rc.c 缺失"
grep -q "start_vnlinkcli"   trunk/user/rc/rc.h       && echo "  ✓ rc.h"      || echo "  ✗ rc.h 缺失"
grep -q "stop_vnlinkcli"    trunk/user/rc/net_wan.c  && echo "  ✓ net_wan.c" || echo "  ✗ net_wan.c 缺失"
grep -q "base64_encode_nopad" trunk/user/rc/services.c && echo "  ✓ services.c" || echo "  ✗ services.c 缺失"

echo "[vn-link-cli] 完成。"