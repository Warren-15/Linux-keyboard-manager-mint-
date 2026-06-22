#!/bin/bash
# lib_common.sh - Enforces Country Layout -> Variant Hierarchy

DEBUG=1
debug() { [[ "$DEBUG" == "1" ]] && echo -e "[DEBUG] $*" >&2; }
ok()   { echo -e "\033[0;32m[OK]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
fail() { echo -e "\033[0;31m[FAIL]\033[0m $*"; }

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAYOUTS_DIR="$SCRIPT_DIR/Layouts"
XKB_SYMBOLS_DIR="/usr/share/X11/xkb/symbols"
XKB_RULES_DIR="/usr/share/X11/xkb/rules"

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: Run with sudo!${NC}"
        exit 1
    fi
}

get_distribution() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$NAME $VERSION_ID"
    else
        echo "Linux"
    fi
}

detect_desktop() {
    if pgrep -x "cinnamon" > /dev/null; then
        echo "cinnamon"
    elif pgrep -x "gnome-shell" > /dev/null; then
        echo "gnome"
    else
        echo "unknown"
    fi
}

get_current_layout() {
    setxkbmap -query 2>/dev/null | grep layout | awk '{print $2}' || echo "us"
}

get_layout_value() {
    local file="$1"
    local key="$2"
    awk -F'=' -v key="$key" '
        $1 ~ key {
            sub(/^[^=]*=/, "");
            gsub(/"/, "");
            gsub(/\r/, "");
            gsub(/^[[:space:]]+/, "");
            gsub(/[[:space:]]+$/, "");
            print;
            exit;
        }' "$file"
}

get_layout_info() {
    local layout_file="$1"
    local display_name=$(get_layout_value "$layout_file" "INPUT_SOURCE_NAME")
    local short_name=$(get_layout_value "$layout_file" "SHORT_NAME")
    local lang=$(get_layout_value "$layout_file" "LANGUAGE_CODE")
    local country=$(get_layout_value "$layout_file" "COUNTRY_CODE")
    local include_val=$(get_layout_value "$layout_file" "INCLUDE")
    local flag=$(get_layout_value "$layout_file" "FLAG")
    
    # The XML <layout> is dictated by the COUNTRY (tn, ca, etc.)
    local parent_layout=$(echo "$country" | tr '[:upper:]' '[:lower:]')
    
    # The <variant> is dictated by the SHORT_NAME (arp, frs, etc.)
    local variant_name=$(echo "$short_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    [[ -z "$variant_name" ]] && variant_name="custom"
    
    # GSettings registers the layout+variant format (e.g. tn+arp, ca+frs)
    local gsettings_id="${parent_layout}+${variant_name}"
    
    # ISO639 mapping for XML standard
    local iso639_2="eng"
    [[ "$lang" == "ar" ]] && iso639_2="ara"
    [[ "$lang" == "fr" ]] && iso639_2="fra"
    
    # Default include fallback if empty
    [[ -z "$include_val" ]] && include_val="us"
    
    # Check if layout already exists
    local layout_exists=0
    grep -q "<name>$parent_layout</name>" "$XKB_RULES_DIR/evdev.xml" 2>/dev/null && layout_exists=1
    
    local SEP=$'\x1f'
    # Format: 1:Name 2:Parent(Country) 3:Variant 4:Short 5:Lang 6:ISO 7:Flag 8:Country 9:Include 10:GSettings 11:Exists
    echo "${display_name}${SEP}${parent_layout}${SEP}${variant_name}${SEP}${short_name}${SEP}${lang}${SEP}${iso639_2}${SEP}${flag}${SEP}${country}${SEP}${include_val}${SEP}${gsettings_id}${SEP}${layout_exists}"
}

is_variant_installed() {
    local parent_layout="$1"
    local variant_name="$2"
    local symbols_file="$XKB_SYMBOLS_DIR/$parent_layout"
    [[ -f "$symbols_file" ]] && grep -q "xkb_symbols \"$variant_name\"" "$symbols_file"
}

is_layout_installed() {
    local layout_id="$1"
    grep -q "<name>$layout_id</name>" "$XKB_RULES_DIR/evdev.xml" 2>/dev/null
}

extract_xkb_symbols() {
    local layout_file="$1"
    grep -E '^\s*key\s+<' "$layout_file" | head -n 200 | sed 's/^[[:space:]]*//'
}

get_input_schema() {
    if pgrep -x "cinnamon" > /dev/null; then
        echo "org.cinnamon.desktop.input-sources"
    else
        echo "org.gnome.desktop.input-sources"
    fi
}

minimal_refresh() {
    echo -e "${CYAN}Refreshing keyboard system...${NC}"
    rm -rf /var/lib/xkb/* 2>/dev/null || true
    udevadm trigger --subsystem-match=input --action=change 2>/dev/null || true
    echo -e "${GREEN}✓ Keyboard system refreshed${NC}"
}

get_current_input_sources() {
    local schema=$(get_input_schema)
    local user="${SUDO_USER:-$USER}"
    local uid=$(id -u "$user")
    local bus_path="/run/user/$uid/bus"
    if [[ -S "$bus_path" ]]; then
        sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
            XDG_RUNTIME_DIR="/run/user/$uid" \
            gsettings get "$schema" sources 2>/dev/null | tr -d ' '
    else
        echo "[]"
    fi
}

set_input_sources() {
    local sources="$1"
    local schema=$(get_input_schema)
    local user="${SUDO_USER:-$USER}"
    local uid=$(id -u "$user")
    local bus_path="/run/user/$uid/bus"
    if [[ -S "$bus_path" ]]; then
        sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
            XDG_RUNTIME_DIR="/run/user/$uid" \
            gsettings set "$schema" sources "$sources" 2>/dev/null
    fi
}

toggle_gsetting() {
    local schema="$1"
    local key="$2"
    local user="${SUDO_USER:-$USER}"
    local uid=$(id -u "$user")
    local bus_path="/run/user/$uid/bus"
    [[ ! -S "$bus_path" ]] && return
    local current=$(sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
        gsettings get "$schema" "$key" 2>/dev/null)
    if [[ "$current" == "true" ]]; then
        sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
            gsettings set "$schema" "$key" false
        echo -e "${GREEN}✓ Disabled $key${NC}"
    else
        sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
            gsettings set "$schema" "$key" true
        echo -e "${GREEN}✓ Enabled $key${NC}"
    fi
}

# ============================================================
# إعدادات تخطيط لوحة المفاتيح (Cinnamon)
# ============================================================
set_layout_options() {
    local schema="org.cinnamon.desktop.input-sources"
    local interface_schema="org.cinnamon.desktop.interface"
    local user="${SUDO_USER:-$USER}"
    local uid=$(id -u "$user")
    local bus_path="/run/user/$uid/bus"
    
    while true; do
        clear
        echo -e "${BLUE}┌────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│           Layout Options (Cinnamon)               │${NC}"
        echo -e "${BLUE}├────────────────────────────────────────────────────┤${NC}"
        
        if [[ -S "$bus_path" ]]; then
            # قراءة القيم الحالية من المسارات الصحيحة
            local per_window=$(sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
                gsettings get "$schema" per-window 2>/dev/null)
            local show_flags=$(sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
                gsettings get "$interface_schema" keyboard-layout-show-flags 2>/dev/null)
            local prefer_variant=$(sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
                gsettings get "$interface_schema" keyboard-layout-prefer-variant-names 2>/dev/null)
            local use_upper=$(sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
                gsettings get "$interface_schema" keyboard-layout-use-upper 2>/dev/null)
            
            # عرض الخيارات الأربعة مع القيم الحالية
            echo -e "  ${CYAN}1)${NC} Remember layout per window:        ${GREEN}${per_window:-false}${NC}"
            echo -e "  ${CYAN}2)${NC} Show country flag:                 ${GREEN}${show_flags:-false}${NC}"
            echo -e "  ${CYAN}3)${NC} Use layout name:                   ${GREEN}${prefer_variant:-false}${NC}"
            echo -e "  ${CYAN}4)${NC} Use upper-case for layout names:   ${GREEN}${use_upper:-false}${NC}"
            echo -e "  ${CYAN}5)${NC} Reset all to default"
            echo -e "  ${CYAN}0)${NC} Back to main menu"
        else
            echo -e "  ${RED}Cannot access DBus${NC}"
        fi
        
        echo -e "${BLUE}└────────────────────────────────────────────────────┘${NC}"
        read -p "$(echo -e "${CYAN}Choice: ${NC}")" opt
        
        case $opt in
            1)
                # تبديل Remember per window
                local new_value="false"
                [[ "$per_window" == "false" ]] && new_value="true"
                sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
                    gsettings set "$schema" per-window "$new_value" 2>/dev/null
                echo -e "${GREEN}✓ Per-window set to $new_value${NC}"
                ;;
            2)
                # تبديل Show country flag
                local new_value="false"
                [[ "$show_flags" == "false" ]] && new_value="true"
                sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
                    gsettings set "$interface_schema" keyboard-layout-show-flags "$new_value" 2>/dev/null
                echo -e "${GREEN}✓ Show flags set to $new_value${NC}"
                ;;
            3)
                # تبديل Use layout name (prefer variant names)
                local new_value="false"
                [[ "$prefer_variant" == "false" ]] && new_value="true"
                sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
                    gsettings set "$interface_schema" keyboard-layout-prefer-variant-names "$new_value" 2>/dev/null
                echo -e "${GREEN}✓ Use layout name set to $new_value${NC}"
                ;;
            4)
                # تبديل Use upper-case
                local new_value="false"
                [[ "$use_upper" == "false" ]] && new_value="true"
                sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
                    gsettings set "$interface_schema" keyboard-layout-use-upper "$new_value" 2>/dev/null
                echo -e "${GREEN}✓ Use upper-case set to $new_value${NC}"
                ;;
            5)
                # إعادة تعيين الكل
                sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
                    gsettings reset "$schema" per-window 2>/dev/null
                sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
                    gsettings reset "$interface_schema" keyboard-layout-show-flags 2>/dev/null
                sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
                    gsettings reset "$interface_schema" keyboard-layout-prefer-variant-names 2>/dev/null
                sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=$bus_path" \
                    gsettings reset "$interface_schema" keyboard-layout-use-upper 2>/dev/null
                echo -e "${GREEN}✓ Reset all options to default${NC}"
                ;;
            0) return 0 ;;
            *) echo -e "${RED}Invalid choice${NC}" ;;
        esac
        sleep 1
    done
}
