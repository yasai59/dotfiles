#!/bin/zsh
# Start Up commands (executed even with i3 reloads)
alernating_layouts.py
systemctl --user restart opentabletdriver.service
~/.config/polybar/launch_polybar.sh
~/.config/picom/load_picom.sh
