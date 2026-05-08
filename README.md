# dotfiles

Configuracion personal de mi entorno de desarrollo en Arch Linux. Incluye configuraciones para multiples window managers (Wayland y X11), Neovim, Kitty, Waybar/Polybar, y mas.

> **Nota**: Este repositorio esta pensado para mi setup personal con triple monitor y drivers NVIDIA. Adapta las configuraciones a tu hardware antes de usarlas.

---

## Estructura del repositorio

```
dotfiles/
├── config/
│   ├── bspwm/           # Window manager (X11)
│   ├── dunst/            # Daemon de notificaciones
│   ├── fastfetch/        # System info en la terminal
│   ├── fontconfig/       # Configuracion de fuentes
│   ├── hypr/             # Hyprland compositor (Wayland) + hyprlock
│   ├── i3/               # Window manager (X11)
│   ├── kitty/            # Emulador de terminal
│   ├── nvim/             # Editor (Neovim + lazy.nvim)
│   ├── picom/            # Compositor (X11)
│   ├── polybar/          # Barra de estado (X11)
│   ├── river/            # Window manager (Wayland)
│   ├── rofi/             # Launcher de aplicaciones
│   ├── sxhkd/            # Daemon de atajos de teclado
│   ├── waybar/           # Barra de estado (Wayland)
│   └── zsh/              # Shell
├── fonts/
│   └── firaMono/         # FiraMono Nerd Font (bundled)
├── icons/                # Iconos personalizados
├── scripts/
│   └── tmux-sessionizer  # Gestor de sesiones tmux con fzf
└── themes/
    └── AtomOneDarkTheme-main/  # Tema GTK Atom One Dark
```

---

## Window Managers

Se incluyen configuraciones para **4 window managers**. El principal es **Hyprland** (Wayland).

### Hyprland (Wayland) - Principal

| Aspecto | Configuracion |
|---------|--------------|
| Monitor principal | DP-2 (2560x1440@165Hz) |
| Monitores secundarios | DP-1 (1080p@144Hz), HDMI-A-1 (1080p@60Hz, rotado) |
| Workspaces | 9 persistentes distribuidos en 3 monitores |
| Teclado | `us,es` con toggle `Win+Space` |
| Gaps | 2px inner, 10px outer |
| Bordes | 2px, rounding 4px |
| Opacidad | Activa 1.0, inactiva 0.95 |
| Blur | Activado (size 4, 2 pasadas) |
| Autostart | udiskie, fcitx5, Quickshell (noctalia-shell), hyprlock |

**Atajos principales**:

| Atajo | Accion |
|-------|--------|
| `Super+Return` | Abrir Kitty |
| `Super+W` | Cerrar ventana |
| `Super+E` | Thunar (gestor de archivos) |
| `Super+D` | Launcher (Quickshell) |
| `Super+C` | Portapapeles (Quickshell) |
| `Super+T` | Toggle flotante |
| `Super+H/J/K/L` | Mover foco |
| `Super+Shift+H/J/K/L` | Mover ventana |
| `Super+1-9` | Cambiar workspace |
| `Super+Shift+1-0` | Mover ventana a workspace |
| `Super+Tab` | Maximizar |
| `Super+M` | Fullscreen |
| `Alt+Shift+F` | Brave |
| `Alt+Shift+V` | VS Code |
| `Alt+Shift+S` | Screenshot |
| `Ctrl+Shift+L` | Bloquear pantalla |

### bspwm (X11)

Triple monitor con 9 workspaces, gaps de 12px, border 3px. Usa sxhkd para los atajos de teclado y polybar como barra de estado.

### i3 (X11)

Config con gaps (inner 6), esquema de colores Nord, nombres de workspace en japones y polybar.

### river (Wayland)

Configuracion basica con rivertile layout, colores solarized dark y controles multimedia.

---

## Terminal: Kitty

| Configuracion | Valor |
|--------------|-------|
| Fuente | FiraMono Nerd Font, size 13 |
| Opacidad | 0.8 (translucida) |
| Color de fondo | #080808 |
| Margenes | 1px |
| Navegacion | `Ctrl+H/J/K/L` entre ventanas |

---

## Neovim

Configuracion basada en **lazy.nvim** con leader key `Space`. Incluye 26 plugins organizados en archivos separados.

### Plugins

