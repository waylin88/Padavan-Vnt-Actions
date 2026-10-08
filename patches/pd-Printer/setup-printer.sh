#!/bin/bash
# =========================================================
# Printer 模块自动安装脚本 (printer-diy.sh)
# 将 patches/pd-Printer 下的子模块拷贝到 trunk/user/
# =========================================================

set -eu

: "${TARGET_BOARD:=}"

REPO_DIR="${GITHUB_WORKSPACE}/build-repo"
SRC_DIR="${GITHUB_WORKSPACE}/padavan-src"
DEFAULTS_H_PATH="${SRC_DIR}/trunk/user/shared/defaults.h"
DEFAULTS_C_PATH="${SRC_DIR}/trunk/user/shared/defaults.c"
TARGET_DETECT="${SRC_DIR}/trunk/user/rc/detect_link.c"

echo "=========================================="
echo ">>> Printer 模块安装脚本"
echo ">>> Actions 仓库路径: ${REPO_DIR}"
echo ">>> Padavan 源码路径: ${SRC_DIR}"
echo "=========================================="

# 工具函数：将源目录递归复制到目标目录（目标不存在时自动创建）
copy_dir_if_exists() {
    local source_dir="$1"
    local target_dir="$2"

    if [ -d "${source_dir}" ]; then
        mkdir -p "${target_dir}"
        cp -rf "${source_dir}"/. "${target_dir}/"
        echo ">>> 已复制: ${source_dir} -> ${target_dir}"
    else
        echo "⚠️ 警告: 源目录不存在，跳过: ${source_dir}"
    fi
}

# 1. 覆盖机型配置
echo ">>> [1/5] 覆盖机型配置文件"
copy_dir_if_exists "${REPO_DIR}/trunk" "${SRC_DIR}/trunk"

# 2. 关闭所有机型配置文件的 IPv6 支持
echo ">>> 关闭机型配置文件的 IPv6 支持"
CONFIG_TEMPLATE_DIR="${SRC_DIR}/trunk/configs/templates"
if [ -d "${CONFIG_TEMPLATE_DIR}" ]; then
    sed -i -E "s/^(CONFIG_FIRMWARE_ENABLE_IPV6=).*/\1n/" "${CONFIG_TEMPLATE_DIR}"/*.config
    grep -H "CONFIG_FIRMWARE_ENABLE_IPV6=" "${CONFIG_TEMPLATE_DIR}"/*.config || echo "  ⚠️ 未找到 CONFIG_FIRMWARE_ENABLE_IPV6，请检查模板配置"
else
    echo "  ⚠️ 警告: 模板配置目录不存在，跳过: ${CONFIG_TEMPLATE_DIR}"
fi

# 3. 修改默认 WiFi SSID 和 defaults.c 参数
echo ">>> 修改默认参数"
CUSTOM_WIFI_NAME="YYWiFi"
echo "  - WiFi SSID 前缀: ${CUSTOM_WIFI_NAME}"
sed -i -E "s/#define DEF_WLAN_2G_SSID\s+.*/#define DEF_WLAN_2G_SSID\t\"${CUSTOM_WIFI_NAME}\" \"_%s\"/g" "${DEFAULTS_H_PATH}"
sed -i -E "s/#define DEF_WLAN_5G_SSID\s+.*/#define DEF_WLAN_5G_SSID\t\"${CUSTOM_WIFI_NAME}\" \"_5G_%s\"/g" "${DEFAULTS_H_PATH}"
sed -i -E "s/#define DEF_WLAN_2G_GSSID\s+.*/#define DEF_WLAN_2G_GSSID\t\"${CUSTOM_WIFI_NAME}\" \"_GUEST_%s\"/g" "${DEFAULTS_H_PATH}"
sed -i -E "s/#define DEF_WLAN_5G_GSSID\s+.*/#define DEF_WLAN_5G_GSSID\t\"${CUSTOM_WIFI_NAME}\" \"_GUEST_5G_%s\"/g" "${DEFAULTS_H_PATH}"
grep -E "DEF_WLAN_" "${DEFAULTS_H_PATH}" || echo "  ⚠️ 未匹配到 DEF_WLAN_，请检查 defaults.h"

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
    "telnetd=0"
    "sshd_enable=0"
    "lltd_enable=0"
    "help_enable=0"
)

