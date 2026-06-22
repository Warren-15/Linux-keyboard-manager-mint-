#!/bin/bash
# refresh.sh - Full desktop refresh

source "$(dirname "${BASH_SOURCE[0]}")/lib_common.sh"

full_refresh() {
    echo -e "\n${CYAN}Full desktop refresh...${NC}"
    
    rm -rf /var/lib/xkb/* 2>/dev/null || true
    udevadm trigger --subsystem-match=input --action=change 2>/dev/null || true
    
    local current_layout=$(get_current_layout)
    setxkbmap -layout "$current_layout" 2>/dev/null || setxkbmap us
    
    if pgrep -x "cinnamon" > /dev/null; then
        echo -e "${YELLOW}Restarting Cinnamon...${NC}"
        if command -v gdbus &>/dev/null; then
            gdbus call --session --dest org.Cinnamon /org/Cinnamon org.Cinnamon.Eval string 'global.reexec_self()' 2>/dev/null
        fi
    elif pgrep -x "gnome-shell" > /dev/null; then
        echo -e "${YELLOW}Restarting GNOME Shell...${NC}"
        if command -v gdbus &>/dev/null; then
            gdbus call --session --dest org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval string 'Meta.restart("Restarting…")' 2>/dev/null
        fi
    fi
    
    echo -e "${GREEN}✓ Full refresh complete${NC}"
    read -n1 -p "Press any key to return to menu..."
}