# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:
let
  hypr-kdeconnect-fix = pkgs.stdenv.mkDerivation {
    pname = "hypr-kdeconnect-fix";
    version = "0-unstable-2026-09-07";
    src = inputs.hypr-kdeconnect-fix;

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
      wayland-scanner
    ];

    buildInputs = with pkgs; [
      qt6.qtbase
      libei              # incluye libeis (libeis-1.0.pc)
      libxkbcommon
      wayland
    ];

    cmakeBuildType = "Release";
    dontWrapQtApps = true;
    doCheck = true;      # ejecuta los tests del proyecto al compilar

    meta = {
      description = "RemoteDesktop portal bridge for KDE Connect on Hyprland";
      homepage = "https://github.com/gfhdhytghd/hypr-kdeconnect-fix";
      license = pkgs.lib.licenses.mit;
      platforms = pkgs.lib.platforms.linux;
      mainProgram = "hypr-kdeconnect-portal";
    };
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];
  boot.kernelParams = [ "nvidia-drm.modeset=1" "nvidia-drm.fbdev=1" ];
  # boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  networking.hostName = "nixos"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."yasai" = {
    isNormalUser = true;
    description = "yasai";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  services.usbmuxd.enable = true;

  security.polkit.enable = true;


  # -------------------------------------------------------
  # PACKAGES
  # -------------------------------------------------------
  environment.systemPackages = with pkgs; [
     # wm and general utilities
     wl-clipboard
     grim
     slurp
     cliphist
     wl-clip-persist
     pavucontrol
     dex
     xrandr
     libreoffice-qt
     qpwgraph
     uxplay
     file-roller
     openfortivpn
     proton-pass

     # terminal
     kitty
     vim
     neovim
     wget
     git
     protonup-rs
     zsh
     fastfetch
     eza
     unzip
     ripgrep
     ifuse

     # GUI apps
     firefox
     obs-studio
     equibop
     prismlauncher
     kdePackages.kdenlive
     vlc
     audacity
     qbittorrent
     feishin
     slack

     # development
     gh
     uv
     gcc
     opencode
     nodejs_26
     bun
     patchelf
     python3
     gnumake
     tree-sitter
     dbeaver-bin
     lmstudio
     jdk

     # Haskell
     ghc
     haskell-language-server
     cabal-install

     # theme
     orchis-theme
     papirus-icon-theme
     bibata-cursors
     nwg-look
  
     # flakes
     inputs.noctalia.packages.${pkgs.system}.default # <-- Noctalia shell
     inputs.zen-browser.packages.${pkgs.system}.default # <-- Zen Browser
  ];

  environment.pathsToLink = [ "/libexec" ];
  
  fonts.packages = with pkgs; [
    nerd-fonts.fira-mono
    nerd-fonts.fira-code
    nerd-fonts.caskaydia-cove
    noto-fonts-cjk-sans     
    noto-fonts-cjk-serif   
    ipafont                
    noto-fonts             
    noto-fonts-color-emoji  
    liberation_ttf     
    corefonts         
    dejavu_fonts      
    ubuntu-classic 
  ];

  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
    ];
  };

  programs.xfconf.enable = true;
  environment.localBinInPath = true;
  programs.kdeconnect.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
        libffi
        glibc
        # dependencias para desarrollar con electron
        glib
        nspr
        nss
        atk
        cups
        dbus
        cairo
        gtk3
        pango
        libX11
        libXcomposite
        libXdamage
        libXext
        libXfixes
        libXrandr
        mesa
        libgbm
        expat
        libxcb
        libxkbcommon
        alsa-lib
        libGL
    ];
  };

  # -------------------------------------------------------
  # DISKS
  # -------------------------------------------------------
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  # SSD 2 (NTFS)
  fileSystems."/media/SSD2" = {
    device = "/dev/disk/by-uuid/D09EE6989EE6767E";
    fsType = "ntfs-3g"; 
    options = [ "nofail" "rw" "uid=1000" "gid=100" "x-gvfs-show" ]; 
  };

  # Data 1 TB HDD (NTFS)
  fileSystems."/media/HDD1TB" = {
    device = "/dev/disk/by-uuid/FEF26A16F269D405";
    fsType = "ntfs-3g"; 
    options = [ "nofail" "rw" "uid=1000" "gid=100" "x-gvfs-show" ]; 
  };

  # --------------------------------------------------------
  # WINDOW MANAGER
  # --------------------------------------------------------
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };
  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gtk 
      pkgs.xdg-desktop-portal-hyprland 
      hypr-kdeconnect-fix
    ];
    config = {
      hyprland = {
        default = [ "hyprland" "gtk" ];
    "org.freedesktop.impl.portal.RemoteDesktop" = "hypr-kdeconnect";
      };
      common = {
        default = [ "gtk" ];
      };
    };
  };
  programs.dconf.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # --------------------------------------------------------
  # GAMING AND GRAPHICS
  # --------------------------------------------------------
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;
  programs.steam.gamescopeSession.enable = true;

  # ---------------------------------------------------------
  # MISC
  # ---------------------------------------------------------
  programs.firefox.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
extraConfig.pipewire."99-mezcla-virtual" = {
    "context.modules" = [
      {
        name = "libpipewire-module-loopback";
        args = {
          "node.description" = "Mezcla_Piano_Micro";
          "node.name" = "mezcla_piano_micro";
      "playback.props" = {
        "media.class" = "Audio/Source";
      };
        };
      }
    ];
  };
  };
# Habilitar el descubrimiento de red para AirPlay
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Permite resolver dominios .local
    publish = {
      enable = true;
      userServices = true;
    };
  };

  # UxPlay necesita ciertos puertos abiertos en el firewall para comunicarse con el iPhone
  networking.firewall.allowedTCPPorts = [ 7000 7001 7100 ];
  networking.firewall.allowedUDPPorts = [ 5353 6000 6001 7011 ];

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    # fastfetch al abrir la terminal o hyprland si iniciamos desde la primera tty
    interactiveShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ]; then
        exec start-hyprland
    else
        fastfetch
    fi
    '';

    shellAliases = {
      updatef = "/home/yasai/scripts/updatef.sh";
      update = "/home/yasai/scripts/update.sh";
      vim = "nvim";
      ls = "eza --icons --color=always";
      ll = "eza -lh --icons --color=always"; # Formato lista con detalles
      la = "eza -lah --icons --color=always"; # Lista con archivos ocultos
      tree = "eza --tree --icons"; # eza también incluye vista de árbol!
      vpn = "/home/yasai/scripts/vpn.sh";
    };

    ohMyZsh = {
      enable = true;
      plugins = ["git" "sudo"]; 
      theme = "kafeitu";
    };
  };

  # experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05"; # Did you read the comment?

}
