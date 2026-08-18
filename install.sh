#!/bin/sh
# JZLite Universal Installer (Linux / ARM64 Router / POSIX Shell)
# Usage:
#   wget -qO- https://raw.githubusercontent.com/jzkanq/jzlite-downloads/main/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/jzkanq/jzlite-downloads/main/install.sh | sh
#
# Flags:
#   sh install.sh --persistent   (Install permanently to /mnt/userdata/jzlite)
#   sh install.sh --temporary    (Deploy to RAM in /tmp/jzlite-test)
#   sh install.sh --uninstall    (Remove JZLite and restore standard routing)

set -e

VERSION="1.0.5"
REPO_URL="https://github.com/jzkanq/jzlite-downloads"
RAW_BASE="https://raw.githubusercontent.com/jzkanq/jzlite-downloads/main"
RELEASE_BASE="https://github.com/jzkanq/jzlite-downloads/releases/download/v${VERSION}"

# Color helpers (uses real ANSI escape bytes for OpenWrt BusyBox ash compatibility)
if [ -t 1 ] || [ -c /dev/tty ]; then
    CYAN=$(printf '\033[0;36m')
    GREEN=$(printf '\033[0;32m')
    YELLOW=$(printf '\033[1;33m')
    RED=$(printf '\033[0;31m')
    NC=$(printf '\033[0m')
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

# Robust download tool detection (handles OpenWrt uclient-fetch, curl, and BusyBox wget)
download_file() {
    URL="$1"
    DEST="$2"
    SUCCESS=0
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL -k -o "$DEST" "$URL" 2>/dev/null; then
            SUCCESS=1
        fi
    fi
    if [ "$SUCCESS" != "1" ] && command -v uclient-fetch >/dev/null 2>&1; then
        if uclient-fetch --no-check-certificate -q -O "$DEST" "$URL" 2>/dev/null || uclient-fetch -q -O "$DEST" "$URL" 2>/dev/null; then
            SUCCESS=1
        fi
    fi
    if [ "$SUCCESS" != "1" ] && command -v wget >/dev/null 2>&1; then
        if wget -q --no-check-certificate -O "$DEST" "$URL" 2>/dev/null || wget -q -O "$DEST" "$URL" 2>/dev/null || wget -O "$DEST" "$URL" 2>/dev/null; then
            SUCCESS=1
        fi
    fi
    # If download failed on OpenWrt due to missing SSL library, auto-install prerequisites
    if [ "$SUCCESS" != "1" ] || [ ! -s "$DEST" ]; then
        if command -v opkg >/dev/null 2>&1; then
            echo "${YELLOW}Notice: OpenWrt requires SSL support for downloads. Installing libustream-mbedtls and ca-certificates...${NC}"
            opkg update >/dev/null 2>&1 || true
            opkg install libustream-mbedtls ca-certificates curl >/dev/null 2>&1 || opkg install libustream-openssl ca-certificates >/dev/null 2>&1 || opkg install libustream-wolfssl ca-certificates >/dev/null 2>&1 || true
            if command -v curl >/dev/null 2>&1; then
                curl -fsSL -k -o "$DEST" "$URL" 2>/dev/null && SUCCESS=1
            elif command -v uclient-fetch >/dev/null 2>&1; then
                uclient-fetch --no-check-certificate -q -O "$DEST" "$URL" 2>/dev/null && SUCCESS=1
            elif command -v wget >/dev/null 2>&1; then
                wget -q --no-check-certificate -O "$DEST" "$URL" 2>/dev/null && SUCCESS=1
            fi
        fi
    fi
    if [ "$SUCCESS" != "1" ] || [ ! -s "$DEST" ]; then
        echo "${RED}Error: Failed to download $URL${NC}" >&2
        echo "${YELLOW}Tip on OpenWrt: Run 'opkg update && opkg install curl ca-certificates libustream-mbedtls' and retry.${NC}" >&2
        rm -f "$DEST" 2>/dev/null || true
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

ACTION="persistent"
if [ "$1" = "--temporary" ] || [ "$1" = "-t" ] || [ "$1" = "temp" ]; then
    ACTION="temporary"
elif [ "$1" = "--coexist" ] || [ "$1" = "-c" ] || [ "$1" = "coexist" ]; then
    ACTION="persistent"
    COEXIST_XLITE=1
elif [ "$1" = "--uninstall" ] || [ "$1" = "-u" ] || [ "$1" = "uninstall" ]; then
    ACTION="uninstall"
elif [ "$1" = "--persistent" ] || [ "$1" = "-p" ] || [ "$1" = "persistent" ]; then
    ACTION="persistent"
elif [ -z "$1" ] && [ -c /dev/tty ]; then
    echo "============================================================"
    echo "                   JZLite Router Setup"
    echo "============================================================"
    echo ""
    echo "  [1] Install Persistently (Default)"
    echo "  [2] Install JZLite (Keep XLite / Coexist)"
    echo "  [3] Temporary RAM Mode (0 KB Flash / Auto-Wipe on Reboot)"
    echo "  [4] Uninstall JZLite"
    echo "  [5] Exit"
    echo ""
    printf "${CYAN}Choose an option [1-5, default 1]: ${NC}"
    read -r CHOICE < /dev/tty || CHOICE="1"
    CHOICE=$(echo "$CHOICE" | tr -d '\r\n')
    case "$CHOICE" in
        2)
            ACTION="persistent"
            COEXIST_XLITE=1
            ;;
        3)
            ACTION="temporary"
            ;;
        4)
            ACTION="uninstall"
            ;;
        5)
            echo "Installation cancelled."
            exit 0
            ;;
        *)
            ACTION="persistent"
            ;;
    esac
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

