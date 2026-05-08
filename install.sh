#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$REPO_DIR/config"
BACKUP_DIR="$HOME/.config/dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

print_banner() {
    echo -e "${CYAN}"
    cat <<'EOF'
  ╔═══════════════════════════════════════╗
  ║          dotfiles installer           ║
  ╚═══════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

detect_aur_helper() {
    if command -v paru &>/dev/null; then
        echo "paru"
    elif command -v yay &>/dev/null; then
        echo "yay"
    else
        echo "pacman"
    fi
}

is_installed() {
    pacman -Qi "$1" &>/dev/null
}

install_packages() {
    local helper="$1"
    shift
    local pkgs=()
    for pkg in "$@"; do
        if ! is_installed "$pkg"; then
            pkgs+=("$pkg")
        fi
    done

    if [[ ${#pkgs[@]} -eq 0 ]]; then
        success "Todos los paquetes ya estan instalados"
        return
    fi

    info "Instalando: ${pkgs[*]}"
    if [[ "$helper" == "pacman" ]]; then
        sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    else
        "$helper" -S --needed --noconfirm "${pkgs[@]}"
    fi
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local yn
    while true; do
        echo -en "${YELLOW}?${NC} ${prompt} ${BOLD}[${default^^}]${NC} "
        read -r yn
        yn="${yn:-$default}"
        case "$yn" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
        esac
    done
}

ask_option() {
    local prompt="$1"
    shift
    local options=("$@")
    echo -e "\n${BOLD}${prompt}${NC}"
    echo "-----------------------------------"
    for i in "${!options[@]}"; do
        echo -e "  ${GREEN}$((i+1)))${NC} ${options[$i]}"
    done
    echo "-----------------------------------"
    local choice
    while true; do
        echo -en "${YELLOW}? Elige una opcion [1-${#options[@]}]: ${NC}"
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#options[@]}" ]]; then
            echo "$choice"
            return
        fi
        warn "Opcion invalida"
    done
}

backup_existing() {
    local target="$1"
    if [[ -L "$target" ]]; then
        rm "$target"
    elif [[ -e "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/"
        info "Backup: $(basename "$target") -> $BACKUP_DIR/"
    fi
}

create_symlink() {
    local source="$1"
    local target="$2"
    backup_existing "$target"
    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
    success "ln -s $source -> $target"
}

make_executable() {
    find "$1" -type f \( -name "*.sh" -o -name "bspwmrc" -o -name "init" -o -name "tmux-sessionizer" -o -name "sxhkdrc" \) -exec chmod +x {} \; 2>/dev/null || true
}

install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        success "Oh My Zsh ya esta instalado"
        return
    fi
    info "Instalando Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

install_zsh_plugins() {
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    if [[ ! -d "$zsh_custom/zsh-autosuggestions" ]]; then
        info "Instalando zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/zsh-autosuggestions"
    else
        success "zsh-autosuggestions ya instalado"
    fi
    if [[ ! -d "$zsh_custom/zsh-syntax-highlighting" ]]; then
        info "Instalando zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$zsh_custom/zsh-syntax-highlighting"
    else
        success "zsh-syntax-highlighting ya instalado"
    fi
}

install_fonts() {
    info "Instalando fuentes del sistema..."
    local helper
    helper=$(detect_aur_helper)
    install_packages "$helper" \
        ttf-freefont ttf-dejavu ttf-inconsolata ttf-ubuntu-font-family \
        noto-fonts-cjk noto-fonts-emoji noto-fonts

    info "Instalando FiraMono Nerd Font (bundled)..."
    local font_dir="$HOME/.local/share/fonts/firaMono"
    if [[ ! -d "$font_dir" ]] || [[ -z "$(ls -A "$font_dir" 2>/dev/null)" ]]; then
        mkdir -p "$font_dir"
        cp "$REPO_DIR/fonts/firaMono/"*.otf "$font_dir/"
        fc-cache -fv "$font_dir" >/dev/null 2>&1
        success "FiraMono Nerd Font instalada"
    else
        success "FiraMono Nerd Font ya instalada"
    fi

    info "Instalando fuentes adicionales..."
    install_packages "$helper" ttf-jetbrains-mono ttf-figtree 2>/dev/null || \
        warn "Algunas fuentes pueden no estar en los repos. Instalalas manualmente si es necesario."
}

install_theme() {
    local theme_dir="$HOME/.themes/AtomOneDarkTheme-main"
    if [[ -d "$theme_dir" ]]; then
        success "Tema Atom One Dark ya instalado"
        return
    fi
    mkdir -p "$HOME/.themes"
    cp -r "$REPO_DIR/themes/AtomOneDarkTheme-main" "$HOME/.themes/"
    success "Tema Atom One Dark instalado en ~/.themes/"
}

declare -A WM_PACKAGES=(
    ["hyprland"]="hyprland hyprlock kitty waybar dunst rofi"
    ["bspwm"]="bspwm sxhkd kitty polybar picom dunst rofi nitrogen lxappearance"
    ["i3"]="i3-wm kitty polybar picom dunst rofi nitrogen"
    ["river"]="river kitty"
)

declare -A WM_SYMLINKS=(
    ["hyprland"]="hypr kitty waybar dunst rofi fastfetch fontconfig nvim"
    ["bspwm"]="bspwm sxhkd kitty polybar picom dunst rofi fastfetch fontconfig nvim"
    ["i3"]="i3 kitty polybar picom dunst rofi fastfetch fontconfig nvim"
    ["river"]="river kitty fastfetch fontconfig nvim"
)

X11_EXTRAS="polybar picom rofi dunst nitrogen flameshot"
WAYLAND_EXTRAS="waybar dunst rofi grimblast wpctl brightnessctl playerctl pamixer"

COMMON_PACKAGES="zsh neovim ripgrep fd fzf tmux lsd bat fastfetch thunar \
    xdg-user-dirs xdotool curl git unzip"

NVIDIA_PACKAGES="nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings egl-wayland"

main() {
    print_banner

    local helper
    helper=$(detect_aur_helper)
    info "AUR helper detectado: ${BOLD}$helper${NC}"

    if [[ "$helper" == "pacman" ]]; then
        warn "No se detecto paru ni yay. Se usara pacman (no podra instalar paquetes AUR)."
        if ! ask_yes_no "Continuar de todos modos?" "n"; then
            exit 0
        fi
    fi

    local wm
    wm=$(ask_option "Que window manager / compositor quieres instalar?" \
        "Hyprland (Wayland)" \
        "bspwm (X11)" \
        "i3 (X11)" \
        "river (Wayland)" \
        "Todos")

    local wm_names=()
    case "$wm" in
        1) wm_names=("hyprland") ;;
        2) wm_names=("bspwm") ;;
        3) wm_names=("i3") ;;
        4) wm_names=("river") ;;
        5) wm_names=("hyprland" "bspwm" "i3" "river") ;;
    esac

    info "Se instalaran los dotfiles para: ${BOLD}${wm_names[*]}${NC}"

    echo ""
    echo -e "${BOLD}--- Paquetes ---${NC}"

    local all_packages=()
    for w in "${wm_names[@]}"; do
        read -ra pkgs <<< "${WM_PACKAGES[$w]}"
        all_packages+=("${pkgs[@]}")
    done

    all_packages+=(${COMMON_PACKAGES})

    local unique_packages=()
    local seen=()
    for pkg in "${all_packages[@]}"; do
        local found=0
        for s in "${seen[@]+"${seen[@]}"}"; do
            if [[ "$s" == "$pkg" ]]; then found=1; break; fi
        done
        if [[ $found -eq 0 ]]; then
            unique_packages+=("$pkg")
            seen+=("$pkg")
        fi
    done

    install_packages "$helper" "${unique_packages[@]}"

    for w in "${wm_names[@]}"; do
        case "$w" in
            hyprland)
                info "Instalando extras Wayland..."
                install_packages "$helper" ${WAYLAND_EXTRAS}
                ;;
            bspwm|i3)
                info "Instalando extras X11..."
                install_packages "$helper" ${X11_EXTRAS}
                ;;
        esac
    done

    echo ""
    echo -e "${BOLD}--- NVIDIA ---${NC}"
    if lspci | grep -qi nvidia; then
        if ask_yes_no "Detectada GPU NVIDIA. Instalar drivers NVIDIA?" "y"; then
            install_packages "$helper" ${NVIDIA_PACKAGES}
        fi
    else
        info "No se detecto GPU NVIDIA, saltando drivers"
    fi

    echo ""
    echo -e "${BOLD}--- Fuentes ---${NC}"
    install_fonts

    echo ""
    echo -e "${BOLD}--- Tema GTK ---${NC}"
    install_theme

    echo ""
    echo -e "${BOLD}--- Oh My Zsh ---${NC}"
    install_oh_my_zsh
    install_zsh_plugins

    echo ""
    echo -e "${BOLD}--- Symlinks ---${NC}"

    local configs_to_link=()
    for w in "${wm_names[@]}"; do
        read -ra configs <<< "${WM_SYMLINKS[$w]}"
        for c in "${configs[@]}"; do
            local already=0
            for existing in "${configs_to_link[@]+"${configs_to_link[@]}"}"; do
                if [[ "$existing" == "$c" ]]; then already=1; break; fi
            done
            if [[ $already -eq 0 ]]; then
                configs_to_link+=("$c")
            fi
        done
    done

    for config in "${configs_to_link[@]}"; do
        local source="$CONFIG_DIR/$config"
        local target="$HOME/.config/$config"

        if [[ "$config" == "zsh" ]]; then
            continue
        fi

        if [[ ! -d "$source" ]]; then
            warn "No existe: $source (saltando)"
            continue
        fi

        make_executable "$source"
        create_symlink "$source" "$target"
    done

    create_symlink "$CONFIG_DIR/zsh/.zshrc" "$HOME/.zshrc"
    success "zshrc enlazado"

    if [[ -d "$REPO_DIR/scripts" ]]; then
        make_executable "$REPO_DIR/scripts"
        success "Scripts marcados como ejecutables"
    fi

    echo ""
    echo -e "${BOLD}--- Post-instalacion ---${NC}"

    info "Instalando plugins de Neovim (primera ejecucion)..."
    if command -v nvim &>/dev/null; then
        nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
        success "Plugins de Neovim instalados"
    fi

    echo ""
    if [[ "$BACKUP_DIR" != "" ]] && [[ -d "$BACKUP_DIR" ]]; then
        info "Tus configs anteriores estan en: $BACKUP_DIR"
    fi

    echo ""
    echo -e "${GREEN}${BOLD}Instalacion completada!${NC}"
    echo ""
    echo -e "  ${CYAN}Proximos pasos:${NC}"
    echo -e "  1. Cierra sesion y selecciona tu WM en el display manager"
    echo -e "  2. Revisa los atajos de teclado en el README.md"
    if [[ " ${wm_names[*]} " =~ " hyprland " ]]; then
        echo -e "  3. Edita ${BOLD}~/.config/hypr/config/displays.conf${NC} para tus monitores"
        echo -e "  4. Edita ${BOLD}~/.config/hypr/config/devices.conf${NC} para tu teclado/mouse"
    fi
    if [[ " ${wm_names[*]} " =~ " bspwm " ]] || [[ " ${wm_names[*]} " =~ " i3 " ]]; then
        echo -e "  3. Edita los nombres de monitor en ${BOLD}~/.config/polybar/launch_polybar.sh${NC}"
    fi
    echo ""
}

main "$@"
