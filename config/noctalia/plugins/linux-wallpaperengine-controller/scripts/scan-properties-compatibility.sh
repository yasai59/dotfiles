#!/bin/bash

# Scan wallpaper folders and mark `--list-properties` compatibility.
# Args:
#   1: Wallpaper Engine workshop directory (contains wallpaper subdirectories)
# Output:
#   Tab-separated rows: <wallpaper_dir>\t<status>
#   status: 0 = compatible, 1 = failed

dir="$1"
[ -d "$dir" ] || exit 10

find "$dir" -mindepth 1 -maxdepth 1 -type d | sort | while IFS= read -r wallpaper_dir; do
  if linux-wallpaperengine "$wallpaper_dir" --list-properties >/dev/null 2>&1; then
    status=0
  else
    status=1
  fi

  printf '%s\t%s\n' "$wallpaper_dir" "$status"
done