# Clean up stale temporary files and previous download remnants to free maximum storage
rm -f /tmp/jzlite_pkg.tgz /tmp/*.tgz /tmp/jzlite-probe* /tmp/xray* /tmp/hev* 2>/dev/null || true

echo "Checking available memory and storage..."
if [ -f /proc/meminfo ]; then
    MEM_TOTAL_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    MEM_AVAIL_KB=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    if [ -n "$MEM_TOTAL_KB" ] && [ "$MEM_TOTAL_KB" -le 290000 ]; then
        MEM_TOTAL_MB=$((MEM_TOTAL_KB / 1024))
        echo ""
        echo "${YELLOW}================================================================${NC}"
        echo "${YELLOW}⚠️  WARNING: DETECTED LOW MODEM MEMORY (${MEM_TOTAL_MB} MB RAM TOTAL)!${NC}"
        echo "${YELLOW}NOT RECOMMENDED TO INSTALL DUE TO SMALL MEMORY SIZE.${NC}"
        echo "${YELLOW}PROCEED WITH YOUR OWN RISK!${NC}"
        echo "${YELLOW}================================================================${NC}"
        echo ""
        sleep 2
    fi
    if [ -n "$MEM_AVAIL_KB" ] && [ "$MEM_AVAIL_KB" -lt 12288 ]; then
        echo "${YELLOW}Notice: Available memory is low (${MEM_AVAIL_KB} KB). Running with low-memory governor.${NC}"
    fi
fi

FREE_SPACE_KB=$(df -k "$INSTALL_TARGET" 2>/dev/null | tail -n 1 | awk '{print $(NF-2)}')
if [ -n "$FREE_SPACE_KB" ] && [ "$FREE_SPACE_KB" -lt 14336 ]; then
    # Try cleaning old backups in userdata if space is still tight
    rm -rf /mnt/userdata/xlite.jzlite-backup /mnt/userdata/*.bak /mnt/userdata/jzlite/run/*.log 2>/dev/null || true
    FREE_SPACE_KB=$(df -k "$INSTALL_TARGET" 2>/dev/null | tail -n 1 | awk '{print $(NF-2)}')
fi

if [ -n "$FREE_SPACE_KB" ] && [ "$FREE_SPACE_KB" -lt 14336 ]; then
    FREE_SPACE_MB=$((FREE_SPACE_KB / 1024))
    echo "${RED}Error: Not enough free storage in $INSTALL_TARGET (${FREE_SPACE_MB} MB available, at least 14 MB required).${NC}"
    echo "Tip: For modems with full flash storage, run in RAM mode: 'sh install.sh --temporary'"
    exit 1
fi

# Stop existing processes
killall jzlite-probe 2>/dev/null || true

# If binaries exist in local package/dist folder, copy them; otherwise download from release
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || echo "/tmp")"

if [ -f "$SCRIPT_DIR/dist/jzlite-probe-${BIN_SUFFIX}" ]; then
    echo "Installing from local dist directory ($SCRIPT_DIR/dist)..."
    cp -f "$SCRIPT_DIR/dist/jzlite-probe-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/jzlite-probe"
    [ -f "$SCRIPT_DIR/dist/xray-${BIN_SUFFIX}" ] && cp -f "$SCRIPT_DIR/dist/xray-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/xray"
    [ -f "$SCRIPT_DIR/dist/hev-socks5-tunnel-${BIN_SUFFIX}" ] && cp -f "$SCRIPT_DIR/dist/hev-socks5-tunnel-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/hev-socks5-tunnel"
elif [ -f "$SCRIPT_DIR/jzlite-probe-${BIN_SUFFIX}" ]; then
    echo "Installing from package directory ($SCRIPT_DIR)..."
    cp -f "$SCRIPT_DIR/jzlite-probe-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/jzlite-probe"
    [ -f "$SCRIPT_DIR/xray-${BIN_SUFFIX}" ] && cp -f "$SCRIPT_DIR/xray-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/xray"
    [ -f "$SCRIPT_DIR/hev-socks5-tunnel-${BIN_SUFFIX}" ] && cp -f "$SCRIPT_DIR/hev-socks5-tunnel-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/hev-socks5-tunnel"
elif [ -f "./dist/jzlite-probe-${BIN_SUFFIX}" ]; then
    echo "Installing from current dist directory..."
    cp -f "./dist/jzlite-probe-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/jzlite-probe"
    [ -f "./dist/xray-${BIN_SUFFIX}" ] && cp -f "./dist/xray-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/xray"
    [ -f "./dist/hev-socks5-tunnel-${BIN_SUFFIX}" ] && cp -f "./dist/hev-socks5-tunnel-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/hev-socks5-tunnel"
elif [ -f "./jzlite-probe-${BIN_SUFFIX}" ]; then
    echo "Installing from current working directory..."
    cp -f "./jzlite-probe-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/jzlite-probe"
    [ -f "./xray-${BIN_SUFFIX}" ] && cp -f "./xray-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/xray"
    [ -f "./hev-socks5-tunnel-${BIN_SUFFIX}" ] && cp -f "./hev-socks5-tunnel-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/hev-socks5-tunnel"
elif [ -f "/tmp/jzlite-probe-${BIN_SUFFIX}" ]; then
    echo "Installing from /tmp directory..."
    cp -f "/tmp/jzlite-probe-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/jzlite-probe"
    [ -f "/tmp/xray-${BIN_SUFFIX}" ] && cp -f "/tmp/xray-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/xray"
    [ -f "/tmp/hev-socks5-tunnel-${BIN_SUFFIX}" ] && cp -f "/tmp/hev-socks5-tunnel-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/hev-socks5-tunnel"
else
    echo "Downloading JZLite v${VERSION} release archive..."
    TAR_TMP="/tmp/jzlite_pkg.tgz"
    download_file "${RELEASE_BASE}/JZLite-${VERSION}-UNSIGNED-EXPERIMENTAL.tgz" "$TAR_TMP"
    if [ ! -s "$TAR_TMP" ]; then
        download_file "${RAW_BASE}/releases/v${VERSION}/JZLite-${VERSION}-UNSIGNED-EXPERIMENTAL.tgz" "$TAR_TMP"
    fi
    if [ ! -s "$TAR_TMP" ]; then
        download_file "${RELEASE_BASE}/jzlite.tgz" "$TAR_TMP"
    fi
    if [ ! -s "$TAR_TMP" ]; then
        echo "${RED}Error: Release archive is empty or failed to download.${NC}" >&2
        exit 1
    fi
    echo "Extracting release package..."
    tar -xzf "$TAR_TMP" -C /tmp/
    if [ ! -f "/tmp/jzlite-probe-${BIN_SUFFIX}" ]; then
        echo "${RED}Error: Failed to extract jzlite-probe-${BIN_SUFFIX} from release archive.${NC}" >&2
        exit 1
    fi
    cp -f "/tmp/jzlite-probe-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/jzlite-probe"
    [ -f "/tmp/xray-${BIN_SUFFIX}" ] && cp -f "/tmp/xray-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/xray"
    [ -f "/tmp/hev-socks5-tunnel-${BIN_SUFFIX}" ] && cp -f "/tmp/hev-socks5-tunnel-${BIN_SUFFIX}" "$INSTALL_TARGET/bin/hev-socks5-tunnel"
    rm -f "/tmp/jzlite-probe-arm64" "/tmp/xray-arm64" "/tmp/hev-socks5-tunnel-arm64" "/tmp/jzlite-probe-amd64" "/tmp/xray-amd64" "/tmp/hev-socks5-tunnel-amd64" "$TAR_TMP" 2>/dev/null || true
fi

chmod +x "$INSTALL_TARGET/bin/jzlite-probe" 2>/dev/null || true
[ -f "$INSTALL_TARGET/bin/xray" ] && chmod +x "$INSTALL_TARGET/bin/xray" 2>/dev/null || true
[ -f "$INSTALL_TARGET/bin/hev-socks5-tunnel" ] && chmod +x "$INSTALL_TARGET/bin/hev-socks5-tunnel" 2>/dev/null || true

if [ ! -f "$INSTALL_TARGET/bin/jzlite-probe" ]; then
    echo "${RED}Error: JZLite probe binary not found at $INSTALL_TARGET/bin/jzlite-probe${NC}" >&2
    exit 1
fi

# License Key Configuration
LICENSE_KEY=""
if [ -n "$2" ] && [ "$2" != "" ]; then
    LICENSE_KEY="$2"
elif [ -n "$JZLITE_KEY" ]; then
    LICENSE_KEY="$JZLITE_KEY"
elif [ -f "$INSTALL_TARGET/data/license-key.txt" ]; then
    LICENSE_KEY="$(cat "$INSTALL_TARGET/data/license-key.txt" 2>/dev/null || true)"
fi

if [ -z "$LICENSE_KEY" ]; then
    if [ -c /dev/tty ]; then
        printf "${CYAN}Enter your JZLite License Key: ${NC}"
        read -r LICENSE_KEY < /dev/tty || true
        LICENSE_KEY=$(echo "$LICENSE_KEY" | tr -d '\r\n')
    fi
fi

if [ -n "$LICENSE_KEY" ]; then
    echo "$LICENSE_KEY" > "$INSTALL_TARGET/data/license-key.txt"
    echo "Activating JZLite license online..."
    "$INSTALL_TARGET/bin/jzlite-probe" \
        -activate-key "$LICENSE_KEY" \
        -license "$INSTALL_TARGET/data/license.json" \
        -binding "$INSTALL_TARGET/data/license-binding.txt" \
        -binding-version "$INSTALL_TARGET/data/license-binding-version.txt" \
        -license-key "$INSTALL_TARGET/data/license-key.txt" 2>/dev/null || echo "${YELLOW}Notice: Online activation will finish on first boot.${NC}"
fi

# Dashboard Password Configuration
if [ ! -f "$INSTALL_TARGET/data/auth.json" ]; then
    DASH_PASS=""
    if [ -c /dev/tty ]; then
        printf "${CYAN}Set Dashboard Password (press Enter for default 'admin123'): ${NC}"
        read -r DASH_PASS < /dev/tty || true
        DASH_PASS=$(echo "$DASH_PASS" | tr -d '\r\n')
    fi
    if [ -z "$DASH_PASS" ]; then
        DASH_PASS="admin123"
    fi
    "$INSTALL_TARGET/bin/jzlite-probe" -init-auth "$DASH_PASS" -auth "$INSTALL_TARGET/data/auth.json" >/dev/null 2>&1 || true
fi

# Create launcher script
REDIRECT_FLAG='-listen ":5000"'
if [ "$NO_REDIRECT" = "1" ] || [ "$COEXIST_XLITE" = "1" ] || [ -f "/mnt/userdata/xlite/XLITE" ]; then
    REDIRECT_FLAG='-no-redirect'
    echo "${CYAN}XLite detected / Coexistence enabled: port 5000 redirect will be disabled for JZLite.${NC}"
fi

cat <<EOF > "$INSTALL_TARGET/bin/start-jzlite.sh"
#!/bin/sh
DIR="\$(cd "\$(dirname "\$0")/.." && pwd)"
cd "\$DIR"

nohup "\$DIR/bin/jzlite-probe" \\
    -auth "\$DIR/data/auth.json" \\
    -profiles "\$DIR/data/profiles.json" \\
    -settings "\$DIR/data/settings.json" \\
    -license "\$DIR/data/license.json" \\
    -license-binding "\$DIR/data/license-binding.txt" \\
    -license-binding-version "\$DIR/data/license-binding-version.txt" \\
    -license-key "\$DIR/data/license-key.txt" \\
    -xray-runtime "\$DIR/run" \\
    -xray "\$DIR/bin/xray" \\
    -hev "\$DIR/bin/hev-socks5-tunnel" \\
    $REDIRECT_FLAG \\
    </dev/null >> "\$DIR/run/jzlite.log" 2>&1 &
EOF
chmod +x "$INSTALL_TARGET/bin/start-jzlite.sh"

# If persistent, create init service
if [ "$ACTION" = "persistent" ]; then
    INIT_DIR=""
    if [ -d "/etc_rw/init.d" ] && [ -w "/etc_rw/init.d" ]; then
        INIT_DIR="/etc_rw/init.d"
    elif [ -d "/etc/init.d" ] && [ -w "/etc/init.d" ]; then
        INIT_DIR="/etc/init.d"
    fi

    if [ -n "$INIT_DIR" ]; then
        cat <<EOF > "$INIT_DIR/jzlite" 2>/dev/null || true
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

# Detect actual router LAN IP
DETECTED_IP=$("$INSTALL_TARGET/bin/jzlite-probe" -lan-ip 2>/dev/null || true)
if [ -z "$DETECTED_IP" ] || [ "$DETECTED_IP" = "127.0.0.1" ]; then
    if command -v uci >/dev/null 2>&1; then
        DETECTED_IP=$(uci get network.lan.ipaddr 2>/dev/null || true)
    fi
    if [ -z "$DETECTED_IP" ]; then
        DETECTED_IP=$(ip -4 addr show br-lan 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 || true)
    fi
    if [ -z "$DETECTED_IP" ]; then
        DETECTED_IP=$(ip -4 addr show br0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 || true)
    fi
    if [ -z "$DETECTED_IP" ]; then
        DETECTED_IP="192.168.0.1"
    fi
fi

# Start service
"$INSTALL_TARGET/bin/start-jzlite.sh"
sleep 1

echo ""
if pidof jzlite-probe >/dev/null 2>&1 || pgrep jzlite-probe >/dev/null 2>&1; then
    echo "${GREEN}✔ JZLite v${VERSION} installed and started successfully!${NC}"
else
    echo "${GREEN}✔ JZLite v${VERSION} installed successfully!${NC}"
    if [ -f "$INSTALL_TARGET/run/jzlite.log" ] && [ -s "$INSTALL_TARGET/run/jzlite.log" ]; then
        echo "${YELLOW}Startup Log Preview:${NC}"
        tail -n 5 "$INSTALL_TARGET/run/jzlite.log" 2>/dev/null || true
    fi
fi
echo "Dashboard URL:  https://${DETECTED_IP}:5443"
echo "Cloud Relay:    https://jzliteadmin.lovable.app"
echo ""