for setting in "${DEFAULT_SETTINGS[@]}"; do
    key="${setting%%=*}"
    value="${setting#*=}"
    sed -i -E "s|(^[[:space:]]*\{[[:space:]]*\"${key}\"[[:space:]]*,[[:space:]]*\")[^\"]*(\"[[:space:]]*\},.*$)|\1${value}\2|" "${DEFAULTS_C_PATH}"
done
grep -E 'rt_sta_auto|wl_sta_auto|fw_enable_x|wl_wme|rt_wme|ip6_|telnetd|sshd_enable|lltd_enable|help_enable' "${DEFAULTS_C_PATH}" || echo "  ⚠️ 未匹配到默认参数，请检查 defaults.c"

# 4. 按机型执行专属补丁
echo ">>> 执行机型补丁 (${TARGET_BOARD})"

if [ "${TARGET_BOARD}" = "ZY-L1-7628N" ]; then
    echo "  - ZY-L1-7628N USB灯响应亮灯补丁"
    sed -i 's/dl_status_usb = is_usb_storage_mounted();/dl_status_usb = has_usb_devices();/' "$TARGET_DETECT"
    grep -n "dl_status_usb =" "$TARGET_DETECT" || echo "  ⚠️ 未匹配到 dl_status_usb=，请检查 detect_link.c"
fi

if [ "${TARGET_BOARD}" = "E8820V2" ]; then
    echo "  - 8820v2 WiFi 不启动补丁 (GPIO_PCIE_PORT1 = 26)"
    PCI_C_PATH="${SRC_DIR}/trunk/linux-3.4.x/arch/mips/rt2880/pci.c"
    sed -i -E '/UARTL3_SHARE_PIN_SW\s+PCIE_SHARE_PIN_SW/,/#define\s+GPIO_PCIE_PORT2/{s/#define\s+GPIO_PCIE_PORT1\s+.*/#define GPIO_PCIE_PORT1\t\t26/}' "${PCI_C_PATH}"
    grep GPIO_PCIE_PORT1 "${PCI_C_PATH}" || echo "  ⚠️ 未匹配到 GPIO_PCIE_PORT1，请检查 pci.c"
fi

if [ "${TARGET_BOARD}" = "ZTE_E8820S" ]; then
    echo "  - 8820s WiFi 不启动补丁 (GPIO_PCIE_PORT1 = 4)"
    PCI_C_PATH="${SRC_DIR}/trunk/linux-3.4.x/arch/mips/rt2880/pci.c"
    sed -i -E '/UARTL3_SHARE_PIN_SW\s+PCIE_SHARE_PIN_SW/,/#define\s+GPIO_PCIE_PORT2/{s/#define\s+GPIO_PCIE_PORT1\s+.*/#define GPIO_PCIE_PORT1\t\t4/}' "${PCI_C_PATH}"
    grep GPIO_PCIE_PORT1 "${PCI_C_PATH}" || echo "  ⚠️ 未匹配到 GPIO_PCIE_PORT1，请检查 pci.c"
fi

# 5. 屏蔽 BusyBox DHCPv6 的日志噪音
echo ">>> 屏蔽 BusyBox DHCPv6 日志噪音"
sed -i 's/bb_info_msg("status code for/if (0) bb_info_msg("status code for/' \
    "${SRC_DIR}/trunk/user/busybox/busybox-1.24.x/networking/udhcp/dhcp6c_ia.c"
sed -i 's/bb_info_msg("unexpected DHCP6 option/if (0) bb_info_msg("unexpected DHCP6 option/' \
    "${SRC_DIR}/trunk/user/busybox/busybox-1.24.x/networking/udhcp/dhcp6c_common.c"

echo "=========================================="
echo ">>> setup-printer.sh 执行完成"
echo "=========================================="