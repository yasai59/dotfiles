#!/bin/zsh
nitrogen --restore
systemctl --user restart opentabletdriver.service
~/.config/polybar/launch_polybar.sh 
flameshot
udiskie -s
