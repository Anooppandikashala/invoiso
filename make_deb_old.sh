#!/bin/bash
set -e

# -------------------------
# CONFIG
# -------------------------
APP_NAME="invoiceapp"
APP_VERSION="1.0.0"
MAINTAINER="Anoop P <your@email.com>"

# Paths
ROOT_DIR="$(pwd)"
BUILD_DIR="$ROOT_DIR/build/linux/x64/release/bundle"
PKG_DIR="$ROOT_DIR/${APP_NAME}_${APP_VERSION}"

# Clean old builds
rm -rf "$PKG_DIR" "${APP_NAME}_${APP_VERSION}.deb"

# -------------------------
# CREATE DIRECTORIES
# -------------------------
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/opt/$APP_NAME"
mkdir -p "$PKG_DIR/usr/local/bin"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/icons/hicolor/256x256/apps"

# -------------------------
# COPY FILES
# -------------------------
cp -r "$BUILD_DIR/"* "$PKG_DIR/opt/$APP_NAME/"

# Wrapper script in /usr/local/bin
cat <<EOF > "$PKG_DIR/usr/local/bin/$APP_NAME"
#!/bin/bash
/opt/$APP_NAME/$APP_NAME "\$@"
EOF
chmod +x "$PKG_DIR/usr/local/bin/$APP_NAME"

# -------------------------
# CONTROL FILE
# -------------------------
cat <<EOF > "$PKG_DIR/DEBIAN/control"
Package: $APP_NAME
Version: $APP_VERSION
Section: utils
Priority: optional
Architecture: amd64
Maintainer: $MAINTAINER
Description: Invoice generating desktop app built with Flutter
EOF

# -------------------------
# DESKTOP ENTRY
# -------------------------
cat <<EOF > "$PKG_DIR/usr/share/applications/$APP_NAME.desktop"
[Desktop Entry]
Name=InvoiceApp
Comment=Invoice generating desktop app built with Flutter
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=Office;Utility;
EOF

# -------------------------
# ICON (update path if needed)
# -------------------------
if [ -f "$ROOT_DIR/assets/images/logo.png" ]; then
    cp "$ROOT_DIR/assets/images/logo.png" "$PKG_DIR/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
else
    echo "⚠️  No icon found at assets/images/logo.png, skipping icon."
fi

# -------------------------
# BUILD DEB
# -------------------------
dpkg-deb --build "$PKG_DIR"

echo "✅ Package built: ${APP_NAME}_${APP_VERSION}.deb"

