#!/bin/bash
# Keyboard Manager - Main launcher

MAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$MAIN_DIR/Sources/lib_common.sh"
source "$MAIN_DIR/Sources/install.sh"
source "$MAIN_DIR/Sources/uninstall.sh"
source "$MAIN_DIR/Sources/refresh.sh"
source "$MAIN_DIR/Sources/clean_reset.sh"

check_root

mkdir -p "$LAYOUTS_DIR"

# عرض الصندوق - 50 حرف بين العمودين
W=50

# دالة لطباعة سطر مع نص ملون في المنتصف (بدون ألوان في الحساب)
print_middle() {
    local text="$1"
    local color="$2"
    local clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#clean_text}
    local pad=$(( (W - text_len) / 2 ))
    local pad_right=$(( W - text_len - pad ))
    local spaces=$(printf '%*s' $pad '')
    local spaces_right=$(printf '%*s' $pad_right '')
    echo -e "${BLUE}║${NC}${spaces}${color}${text}${NC}${spaces_right}${BLUE}║${NC}"
}

# دالة لطباعة سطر مع نص على اليسار (يحسب طول النص بدون أكواد الألوان)
print_left() {
    local text="$1"
    # إزالة أكواد الألوان لحساب الطول الحقيقي
    local clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#clean_text}
    local pad=$(( W - text_len - 1 ))
    local spaces=$(printf '%*s' $pad '')
    echo -e "${BLUE}║${NC} ${text}${spaces}${BLUE}║${NC}"
}

# دالة لطباعة سطر فارغ
print_empty() {
    echo -e "${BLUE}║${NC}$(printf '%*s' $W '')${BLUE}║${NC}"
}

while true; do
    clear
    
    # السطر العلوي
    echo -e "${BLUE}╔$(printf '═%.0s' $(seq 1 $W))╗${NC}"
    
    # العنوان في المنتصف
    print_middle "Keyboard Manager" "${CYAN}"
    
    # سطر فارغ
    print_empty
    
    # سطر التوزيعة
    print_middle "Distribution: $(get_distribution)" "${YELLOW}"
    
    # الخط الفاصل
    echo -e "${BLUE}╠$(printf '═%.0s' $(seq 1 $W))╣${NC}"
    
    # القائمة - باستخدام print_left مع النص الكامل (الألوان مضمنة)
    print_left "${CYAN}1)${NC} Install custom layouts"
    print_left "${CYAN}2)${NC} Remove custom layouts"
    print_left "${CYAN}3)${NC} Full desktop refresh (Alt+F2 then r)"
    print_left "${CYAN}4)${NC} Clean ALL custom layouts "
    print_left "${CYAN}5)${NC} Layout options"
    print_left "${CYAN}6)${NC} Emergency reset XKB (factory restore)"
    print_left "${CYAN}7)${NC} Exit"
    
    # السطر السفلي
    echo -e "${BLUE}╚$(printf '═%.0s' $(seq 1 $W))╝${NC}"
    
    echo -e "${YELLOW}Desktop: $(detect_desktop) | Current: $(get_current_layout)${NC}"
    
    read -p "$(echo -e "${CYAN}Choice (1-7): ${NC}")" choice
    
    case $choice in
        1) install_layouts_menu ;;
        2) remove_layouts_menu ;;
        3) full_refresh ;;
        4) clean_all_layouts ;;
        5) set_layout_options ;;
        6) emergency_cleanup ;;
        7) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid choice!${NC}"; sleep 1 ;;
    esac
done