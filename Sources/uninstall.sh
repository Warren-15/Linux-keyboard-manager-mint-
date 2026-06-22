#!/bin/bash
# uninstall.sh - Safely strip custom configurations from parent layout scopes

source "$(dirname "${BASH_SOURCE[0]}")/lib_common.sh"

remove_variant() {
    local parent_layout="$1"
    local variant_name="$2"
    local display_name="$3"
    
    debug "Removing variant: $display_name ($parent_layout+$variant_name)"
    
    local symbols_file="$XKB_SYMBOLS_DIR/$parent_layout"
    if [[ -f "$symbols_file" ]]; then
        sudo sed -i "/^\/\/ CUSTOM_VARIANT_START $variant_name$/,/^\/\/ CUSTOM_VARIANT_END $variant_name$/d" "$symbols_file"
        echo -e "${GREEN}  ✓ Removed variant from $parent_layout symbols${NC}"
    fi
    
    for XML in "$XKB_RULES_DIR"/evdev.xml "$XKB_RULES_DIR"/base.xml; do
        if [[ -f "$XML" ]]; then
            sudo awk -v parent="$parent_layout" -v target="$variant_name" '
              /<layout>/ { in_layout=1; in_target=0; in_config=0; in_variant=0 }
              in_layout && /<configItem>/ { in_config=1 }
              in_layout && /<\/configItem>/ { in_config=0 }
              in_config && /<name>/ { if ($0 ~ "<name>" parent "</name>") in_target=1 }
              in_target && /<variant>/ { in_variant=1; var_buf=$0 "\n"; found_var=0; next }
              in_variant {
                  var_buf = var_buf $0 "\n"
                  if ($0 ~ "<name>" target "</name>") found_var=1
                  if (/<\/variant>/) {
                      if (!found_var) printf "%s", var_buf
                      in_variant=0; var_buf=""
                  }
                  next
              }
              /<\/layout>/ { in_layout=0; in_target=0 }
              { print }
            ' "$XML" > /tmp/xml_tmp && sudo mv /tmp/xml_tmp "$XML"
            echo -e "${GREEN}  ✓ Removed variant from $(basename "$XML")${NC}"
        fi
    done
    
    for LST in "$XKB_RULES_DIR"/evdev.lst "$XKB_RULES_DIR"/base.lst; do
        if [[ -f "$LST" ]]; then
            sudo sed -i "/^[[:space:]]*$parent_layout:$variant_name[[:space:]]\+/d" "$LST"
            echo -e "${GREEN}  ✓ Removed from $(basename "$LST")${NC}"
        fi
    done
    
    # Manage input sources desktop state strings
    local current_sources=$(get_current_input_sources)
    local source_id="${parent_layout}+${variant_name}"
    local new_sources=$(echo "$current_sources" | sed "s/, ('xkb', '$source_id')//g; s/('xkb', '$source_id'), //g; s/('xkb', '$source_id')//g")
    new_sources=$(echo "$new_sources" | sed 's/\[, /\[/g; s/, \]/\]/g')
    if [[ "$new_sources" != "$current_sources" ]]; then
        set_input_sources "$new_sources"
        echo -e "${GREEN}  ✓ Removed from input sources${NC}"
    fi
}

remove_standalone_layout() {
    local layout_id="$1"
    local display_name="$2"
    
    debug "Removing standalone layout: $display_name ($layout_id)"
    
    sudo rm -f "$XKB_SYMBOLS_DIR/$layout_id"
    echo -e "${GREEN}  ✓ Removed symbols file${NC}"
    
    for XML in "$XKB_RULES_DIR"/evdev.xml "$XKB_RULES_DIR"/base.xml; do
        if [[ -f "$XML" ]]; then
            sudo awk -v target="$layout_id" '
              /<layout>/ { in_layout=1; in_config=0; layout_buf=$0 "\n"; found_layout=0; next }
              in_layout {
                  layout_buf = layout_buf $0 "\n"
                  if (/<configItem>/) in_config=1
                  if (/<\/configItem>/) in_config=0
                  if (in_config && $0 ~ "<name>" target "</name>") found_layout=1
                  if (/<\/layout>/) {
                      if (!found_layout) printf "%s", layout_buf
                      in_layout=0; layout_buf=""
                  }
                  next
              }
              { print }
            ' "$XML" > /tmp/xml_tmp && sudo mv /tmp/xml_tmp "$XML"
            echo -e "${GREEN}  ✓ Removed layout from $(basename "$XML")${NC}"
        fi
    done
    
    for LST in "$XKB_RULES_DIR"/evdev.lst "$XKB_RULES_DIR"/base.lst; do
        if [[ -f "$LST" ]]; then
            sudo sed -i "/^[[:space:]]*$layout_id[[:space:]]\+/d" "$LST"
            echo -e "${GREEN}  ✓ Removed from $(basename "$LST")${NC}"
        fi
    done
    
    local current_sources=$(get_current_input_sources)
    local new_sources=$(echo "$current_sources" | sed "s/, ('xkb', '$layout_id')//g; s/('xkb', '$layout_id'), //g; s/('xkb', '$layout_id')//g")
    new_sources=$(echo "$new_sources" | sed 's/\[, /\[/g; s/, \]/\]/g')
    if [[ "$new_sources" != "$current_sources" ]]; then
        set_input_sources "$new_sources"
        echo -e "${GREEN}  ✓ Removed from input sources${NC}"
    fi
}

