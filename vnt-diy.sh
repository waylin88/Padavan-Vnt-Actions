#!/bin/bash
# =========================================================
# 自动化自定义文件替换与覆盖脚本 (vnt-diy.sh)
# 运行环境：GitHub Actions 根目录
# =========================================================

echo "=========================================="
echo ">>> 开始执行 vnt-diy.sh 自定义文件同步覆盖"
echo "=========================================="

# 1. 覆盖自定义 trunk 机型配置文件
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

# 2. 强制覆盖 padavan-mod-package Web UI (www) 目录 [有冲突文件自动替换]
WWW_SRC=""
if [ -d "padavan-mod-package/original/trunk/user/www" ]; then
    WWW_SRC="padavan-mod-package/original/trunk/user/www"
elif [ -d "build-repo/padavan-mod-package/original/trunk/user/www" ]; then
    WWW_SRC="build-repo/padavan-mod-package/original/trunk/user/www"
fi

if [ -n "$WWW_SRC" ]; then
    echo ">>> 找到 Web UI 目录: $WWW_SRC"
    echo ">>> 正在强制覆盖至 padavan-src/trunk/user/www/ ..."
    
    # 确保目标目录存在并进行递归强制覆盖 (-rf)
    mkdir -p padavan-src/trunk/user/www
    cp -rf "$WWW_SRC"/* padavan-src/trunk/user/www/
    
    echo ">>> www 目录覆盖完成！"
else
    echo "⚠️ 提示: 未找到 padavan-mod-package/original/trunk/user/www 目录，跳过覆盖。"
fi

echo "=========================================="
echo ">>> vnt-diy.sh 执行完毕"
echo "=========================================="
