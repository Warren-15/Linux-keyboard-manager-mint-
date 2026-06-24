#!/bin/bash
# install.sh - ينشئ تخطيطات البلد ويضيف المتغيرات داخلها

source "$(dirname "${BASH_SOURCE[0]}")/lib_common.sh"

# ============================================================
# إنشاء تخطيط بلد جديد - يضاف بعد التخطيط العام (generic layout) الخاص باللغة
# ============================================================
create_country_layout() {
    local layout_id="$1"          # tn
    local short_desc="$2"         # tun
    local full_name="$3"          # Tunisian
    local iso639="$4"             # ara, fra, eng
    local iso3166="$5"            # TN
    local lang="$6"               # ar, fr, en
    
    if is_layout_installed "$layout_id"; then
        debug "Layout $layout_id already exists"
        return 0
    fi
    
    echo -e "${CYAN}  Creating country layout: $layout_id ($full_name)${NC}"
    
    # 1. إنشاء ملف الرموز (فارغ، بدون basic لتجنب التعارض مع المتغيرات)
    local symbols_file="$XKB_SYMBOLS_DIR/$layout_id"
    if [[ ! -f "$symbols_file" ]]; then
        sudo tee "$symbols_file" > /dev/null <<EOF
// $full_name ($layout_id) - Custom layout
// Variants will be added by the installer
EOF
        sudo chmod 644 "$symbols_file"
        echo -e "${GREEN}    ✓ Created symbols file${NC}"
    else
        echo -e "${GREEN}    ✓ Symbols file already exists${NC}"
    fi
    
    # 2. تحضير كتلة XML مع countryList و languageList
    local country_list="        <countryList>\n          <iso3166Id>$iso3166</iso3166Id>\n        </countryList>"
    local language_list="        <languageList>\n          <iso639Id>$iso639</iso639Id>\n        </languageList>"
    
    local layout_block="    <layout>
      <configItem>
        <name>$layout_id</name>
        <shortDescription>$short_desc</shortDescription>
        <description>$full_name</description>
$country_list
$language_list
      </configItem>
      <variantList/>
    </layout>"
    
    # تحديد التخطيط العام (generic layout) بناءً على اللغة
    local generic_layout=""
    case "$lang" in
        "ar") generic_layout="ara" ;;
        "fr") generic_layout="fr"  ;;
        "en") generic_layout="us"  ;;
        *)    generic_layout="us"  ;;
    esac
    
    for XML in "$XKB_RULES_DIR"/evdev.xml "$XKB_RULES_DIR"/base.xml; do
        if [[ -f "$XML" ]] && ! grep -q "<name>$layout_id</name>" "$XML"; then
            echo -e "${YELLOW}  Checking insertion point in $(realpath "$XML")...${NC}"
            
            # البحث عن رقم السطر الذي يحتوي على </layout> للتخطيط العام
            local target_line=$(sudo awk -v gen="$generic_layout" '
            BEGIN { in_gen=0; found=0; line=0 }
            /<layout>/ { in_layout=1 }
            /<name>'"$generic_layout"'<\/name>/ && in_layout {
                in_gen=1
            }
            /<\/layout>/ && in_layout && in_gen && !found {
                line = NR
                found=1
            }
            /<\/layout>/ { in_layout=0; in_gen=0 }
            END { print line }
            ' "$XML")
            
            if [[ -n "$target_line" && "$target_line" != "0" ]]; then
                echo -e "${GREEN}    Will insert after generic layout '$generic_layout' at line $target_line${NC}"
                sudo awk -v line="$target_line" 'NR==line || NR==line+1 { print "    " $0 }' "$XML"
            else
                # Fallback: البحث عن أول تخطيط بلد بنفس اللغة
                target_line=$(sudo awk -v lang="$iso639" '
                BEGIN { first_country_line=0; in_layout=0; has_country=0; current_lang="" }
                {
                    if ($0 ~ /<layout>/) { in_layout=1; has_country=0; current_lang="" }
                    else if (in_layout && $0 ~ /<countryList>/) has_country=1
                    else if (in_layout && $0 ~ /<iso639Id>/) {
                        match($0, /<iso639Id>([^<]+)<\/iso639Id>/, arr)
                        if (arr[1]) current_lang = arr[1]
                    }
                    else if (in_layout && $0 ~ /<\/layout>/ && has_country && current_lang == lang && first_country_line==0) {
                        first_country_line = NR
                        in_layout=0
                    }
                    else if (in_layout && $0 ~ /<\/layout>/) { in_layout=0 }
                }
                END { print first_country_line }
                ' "$XML")
                if [[ -n "$target_line" && "$target_line" != "0" ]]; then
                    local insert_before=$((target_line - 1))
                    echo -e "${YELLOW}    Generic layout '$generic_layout' not found. Will insert before first country layout of language $iso639${NC}"
                    target_line=$insert_before
                else
                    target_line=$(sudo awk '
                    BEGIN { last=0; in_layout=0; has_country=0 }
                    {
                        if ($0 ~ /<layout>/) { in_layout=1; has_country=0 }
                        else if (in_layout && $0 ~ /<countryList>/) has_country=1
                        else if (in_layout && $0 ~ /<\/layout>/ && has_country) last=NR
                        else if (in_layout && $0 ~ /<\/layout>/) in_layout=0
                    }
                    END { print last }
                    ' "$XML")
                    echo -e "${YELLOW}    No layout with language $iso639 found. Will insert after last country layout${NC}"
                fi
            fi
            
            # الحقن بعد السطر المحدد
            sudo awk -v line="$target_line" -v block="$(echo -e "$layout_block")" '
            {
                print $0
                if (NR == line) {
                    print block
                }
            }
            ' "$XML" > /tmp/xml_tmp && sudo mv /tmp/xml_tmp "$XML"
            
            echo -e "${GREEN}    ✓ Added layout to $(basename "$XML")${NC}"
        fi
    done
    
    # 3. إضافة إلى .lst
    for LST in "$XKB_RULES_DIR"/evdev.lst "$XKB_RULES_DIR"/base.lst; do
        if [[ -f "$LST" ]]; then
            if ! grep -q "^  $layout_id[[:space:]]" "$LST"; then
                sudo sed -i "/^! layout$/a\  $layout_id\t\t$full_name" "$LST"
                echo -e "${GREEN}    ✓ Added to $(basename "$LST")${NC}"
            fi
        fi
    done
    
    echo -e "${GREEN}  ✓ Layout $layout_id created${NC}"
    return 0
}
# ============================================================
# إضافة متغير إلى تخطيط بلد
# ============================================================
add_variant_to_layout() {
    local parent_layout="$1"
    local variant_name="$2"
    local display_name="$3"
    local short_name="$4"
    local iso639_2="$5"
    local include_val="$6"      # سيتم تجاهله الآن
    local xkb_content="$7"
    
    echo -e "${YELLOW}  Adding variant '$variant_name' to layout '$parent_layout'...${NC}"
    
    # 1. تحديث ملف الرموز
    local symbols_file="$XKB_SYMBOLS_DIR/$parent_layout"
    if [[ ! -f "$symbols_file" ]]; then
        sudo touch "$symbols_file"
        sudo chmod 644 "$symbols_file"
        echo "// Basic layout for $parent_layout" | sudo tee "$symbols_file" > /dev/null
    fi
    
    # إزالة أي كتلة سابقة بالكامل (من START إلى END)
    sudo sed -i "/\/\/ CUSTOM_VARIANT_START $variant_name$/,/\/\/ CUSTOM_VARIANT_END $variant_name$/d" "$symbols_file"
    
    # كتابة الكتلة الجديدة بالكامل
    {
        echo ""
        echo "// CUSTOM_VARIANT_START $variant_name"
        echo "partial alphanumeric_keys"
        echo "xkb_symbols \"$variant_name\" {"
        echo "    name[Group1] = \"$display_name\";"
        printf '%s\n' "$xkb_content"
        echo "    include \"level3(ralt_switch)\""
        echo "};"
        echo "// CUSTOM_VARIANT_END $variant_name"
    } | sudo tee -a "$symbols_file" > /dev/null
    
    echo -e "${GREEN}    ✓ Injected variant into symbols file (overwrote existing block)${NC}"
    
    # 2. تحديث XML (بدون تغيير)
    local variant_entry="        <variant>
          <configItem>
            <name>$variant_name</name>
            <shortDescription>$short_name</shortDescription>
            <description>$display_name</description>
            <languageList><iso639Id>$iso639_2</iso639Id></languageList>
          </configItem>
        </variant>"
    
    for XML in "$XKB_RULES_DIR"/evdev.xml "$XKB_RULES_DIR"/base.xml; do
        if [[ -f "$XML" ]]; then
            # إزالة إدخال سابق للمتغير في XML
            sudo awk -v target="$variant_name" '
              /<variant>/ { buf = $0 "\n"; in_v = 1; found = 0; next }
              in_v {
                  buf = buf $0 "\n"
                  if ($0 ~ "<name>" target "</name>") found = 1
                  if (/<\/variant>/) { if (!found) printf "%s", buf; in_v=0; buf=""; found=0; next }
                  next
              }
              { print }
            ' "$XML" > /tmp/xml_tmp && sudo mv /tmp/xml_tmp "$XML"
            
            # تأكد من وجود variantList
            sudo sed -i 's|<variantList/>|<variantList>\n        </variantList>|g' "$XML"
            
            # إضافة المتغير الجديد قبل </variantList>
            sudo awk -v parent="$parent_layout" -v entry="$variant_entry" '
            BEGIN { in_layout=0; in_target=0; inserted=0 }
            /<layout>/ { in_layout=1; in_target=0 }
            in_layout && /<name>/ && !in_target {
                if ($0 ~ "<name>" parent "</name>") in_target=1
            }
            in_target && /<\/variantList>/ && !inserted {
                print entry
                print $0
                inserted=1; in_target=0; next
            }
            /<\/layout>/ { in_layout=0; in_target=0 }
            { print $0 }
            ' "$XML" > /tmp/xml_tmp && sudo mv /tmp/xml_tmp "$XML"
        fi
    done
    
    # 3. تحديث .lst
    for LST in "$XKB_RULES_DIR"/evdev.lst "$XKB_RULES_DIR"/base.lst; do
        if [[ -f "$LST" ]]; then
            # إزالة أي إدخال سابق
            sudo sed -i "/^[[:space:]]*$parent_layout:$variant_name[[:space:]]\+/d" "$LST"
            # إضافة الإدخال الجديد
            sudo sed -i "/^! variant$/a\  $parent_layout:$variant_name\t$display_name" "$LST"
            echo -e "${GREEN}    ✓ Updated $(basename "$LST")${NC}"
        fi
    done
    
    echo -e "${GREEN}  ✓ Variant '$variant_name' added to layout '$parent_layout'${NC}"
    return 0
}
# ============================================================
# دالة التثبيت الرئيسية
# ============================================================
install_layout() {
    local layout_file="$1"
    local display_name="$2"
    local parent_layout="$3"      # tn, ca
    local variant_name="$4"
    local short_name="$5"
    local lang="$6"
    local iso639_2="$7"
    local flag="$8"
    local country="${9}"
    local include_val="${10}"
    local gsettings_id="${11}"
    local layout_exists="${12}"
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Installing: $display_name${NC}"
    echo -e "${CYAN}  Layout Hierarchy: $lang -> $parent_layout -> $variant_name${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # استخراج الرموز
    echo -e "${YELLOW}[1/3] Extracting key symbols...${NC}"
    local xkb_content=$(extract_xkb_symbols "$layout_file")
    if [[ -z "$xkb_content" ]]; then
        echo -e "${RED}  ✗ No key definitions found${NC}"
        return 1
    fi
    local key_count=$(echo "$xkb_content" | grep -c "key" 2>/dev/null || echo "0")
    echo -e "${GREEN}  ✓ Extracted $key_count key definitions${NC}"
    
    # إنشاء تخطيط البلد إذا لم يكن موجوداً
    echo -e "${YELLOW}[2/3] Ensuring country layout '$parent_layout' exists...${NC}"
    if [[ "$layout_exists" == "0" ]]; then
        local short_desc=$(echo "$parent_layout" | tr '[:upper:]' '[:lower:]')
        local full_name=""
        case "${country^^}" in
            "TN") full_name="Tunisian" ;;
            "CA") full_name="Canadian" ;;
            "DZ") full_name="Algerian" ;;
            "EG") full_name="Egyptian" ;;
            *) full_name="${country^^}" ;;
        esac
        create_country_layout "$parent_layout" "$short_desc" "$full_name" "$iso639_2" "${country^^}" "$lang"
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}  ✗ Failed to create country layout${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}  ✓ Country layout '$parent_layout' already exists${NC}"
    fi
    
    # إضافة المتغير
    echo -e "${YELLOW}[3/3] Adding variant to layout...${NC}"
    add_variant_to_layout "$parent_layout" "$variant_name" "$display_name" "$short_name" "$iso639_2" "$include_val" "$xkb_content"
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    if is_variant_installed "$parent_layout" "$variant_name"; then
        echo -e "${GREEN}✅ Installation successful!${NC}"
        echo -e "${YELLOW}  System ID: $gsettings_id${NC}"
        return 0
    else
        echo -e "${RED}❌ Installation failed${NC}"
        return 1
    fi
}

