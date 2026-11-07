#!/usr/bin/env zsh


echo "Copying files... please enter your password"
sudo cp /home/yasai/.dotfiles/config/nixos/configuration.nix /etc/nixos/configuration.nix

echo "==================================================="
echo "                     UPDATING"
echo "==================================================="
sudo nixos-rebuild switch
