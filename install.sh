#!/bin/sh
# JZLite Universal Installer (Linux / ARM64 Router / POSIX Shell)
# Usage:
#   wget -qO- https://raw.githubusercontent.com/jzkanq/litesecret/main/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/jzkanq/litesecret/main/install.sh | sh
#
# Flags:
#   sh install.sh --persistent   (Install permanently to /mnt/userdata/jzlite)
#   sh install.sh --temporary    (Deploy to RAM in /tmp/jzlite-test)
#   sh install.sh --uninstall    (Remove JZLite and restore standard routing)

set -e

VERSION="1.0.4"
REPO_URL="https://github.com/jzkanq/jzlite-downloads"
RAW_BASE="https://raw.githubusercontent.com/jzkanq/jzlite-downloads/main"
RELEASE_BASE="https://github.com/jzkanq/jzlite-downloads/releases/download/v${VERSION}"

# Color helpers
if [ -t 1 ]; then
    CYAN='\033[0;36m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    CYAN=''
    GREEN=''
    YELLOW=''
    RED=''
    NC=''
fi

echo "${CYAN}"
echo "   ██╗███████╗██╗     ██╗████████╗███████╗"
echo "   ██║╚══███╔╝██║     ██║╚══██╔══╝██╔════╝"
echo "   ██║  ███╔╝ ██║     ██║   ██║   █████╗  "
echo "██ ██║ ███╔╝  ██║     ██║   ██║   ██╔══╝  "
echo "╚████║███████╗███████╗██║   ██║   ███████╗"
echo " ╚═══╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚══════╝"
echo "   JZLite Cloud-Connected Router Engine v${VERSION}"
echo "${NC}"

# Detect download tool
download_file() {
    URL="$1"
    DEST="$2"
    if command -v wget >/dev/null 2>&1; then
        wget -q --no-check-certificate -O "$DEST" "$URL" || wget -q -O "$DEST" "$URL"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL -k -o "$DEST" "$URL"
    else
        echo "${RED}Error: Neither wget nor curl found on system.${NC}" >&2
        exit 1
    fi
}

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
    aarch64|arm64)
        BIN_SUFFIX="arm64"
        ;;
    x86_64|amd64)
        BIN_SUFFIX="amd64"
        ;;
    *)
        BIN_SUFFIX="arm64"
        ;;
esac

# Target destination directories
if [ -d "/mnt/userdata" ]; then
    PERSISTENT_DIR="/mnt/userdata/jzlite"
else
    PERSISTENT_DIR="/opt/jzlite"
fi
TEMP_DIR="/tmp/jzlite-test"

ACTION=""
if [ "$1" = "--temporary" ] || [ "$1" = "-t" ] || [ "$1" = "temp" ]; then
    ACTION="temporary"
elif [ "$1" = "--uninstall" ] || [ "$1" = "-u" ] || [ "$1" = "uninstall" ]; then
    ACTION="uninstall"
elif [ "$1" = "--persistent" ] || [ "$1" = "-p" ] || [ "$1" = "persistent" ]; then
    ACTION="persistent"
fi

if [ -z "$ACTION" ]; then
    if [ -t 0 ]; then
        echo "============================================================"
        echo "                   JZLite Setup Menu"
        echo "============================================================"
        echo ""
        echo "  [1] Install Persistently (Recommended)"
        echo "      Installs to /mnt/userdata/jzlite with autostart on boot."
        echo ""
        echo "  [2] Temporary Clean Run (RAM-only)"
        echo "      Runs from /tmp/jzlite-test and disappears after reboot."
        echo ""
        echo "  [3] Uninstall"
        echo "      Stops all services and removes JZLite."
        echo ""
        echo "  [4] Exit"
        echo ""
        printf "Choose [1-4] (default: 1): "
        read -r CHOICE
        case "$CHOICE" in
            2) ACTION="temporary" ;;
            3) ACTION="uninstall" ;;
            4) echo "Exiting."; exit 0 ;;
            *) ACTION="persistent" ;;
        esac
    else
        ACTION="persistent"
    fi
fi

if [ "$ACTION" = "uninstall" ]; then
    echo "${YELLOW}Uninstalling JZLite...${NC}"
    killall jzlite-probe 2>/dev/null || true
    killall xray 2>/dev/null || true
    killall hev-socks5-tunnel 2>/dev/null || true
    rm -rf "$PERSISTENT_DIR" "$TEMP_DIR" 2>/dev/null || true
    rm -f /etc_rw/init.d/jzlite 2>/dev/null || true
    rm -f /etc/init.d/jzlite 2>/dev/null || true
    echo "${GREEN}JZLite uninstalled successfully.${NC}"
    exit 0
fi

INSTALL_TARGET="$PERSISTENT_DIR"
if [ "$ACTION" = "temporary" ]; then
    INSTALL_TARGET="$TEMP_DIR"
    echo "${CYAN}Deploying in Temporary RAM Mode (${TEMP_DIR})...${NC}"
else
    echo "${CYAN}Installing in Persistent Mode (${PERSISTENT_DIR})...${NC}"
fi

mkdir -p "$INSTALL_TARGET/bin" "$INSTALL_TARGET/data" "$INSTALL_TARGET/run"

