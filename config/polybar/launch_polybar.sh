#!/bin/zsh

killall polybar

monitores=(HDMI-0 DP-0)

MONITOR=DP-2 polybar --reload primary &

if type "xrandr"; then
  for m in "${monitores[@]}"; do
    MONITOR=$m polybar --reload general &
  done
else
  polybar --reload primary &
fi
