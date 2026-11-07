# Dotfiles — NixOS + Hyprland + Noctalia

Dotfiles personales para un entorno Linux con **Hyprland** como compositor, **Kitty** como terminal, **Noctalia** como shell de escritorio, y **Fastfetch**, **Neovim** y **Zsh** como herramientas principales.

> El script `install.sh` de la raíz automatiza todo el proceso en NixOS: copia `configuration.nix` y `flake.nix` a `/etc/nixos` (conservando tu `hardware-configuration.nix` y con backup de lo anterior), activa los flakes si es el primer build, ejecuta `nixos-rebuild switch --flake` y crea los symlinks de las dotfiles. Pide confirmación antes de tocar el sistema. Los pasos manuales equivalentes se detallan a continuación.

---

## Estructura del repositorio

```text
.dotfiles/
├── install.sh              # Instalador para NixOS (configs del sistema + symlinks)
├── scripts/                # Scripts de sistema
│   ├── update.sh           #   Copia configuration.nix y hace nixos-rebuild switch
│   ├── updatef.sh          #   Copia configuration.nix + flake.nix y rebuild con flake
│   └── vpn.sh              #   Conexión VPN (openfortivpn, personal)
├── fonts/firaMono/         # FiraMono Nerd Font en OTF (respaldo; en NixOS se instala por nix)
├── icons/                  # Temas de iconos (BreezeX-Dark, Uos...)
├── themes/                 # Tema GTK Atom One Dark
└── config/
    ├── hypr/               # Configuración de Hyprland (en Lua)
    ├── kitty/              # Configuración de Kitty
    ├── fastfetch/          # Configuración de Fastfetch
    ├── nvim/               # Configuración de Neovim (lazy.nvim)
    ├── zsh/                # .zshrc legacy de Arch (en NixOS zsh es declarativo)
    ├── noctalia/           # Configuración de Noctalia shell (ajustes, colores, plugins)
    ├── nixos/              # configuration.nix y flake.nix del sistema
    ├── fontconfig/         # Config de fuentes (opcional)
    ├── rofi/               # Config de rofi (opcional)
    └── waybar/             # Config de waybar (no se usa con Noctalia)
```

---

## Requisitos