echo "Checking available memory..."
if [ -f /proc/meminfo ]; then
    MEM_AVAIL=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    if [ -n "$MEM_AVAIL" ] && [ "$MEM_AVAIL" -lt 12288 ]; then
        echo "${YELLOW}Warning: Available memory is low (${MEM_AVAIL} KB). Running with low-memory governor.${NC}"
    fi
fi

# Stop existing processes
killall jzlite-probe 2>/dev/null || true

# If binaries exist in local dist folder, copy them; otherwise download from release
if [ -f "./dist/jzlite-probe-${BIN_SUFFIX}" ]; then
    echo "Installing from local dist directory..."
    cp -f "./dist/jzlite-probe-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/jzlite-probe"
    [ -f "./dist/xray-${BIN_SUFFIX}" ] && cp -f "./dist/xray-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/xray"
    [ -f "./dist/hev-socks5-tunnel-${BIN_SUFFIX}" ] && cp -f "./dist/hev-socks5-tunnel-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/hev-socks5-tunnel"
elif [ -f "./jzlite-probe-${BIN_SUFFIX}" ]; then
    echo "Installing from current directory..."
    cp -f "./jzlite-probe-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/jzlite-probe"
    [ -f "./xray-${BIN_SUFFIX}" ] && cp -f "./xray-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/xray"
    [ -f "./hev-socks5-tunnel-${BIN_SUFFIX}" ] && cp -f "./hev-socks5-tunnel-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/hev-socks5-tunnel"
else
    echo "Downloading JZLite v${VERSION} release archive..."
    TAR_TMP="/tmp/jzlite_pkg.tgz"
    download_file "${RELEASE_BASE}/JZLite-${VERSION}-UNSIGNED-EXPERIMENTAL.tgz" "$TAR_TMP"
    echo "Extracting release package..."
    tar -xzf "$TAR_TMP" -C /tmp/
    if [ -f "/tmp/jzlite-probe-${BIN_SUFFIX}" ]; then
        cp -f "/tmp/jzlite-probe-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/jzlite-probe"
        [ -f "/tmp/xray-${BIN_SUFFIX}" ] && cp -f "/tmp/xray-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/xray"
        [ -f "/tmp/hev-socks5-tunnel-${BIN_SUFFIX}" ] && cp -f "/tmp/hev-socks5-tunnel-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/hev-socks5-tunnel"
        rm -f "/tmp/jzlite-probe-arm64" "/tmp/xray-arm64" "/tmp/hev-socks5-tunnel-arm64" "$TAR_TMP" 2>/dev/null || true
    fi
fi

chmod +x "$INSTALL_TARGET/bin/jzlite-probe" 2>/dev/null || true
[ -f "$INSTALL_TARGET/bin/xray" ] && chmod +x "$INSTALL_TARGET/bin/xray" 2>/dev/null || true
[ -f "$INSTALL_TARGET/bin/hev-socks5-tunnel" ] && chmod +x "$INSTALL_TARGET/bin/hev-socks5-tunnel" 2>/dev/null || true

# Check for license key flag or stage
if [ -n "$2" ] && [ "$2" != "" ]; then
    echo "$2" > "$INSTALL_TARGET/data/license-key.txt"
fi

# Create launcher script
cat <<'EOF' > "$INSTALL_TARGET/bin/start-jzlite.sh"
#!/bin/sh
DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

GOGC=30 GOMEMLIMIT=28MiB exec "$DIR/bin/jzlite-probe" \
    -auth "$DIR/data/auth.json" \
    -profiles "$DIR/data/profiles.json" \
    -settings "$DIR/data/settings.json" \
    -license "$DIR/data/license.json" \
    -binding "$DIR/data/license-binding.txt" \
    -binding-version "$DIR/data/license-binding-version.txt" \
    -license-key "$DIR/data/license-key.txt" \
    -runtime-dir "$DIR/run" \
    -listen ":8080" \
    >> "$DIR/run/jzlite.log" 2>&1 &
EOF
chmod +x "$INSTALL_TARGET/bin/start-jzlite.sh"

# If persistent, create init service
if [ "$ACTION" = "persistent" ]; then
    INIT_DIR=""
    if [ -d "/etc_rw/init.d" ]; then
        INIT_DIR="/etc_rw/init.d"
    elif [ -d "/etc/init.d" ]; then
        INIT_DIR="/etc/init.d"
    fi

    if [ -n "$INIT_DIR" ]; then
        cat <<EOF > "$INIT_DIR/jzlite"
#!/bin/sh
case "\$1" in
    start)
        "$PERSISTENT_DIR/bin/start-jzlite.sh"
        ;;
    stop)
        killall jzlite-probe 2>/dev/null || true
        ;;
    restart)
        killall jzlite-probe 2>/dev/null || true
        sleep 1
        "$PERSISTENT_DIR/bin/start-jzlite.sh"
        ;;
    *)
        "$PERSISTENT_DIR/bin/start-jzlite.sh"
        ;;
esac
EOF
        chmod +x "$INIT_DIR/jzlite" 2>/dev/null || true
    fi
fi

# Start service
"$INSTALL_TARGET/bin/start-jzlite.sh"

echo ""
echo "${GREEN}✔ JZLite v${VERSION} installed and started successfully!${NC}"
echo "Dashboard URL:  https://192.168.0.1:5443"
echo "Cloud Relay:    https://jzliteadmin.lovable.app"
echo ""
