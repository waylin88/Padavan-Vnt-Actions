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

# 1. 覆盖机型配置、Web UI 和 VNTC 模块
copy_dir_if_exists "${REPO_DIR}/trunk" "${SRC_DIR}/trunk"
copy_dir_if_exists \
    "${REPO_DIR}/padavan-mod-package/modified/trunk/user/www" \
    "${SRC_DIR}/trunk/user/www"
copy_dir_if_exists "${REPO_DIR}/patches/vntc" "${SRC_DIR}/trunk/user/vntc"

echo ">>> 覆盖自定义 Web UI 文件"
mkdir -p "${SRC_DIR}/trunk/user/httpd" "${SRC_DIR}/trunk/user/www/n56u_ribbon_fixed"
cp -f "${WEB_UI_DIR}/httpd/httpd.c" "${SRC_DIR}/trunk/user/httpd/httpd.c"
cp -f "${WEB_UI_DIR}/httpd/httpd.h" "${SRC_DIR}/trunk/user/httpd/httpd.h"
cp -f "${WEB_UI_DIR}/httpd/web_ex.c" "${SRC_DIR}/trunk/user/httpd/web_ex.c"
cp -f "${WEB_UI_DIR}/www/n56u_ribbon_fixed/Login.asp" \
    "${SRC_DIR}/trunk/user/www/n56u_ribbon_fixed/Login.asp"
cp -f "${WEB_UI_DIR}/www/n56u_ribbon_fixed/Logout.asp" \
    "${SRC_DIR}/trunk/user/www/n56u_ribbon_fixed/Logout.asp"

if [ -d "${SRC_DIR}/trunk/user/vntc" ]; then
    chmod -R +x "${SRC_DIR}/trunk/user/vntc"
fi

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

# 屏蔽 BusyBox DHCPv6 的日志噪音
echo ">>> 屏蔽 BusyBox DHCPv6 日志噪音"
sed -i 's/bb_info_msg("status code for/if (0) bb_info_msg("status code for/' \
    "${SRC_DIR}/trunk/user/busybox/busybox-1.24.x/networking/udhcp/dhcp6c_ia.c"
sed -i 's/bb_info_msg("unexpected DHCP6 option/if (0) bb_info_msg("unexpected DHCP6 option/' \
    "${SRC_DIR}/trunk/user/busybox/busybox-1.24.x/networking/udhcp/dhcp6c_common.c"