# ============================================================
# قائمة اختيار التخطيطات
# ============================================================
install_layouts_menu() {
    debug "Starting install menu"
    
    local SEP=$'\x1f'
    local files=() names=() parents=() variants=() short_names=() langs=() iso639=() flags=() countries=() includes=() gsettings_ids=() layout_exists=()
    
    for file in "$LAYOUTS_DIR"/*.layout; do
        [[ -f "$file" ]] || continue
        local _name _parent _variant _sname _lang _iso639 _flag _country _include _gsettings_id _exists
        IFS="$SEP" read -r \
            _name _parent _variant _sname _lang _iso639 _flag _country _include _gsettings_id _exists \
            <<< "$(get_layout_info "$file")"
        files+=("$file"); names+=("$_name"); parents+=("$_parent"); variants+=("$_variant")
        short_names+=("$_sname"); langs+=("$_lang"); iso639+=("$_iso639")
        flags+=("$_flag"); countries+=("$_country"); includes+=("$_include"); gsettings_ids+=("$_gsettings_id"); layout_exists+=("$_exists")
        debug "Loaded: $_name -> country=$_parent variant=$_variant exists=$_exists"
    done
    
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}No .layout files found in $LAYOUTS_DIR${NC}"
        read -n1
        return 0
    fi
    
    local selected=()
    while true; do
        clear
        echo -e "${BLUE}┌────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│                    Select Layouts to Install                      │${NC}"
        echo -e "${BLUE}├────────────────────────────────────────────────────────────────────┤${NC}"
        for i in "${!names[@]}"; do
            local status=""
            if is_variant_installed "${parents[$i]}" "${variants[$i]}"; then
                status="${GREEN}[installed]${NC}"
            else
                status="${YELLOW}[new]${NC}"
            fi
            local marker="[ ]"
            if [[ " ${selected[@]} " =~ " $i " ]]; then
                marker="${GREEN}[✓]${NC}"
            fi
            # استخدام echo -e بدلاً من printf لتفسير الألوان بشكل صحيح
            echo -e "  ${CYAN}$((i+1))${NC}) ${marker} ${names[$i]} (${langs[$i]} -> ${parents[$i]} -> ${variants[$i]}) $status"
        done
        echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Commands: numbers (toggle), 0 (all), c (clear), Enter (confirm), q (cancel)${NC}"
        read -p "$(echo -e "${CYAN}Your choice: ${NC}")" input
        
        case "$input" in
            c|C|\.) selected=(); echo -e "${YELLOW}Cleared${NC}"; sleep 1; continue ;;
            0) selected=(); for i in "${!names[@]}"; do selected+=("$i"); done; echo -e "${GREEN}All selected${NC}"; sleep 1; continue ;;
            q|Q) echo -e "${YELLOW}Cancelled${NC}"; sleep 1; return 0 ;;
            "")
                if [[ ${#selected[@]} -eq 0 ]]; then
                    echo -e "${YELLOW}No layouts selected${NC}"
                    sleep 1
                    continue
                else
                    break
                fi
                ;;
            *)
                IFS=' ' read -ra nums <<< "$input"
                for num in "${nums[@]}"; do
                    if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#names[@]} ]]; then
                        local idx=$((num-1))
                        if [[ " ${selected[@]} " =~ " $idx " ]]; then
                            local new_sel=()
                            for s in "${selected[@]}"; do [[ $s -ne $idx ]] && new_sel+=("$s"); done
                            selected=("${new_sel[@]}")
                            echo -e "${YELLOW}Deselected: ${names[$idx]}${NC}"
                        else
                            selected+=("$idx")
                            echo -e "${GREEN}Selected: ${names[$idx]}${NC}"
                        fi
                    else
                        echo -e "${RED}Invalid: $num${NC}"
                    fi
                done
                sleep 1
                ;;
        esac
    done
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installing ${#selected[@]} layout(s)...${NC}"
    
    local successful_ids=()
    for idx in "${selected[@]}"; do
        if install_layout "${files[$idx]}" "${names[$idx]}" "${parents[$idx]}" "${variants[$idx]}" \
            "${short_names[$idx]}" "${langs[$idx]}" "${iso639[$idx]}" \
            "${flags[$idx]}" "${countries[$idx]}" "${includes[$idx]}" "${gsettings_ids[$idx]}" \
            "${layout_exists[$idx]}"; then
            successful_ids+=("${gsettings_ids[$idx]}")
        else
            warn "Failed to install ${names[$idx]}"
        fi
        echo ""
    done
    
    if [[ ${#successful_ids[@]} -eq 0 ]]; then
        echo -e "${RED}No layouts installed successfully${NC}"
        read -n1
        return 1
    fi
    
    # تحديث GSettings
    local current_sources=$(get_current_input_sources)
    echo -e "\n${CYAN}Current input sources: $current_sources${NC}"
    echo -e "\n${YELLOW}Add to input sources?${NC}"
    echo -e "  ${CYAN}1)${NC} Keep current + add new"
    echo -e "  ${CYAN}2)${NC} Replace all with new"
    echo -e "  ${CYAN}3)${NC} Skip"
    read -p "$(echo -e "${CYAN}Choice (1-3): ${NC}")" src_mode
    
    case $src_mode in
        1)
            local new_sources="$current_sources"
            for gsid in "${successful_ids[@]}"; do
                if ! echo "$new_sources" | grep -Fq "'$gsid'"; then
                    if [[ "$new_sources" == "[]" || -z "$new_sources" ]]; then
                        new_sources="[('xkb', '$gsid')]"
                    else
                        new_sources="${new_sources%]}, ('xkb', '$gsid')]"
                    fi
                fi
            done
            set_input_sources "$new_sources"
            ;;
        2)
            local new_sources="["
            local first=true
            for gsid in "${successful_ids[@]}"; do
                if [[ "$first" == true ]]; then
                    new_sources="${new_sources}('xkb', '$gsid')"
                    first=false
                else
                    new_sources="${new_sources}, ('xkb', '$gsid')"
                fi
            done
            new_sources+="]"
            set_input_sources "$new_sources"
            ;;
        3|*) echo -e "${YELLOW}  Skipped updating input sources.${NC}" ;;
    esac
    
    minimal_refresh
    
    echo -e "\n${GREEN}✅ Installation complete!${NC}"
    echo -e "${YELLOW}⚠️  Logout and login again to see changes.${NC}"
    read -n1 -p "Press any key to return..."
}
