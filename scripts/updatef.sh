#!/usr/bin/env zsh
#
# updatef: actualiza los inputs del flake (nixpkgs, noctalia, zen-browser,
#          hypr-kdeconnect-fix...), aplica la configuración a /etc/nixos
#          y reconstruye NixOS.
#
#          El flake.lock actualizado queda versionado en las dotfiles:
#          tras el rebuild, haz `git add config/nixos/flake.lock && git commit`.

set -e

DOTFILES_NIXOS="$HOME/.dotfiles/config/nixos"
ETC_NIXOS="/etc/nixos"

echo "Updating flake inputs..."
( cd "$DOTFILES_NIXOS" && nix flake update )

echo "Copiando configuración a /etc/nixos... please enter your password"
sudo cp "$DOTFILES_NIXOS/configuration.nix" "$ETC_NIXOS/configuration.nix"
sudo cp "$DOTFILES_NIXOS/flake.nix"         "$ETC_NIXOS/flake.nix"
sudo cp "$DOTFILES_NIXOS/flake.lock"        "$ETC_NIXOS/flake.lock"

echo "==================================================="
echo "                     UPDATING"
echo "==================================================="
sudo nixos-rebuild switch --flake "$ETC_NIXOS#nixos"
