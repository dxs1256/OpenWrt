#!/bin/bash
# ================================================
# DIY Script for OpenWrt
# 说明：
# 1. 保留 unishare 和 pushbot
# 2. 适配 aarch64 架构，避免依赖缺失
# ================================================

# 1. 删除 feed 自带的可能冲突插件
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-ksmbd
rm -rf feeds/luci/applications/luci-app-opkg

# 2. 进入 package 目录
mkdir -p package
cd package

# 3. 拉取自定义插件
git clone https://github.com/rufengsuixing/luci-app-adguardhome
git clone https://github.com/sbwml/luci-app-alist
git clone https://github.com/sbwml/luci-app-unishare
git clone https://github.com/zzsj0928/luci-app-pushbot

# 4. 拉取 Argon 主题
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon

# 5. 可选：更改 Argon 主题背景
if [ -f "$GITHUB_WORKSPACE/images/bg1.jpg" ]; then
    cp -f $GITHUB_WORKSPACE/images/bg1.jpg luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
fi

# 6. 返回 openwrt 根目录
cd ..

# 7. 修改本地时间格式（autocore）
if [ -d package/lean/autocore/files ]; then
    sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm
fi

# 8. 修正 Makefile 路径
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|\.\./\.\./luci.mk|$(TOPDIR)/feeds/luci/luci.mk|g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|\.\./\.\./lang/golang/golang-package.mk|$(TOPDIR)/feeds/packages/lang/golang/golang-package.mk|g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|PKG_SOURCE_URL:=@GHREPO|PKG_SOURCE_URL:=https://github.com|g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|PKG_SOURCE_URL:=@GHCODELOAD|PKG_SOURCE_URL:=https://codeload.github.com|g' {}

# 9. 取消主题默认设置（防止 Argon 自动改 mediaurlbase）
find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

# 10. 添加外部软件包源
sed -i '$a src-git smpackage https://github.com/kenzok8/small-package' feeds.conf.default

# 11. 更新并安装 feeds
./scripts/feeds update -a
./scripts/feeds install -a

echo "DIY 脚本执行完成 ✅"
