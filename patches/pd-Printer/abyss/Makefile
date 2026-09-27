#
# Makefile -- abyss 插件
#
# 将预编译的 abyss 二进制安装到固件文件系统。
# 启动/停止/守护逻辑全部由 rc (services.c / watchdog.c) 以 C 代码实现,
# WAN up 时 start_abyss() 启动, watchdog 守护, WAN down 时 stop_abyss() 停止。
#
# 目录结构:
#   abyss  -- 预编译的 mipsel 可执行文件
#

THISDIR = $(shell pwd)

all:

clean:

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/abyss /usr/bin/abyss

.PHONY: all clean romfs
