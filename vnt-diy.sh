#!/bin/bash
# =========================================================
# 自动化自定义文件替换与覆盖脚本 (vnt-diy.sh)
# 运行环境：GitHub Actions 根目录
# =========================================================

echo "=========================================="
echo ">>> 开始执行 vnt-diy.sh 自定义文件同步覆盖"
echo "=========================================="

# 查找自定义 trunk 目录的位置
SRC_TRUNK=""
if [ -d "trunk" ]; then
    SRC_TRUNK="trunk"
elif [ -d "build-repo/trunk" ]; then
    SRC_TRUNK="build-repo/trunk"
fi

# 执行覆盖逻辑
if [ -n "$SRC_TRUNK" ]; then
    echo ">>> 找到自定义配置文件目录: $SRC_TRUNK"
    echo ">>> 正在强制覆盖至 padavan-src/trunk/ ..."
    cp -rf "$SRC_TRUNK"/* padavan-src/trunk/
    echo ">>> 文件覆盖完成！"
else
    echo "⚠️ 提示: 未在根目录下找到自定义 trunk 文件夹，跳过覆盖。"
fi

# 提示：后续若有其他修改补丁、规则替换需求，可直接在此脚本下方追加

echo "=========================================="
echo ">>> vnt-diy.sh 执行完毕"
echo "=========================================="
