#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# 临时解决Rust问题
sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile

# daed 源码编译会在 Actions 中拉取 Go/Node 依赖并构建前后端，开销很大。
# 这里改为复用上游已经发布的 ARM64 ipk，再由当前目标重新封装，保留本地包管理关系。
cat <<'EOF' > package/dae/daed/Makefile
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=daed
PKG_VERSION:=2026.05.26
PKG_RELEASE:=1

PKG_SOURCE:=daed_$(PKG_VERSION)-r$(PKG_RELEASE)_aarch64_generic-openwrt-24.10.ipk
PKG_SOURCE_URL:=https://github.com/QiuSimons/luci-app-daed/releases/download/daed_$(PKG_VERSION)-r$(PKG_RELEASE)
PKG_HASH:=7c79420aaf42bc7e9967406a85f17573d4ceedf5f7ce5924c59654f744d8efba

PKG_LICENSE:=AGPL-3.0-only MIT
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/daed
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=A Modern Dashboard For dae
  URL:=https://github.com/daeuniverse/daed
  DEPENDS:=+ca-bundle +kmod-sched-core +kmod-sched-bpf +kmod-veth +v2ray-geoip +v2ray-geosite +@KERNEL_XDP_SOCKETS
endef

define Package/daed/description
  daed is a backend of dae, provides a method to bundle arbitrary
  frontend, dae and geodata into one binary.
endef

define Package/daed/conffiles
/etc/daed/wing.db
/etc/config/daed
endef

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)/pkg $(PKG_BUILD_DIR)/src
	( \
		tar -xzf $(DL_DIR)/$(PKG_SOURCE) -C $(PKG_BUILD_DIR)/src && \
		cd $(PKG_BUILD_DIR)/src && \
		tar -xzf data.tar.gz -C $(PKG_BUILD_DIR)/pkg \
	)
endef

define Build/Compile
endef

define Package/daed/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/pkg/usr/bin/daed $(1)/usr/bin/daed

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/pkg/etc/config/daed $(1)/etc/config/daed

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/pkg/etc/init.d/daed $(1)/etc/init.d/daed
endef

$(eval $(call BuildPackage,daed))
EOF

# add date in output file name
sed -i -e '/^IMG_PREFIX:=/i BUILD_DATE := $(shell date +%Y%m%d)' \
       -e '/^IMG_PREFIX:=/ s/\($(SUBTARGET)\)/\1-$(BUILD_DATE)/' include/image.mk

# set ubi to 122M
# sed -i 's/reg = <0x5c0000 0x7000000>;/reg = <0x5c0000 0x7a40000>;/' target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1-ubootmod.dts
