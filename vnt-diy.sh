#!/bin/bash
# =========================================================
# 自动化自定义文件增量覆盖脚本 (vnt-diy.sh)
# =========================================================

set -e # 遇到错误立即停止

# 定义绝对路径
REPO_DIR="${GITHUB_WORKSPACE}/build-repo"
SRC_DIR="${GITHUB_WORKSPACE}/padavan-src"
MAKEFILE_PATH="${SRC_DIR}/trunk/user/Makefile"

echo "=========================================="
echo ">>> Actions 仓库路径: ${REPO_DIR}"
echo ">>> Padavan 源码路径: ${SRC_DIR}"
echo ">>> Makefile: ${MAKEFILE_PATH}"
echo "=========================================="

# 1. 覆盖机型配置文件
if [ -d "${REPO_DIR}/trunk" ]; then
    echo ">>> 正在覆盖 trunk 配置文件..."
    cp -rf "${REPO_DIR}/trunk"/* "${SRC_DIR}/trunk/"
fi

# 2. 增量覆盖 Web UI (www)
WWW_SRC="${REPO_DIR}/padavan-mod-package/modified/trunk/user/www"
if [ -d "${WWW_SRC}" ]; then
    echo ">>> 正在增量覆盖 Web UI (www)..."
    cp -rf "${WWW_SRC}"/. "${SRC_DIR}/trunk/user/www/"
fi

# 3. 拷贝 VNTC 模块
VNTC_SRC="${REPO_DIR}/patches/vntc"
if [ -d "${VNTC_SRC}" ]; then
    echo ">>> 正在拷贝 VNTC 模块..."
    mkdir -p "${SRC_DIR}/trunk/user/vntc"
    cp -rf "${VNTC_SRC}"/* "${SRC_DIR}/trunk/user/vntc/"
    chmod -R +x "${SRC_DIR}/trunk/user/vntc/"
fi
# 4. 修改 Makefile 添加 vntc 编译项
echo ">>> 正在直接修改 Makefile: ${MAKEFILE_PATH}"
sed -i '/^all:/i dir_$(CONFIG_FIRMWARE_INCLUDE_VNT)\t\t+= vntc' "${MAKEFILE_PATH}"

echo ">>> Makefile 修改结果验证："
grep -B 2 "^all:" "${MAKEFILE_PATH}"
echo "=========================================="
echo ">>> vnt-diy.sh 执行成功！"
echo "=========================================="
