#!/bin/bash
# =========================================================
# Printer 模块自动安装脚本 (printer-diy.sh)
# 将 patches/pd-Printer 下的子模块拷贝到 trunk/user/
# =========================================================

set -eu

TARGET_BOARD="${TARGET_BOARD:-}"

REPO_DIR="${GITHUB_WORKSPACE}/build-repo"
SRC_DIR="${GITHUB_WORKSPACE}/padavan-src"
MAKEFILE_PATH="${SRC_DIR}/trunk/user/Makefile"
PRINTER_PATCH_DIR="${REPO_DIR}/patches/pd-Printer"
RC_C_PATH="${SRC_DIR}/trunk/user/rc/rc.c"
WWW_MAKEFILE_PATH="${SRC_DIR}/trunk/user/www/Makefile"
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
echo ">>> [1/1] 覆盖机型配置文件"
copy_dir_if_exists "${REPO_DIR}/trunk" "${SRC_DIR}/trunk"


# 3. 按机型执行专属补丁
echo ">>> 执行机型补丁 (${TARGET_BOARD})"

if [ "${TARGET_BOARD}" = "ZY-L1-7628N" ]; then
    echo "  - ZY-L1-7628N USB灯响应亮灯补丁"
    sed -i 's/dl_status_usb = is_usb_storage_mounted();/dl_status_usb = has_usb_devices();/' "$TARGET_DETECT"
    grep -n "dl_status_usb =" "$TARGET_DETECT"
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

# 4. 屏蔽 BusyBox DHCPv6 的日志噪音
echo ">>> 屏蔽 BusyBox DHCPv6 日志噪音"
sed -i 's/bb_info_msg("status code for/if (0) bb_info_msg("status code for/' \
    "${SRC_DIR}/trunk/user/busybox/busybox-1.24.x/networking/udhcp/dhcp6c_ia.c"
sed -i 's/bb_info_msg("unexpected DHCP6 option/if (0) bb_info_msg("unexpected DHCP6 option/' \
    "${SRC_DIR}/trunk/user/busybox/busybox-1.24.x/networking/udhcp/dhcp6c_common.c"