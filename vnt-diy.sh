#!/bin/bash
# =========================================================
# 自动化自定义文件替换与覆盖脚本 (vnt-diy.sh)
# 说明：采用补丁(Patch)增量覆盖模式，保留原 www 目录其他文件
# =========================================================

set -u

echo "=========================================="
echo ">>> 开始执行 vnt-diy.sh 自定义文件增量覆盖"
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

# 📍 2. Web UI (www) 增量/增补覆盖 (保留原有文件，冲突则覆盖)
WWW_SRC=""
if [ -d "padavan-mod-package/original/trunk/user/www" ]; then
    WWW_SRC="padavan-mod-package/original/trunk/user/www"
elif [ -d "build-repo/padavan-mod-package/original/trunk/user/www" ]; then
    WWW_SRC="build-repo/padavan-mod-package/original/trunk/user/www"
fi

if [ -n "$WWW_SRC" ]; then
    echo ">>> 找到 Web UI 补丁目录: $WWW_SRC"
    
    # 容错检查：如果补丁包里多嵌套了一层 www 文件夹
    if [ -d "$WWW_SRC/www" ]; then
        WWW_SRC="$WWW_SRC/www"
        echo ">>> 检测到嵌套路径，调整补丁源为: $WWW_SRC"
    fi

    echo ">>> 正在执行补丁增量覆盖 (同名替换，异名保留)..."
    
    # 进入补丁目录执行拷贝，确保 *.asp, *.css 等点开头或普通文件全量送达
    (cd "$WWW_SRC" && cp -rf . "../../padavan-src/trunk/user/www/") 2>/dev/null || \
    cp -rf "$WWW_SRC"/. padavan-src/trunk/user/www/
    
    echo ">>> www 增量覆盖完成！检查覆盖结果："
    ls -la padavan-src/trunk/user/www | head -n 8
else
    echo "⚠️ 警告: 未找到 www 补丁目录！"
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
    
    mkdir -p padavan-src/trunk/user/vntc
    cp -rf "$VNTC_SRC"/* padavan-src/trunk/user/vntc/
    
    chmod -R +x padavan-src/trunk/user/vntc/
    echo ">>> vntc 模块拷贝与权限赋予完成！"
else
    echo "⚠️ 警告: 未找到 patches/vntc 目录！"
fi

echo "=========================================="
echo ">>> vnt-diy.sh 执行完毕"
echo "=========================================="
