#!/bin/bash
set -e
set -x

# -------------------------
# DEFAULT CONFIG
# -------------------------
APP_NAME="invoiso"
APP_VERSION="1.0.0"
MAINTAINER="Anoop P <anooppkrishnan96@gmail.com>"
BUILD_NUMBER_FILE=".build_number"
DEFAULT_BUILD_DIR="build/linux/x64/release/bundle"

# -------------------------
# ARGS / FLAGS
# -------------------------
DO_BUILD=false
RESET_BUILD=false
CUSTOM_BUILD_DIR=""

function usage
{
  cat <<EOF
Usage: $0 [options]

Options:
  -v, --version VERSION      Set app version (default: $APP_VERSION)
  -b, --build                Run 'flutter build linux --release' before packaging
  -d, --build-dir PATH       Use custom build directory (default: $DEFAULT_BUILD_DIR)
      --reset-build         Reset stored build number to 0
  -h, --help                 Show this help
EOF
}

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version)
      APP_VERSION="$2"
      shift 2
      ;;
    -b|--build)
      DO_BUILD=true
      shift
      ;;
    -d|--build-dir)
      CUSTOM_BUILD_DIR="$2"
      shift 2
      ;;
    --reset-build)
      RESET_BUILD=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "❌ Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# -------------------------
# PATHS
# -------------------------
ROOT_DIR="$(pwd)"
: "${BUILD_DIR:=$ROOT_DIR/$DEFAULT_BUILD_DIR}"
if [ -n "$CUSTOM_BUILD_DIR" ]; then
  # if user gave a relative path, make it relative to ROOT_DIR
  if [[ "$CUSTOM_BUILD_DIR" = /* ]]; then
    BUILD_DIR="$CUSTOM_BUILD_DIR"
  else
    BUILD_DIR="$ROOT_DIR/$CUSTOM_BUILD_DIR"
  fi
fi
BUILD_NUMBER_FILE="$ROOT_DIR/$BUILD_NUMBER_FILE"

# -------------------------
# HANDLE BUILD NUMBER
# -------------------------
if [ "$RESET_BUILD" = true ]; then
  echo "0" > "$BUILD_NUMBER_FILE"
fi

if [ ! -f "$BUILD_NUMBER_FILE" ]; then
  echo "0" > "$BUILD_NUMBER_FILE"
fi

BUILD_NUMBER=$(cat "$BUILD_NUMBER_FILE" 2>/dev/null || echo "0")
BUILD_NUMBER=$((BUILD_NUMBER + 1))
echo "$BUILD_NUMBER" > "$BUILD_NUMBER_FILE"

# Append build number to version (e.g., 1.0.0-1)
FULL_VERSION="${APP_VERSION}-${BUILD_NUMBER}"

PKG_DIR="$ROOT_DIR/${APP_NAME}_${FULL_VERSION}"
OUT_DEB="$ROOT_DIR/${APP_NAME}_${FULL_VERSION}.deb"

# -------------------------
# OPTIONAL: build Flutter
# -------------------------
if [ "$DO_BUILD" = true ]; then
  if ! command -v flutter >/dev/null 2>&1; then
    echo "❌ flutter command not found. Install Flutter or remove -b flag."
    exit 1
  fi
  echo "🔨 Running: flutter pub get && flutter build linux --release"
  flutter pub get
  flutter build linux --release
fi

# -------------------------
# CHECK BUILD DIR
# -------------------------
if [ ! -d "$BUILD_DIR" ]; then
  echo "❌ Build directory not found: $BUILD_DIR"
  echo "Run: flutter build linux --release (or pass -d to specify a custom build directory)"
  exit 1
fi

# -------------------------
# CLEAN OLD
# -------------------------
rm -rf "$PKG_DIR" "$OUT_DEB"

# -------------------------
# CREATE DIRECTORIES
# -------------------------
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/opt/$APP_NAME"
mkdir -p "$PKG_DIR/usr/local/bin"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/icons/hicolor/256x256/apps"

# -------------------------
# COPY BUILD OUTPUT (bin, lib, data)
# -------------------------
cp -r "$BUILD_DIR/"* "$PKG_DIR/opt/$APP_NAME/"

# ensure main binary is executable
if [ -f "$PKG_DIR/opt/$APP_NAME/$APP_NAME" ]; then
  chmod +x "$PKG_DIR/opt/$APP_NAME/$APP_NAME"
fi

# -------------------------
# WRAPPER (usr/local/bin)
# -------------------------
cat <<EOF > "$PKG_DIR/usr/local/bin/$APP_NAME"
#!/bin/bash
exec /opt/$APP_NAME/$APP_NAME "\$@"
EOF
chmod +x "$PKG_DIR/usr/local/bin/$APP_NAME"

# -------------------------
# CONTROL FILE
# -------------------------
cat <<EOF > "$PKG_DIR/DEBIAN/control"
Package: $APP_NAME
Version: $FULL_VERSION
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
Name=Invoiso
Comment=Invoice generating desktop app built with Flutter
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=Office;Utility;
EOF

# -------------------------
# ICON (copy if exists)
# -------------------------
ICON_SRC="$ROOT_DIR/assets/deb/images/logo.png"
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$PKG_DIR/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
else
  echo "⚠️  No icon found at $ICON_SRC, skipping icon."
fi

# -------------------------
# BUILD THE DEB
# -------------------------
dpkg-deb --build "$PKG_DIR" "$OUT_DEB"

echo "✅ Package built: $OUT_DEB"

