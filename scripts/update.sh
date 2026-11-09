#!/usr/bin/env zsh
#
# update: aplica la configuración actual de las dotfiles a /etc/nixos
#         y reconstruye NixOS (SIN actualizar los inputs del flake).
#
#         Para actualizar también los inputs (nixpkgs, noctalia, zen...)
#         usa `updatef`.

set -e

DOTFILES_NIXOS="$HOME/.dotfiles/config/nixos"
ETC_NIXOS="/etc/nixos"

echo "Copiando configuración a /etc/nixos... please enter your password"
sudo cp "$DOTFILES_NIXOS/configuration.nix" "$ETC_NIXOS/configuration.nix"
sudo cp "$DOTFILES_NIXOS/flake.nix"         "$ETC_NIXOS/flake.nix"
sudo cp "$DOTFILES_NIXOS/flake.lock"        "$ETC_NIXOS/flake.lock"

echo "==================================================="
echo "                     UPDATING"
echo "==================================================="
sudo nixos-rebuild switch --flake "$ETC_NIXOS#nixos"
