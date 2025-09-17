#!/bin/bash
set -e

# 函数：增量拉取插件
function ensure_package() {
  pkg_name="$1"
  repo_url="$2"
  dest_dir="package/$pkg_name"

  if [ ! -d "$dest_dir" ]; then
    git clone --depth 1 "$repo_url" "$dest_dir"
  else
    echo "$pkg_name 已存在，尝试更新..."
    cd "$dest_dir"
    git pull --rebase --depth 1 || true
    cd ../../
  fi
}

# 删除 feed 里自带的插件
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-pushbot
rm -rf feeds/luci/applications/luci-app-ksmbd
rm -rf feeds/luci/applications/luci-app-opkg
rm -rf feeds/luci/applications/luci-app-unishare

# 拉取自定义插件（增量）
ensure_package luci-app-adguardhome https://github.com/rufengsuixing/luci-app-adguardhome
ensure_package luci-app-unishare https://github.com/dxs12566/nas-packages
ensure_package luci-app-pushbot https://github.com/zzsj0928/luci-app-pushbot
ensure_package luci-app-alist https://github.com/sbwml/luci-app-alist

# 主题
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon

# 修改本地时间格式
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by Situ/g" package/lean/default-settings/files/zzz-default-settings

# 修改 Makefile
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

# 取消主题默认设置
find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

# 添加外部软件包源
sed -i '$a src-git smpackage https://github.com/kenzok8/small-package' feeds.conf.default

# 更新并安装所有源
./scripts/feeds update -a
./scripts/feeds install -a
