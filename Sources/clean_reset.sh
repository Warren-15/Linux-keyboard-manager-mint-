#!/bin/bash
# clean_reset.sh - Clean all custom layouts and emergency reset

source "$(dirname "${BASH_SOURCE[0]}")/lib_common.sh"

clean_all_layouts() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Cleaning ALL custom layouts${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Restore XML and LST from backups
    for XML in "$XKB_RULES_DIR"/evdev.xml "$XKB_RULES_DIR"/base.xml; do
        if [[ -f "${XML}.custom_backup" ]]; then
            sudo cp "${XML}.custom_backup" "$XML"
            echo -e "${GREEN}  ✓ Restored $(basename "$XML")${NC}"
        fi
    done
    for LST in "$XKB_RULES_DIR"/evdev.lst "$XKB_RULES_DIR"/base.lst; do
        if [[ -f "${LST}.custom_backup" ]]; then
            sudo cp "${LST}.custom_backup" "$LST"
            echo -e "${GREEN}  ✓ Restored $(basename "$LST")${NC}"
        fi
    done
    
    # Remove custom variants from parent symbol files
    for parent in ca fr ara ar us; do
        local symbols_file="$XKB_SYMBOLS_DIR/$parent"
        if [[ -f "$symbols_file" ]]; then
            sudo sed -i '/\/\/ CUSTOM_VARIANT_START/,/\/\/ CUSTOM_VARIANT_END/d' "$symbols_file"
            echo -e "${GREEN}  ✓ Cleaned $parent symbols${NC}"
        fi
    done
    
    # Remove standalone custom layouts (tn, dz, etc.)
    for file in "$LAYOUTS_DIR"/*.layout; do
        [[ -f "$file" ]] || continue
        IFS='|' read -r _ parent _ _ _ _ _ country _ _ _ is_new <<< "$(get_layout_info "$file")"
        if [[ "$is_new" == "1" ]]; then
            sudo rm -f "$XKB_SYMBOLS_DIR/$parent"
            echo -e "${GREEN}  ✓ Removed standalone $parent${NC}"
        fi
    done
    
    # Also remove any legacy _custom files
    sudo rm -f "$XKB_SYMBOLS_DIR"/*_custom 2>/dev/null
    
    echo -e "\n${YELLOW}Choose default keyboard layout:${NC}"
    echo "  1) us (English)"
    echo "  2) fr (French)"
    echo "  3) ca (Canadian)"
    echo "  4) ara (Arabic)"
    read -p "Choice (1-4): " default_choice
    case $default_choice in
        1) DEFAULT="us" ;;
        2) DEFAULT="fr" ;;
        3) DEFAULT="ca" ;;
        4) DEFAULT="ara" ;;
        *) DEFAULT="us" ;;
    esac
    
    set_input_sources "[('xkb', '$DEFAULT')]"
    echo -e "${GREEN}  ✓ Reset to $DEFAULT${NC}"
    
    rm -rf /var/lib/xkb/* 2>/dev/null || true
    setxkbmap "$DEFAULT" 2>/dev/null || true
    
    echo -e "\n${GREEN}✅ Clean complete! Default: $DEFAULT${NC}"
    echo -e "${YELLOW}⚠️  Logout/login required for full effect${NC}"
    read -n1 -p "Press any key..."
}

emergency_cleanup() {
    echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}            EMERGENCY KEYBOARD RESET              ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "\n${YELLOW}This will completely reset your keyboard to factory defaults.${NC}"
    echo -e "${RED}All custom layouts will be removed.${NC}"
    echo -e "\n${CYAN}Are you sure? (y/N)${NC}"
    read -p "> " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted.${NC}"
        read -n1 -p "Press any key..."
        return 0
    fi
    
    echo -e "\n${YELLOW}Step 1: Reinstalling xkb-data...${NC}"
    if command -v apt-get &>/dev/null; then
        apt-get update && apt-get install --reinstall -y xkb-data x11-xkb-utils
    elif command -v dnf &>/dev/null; then
        dnf reinstall -y xkeyboard-config xorg-x11-xkb-utils
    elif command -v pacman &>/dev/null; then
        pacman -S --noconfirm xkeyboard-config xorg-xkb-utils
    else
        echo -e "${RED}Could not reinstall xkb-data. Please do it manually.${NC}"
    fi
    
    echo -e "\n${YELLOW}Step 2: Clearing all XKB caches...${NC}"
    sudo rm -rf /var/lib/xkb/* 2>/dev/null || true
    rm -rf ~/.cache/xkb/* 2>/dev/null || true
    
    echo -e "\n${YELLOW}Step 3: Restoring original XML and LST files (if backups exist)...${NC}"
    for XML in "$XKB_RULES_DIR"/evdev.xml "$XKB_RULES_DIR"/base.xml; do
        if [[ -f "${XML}.custom_backup" ]]; then
            sudo cp "${XML}.custom_backup" "$XML"
            echo -e "${GREEN}  Restored $(basename "$XML")${NC}"
        fi
    done
    for LST in "$XKB_RULES_DIR"/evdev.lst "$XKB_RULES_DIR"/base.lst; do
        if [[ -f "${LST}.custom_backup" ]]; then
            sudo cp "${LST}.custom_backup" "$LST"
            echo -e "${GREEN}  Restored $(basename "$LST")${NC}"
        fi
    done
    
    echo -e "\n${YELLOW}Step 4: Removing custom symbols files and variants...${NC}"
    for parent in ca fr ara ar us; do
        local symbols_file="$XKB_SYMBOLS_DIR/$parent"
        if [[ -f "$symbols_file" ]]; then
            sudo sed -i '/\/\/ CUSTOM_VARIANT_START/,/\/\/ CUSTOM_VARIANT_END/d' "$symbols_file"
            echo -e "${GREEN}  Cleaned $parent symbols${NC}"
        fi
    done
    sudo rm -f "$XKB_SYMBOLS_DIR"/*_custom 2>/dev/null
    for file in "$LAYOUTS_DIR"/*.layout; do
        [[ -f "$file" ]] || continue
        IFS='|' read -r _ parent _ _ _ _ _ country _ _ _ is_new <<< "$(get_layout_info "$file")"
        if [[ "$is_new" == "1" ]]; then
            sudo rm -f "$XKB_SYMBOLS_DIR/$parent"
            echo -e "${GREEN}  Removed standalone $parent${NC}"
        fi
    done
    
    echo -e "\n${YELLOW}Step 5: Choose your default layout after reset:${NC}"
    echo "  1) English (us)"
    echo "  2) French (fr)"
    echo "  3) Canadian (ca)"
    echo "  4) Arabic (ara)"
    read -p "$(echo -e "${CYAN}Choice (1-4): ${NC}")" default_choice
    case $default_choice in
        1) DEFAULT="us" ;;
        2) DEFAULT="fr" ;;
        3) DEFAULT="ca" ;;
        4) DEFAULT="ara" ;;
        *) DEFAULT="us" ;;
    esac
    
    echo -e "\n${YELLOW}Step 6: Applying default layout ($DEFAULT)...${NC}"
    set_input_sources "[('xkb', '$DEFAULT')]"
    setxkbmap "$DEFAULT"
    sudo udevadm trigger --subsystem-match=input --action=change
    
    echo -e "\n${GREEN}✅ Emergency reset complete! Default layout: $DEFAULT${NC}"
    echo -e "${YELLOW}⚠️  It is recommended to reboot now for complete freshness.${NC}"
    read -n1 -p "Press any key to return to main menu..."
}

reinstall_xkb() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Reinstalling xkb-data (Factory Reset)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "\n${RED}⚠️  This will COMPLETELY reset all XKB settings!${NC}"
    read -p "Are you sure? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        return 0
    fi
    
    if command -v apt-get &>/dev/null; then
        apt-get update && apt-get install --reinstall -y xkb-data x11-xkb-utils
    elif command -v dnf &>/dev/null; then
        dnf reinstall -y xkeyboard-config xorg-x11-xkb-utils
    elif command -v pacman &>/dev/null; then
        pacman -S --noconfirm xkeyboard-config xorg-xkb-utils
    fi
    
    clean_all_layouts
    echo -e "\n${GREEN}✅ Factory reset complete. REBOOT REQUIRED.${NC}"
    read -n1 -p "Press any key..."
}