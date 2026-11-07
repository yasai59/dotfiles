#!/usr/bin/env zsh


echo "Copying files... please enter your password"

sudo cp /home/yasai/.dotfiles/config/nixos/configuration.nix /etc/nixos/configuration.nix
sudo cp /home/yasai/.dotfiles/config/nixos/flake.nix /etc/nixos/flake.nix

echo "==================================================="
echo "                     UPDATING"
echo "==================================================="
sudo nixos-rebuild switch --flake /etc/nixos
