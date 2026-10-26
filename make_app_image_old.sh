#!/usr/bin/env bash
# Disabled: appimage-builder hardcodes xz compression, which AppImageHub
# cannot mount. AppImage is now built with appimagetool in
# .github/workflows/build.yml (build-appimage job).
#set -e
#
## ====== CONFIG ======
#VERSION=${1:-"1.0.0"}   # pass version as arg, default 1.0.0
#FLUTTER_VERSION="3.32.8"
#
#echo "🚀 Building AppImage for version: $VERSION"
#
## ====== Install dependencies ======
#echo "🔧 Installing dependencies..."
#sudo apt-get update -y
#sudo apt-get install -y \
#  clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev patchelf squashfs-tools \
#  appstream file desktop-file-utils libfuse2 zsync
#
### ====== Install Flutter if missing ======
##if ! command -v flutter &>/dev/null; then
##  echo "⚡ Installing Flutter $FLUTTER_VERSION ..."
##  git clone https://github.com/flutter/flutter.git -b stable
##  export PATH="$PWD/flutter/bin:$PATH"
##  flutter --version
##fi
#
### ====== Build Flutter Linux Release ======
##echo "🛠️ Running Flutter build..."
##flutter pub get
##flutter build linux --release
#
## ====== Prepare AppDir ======
#echo "📂 Preparing AppDir..."
#rm -rf AppDir
#mkdir -p AppDir/usr/bin
##cp -r build/linux/x64/release/bundle/* AppDir/usr/bin/
#cp -r build/linux/x64/release/bundle/* AppDir/
#cp build/linux/x64/release/bundle/invoiso AppDir/invoiso
#
#mkdir -p AppDir/usr/share/icons
#cp assets/deb/images/logo.png AppDir/usr/share/icons/logo.png
#
## ====== Install AppImage Builder ======
#if ! command -v appimage-builder &>/dev/null; then
#  echo "⚡ Installing AppImage Builder..."
#  pip install --user appimage-builder
#  export PATH="$HOME/.local/bin:$PATH"
#fi
#
## ====== Update version in AppImageBuilder.yml ======
#echo "✏️ Updating AppImageBuilder.yml with version $VERSION"
##sed -i "s/^\(\s*version:\s*\)[0-9.]\+$/\1$VERSION/" AppImageBuilder.yml
#sed -i "/app_info:/,/^[^ ]/ s/^\(\s*version:\s*\)[0-9.]\+$/\1$VERSION/" AppImageBuilder.yml
#
#
## ====== Build AppImage ======
#echo "📦 Building AppImage..."
#appimage-builder --recipe AppImageBuilder.yml --skip-test
#
#echo "✅ Build complete. Check for .AppImage file in the current directory."