- **NixOS** (el flake usa `nixos-unstable`).
- **Hyprland >= 0.56**: es la versión que lee la configuración en **Lua** (`~/.config/hypr/hyprland.lua`) de forma nativa. La versión de unstable cumple esto.
- GPU **NVIDIA** (la configuración actual incluye drivers y variables específicas de NVIDIA; ver [Personalización de hardware](#personalización-de-hardware) si tu hardware es distinto).

---

## Instalación en un NixOS nuevo

> **Atajo:** `./install.sh` automatiza los pasos 2 a 7 (con confirmaciones, backups de las configs previas e instalación de los plugins de Neovim). El detalle manual:

### 1. Instalar NixOS base

Instala NixOS desde la ISO oficial como de costumbre. Al terminar, `/etc/nixos/` contendrá un `configuration.nix` y un `hardware-configuration.nix` generados por el instalador.

> **Importante:** conserva el `hardware-configuration.nix` de tu máquina. Este archivo es específico del hardware y **no** está en este repositorio.

### 2. Copiar la configuración del sistema

Clona o copia este repositorio en `~/.dotfiles` (puedes hacerlo desde la ISO con `git`, o tras el primer rebuild), y copia la configuración de NixOS a `/etc/nixos`:

```bash
sudo cp ~/.dotfiles/config/nixos/configuration.nix /etc/nixos/configuration.nix
sudo cp ~/.dotfiles/config/nixos/flake.nix         /etc/nixos/flake.nix
# NO sobrescribas /etc/nixos/hardware-configuration.nix
```

### 3. Personalizar antes del primer rebuild

Revisa `configuration.nix` y ajusta lo que sea específico de tu máquina:

| Qué | Dónde | Nota |
|---|---|---|
| Usuario | `users.users."yasai"` | El config asume usuario `yasai` y rutas `/home/yasai` en varios sitios (aliases, scripts) |
| Hostname | `networking.hostName` | Debe ser `nixos` (o cambia el atributo `nixosConfigurations.nixos` del flake) |
| Zona horaria / locale | `time.timeZone`, `i18n.*` | Actualmente `Europe/Madrid` + español |
| Discos NTFS extra | `fileSystems."/media/..."` | Montajes personales por UUID; elimínalos si no aplican |
| GPU | `hardware.nvidia`, `services.xserver.videoDrivers`, `boot.kernelParams` | Sección solo válida para NVIDIA |
| Paquetes personales | `environment.systemPackages` | Quita lo que no uses (equibop, feishin, lmstudio, vpn...) |
| `hypr-kdeconnect-fix` | input del flake + derivación | Parche opcional para KDE Connect sobre Hyprland; puedes quitar el input y la derivación si no lo necesitas |

### 4. Primer rebuild (activando flakes)

El flake necesita `nix-command` y `flakes` activados. La configuración ya los declara (`nix.settings.experimental-features`), pero para el *primer* build hay que habilitarlos a mano:

```bash
sudo mkdir -p /etc/nix
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

Esto instala todo el sistema: Hyprland, Kitty, Fastfetch, Neovim, Zsh (con Oh My Zsh), Noctalia (desde su flake), fuentes Nerd Fonts, PipeWire, portales XDG, drivers NVIDIA, etc.

### 5. Crear los symlinks de las dotfiles

Enlaza las carpetas de configuración de este repo en `~/.config`:

```bash
cd ~/.dotfiles/config

for dir in hypr kitty fastfetch nvim noctalia; do
  rm -rf ~/.config/$dir        # elimina la config por defecto si existiera
  ln -s ~/.dotfiles/config/$dir ~/.config/$dir
done

# Los aliases `update`, `updatef` y `vpn` apuntan a ~/scripts:
ln -sfn ~/.dotfiles/scripts ~/scripts
```

Notas:

- **Zsh no se enlaza**: en NixOS está configurado de forma declarativa en `configuration.nix` (ver [Zsh](#zsh)). El `config/zsh/.zshrc` del repo es el legacy de Arch y no debe enlazarse.
- Si tu usuario no es `yasai`, actualiza las rutas absolutas (`/home/yasai/...`) de `configuration.nix`, `scripts/` y `autostart.lua`.

### 6. Reiniciar e iniciar sesión

```bash
sudo reboot
```

Tras reiniciar, inicia sesión en la **TTY1** con tu usuario: `programs.zsh` está configurado para que, al abrir una shell en `/dev/tty1`, ejecute automáticamente `start-hyprland` (binario incluido con el propio paquete de Hyprland) y entre al escritorio. En cualquier otra TTY/shell se lanza `fastfetch` en su lugar.

### 7. Primera ejecución de Neovim

Al abrir `nvim` por primera vez, **lazy.nvim** se descarga solo e instala todos los plugins. También puedes forzarlo desde la terminal:

```bash
nvim --headless "+Lazy! sync" +qa
```

---

## Contenido por herramienta

### Hyprland (`config/hypr/`)

La configuración está escrita en **Lua** y Hyprland la carga nativamente desde `hyprland.lua`:

```text
config/hypr/
├── hyprland.lua          # Entry point: require("config/init")
├── hyprtoolkit.conf      # Colores para el toolkit de Hyprland
└── config/
    ├── init.lua          # Carga el resto de módulos
    ├── theme.lua         # Gaps, bordes, blur, animaciones
    ├── autostart.lua     # Programas al iniciar (noctalia-shell, fcitx5, etc.)
    ├── environment.lua   # Variables de entorno de la sesión
    ├── monitors.lua      # Monitores y workspaces persistentes
    ├── nvidia.lua        # Variables y ajustes NVIDIA
    ├── devices.lua       # Teclado, ratón, sensibilidad
    ├── windowrules.lua   # Reglas de ventanas (equibop, steam)
    └── keybinds.lua      # Atajos de teclado
└── noctalia/
    ├── noctalia-colors.lua   # Colores de Hyprland generados por Noctalia
    └── noctalia-colors.conf
```

Atajos principales (definidos en `keybinds.lua`):

| Atajo | Acción |
|---|---|
| `SUPER + Return` | Abrir Kitty |
| `SUPER + W` | Cerrar ventana |
| `SUPER + SHIFT + Q` | Salir de Hyprland |
| `SUPER + E` | Thunar |
| `SUPER + D` | Launcher de Noctalia |
| `SUPER + C` | Historial de portapapeles |
| `SUPER + ,` | Ajustes de Noctalia |
| `SUPER + P` | Pseudo-tiling |
| `SUPER + T` | Ventana flotante |
| `ALT + SHIFT + L` | Bloquear pantalla (Noctalia) |
| `SUPER + SHIFT + P` | Menú de sesión |
| `ALT + SHIFT + S` | Captura de pantalla (plugin de Noctalia) |
| `ALT + SHIFT + F` | Zen Browser |
| `ALT + SHIFT + V` | VS Code |
| `SUPER + H/J/K/L` | Mover el foco (estilo Vim) |
| `SUPER + SHIFT + H/J/K/L` | Mover la ventana |
| `SUPER + 1..9` | Ir al workspace N |
| `SUPER + SHIFT + 1..9 / 0` | Mover ventana al workspace N / 10 |
| `SUPER + Tab` / `SUPER + M` | Fullscreen maximizado / completo |
| `SUPER + rueda` | Cambiar de workspace |
| `SUPER + arrastrar` | Mover / redimensionar con el ratón |
| `XF86AudioRaise/LowerVolume` | Volumen (`wpctl`) |

Cambio de idioma del teclado: **Win + Espacio** (distribución `us,es`).

#### Personalización de hardware

- **`monitors.lua`**: configurado para 3 monitores (`DP-2` 2560x1440@165 principal, `DP-1` 1920x1080@144 a la derecha, `HDMI-A-1` 2560x1440@144). Ajusta salidas, resoluciones y posiciones con los nombres que reporte `hyprctl monitors`.
- **`devices.lua`**: contiene una regla específica para un ratón Razer Deathadder; elimínala o ajusta tu `sensitivity`.
- **`nvidia.lua`**: variables NVIDIA + `no_hardware_cursors`. Si tu GPU **no** es NVIDIA, borra este módulo (y su `require` en `init.lua`) junto con la sección `hardware.nvidia` de `configuration.nix`.
- **`autostart.lua`**: revisa la lista; algunos comandos (`fcitx5`, `udiskie`, `clipboard-sync`, `qpwgraph`, `equibop`, `kdeconnect-indicator`) no están todos en `configuration.nix`. Instálalos o comenta las líneas que no necesites.

### Kitty (`config/kitty/`)

- Fuente: **FiraMono Nerd Font** tamaño 10 (la fuente la instala `configuration.nix` con `nerd-fonts.fira-mono`).
- Opacidad de fondo `0.8`, margen de 1px, sin campana de audio.
- Navegación entre ventanas/paneles con `Ctrl + H/J/K/L` (estilo Vim).
- Incluye `current-theme.conf`, un tema **generado automáticamente por Noctalia**: la shell escribe ahí su paleta al cambiar de colorscheme, de modo que Kitty sigue el tema del escritorio. No borres ese `include`.

### Fastfetch (`config/fastfetch/`)

- `config.jsonc`: layout personalizado con secciones (System, Hardware, Visual, Misc) y color verde/cian.
- `ascii.txt`: logo ASCII personalizado que se muestra en lugar del logo de la distro. `logo1.png` es un logo alternativo (en formato imagen).
- Se ejecuta **automáticamente al abrir cualquier terminal**, configurado en `programs.zsh.interactiveShellInit` de `configuration.nix`.

### Neovim (`config/nvim/`)

Configuración modular gestionada con **lazy.nvim**:

```text
config/nvim/
├── init.lua               # Entry point
├── lazy-lock.json         # Versiones fijadas de plugins
├── lua/config/
│   ├── core/              # options.lua (opciones del editor) y keymaps.lua (atajos)
│   ├── lazy.lua           # Bootstrap de lazy.nvim
│   └── plugins/           # Un archivo por plugin
│       ├── lsp/           # mason + nvim-lspconfig
│       └── blink, barbar, telescope, oil, harpoon,
│         nvim-treesitter, auto-pairs, colorscheme,
│         sessions, java, lazydev, codeactions ...
└── bak/                   # Configuración anterior (respaldo, no se carga)
```

- **Leader**: espacio.
- Plugins destacados: `blink.cmp` (autocompletado), `barbar` (bufferline con `Alt + ,/.` para navegar), `telescope` (fuzzy finder), `oil.nvim` (explorador de archivos como buffer), `harpoon` (marcadores de archivos), `nvim-treesitter`, LSP con `mason` + `nvim-lspconfig`.
- Atajos útiles: `<leader>f` formatea con LSP, `<leader>e` muestra diagnósticos, `<leader>d` borra sin copiar, `J`/`K` en visual mueven líneas, `<leader>sv/sh/sx` gestionan splits, `<leader>to/tx/tn/tp` gestionan tabs.
- Los plugins se instalan solos en la primera ejecución (o con `nvim --headless "+Lazy! sync" +qa`).

### Zsh (declarativo en `configuration.nix`)

En NixOS la shell no se configura con `.zshrc` sino con el módulo `programs.zsh` de `configuration.nix`, que ya incluye:

- **Oh My Zsh** con tema `kafeitu` y plugins `git` y `sudo`.
- **zsh-autosuggestions** y **zsh-syntax-highlighting** (activados por el módulo).
- **Aliases**: `ls`/`ll`/`la`/`tree` → `eza` con iconos, `vim` → `nvim`, `update` → `~/scripts/update.sh`, `updatef` → `~/scripts/updatef.sh`, `vpn` → `~/scripts/vpn.sh`.
- **Comportamiento al abrir shell**: en `/dev/tty1` ejecuta `start-hyprland` (entrada directa al escritorio); en cualquier otra terminal muestra `fastfetch`.

El archivo `config/zsh/.zshrc` del repositorio es la versión antigua de **Arch** (usa `yay`, `lsd`, `bat`) y se mantiene solo como referencia: **no lo enlaces en NixOS**.

### Noctalia (`config/noctalia/`)

[Noctalia](https://github.com/noctalia-dev/noctalia) es la shell de escritorio basada en Quickshell que aporta barra, launcher, centro de control, lock screen, notificaciones, etc. Se instala como **input del flake** (`github:noctalia-dev/noctalia/legacy-v4`) en `flake.nix`, y su paquete añade el binario `noctalia-shell` al sistema. Se autoinicia desde `autostart.lua` de Hyprland.

Contenido de `~/.config/noctalia`:

| Archivo/carpeta | Descripción |
|---|---|
| `settings.json` | Ajustes completos: barra flotante arriba (en `DP-1`, `DP-2`, `HDMI-A-1`), launcher (posición, iconos, portapapeles), audio, lock screen, etc. |
| `colors.json` | Paleta de colores activa (tema monocromo actual) |
| `colorschemes/` | Esquemas de color disponibles: `yasai` (personal), `Cherry Blossom`, `Cream`, `Noir` |
| `plugins.json` + `plugins/` | Plugins instalados y su código: `clipper` (portapapeles/notas), `kaomoji-provider`, `network-manager-vpn`, `polkit-agent`, `privacy-indicator`, `screen-shot-and-record`, `usb-drive-manager` |
| `user-templates.toml` | Plantillas para propagar el tema de Noctalia a otras apps |

**Integración de temas**: al cambiar el colorscheme desde los ajustes de Noctalia (`SUPER + ,`), la shell regenera automáticamente:

- `~/.config/kitty/current-theme.conf` (Kitty lo incluye en su `kitty.conf`).
- `~/.config/hypr/noctalia/noctalia-colors.lua` / `.conf` (colores de Hyprland). Para aplicarlos a los bordes de Hyprland, descomenta el `dofile(...)` del final de `hyprland.lua`.

---

## Actualización del sistema

Con los aliases definidos en zsh (requiere el symlink `~/scripts`):

```bash
update    # copia configuration.nix a /etc/nixos y hace nixos-rebuild switch
updatef   # copia configuration.nix + flake.nix y hace nixos-rebuild switch --flake /etc/nixos
```

O manualmente:

```bash
cd ~/.dotfiles && git pull
sudo cp config/nixos/configuration.nix config/nixos/flake.nix /etc/nixos/
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

Tras cambiar cualquier archivo de `config/hypr/`, recarga la configuración con `hyprctl reload` o cierra y reabre la sesión.
