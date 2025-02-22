#!/bin/zsh
nitrogen --restore
systemctl --user restart opentabletdriver.service
~/.config/polybar/launch_polybar.sh 
~/.config/picom/load_picom.sh 