| Plugin | Proposito | Atajo principal |
|--------|-----------|-----------------|
| **nvim-lspconfig** | Cliente LSP | `K` hover, `gd` definicion, `<leader>rn` renombrar |
| **telescope.nvim** | Fuzzy finder | `<leader>pf` archivos, `<leader>pg` grep, `<leader>ps` string |
| **oil.nvim** | Explorador de archivos | `<leader>pv` abrir |
| **treesitter** | Syntax highlighting | Auto-install para lua, typescript |
| **treesitter-context** | Contexto sticky | Automatico |
| **blink.cmp** | Autocompletado | `Tab` aceptar, `C-j/k` navegar |
| **conform.nvim** | Formateo al guardar | Automatico al guardar |
| **lualine.nvim** | Barra de estado | Automatico |
| **harpoon** | Marcadores de archivos | `<leader>m` marcar, `Alt+F/D/S/G` navegar |
| **trouble.nvim** | Lista de diagnositcos | `<leader>pe` proyecto, `<leader>fe` buffer |
| **gitsigns.nvim** | Signos de git en gutter | Blame en linea actual |
| **auto-session** | Gestor de sesiones | Automatico |
| **render-markdown.nvim** | Renderizado markdown | Automatico |
| **nvim-colorizer.lua** | Preview de colores hex/rgb | Automatico |
| **indent-blankline.nvim** | Guias de indentacion | `▏` como caracter |
| **cloak.nvim** | Ocultar valores .env | Automatico en `.env*` |
| **nvim-notify** | Notificaciones mejoradas | Automatico |
| **fidget.nvim** | Progreso LSP | Automatico |
| **tokyonight.nvim** | Tema (Tokyo Night Storm) | Transparente |
| **flutter-tools.nvim** | Desarrollo Flutter | `<leader>fc` comandos |
| **tsc.nvim** | Type checking TypeScript | Monorepo mode |
| **lazydev.nvim** | Desarrollo Lua | Automatico |
| **workspace-diagnostics** | Diagnostico workspace | Automatico |

### Formatters (conform.nvim)

| Lenguaje | Formatter |
|----------|-----------|
| Lua | stylua |
| TypeScript/JS/JSX | prettierd |
| CSS/HTML/JSON | prettierd |
| Bash/Shell | shfmt |
| Go | gofmt |
| Python | pyink |
| Rust | rustfmt |
| C/C++ | clang-format |
| C# | csharpier |
| Java | astyle |
| PHP | pint |
| TOML | taplo |
| YAML | yamlfmt |
| LaTeX | latexindent |
| XML | xmlformatter |

### LSP Servers configurados

`lua_ls`, `vtsls`, `gopls`, `clangd`, `fish_lsp`, `tailwindcss`, `astro`

---

## Barra de estado

### Waybar (Hyprland)

Barra transparente con FiraMono Nerd Font. Modulos:

- **Izquierda**: Launcher (rofi), CPU, RAM, media (Spotify/playerctl), tray, ventana activa
- **Centro**: Workspaces (iconos numericos japoneses)
- **Derecha**: Idioma ("GUIRI IDIOM" / "VIVA ESPANA"), updates disponibles, volumen, reloj, wallpaper

### Polybar (bspwm/i3)

Dos barras: `primary` (monitor principal con systray) y `general` (monitores secundarios). Colores Tokyo Night. Layout de teclado como "GUIRI" / "ESPANITA".

---

## App Launcher: Rofi

Tema minimalista negro con texto blanco, ventana de 450px, bordes redondeados (8px), fuente Figtree 13. Funciona en X11 y Wayland (modo `-normal-window`).

---

## Shell: Zsh

- **Framework**: Oh My Zsh
- **Tema**: kafeitu
- **Plugins**: git, zsh-autosuggestions, sudo, zsh-syntax-highlighting
- **Aliases**:
  - `ls` → `lsd`
  - `cat` → `bat`
  - `vim` → `nvim`
  - `lock` → `hyprlock`
  - `work` → `cd ~/Documents/work`
  - `update` → `yay -Syu` + flatpak update
  - `purge` → limpiar paquetes huerfanos
- **fastfetch** al abrir terminal

---

## Notificaciones: Dunst

Posicionado abajo-derecha. Esquinas redondeadas (10px), transparencia 10%. Iconos personalizados (pokeball para normales). Criticas persistentes hasta cierre manual.

---

## Compositor X11: Picom

