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
RC_C_PATH="${SRC_DIR}/trunk/user/rc/rc.c"
WWW_MAKEFILE_PATH="${SRC_DIR}/trunk/user/www/Makefile"

echo "=========================================="
echo ">>> Printer 模块安装脚本"
echo ">>> Actions 仓库路径: ${REPO_DIR}"
echo ">>> Padavan 源码路径: ${SRC_DIR}"
echo "=========================================="

# 1. 覆盖机型配置
copy_dir_if_exists "${REPO_DIR}/trunk" "${SRC_DIR}/trunk"
echo ">>> [1/1] 覆盖机型配置文件"