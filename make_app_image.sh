#!/usr/bin/env bash
set -e

# ====== CONFIG ======
VERSION=${1:-"1.0.0"}   # pass version as argument, default 1.0.0
FLUTTER_VERSION="3.32.8"

echo "🚀 Building AppImage for version: $VERSION"

# ====== Install dependencies ======
echo "🔧 Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y \
  clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev patchelf squashfs-tools \
  appstream file desktop-file-utils libfuse2 zsync python3-pip

# ====== (Optional) Install Flutter if missing ======
# if ! command -v flutter &>/dev/null; then
#   echo "⚡ Installing Flutter $FLUTTER_VERSION ..."
#   git clone https://github.com/flutter/flutter.git -b stable
#   export PATH="$PWD/flutter/bin:$PATH"
#   flutter --version
# fi

# ====== Build Flutter Linux Release ======
# echo "🛠️ Running Flutter build..."
# flutter pub get
# flutter build linux --release

# ====== Prepare AppDir ======
echo "📂 Preparing AppDir..."
rm -rf AppDir
mkdir -p AppDir/usr/bin
cp -r build/linux/x64/release/bundle/* AppDir/
cp build/linux/x64/release/bundle/invoiso AppDir/invoiso

# Copy icon
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps
cp assets/deb/images/logo.png AppDir/usr/share/icons/hicolor/256x256/apps/logo.png

# Copy .desktop file (ensure it exists)
#if [[ -f assets/deb/com.invoiso.desktop ]]; then
#  cp assets/deb/com.invoiso.desktop AppDir/com.invoiso.desktop.desktop
#else
#  echo "⚠️ Warning: com.invoiso.desktop not found, skipping..."
#fi

# ====== Install AppImage Builder ======
if ! command -v appimage-builder &>/dev/null; then
  echo "⚡ Installing AppImage Builder..."
  pip install --user appimage-builder
  export PATH="$HOME/.local/bin:$PATH"
fi

# ====== Update version in AppImageBuilder.yml ======
echo "✏️ Updating AppImageBuilder.yml with version $VERSION"
# Only update the version inside 'app_info:' section
sed -i "/app_info:/,/^[^ ]/ s/^\(\s*version:\s*\)[0-9.]\+$/\1$VERSION/" AppImageBuilder.yml

# ====== Build AppImage ======
echo "📦 Building AppImage..."
appimage-builder --recipe AppImageBuilder.yml --skip-test

# ====== Output Summary ======
echo "✅ Build complete!"
ls -lh *.AppImage || echo "❌ AppImage not found!"
