#!/bin/bash
# =========================================================
# Printer 模块自动安装脚本 (printer-diy.sh)
# 将 patches/pd-Printer 下的子模块拷贝到 trunk/user/
# =========================================================

set -e

REPO_DIR="${GITHUB_WORKSPACE}/build-repo"
SRC_DIR="${GITHUB_WORKSPACE}/padavan-src"
MAKEFILE_PATH="${SRC_DIR}/trunk/user/Makefile"
PRINTER_PATCH_DIR="${REPO_DIR}/patches/pd-Printer"

echo "=========================================="
echo ">>> Printer 模块安装脚本"
echo ">>> Actions 仓库路径: ${REPO_DIR}"
echo ">>> Padavan 源码路径: ${SRC_DIR}"
echo "=========================================="

# 1. 拷贝三个模块到 trunk/user/
echo ">>> 拷贝 printer-script"
mkdir -p "${SRC_DIR}/trunk/user/printer-script"
cp -rf "${PRINTER_PATCH_DIR}/printer-script"/. "${SRC_DIR}/trunk/user/printer-script/"

echo ">>> 拷贝 virtualhere"
mkdir -p "${SRC_DIR}/trunk/user/virtualhere"
cp -rf "${PRINTER_PATCH_DIR}/virtualhere"/. "${SRC_DIR}/trunk/user/virtualhere/"

echo ">>> 拷贝 vn-link-cli"
mkdir -p "${SRC_DIR}/trunk/user/vn-link-cli"
cp -rf "${PRINTER_PATCH_DIR}/vn-link-cli"/. "${SRC_DIR}/trunk/user/vn-link-cli/"


# 3. 注入编译项到 user/Makefile
echo ">>> 添加 printer 模块编译项到 Makefile"
sed -i '/^all:/i dir_y\t\t+= vn-link-cli' "${MAKEFILE_PATH}"
sed -i '/^all:/i dir_y\t\t+= virtualhere' "${MAKEFILE_PATH}"
sed -i '/^all:/i dir_y\t\t+= printer-script' "${MAKEFILE_PATH}"

grep '^dir_y.*printer-script\|^dir_y.*virtualhere\|^dir_y.*vn-link-cli' "${MAKEFILE_PATH}" | head -5

echo "=========================================="
echo ">>> Printer 模块安装完成 ✅"
echo "=========================================="