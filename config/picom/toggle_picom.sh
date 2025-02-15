#!/bin/zsh

if pgrep -x "picom" > /dev/null 
then
	killall picom
	dunstify "Compositor off"
else
	~/.config/picom/load_picom.sh
	dunstify "Compositor on"
fi
