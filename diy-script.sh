#!/bin/bash

# 删除自带 SSR-Plus 源码
rm -rf feeds/luci/applications/luci-app-ssr-plus
rm -rf feeds/luci/luci-app-ssr-plus
rm -rf package/luci-app-ssr-plus

# 强制在 .config 禁用 SSR-Plus
sed -i '/CONFIG_PACKAGE_luci-app-ssr-plus/d' .config
echo "# CONFIG_PACKAGE_luci-app-ssr-plus is not set" >> .config

# 额外插件
git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome
git clone --depth=1 https://github.com/zzsj0928/luci-app-pushbot package/luci-app-pushbot

# 替换 golang
rm -rf feeds/packages/lang/golang
git clone https://github.com/OpenListTeam/packages_lang_golang -b 24.x feeds/packages/lang/golang

# 科学上网插件
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall

# 主题
git clone https://github.com/gngpp/luci-theme-design.git package/luci-theme-design
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon

# 修改本地时间显示格式
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm || true

# 修改版本号为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(grep "DISTRIB_REVISION=" package/lean/default-settings/files/zzz-default-settings | awk -F"'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by Situ/g" package/lean/default-settings/files/zzz-default-settings || true

# 修复 Makefile 路径
find package/*/ -maxdepth 2 -name "Makefile" | xargs -r -I {} sed -i 's|\.\./\.\./luci.mk|$(TOPDIR)/feeds/luci/luci.mk|g' {}
find package/*/ -maxdepth 2 -name "Makefile" | xargs -r -I {} sed -i 's|\.\./\.\./lang/golang/golang-package.mk|$(TOPDIR)/feeds/packages/lang/golang/golang-package.mk|g' {}
find package/*/ -maxdepth 2 -name "Makefile" | xargs -r -I {} sed -i 's|PKG_SOURCE_URL:=@GHREPO|PKG_SOURCE_URL:=https://github.com|g' {}
find package/*/ -maxdepth 2 -name "Makefile" | xargs -r -I {} sed -i 's|PKG_SOURCE_URL:=@GHCODELOAD|PKG_SOURCE_URL:=https://codeload.github.com|g' {}

# 取消主题默认设置（避免强制切换主题）
find package/luci-theme-*/* -type f -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

# 添加外部软件包源
sed -i '$a src-git smpackage https://github.com/kenzok8/small-package' feeds.conf.default

# 更新 feeds（不要在这里 install -a，避免 ssr-plus 被拉回）
./scripts/feeds update -a
./scripts/feeds install -a

# 最后再强制禁用 ssr-plus
sed -i '/CONFIG_PACKAGE_luci-app-ssr-plus/d' .config
echo "# CONFIG_PACKAGE_luci-app-ssr-plus is not set" >> .config
