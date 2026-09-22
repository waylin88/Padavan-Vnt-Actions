#!/bin/bash
# =========================================================
# Padavan 通用自定义脚本 (diy.sh)
# 功能: 覆盖机型配置 / 添加 Web UI / 修改默认参数 / 机型补丁
# =========================================================

set -e

TARGET_BOARD="${TARGET_BOARD:-}"
if [ -z "${TARGET_BOARD}" ]; then
    echo "错误: 未传入 TARGET_BOARD，无法判断机型。"
    exit 1
fi

REPO_DIR="${GITHUB_WORKSPACE}/build-repo"
SRC_DIR="${GITHUB_WORKSPACE}/padavan-src"
MAKEFILE_PATH="${SRC_DIR}/trunk/user/Makefile"
RC_C_PATH="${SRC_DIR}/trunk/user/rc/rc.c"
DEFAULTS_H_PATH="${SRC_DIR}/trunk/user/shared/defaults.h"
DEFAULTS_C_PATH="${SRC_DIR}/trunk/user/shared/defaults.c"
WEB_UI_DIR="${REPO_DIR}/patches/web_ui"

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

# 1. 覆盖机型配置
echo ">>> [1/5] 覆盖机型配置文件"
copy_dir_if_exists "${REPO_DIR}/trunk" "${SRC_DIR}/trunk"

# 2. 添加 / 覆盖 Web UI
echo ">>> [2/5] 添加 Web UI"
copy_dir_if_exists \
    "${REPO_DIR}/padavan-mod-package/modified/trunk/user/www" \
    "${SRC_DIR}/trunk/user/www"

if [ -d "${WEB_UI_DIR}" ]; then
    mkdir -p "${SRC_DIR}/trunk/user/httpd" "${SRC_DIR}/trunk/user/www/n56u_ribbon_fixed"
    cp -f "${WEB_UI_DIR}/httpd/httpd.c" "${SRC_DIR}/trunk/user/httpd/httpd.c" 2>/dev/null || true
    cp -f "${WEB_UI_DIR}/httpd/httpd.h" "${SRC_DIR}/trunk/user/httpd/httpd.h" 2>/dev/null || true
    cp -f "${WEB_UI_DIR}/httpd/web_ex.c" "${SRC_DIR}/trunk/user/httpd/web_ex.c" 2>/dev/null || true
    cp -f "${WEB_UI_DIR}/www/n56u_ribbon_fixed/Login.asp" \
        "${SRC_DIR}/trunk/user/www/n56u_ribbon_fixed/Login.asp" 2>/dev/null || true
    cp -f "${WEB_UI_DIR}/www/n56u_ribbon_fixed/Logout.asp" \
        "${SRC_DIR}/trunk/user/www/n56u_ribbon_fixed/Logout.asp" 2>/dev/null || true
fi

# 3. 修改默认 WiFi SSID 和 defaults.c 参数
echo ">>> [3/5] 修改默认参数"
CUSTOM_WIFI_NAME="YYWiFi"
echo "  - WiFi SSID 前缀: ${CUSTOM_WIFI_NAME}"
sed -i -E "s/#define DEF_WLAN_2G_SSID\s+.*/#define DEF_WLAN_2G_SSID\t\"${CUSTOM_WIFI_NAME}\" \"_%s\"/g" "${DEFAULTS_H_PATH}"
sed -i -E "s/#define DEF_WLAN_5G_SSID\s+.*/#define DEF_WLAN_5G_SSID\t\"${CUSTOM_WIFI_NAME}\" \"_5G_%s\"/g" "${DEFAULTS_H_PATH}"
sed -i -E "s/#define DEF_WLAN_2G_GSSID\s+.*/#define DEF_WLAN_2G_GSSID\t\"${CUSTOM_WIFI_NAME}\" \"_GUEST_%s\"/g" "${DEFAULTS_H_PATH}"
sed -i -E "s/#define DEF_WLAN_5G_GSSID\s+.*/#define DEF_WLAN_5G_GSSID\t\"${CUSTOM_WIFI_NAME}\" \"_GUEST_5G_%s\"/g" "${DEFAULTS_H_PATH}"
grep -E "DEF_WLAN_" "${DEFAULTS_H_PATH}"

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

# 4. 按机型执行专属补丁
echo ">>> [5/5] 执行机型补丁 (${TARGET_BOARD})"
if [ "${TARGET_BOARD}" = "JSH-03" ]; then
    echo "  - JSH-03 组网盒子亮灯补丁"
    sed -i '/cpu_gpio_set_pin(gpio_led, flag);/i\        cpu_gpio_mode_set_bit(34, 1);' "${RC_C_PATH}"
    grep -A 3 "cpu_gpio_mode_set_bit(34, 1)" "${RC_C_PATH}"
fi

if [ "${TARGET_BOARD}" = "8820v2" ]; then
    echo "  - 8820v2 WiFi 不启动补丁 (GPIO_PCIE_PORT1 = 26)"
    PCI_C_PATH="${SRC_DIR}/trunk/linux-3.4.x/arch/mips/rt2880/pci.c"
    sed -i -E '/UARTL3_SHARE_PIN_SW\s+PCIE_SHARE_PIN_SW/,/#define\s+GPIO_PCIE_PORT2/{s/#define\s+GPIO_PCIE_PORT1\s+.*/#define GPIO_PCIE_PORT1\t\t26/}' "${PCI_C_PATH}"
    grep GPIO_PCIE_PORT1 "${PCI_C_PATH}"
fi

if [ "${TARGET_BOARD}" = "8820s" ]; then
    echo "  - 8820s WiFi 不启动补丁 (GPIO_PCIE_PORT1 = 4)"
    PCI_C_PATH="${SRC_DIR}/trunk/linux-3.4.x/arch/mips/rt2880/pci.c"
    sed -i -E '/UARTL3_SHARE_PIN_SW\s+PCIE_SHARE_PIN_SW/,/#define\s+GPIO_PCIE_PORT2/{s/#define\s+GPIO_PCIE_PORT1\s+.*/#define GPIO_PCIE_PORT1\t\t4/}' "${PCI_C_PATH}"
    grep GPIO_PCIE_PORT1 "${PCI_C_PATH}"
fi

# 屏蔽 BusyBox DHCPv6 的日志噪音
echo ">>> 屏蔽 BusyBox DHCPv6 日志噪音"
sed -i 's/bb_info_msg("status code for/if (0) bb_info_msg("status code for/' \
    "${SRC_DIR}/trunk/user/busybox/busybox-1.24.x/networking/udhcp/dhcp6c_ia.c"
sed -i 's/bb_info_msg("unexpected DHCP6 option/if (0) bb_info_msg("unexpected DHCP6 option/' \
    "${SRC_DIR}/trunk/user/busybox/busybox-1.24.x/networking/udhcp/dhcp6c_common.c"

cp -f "${REPO_DIR}/patches/apply-vn-link-cli.sh" "${SRC_DIR}/"
cp -f "${REPO_DIR}/patches/vn-link-cli-rc.patch" "${SRC_DIR}/"
chmod +x "${SRC_DIR}/apply-vn-link-cli.sh"
cd "${SRC_DIR}" && bash apply-vn-link-cli.sh

echo ">>> diy.sh 执行完成"