# (Keep remove_layouts_menu() structure as provided originally)

remove_layouts_menu() {
    local SEP=$'\x1f'
    local parents=() variants=() layout_ids=() display_names=() is_standalone=()
    
    for file in "$LAYOUTS_DIR"/*.layout; do
        [[ -f "$file" ]] || continue
        IFS="$SEP" read -r name parent variant _ _ _ _ _ _ _ _ is_new <<< "$(get_layout_info "$file")"
        if [[ "$is_new" == "1" ]]; then
            if is_layout_installed "$parent"; then
                layout_ids+=("$parent")
                display_names+=("$name")
                is_standalone+=("1")
                debug "Found installed standalone: $name -> $parent"
            fi
        else
            if is_variant_installed "$parent" "$variant"; then
                parents+=("$parent")
                variants+=("$variant")
                display_names+=("$name")
                is_standalone+=("0")
                debug "Found installed variant: $name -> $parent+$variant"
            fi
        fi
    done
    
    if [[ ${#display_names[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No custom layouts installed.${NC}"
        read -n1
        return 0
    fi
    
    local selected=()
    while true; do
        clear
        echo -e "${BLUE}┌────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│              Remove Layouts                        │${NC}"
        echo -e "${BLUE}├────────────────────────────────────────────────────┤${NC}"
        for i in "${!display_names[@]}"; do
            local marker="[ ]"
            local name="${display_names[$i]}"
            if [[ " ${selected[@]} " =~ " $i " ]]; then
                marker="${RED}[×]${NC}"
                name="${RED}${display_names[$i]}${NC}"
            fi
            local id=""
            if [[ "${is_standalone[$i]}" == "1" ]]; then
                id="${layout_ids[$i]}"
            else
                id="${parents[$i]}+${variants[$i]}"
            fi
            echo -e "  ${CYAN}$((i+1)))${NC} $marker $name ($id)"
        done
        echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Commands: numbers (toggle), 0 (all), c/. (clear), Enter (confirm), q (cancel)${NC}"
        read -p "$(echo -e "${CYAN}Your choice: ${NC}")" input
        
        if [[ "$input" == "c" ]] || [[ "$input" == "." ]]; then
            selected=(); echo -e "${YELLOW}Cleared selections${NC}"; sleep 1; continue
        fi
        if [[ "$input" == "0" ]]; then
            selected=(); for i in "${!display_names[@]}"; do selected+=("$i"); done
            echo -e "${RED}Selected all for removal${NC}"; sleep 1; continue
        fi
        if [[ "$input" == "q" ]]; then
            echo -e "${YELLOW}Cancelled${NC}"; sleep 1; return 0
        fi
        if [[ -z "$input" ]]; then
            if [[ ${#selected[@]} -eq 0 ]]; then
                echo -e "${YELLOW}No layouts selected. Returning to main menu.${NC}"
                sleep 1; return 0
            else
                break
            fi
        fi
        IFS=' ' read -ra nums <<< "$input"
        for num in "${nums[@]}"; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#display_names[@]} ]]; then
                local idx=$((num-1))
                if [[ " ${selected[@]} " =~ " $idx " ]]; then
                    local new_sel=()
                    for s in "${selected[@]}"; do [[ $s -ne $idx ]] && new_sel+=("$s"); done
                    selected=("${new_sel[@]}")
                    echo -e "${YELLOW}Deselected: ${display_names[$idx]}${NC}"
                else
                    selected+=("$idx")
                    echo -e "${RED}Marked: ${display_names[$idx]}${NC}"
                fi
            fi
        done
        sleep 1
    done
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}Removing ${#selected[@]} layout(s)...${NC}"
    
    for idx in "${selected[@]}"; do
        if [[ "${is_standalone[$idx]}" == "1" ]]; then
            remove_standalone_layout "${layout_ids[$idx]}" "${display_names[$idx]}"
        else
            remove_variant "${parents[$idx]}" "${variants[$idx]}" "${display_names[$idx]}"
        fi
        echo ""
    done
    
    minimal_refresh
    echo -e "\n${GREEN}✅ Removal complete!${NC}"
    read -n1 -p "Press any key to return to main menu..."
    return 0
}