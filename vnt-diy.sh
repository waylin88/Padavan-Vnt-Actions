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

copy_dir_if_exists() {
    local source_dir="$1"
    local target_dir="$2"

    if [ -d "${source_dir}" ]; then
        mkdir -p "${target_dir}"
        cp -rf "${source_dir}"/. "${target_dir}/"
    fi
}

# 1. 覆盖机型配置、Web UI 和 VNTC 模块
copy_dir_if_exists "${REPO_DIR}/trunk" "${SRC_DIR}/trunk"
copy_dir_if_exists \
    "${REPO_DIR}/padavan-mod-package/modified/trunk/user/www" \
    "${SRC_DIR}/trunk/user/www"
copy_dir_if_exists "${REPO_DIR}/patches/vntc" "${SRC_DIR}/trunk/user/vntc"

if [ -d "${SRC_DIR}/trunk/user/vntc" ]; then
    chmod -R +x "${SRC_DIR}/trunk/user/vntc"
fi

# 4. 修改默认 WiFi SSID 前缀和 STA 自动连接参数
CUSTOM_WIFI_NAME="YYWiFi"
echo ">>> 正在更新 WiFi SSID 前缀为: ${CUSTOM_WIFI_NAME}"
sed -i -E "s/#define DEF_WLAN_2G_SSID\s+.*/#define DEF_WLAN_2G_SSID\t\"${CUSTOM_WIFI_NAME}\" \"_%s\"/g" "${DEFAULTS_H_PATH}"
sed -i -E "s/#define DEF_WLAN_5G_SSID\s+.*/#define DEF_WLAN_5G_SSID\t\"${CUSTOM_WIFI_NAME}\" \"_5G_%s\"/g" "${DEFAULTS_H_PATH}"
sed -i -E "s/#define DEF_WLAN_2G_GSSID\s+.*/#define DEF_WLAN_2G_GSSID\t\"${CUSTOM_WIFI_NAME}\" \"_GUEST_%s\"/g" "${DEFAULTS_H_PATH}"
sed -i -E "s/#define DEF_WLAN_5G_GSSID\s+.*/#define DEF_WLAN_5G_GSSID\t\"${CUSTOM_WIFI_NAME}\" \"_GUEST_5G_%s\"/g" "${DEFAULTS_H_PATH}"
grep -E "DEF_WLAN_" "${DEFAULTS_H_PATH}"

echo ">>> 正在修改 defaults.c 参数配置..."
DEFAULT_SETTINGS=(
    "rt_sta_auto=1"
    "wl_sta_auto=1"
    "fw_enable_x=0"
    "wl_wme=0"
    "rt_wme=0"
    "ip6_service=dhcp6"
    "ip6_ppe_on=1"
    "ip6_dns_auto=1"
    "ip6_lan_auto=1"
    "ip6_lan_addr=fc00:101:101::1"
    "ip6_lan_radv=0"
    "telnetd=1"
    "sshd_enable=0"
    "lltd_enable=0"
    "help_enable=0"
)

for setting in "${DEFAULT_SETTINGS[@]}"; do
    key="${setting%%=*}"
    value="${setting#*=}"
    sed -i -E "s|(^[[:space:]]*\{[[:space:]]*\"${key}\"[[:space:]]*,[[:space:]]*\")[^\"]*(\"[[:space:]]*\},.*$)|\1${value}\2|" "${DEFAULTS_C_PATH}"
done
grep -E 'rt_sta_auto|wl_sta_auto|fw_enable_x|wl_wme|rt_wme|ip6_|telnetd|sshd_enable|lltd_enable|help_enable' "${DEFAULTS_C_PATH}"


# 4. 修改 Makefile 添加 vntc 编译项
echo ">>> 添加vntc编译项到Makefile"
sed -i '/^all:/i dir_$(CONFIG_FIRMWARE_INCLUDE_VNT)\t\t+= vntc' "${MAKEFILE_PATH}"
grep -B 2 "^all:" "${MAKEFILE_PATH}"

# 5. 修改 rc.c 自动调用 system("start")
echo ">>> 添加 system(\"start\") 到 rc.c"
sed -i '/system("\/etc\/storage\/started_script\.sh &");/a \\tsystem("start");' "${RC_C_PATH}"
sed -i '/system("\/etc\/storage\/started_script\.sh &");/a \\tsystem("nvram set fw_sn=$(lan_eeprom_mac | awk '\''/MAC/ {gsub(/:/, \\"\\"); print $NF}'\'')");' "${RC_C_PATH}"
grep -A 3 "// system ready" "${RC_C_PATH}"

# 8. 修改 net_wan.c 自动调用 system("vnt auto");
echo ">>> 添加 system(\"vnt auto\") 到 net_wan.c"
sed -i '/doSystem("%s %s %s %s", script_postw, "up"/a \\tsystem("vnt auto");' "${SRC_DIR}/trunk/user/rc/net_wan.c"
grep -A 3 "script_postw" "${SRC_DIR}/trunk/user/rc/net_wan.c"

# 按机型执行专用补丁
if [ "${TARGET_BOARD}" = "JSH-03" ]; then
    echo ">>> 应用 JSH-03 组网盒子亮灯补丁"
    sed -i '/cpu_gpio_set_pin(gpio_led, flag);/i\        cpu_gpio_mode_set_bit(34, 1);' "${RC_C_PATH}"
    grep -A 3 "cpu_gpio_mode_set_bit(34, 1)" "${RC_C_PATH}"
fi

sed -i 's/bb_info_msg("status code for/if (0) bb_info_msg("status code for/' \
trunk/user/busybox/busybox-1.24.x/networking/udhcp/dhcp6c_ia.c

sed -i 's/bb_info_msg("unexpected DHCP6 option/if (0) bb_info_msg("unexpected DHCP6 option/' \
trunk/user/busybox/busybox-1.24.x/networking/udhcp/dhcp6c_common.c

