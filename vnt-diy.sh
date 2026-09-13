#!/bin/bash
# =========================================================
# 自动化自定义文件替换与覆盖脚本 (vnt-diy.sh)
# 说明：精确匹配根目录下的 padavan-mod-package 与 patches
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
    echo ">>> 找到 Web UI 源目录: $WWW_SRC"
    
    # 容错：防止 padavan-mod-package 内部多嵌套了一层 www 文件夹
    if [ -d "$WWW_SRC/www" ]; then
        WWW_SRC="$WWW_SRC/www"
        echo ">>> 检测到嵌套路径，调整为: $WWW_SRC"
    fi

    echo ">>> 正在强行清空原 www 目录并覆盖最新页面..."
    rm -rf padavan-src/trunk/user/www
    cp -rf "$WWW_SRC" padavan-src/trunk/user/www
    
    echo ">>> www 目录覆盖成功！根目录文件列表："
    ls -la padavan-src/trunk/user/www | head -n 8
else
    echo "❌ 错误: 未找到 padavan-mod-package/original/trunk/user/www 目录！"
fi

# 3. 强制拷贝根目录 patches/vntc 到源码中
VNTC_SRC=""
if [ -d "patches/vntc" ]; then
    VNTC_SRC="patches/vntc"
elif [ -d "build-repo/patches/vntc" ]; then
    VNTC_SRC="build-repo/patches/vntc"
fi

if [ -n "$VNTC_SRC" ]; then
    echo ">>> 找到 vntc 源码目录: $VNTC_SRC"
    echo ">>> 正在拷贝至 padavan-src/trunk/user/vntc/ ..."
    
    # 清理并全量拷贝
    rm -rf padavan-src/trunk/user/vntc
    mkdir -p padavan-src/trunk/user/vntc
    cp -rf "$VNTC_SRC"/* padavan-src/trunk/user/vntc/
    
    # 赋予执行权限
    chmod -R +x padavan-src/trunk/user/vntc/
    echo ">>> vntc 模块拷贝与权限赋予完成！"
else
    echo "❌ 错误: 未找到 patches/vntc 目录！"
fi

echo "=========================================="
echo ">>> vnt-diy.sh 执行完毕"
echo "=========================================="