Animaciones de apertura/cierre (scale+fade, 0.7s), fading suave, backend GLX. Sin sombras. Script de toggle con notificacion dunstify.

> Requiere el fork con soporte de animaciones (`picom-animations` o `picom-git`).

---

## Screen Lock: Hyprlock

Pantalla de bloqueo con wallpaper blurizado, reloj grande (JetBrains Mono Extrabold, 95px), fecha y campo de password redondeado (32px).

---

## Fastfetch

Muestra informacion del sistema al abrir la terminal con ASCII art personalizado. Muestra: OS, kernel, paquetes, CPU, GPU, displays, RAM, shell, tema, terminal y mas.

---

## Tema GTK: Atom One Dark

Tema completo GTK incluido en `themes/`. Compatible con GTK 2.0, 3.0, 3.20, Metacity, Openbox, Xfwm4 y Unity.

---

## Dependencias

### Fuentes

```sh
paru -S ttf-freefont ttf-ms-fonts ttf-linux-libertine ttf-dejavu \
       ttf-inconsolata ttf-ubuntu-font-family noto-fonts-cjk \
       noto-fonts-emoji noto-fonts
```

Fuentes adicionales necesarias (no en repos):

- **FiraMono Nerd Font** (incluida en `fonts/firaMono/`)
- **JetBrains Mono** (para hyprlock)
- **Figtree** (para rofi)

### Core (Wayland - Hyprland)

```sh
paru -S hyprland hyprlock waybar rofi-wayland dunst kitty \
       quickshell grimblast wpctl udiskie playerctl \
       fcitx5 pamixer dex brightnessctl
```

### Core (X11 - bspwm/i3)

```sh
paru -S bspwm sxhkd i3-wm polybar picom nitrogen lxappearance \
       xrandr flameshot nm-applet xkblayout-state
```

### Neovim y herramientas de desarrollo

```sh
paru -S neovim ripgrep fd fzf tmux lazygit \
       stylua prettierd shfmt clang-format go python-pyink \
       rustfmt astyle csharpier taplo yamlfmt latexindent xmlformatter \
       nodejs typescript gopls clang lua-language-server \
       tailwindcss-language-server astro-language-server
```

### Shell y utilidades

```sh
paru -S zsh lsd bat fastfetch yay paru flatpak thunar brave
```

### Oh My Zsh + plugins

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

### Drivers NVIDIA (si aplica)

```sh
paru -S nvidia-dkms nvidia-utils lib32-nvidia-utils \
       nvidia-settings egl-wayland
```

---

## Instalacion

1. Clonar el repositorio:

```sh
git clone https://github.com/<tu-usuario>/dotfiles.git ~/dotfiles
```

2. Crear symlinks a `~/.config/`:

```sh
# Ejemplo para Hyprland
ln -s ~/dotfiles/config/hypr ~/.config/hypr
ln -s ~/dotfiles/config/kitty ~/.config/kitty
ln -s ~/dotfiles/config/nvim ~/.config/nvim
ln -s ~/dotfiles/config/waybar ~/.config/waybar
ln -s ~/dotfiles/config/rofi ~/.config/rofi
ln -s ~/dotfiles/config/dunst ~/.config/dunst
ln -s ~/dotfiles/config/zsh/.zshrc ~/.zshrc
ln -s ~/dotfiles/config/fastfetch ~/.config/fastfetch
ln -s ~/dotfiles/config/fontconfig ~/.config/fontconfig
```

3. Instalar la fuente FiraMono Nerd Font:

```sh
cp -r ~/dotfiles/fonts/firaMono ~/.local/share/fonts/
fc-cache -fv
```

4. Instalar el tema GTK Atom One Dark:

```sh
cp -r ~/dotfiles/themes/AtomOneDarkTheme-main ~/.themes/
```

5. Asegurar que el script tmux-sessionizer es ejecutable:

```sh
chmod +x ~/dotfiles/scripts/tmux-sessionizer
```

---

## Hardware de referencia

| Componente | Modelo |
|-----------|--------|
| GPU | NVIDIA RTX 3070 |
| Monitor principal | DP-2 (2560x1440@165Hz) |
| Monitor secundario | DP-1 (1080p@144Hz) |
| Monitor terciario | HDMI-A-1 (1080p@60Hz, rotado) |
| Mouse | Razer DeathAdder Essential |
