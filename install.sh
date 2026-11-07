#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$REPO_DIR/config"
NIXOS_CONFIG_DIR="$CONFIG_DIR/nixos"
ETC_NIXOS="/etc/nixos"
NIX_CONF="/etc/nix/nix.conf"
BACKUP_DIR="$HOME/.config/dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
ETC_BACKUP_DIR="$ETC_NIXOS/dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

# Dotfiles que se enlazan en ~/.config
DOTFILES_DIRS=(hypr kitty fastfetch nvim noctalia)

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
  ║      dotfiles installer - NixOS       ║
  ╚═══════════════════════════════════════╝
EOF
    echo -e "${NC}"
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

check_environment() {
    grep -qi '^ID=nixos' /etc/os-release \
        || error "Este instalador es para NixOS (la version para Arch esta en el historial de git)"
    [[ $EUID -eq 0 ]] && error "No ejecutes el script como root: los symlinks deben crearse en tu HOME"
    command -v sudo &>/dev/null || error "sudo no esta disponible"
    [[ -f "$NIXOS_CONFIG_DIR/configuration.nix" ]] || error "Falta $NIXOS_CONFIG_DIR/configuration.nix"
    [[ -f "$NIXOS_CONFIG_DIR/flake.nix" ]] || error "Falta $NIXOS_CONFIG_DIR/flake.nix"
    if [[ "$USER" != "yasai" ]]; then
        warn "Usuario actual: '$USER'. configuration.nix y varias configs usan rutas de /home/yasai; revisalo antes del rebuild."
    fi
    success "Entorno NixOS detectado"
}

copy_nixos_config() {
    if [[ ! -f "$ETC_NIXOS/hardware-configuration.nix" ]]; then
        error "Falta $ETC_NIXOS/hardware-configuration.nix. Ese archivo lo genera el instalador de NixOS (no esta en el repo). Instala NixOS base primero."
    fi

    sudo mkdir -p "$ETC_NIXOS"

    local f
    for f in configuration.nix flake.nix; do
        if [[ -f "$ETC_NIXOS/$f" ]]; then
            sudo mkdir -p "$ETC_BACKUP_DIR"
            sudo cp "$ETC_NIXOS/$f" "$ETC_BACKUP_DIR/"
            info "Backup: $f -> $ETC_BACKUP_DIR/"
        fi
        sudo cp "$NIXOS_CONFIG_DIR/$f" "$ETC_NIXOS/$f"
        success "Copiado $f a $ETC_NIXOS/"
    done

    info "hardware-configuration.nix se conserva (no se sobrescribe nunca)"
}

ensure_flakes() {
    if grep -qs '^experimental-features' "$NIX_CONF"; then
        if grep -qs '^experimental-features.*flakes' "$NIX_CONF"; then
            success "Flakes ya activados en $NIX_CONF"
            return
        fi
        info "Anadiendo flakes a experimental-features en $NIX_CONF..."
        sudo sed -i 's/^experimental-features.*/experimental-features = nix-command flakes/' "$NIX_CONF"
    else
        info "Activando flakes en $NIX_CONF (necesario para el primer build)..."
        sudo mkdir -p /etc/nix
        echo "experimental-features = nix-command flakes" | sudo tee -a "$NIX_CONF" >/dev/null
    fi
    success "Flakes activados (nix-command flakes)"
}

rebuild() {
    info "Ejecutando nixos-rebuild switch (la primera vez puede tardar bastante)..."
    sudo nixos-rebuild switch --flake "$ETC_NIXOS#nixos"
    success "Sistema reconstruido"
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
    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        success "Ya enlazado: $target"
        return
    fi
    backup_existing "$target"
    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
    success "ln -s $source -> $target"
}

link_dotfiles() {
    local dir
    for dir in "${DOTFILES_DIRS[@]}"; do
        local source="$CONFIG_DIR/$dir"
        if [[ ! -d "$source" ]]; then
            warn "No existe: $source (saltando)"
            continue
        fi
        create_symlink "$source" "$HOME/.config/$dir"
    done

    # ~/scripts para los aliases de zsh: update, updatef y vpn
    create_symlink "$REPO_DIR/scripts" "$HOME/scripts"

    chmod +x "$REPO_DIR/scripts/"*.sh 2>/dev/null || true
}

install_nvim_plugins() {
    if ! command -v nvim &>/dev/null; then
        warn "nvim no esta en el PATH todavia; sus plugins se instalaran solos al abrirlo por primera vez"
        return
    fi
    info "Instalando plugins de Neovim (lazy.nvim)..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    success "Plugins de Neovim instalados"
}

main() {
    print_banner
    check_environment

    local do_rebuild=0

    echo ""
    echo -e "${BOLD}--- Configuracion del sistema ---${NC}"
    if ask_yes_no "Copiar configuration.nix y flake.nix a /etc/nixos y reconstruir el sistema?" "y"; then
        copy_nixos_config
        ensure_flakes

        echo ""
        warn "Antes del primer build, revisa /etc/nixos/configuration.nix:"
        echo "       usuario, hostname, GPU (hardware.nvidia), discos NTFS y paquetes personales"
        if ask_yes_no "Continuar con nixos-rebuild switch?" "y"; then
            do_rebuild=1
        else
            info "Rebuild saltado. Lanzalo cuando quieras con:"
            echo "       sudo nixos-rebuild switch --flake /etc/nixos#nixos"
        fi
    else
        info "Configuracion del sistema saltada (solo se crearan los symlinks)"
    fi

    if [[ $do_rebuild -eq 1 ]]; then
        echo ""
        rebuild
    fi

    echo ""
    echo -e "${BOLD}--- Symlinks ---${NC}"
    link_dotfiles

    echo ""
    echo -e "${BOLD}--- Post-instalacion ---${NC}"
    install_nvim_plugins

    echo ""
    if [[ -d "$BACKUP_DIR" ]]; then
        info "Tus configs anteriores de ~/.config estan en: $BACKUP_DIR"
    fi
    if [[ -d "$ETC_BACKUP_DIR" ]]; then
        info "Tus configs anteriores de /etc/nixos estan en: $ETC_BACKUP_DIR"
    fi

    echo ""
    echo -e "${GREEN}${BOLD}Instalacion completada!${NC}"
    echo ""
    echo -e "  ${CYAN}Proximos pasos:${NC}"
    echo -e "  1. Edita ${BOLD}~/.config/hypr/config/monitors.lua${NC} para tus monitores"
    echo -e "  2. Edita ${BOLD}~/.config/hypr/config/devices.lua${NC} para tu teclado/raton"
    echo -e "  3. Revisa ${BOLD}~/.config/hypr/config/autostart.lua${NC} (apps que se lanzan al inicio)"
    if [[ $do_rebuild -eq 1 ]]; then
        echo -e "  4. Reinicia e inicia sesion en la TTY1: Hyprland arranca solo"
    fi
    echo ""
}

main "$@"
