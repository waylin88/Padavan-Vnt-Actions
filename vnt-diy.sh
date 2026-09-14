#!/bin/bash
# =========================================================
# 自动化自定义文件增量覆盖脚本 (vnt-diy.sh)
# =========================================================

set -e # 遇到错误立即停止

TARGET_BOARD="${TARGET_BOARD:-}"
if [ -z "${TARGET_BOARD}" ]; then
    echo "❌ 错误: 未传入 TARGET_BOARD，无法判断机型。"
    exit 1
fi

# 定义绝对路径
REPO_DIR="${GITHUB_WORKSPACE}/build-repo"
SRC_DIR="${GITHUB_WORKSPACE}/padavan-src"
MAKEFILE_PATH="${SRC_DIR}/trunk/user/Makefile"
RC_C_PATH="${SRC_DIR}/trunk/user/rc/rc.c"
DEFAULTS_H_PATH="${SRC_DIR}/trunk/user/shared/defaults.h"
DEFAULTS_C_PATH="${SRC_DIR}/trunk/user/shared/defaults.c"

echo "=========================================="
echo ">>> Actions 仓库路径: ${REPO_DIR}"
echo ">>> Padavan 源码路径: ${SRC_DIR}"
echo ">>> Makefile: ${MAKEFILE_PATH}"
echo ">>> RC: ${RC_C_PATH}"
echo ">>> defaults.h: ${DEFAULTS_H_PATH}"
echo ">>> defaults.c: ${DEFAULTS_C_PATH}"
echo ">>> 目标机型: ${TARGET_BOARD}"
echo "=========================================="

# 1. 覆盖机型配置文件
if [ -d "${REPO_DIR}/trunk" ]; then
    cp -rf "${REPO_DIR}/trunk"/* "${SRC_DIR}/trunk/"
fi

# 2. 增量覆盖 Web UI (www)
WWW_SRC="${REPO_DIR}/padavan-mod-package/modified/trunk/user/www"
if [ -d "${WWW_SRC}" ]; then
    cp -rf "${WWW_SRC}"/. "${SRC_DIR}/trunk/user/www/"
fi

# 3. 拷贝 VNTC 模块
VNTC_SRC="${REPO_DIR}/patches/vntc"
if [ -d "${VNTC_SRC}" ]; then
    mkdir -p "${SRC_DIR}/trunk/user/vntc"
    cp -rf "${VNTC_SRC}"/* "${SRC_DIR}/trunk/user/vntc/"
    chmod -R +x "${SRC_DIR}/trunk/user/vntc/"
fi

# 4. 修改默认 WiFi SSID 前缀和 STA 自动连接参数
CUSTOM_WIFI_NAME="YYWiFi"

if [ ! -f "${DEFAULTS_H_PATH}" ]; then
    echo "❌ 错误: 未找到 ${DEFAULTS_H_PATH} 文件！"
    exit 1
fi

echo ">>> 正在更新 WiFi SSID 前缀为: ${CUSTOM_WIFI_NAME}"
sed -i -E "s/#define DEF_WLAN_2G_SSID\s+.*/#define DEF_WLAN_2G_SSID\t\"${CUSTOM_WIFI_NAME}\" \"_%s\"/g" "${DEFAULTS_H_PATH}"
sed -i -E "s/#define DEF_WLAN_5G_SSID\s+.*/#define DEF_WLAN_5G_SSID\t\"${CUSTOM_WIFI_NAME}\" \"_5G_%s\"/g" "${DEFAULTS_H_PATH}"
sed -i -E "s/#define DEF_WLAN_2G_GSSID\s+.*/#define DEF_WLAN_2G_GSSID\t\"${CUSTOM_WIFI_NAME}\" \"_GUEST_%s\"/g" "${DEFAULTS_H_PATH}"
sed -i -E "s/#define DEF_WLAN_5G_GSSID\s+.*/#define DEF_WLAN_5G_GSSID\t\"${CUSTOM_WIFI_NAME}\" \"_GUEST_5G_%s\"/g" "${DEFAULTS_H_PATH}"
grep -E "DEF_WLAN_" "${DEFAULTS_H_PATH}"

if [ -f "${DEFAULTS_C_PATH}" ]; then
    echo ">>> 正在修改 defaults.c 参数配置..."
    sed -i -E 's/\{\s*"rt_sta_auto"\s*,\s*"[0-9]+"*\s*\}/\{ "rt_sta_auto", "1" \}/g' "${DEFAULTS_C_PATH}"
    sed -i -E 's/\{\s*"wl_sta_auto"\s*,\s*"[0-9]+"*\s*\}/\{ "wl_sta_auto", "1" \}/g' "${DEFAULTS_C_PATH}"
    grep -E "rt_sta_auto|wl_sta_auto" "${DEFAULTS_C_PATH}"
else
    echo "⚠️ 警告: 未找到 ${DEFAULTS_C_PATH} 文件，跳过此步骤。"
fi

# 4. 修改 Makefile 添加 vntc 编译项
sed -i '/^all:/i dir_$(CONFIG_FIRMWARE_INCLUDE_VNT)\t\t+= vntc' "${MAKEFILE_PATH}"
grep -B 2 "^all:" "${MAKEFILE_PATH}"
echo "=========================================="
echo ">>> vnt-diy.sh 执行成功！"
echo "=========================================="

# 5. 修改 rc.c 自动调用 system("start")
sed -i '/system("\/etc\/storage\/started_script\.sh &");/a \\tsystem("start");' "${RC_C_PATH}"
sed -i '/system("\/etc\/storage\/started_script\.sh &");/a \\tsystem("nvram set fw_sn=$(lan_eeprom_mac | awk '\''/MAC/ {gsub(/:/, \\"\\"); print $NF}'\'')");' "${RC_C_PATH}"
grep -A 3 "// system ready" "${RC_C_PATH}"

# 8. 修改 net_wan.c 自动调用 system("vnt auto");
# 精准插入：在 doSystem("%s %s %s %s", script_postw... 行下方追加带 Tab 缩进的 system("vnt auto");
sed -i '/doSystem("%s %s %s %s", script_postw, "up"/a \\tsystem("vnt auto");' "${SRC_DIR}/trunk/user/rc/net_wan.c"
grep -A 3 "script_postw" "${SRC_DIR}/trunk/user/rc/net_wan.c"

# 按机型执行专用补丁
if [ "${TARGET_BOARD}" = "JSH-03" ]; then
    echo ">>> 应用 JSH-03 组网盒子亮灯补丁"
    sed -i '/cpu_gpio_set_pin(gpio_led, flag);/i \t\tcpu_gpio_mode_set_bit(34, 1);' "${RC_C_PATH}"
    grep -A 3 "cpu_gpio_mode_set_bit(34, 1)" "${RC_C_PATH}"
fi
