#!/usr/bin/env bash

set -euo pipefail

APP_NAME="Invoiso"
REPO_OWNER="Anooppandikashala"
REPO_NAME="invoiso"
RELEASE_API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"

MY_OS_ARCH=$(uname -m)

if [ "$MY_OS_ARCH" != "x86_64" ]; then
    echo "Unsupported architecture: $MY_OS_ARCH"
    exit 1
fi

INSTALL_MODE="deb"

case "${1:-}" in
    --appimage)
        INSTALL_MODE="appimage"
        ;;
    --deb|"")
        INSTALL_MODE="deb"
        ;;
    -h|--help)
        echo "Usage: install.sh [--deb|--appimage]"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Usage: install.sh [--deb|--appimage]"
        exit 1
        ;;
esac

echo "Fetching latest release info..."

if command -v curl >/dev/null 2>&1; then
    RELEASE_INFO=$(curl -fsSL "${RELEASE_API_URL}")
elif command -v wget >/dev/null 2>&1; then
    RELEASE_INFO=$(wget -qO- "${RELEASE_API_URL}")
else
    echo "curl or wget is required to fetch release info."
    exit 1
fi

LATEST_TAG=$(printf '%s\n' "${RELEASE_INFO}" \
    | grep '"tag_name":' \
    | head -n 1 \
    | sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo "Failed to fetch latest release."
    exit 1
fi

APP_VERSION="${LATEST_TAG#v}"

echo "Latest version: ${APP_VERSION}"

MY_OS_ID=""
MY_OS_VERSION=""

if [ -r /etc/os-release ]; then
    . /etc/os-release
    MY_OS_ID="${ID:-}"
    MY_OS_VERSION="${VERSION_ID:-}"
fi

if [ "$INSTALL_MODE" = "deb" ]; then
    if [ "$MY_OS_ID" != "ubuntu" ]; then
        echo "DEB packages are officially supported on Ubuntu 22.04 and 24.04."
        echo "Detected ${MY_OS_ID:-unknown} ${MY_OS_VERSION:-unknown}; using AppImage instead."
        INSTALL_MODE="appimage"
    else
        echo "Detected Ubuntu ${MY_OS_VERSION}"

        case "$MY_OS_VERSION" in

            22.04)
                APP_FILE_NAME="Invoiso-${APP_VERSION}-ubuntu22.deb"
                ;;

            24.04)
                APP_FILE_NAME="Invoiso-${APP_VERSION}-ubuntu24.deb"
                ;;

            *)
                echo "Ubuntu ${MY_OS_VERSION} is not officially supported by the DEB package."
                echo "Using AppImage instead."
                INSTALL_MODE="appimage"
                ;;
        esac
    fi
fi

if [ "$INSTALL_MODE" = "appimage" ] && [ "${APP_FILE_NAME:-}" = "" ]; then
    if [ "$MY_OS_ID" = "ubuntu" ] && [ "$MY_OS_VERSION" = "24.04" ]; then
        APP_FILE_NAME="Invoiso-${APP_VERSION}-ubuntu24-x86_64.AppImage"
    else
        APP_FILE_NAME="Invoiso-${APP_VERSION}-x86_64.AppImage"
    fi
fi

DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${LATEST_TAG}/${APP_FILE_NAME}"

TEMP_FILE="/tmp/${APP_FILE_NAME}"

echo ""
echo "Downloading ${APP_FILE_NAME}..."

if command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "${TEMP_FILE}" "${DOWNLOAD_URL}"
else
    curl -fL "${DOWNLOAD_URL}" -o "${TEMP_FILE}"
fi

echo ""

if [ "${APP_FILE_NAME##*.}" = "deb" ]; then

    echo "Installing DEB package..."

    sudo apt-get update
    sudo apt-get install -y "${TEMP_FILE}"

    echo ""
    echo "${APP_NAME} installed successfully!"

else

    echo "Installing AppImage..."

    chmod +x "${TEMP_FILE}"

    mkdir -p "$HOME/Applications"

    FINAL_PATH="$HOME/Applications/${APP_FILE_NAME}"

    mv "${TEMP_FILE}" "${FINAL_PATH}"

    echo ""
    echo "AppImage installed successfully!"

    echo ""
    echo "Run using:"
    echo "${FINAL_PATH}"
fi
