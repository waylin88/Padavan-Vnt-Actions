#!/bin/bash
# =========================================================
# 自动化自定义文件替换与覆盖脚本 (vnt-diy.sh)
# 说明：自动检测运行路径，并将自定义 trunk、www 及 vntc 拷贝至源码中
# =========================================================

set -u

echo "=========================================="
echo ">>> 开始执行 vnt-diy.sh 自定义文件同步覆盖"
echo "=========================================="

# 1. 覆盖自定义 trunk 配置文件
SRC_TRUNK=""
if [ -d "trunk" ]; then
    SRC_TRUNK="trunk"
elif [ -d "build-repo/trunk" ]; then
    SRC_TRUNK="build-repo/trunk"
fi

if [ -n "$SRC_TRUNK" ]; then
    echo ">>> 正在强制覆盖自定义 trunk 配置文件至 padavan-src/trunk/ ..."
    cp -rf "$SRC_TRUNK"/* padavan-src/trunk/
fi

# 2. 强制覆盖 Web UI (www) 目录
WWW_SRC=""
if [ -d "padavan-mod-package/original/trunk/user/www" ]; then
    WWW_SRC="padavan-mod-package/original/trunk/user/www"
elif [ -d "build-repo/padavan-mod-package/original/trunk/user/www" ]; then
    WWW_SRC="build-repo/padavan-mod-package/original/trunk/user/www"
fi

if [ -n "$WWW_SRC" ]; then
    echo ">>> 找到 Web UI 目录: $WWW_SRC"
    echo ">>> 正在强制覆盖至 padavan-src/trunk/user/www/ ..."
    mkdir -p padavan-src/trunk/user/www
    cp -rf "$WWW_SRC"/* padavan-src/trunk/user/www/
    echo ">>> www 目录覆盖完成！"
else
    echo "⚠️ 提示: 未找到 www 源码目录，跳过覆盖。"
fi

# 📍 3. 新增：将 vntc 模块拷贝至源码 trunk/user/ 目录下
VNTC_SRC=""
if [ -d "patches/vntc" ]; then
    VNTC_SRC="patches/vntc"
elif [ -d "build-repo/patches/vntc" ]; then
    VNTC_SRC="build-repo/patches/vntc"
elif [ -d "vntc" ]; then
    VNTC_SRC="vntc"
elif [ -d "build-repo/vntc" ]; then
    VNTC_SRC="build-repo/vntc"
fi

if [ -n "$VNTC_SRC" ]; then
    echo ">>> 找到 vntc 模块目录: $VNTC_SRC"
    echo ">>> 正在拷贝至 padavan-src/trunk/user/vntc/ ..."
    mkdir -p padavan-src/trunk/user/vntc
    cp -rf "$VNTC_SRC"/* padavan-src/trunk/user/vntc/
    
    # 赋予 vntc 目录下可能存在的可执行脚本权限
    chmod -R +x padavan-src/trunk/user/vntc/
    echo ">>> vntc 模块拷贝完成！"
else
    echo "⚠️ 提示: 未找到 vntc 模块源目录，跳过拷贝。"
fi

echo "=========================================="
echo ">>> vnt-diy.sh 执行完毕"
echo "=========================================="
