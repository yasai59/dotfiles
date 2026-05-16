#!/bin/bash

# Scan wallpaper folders and extract metadata for panel listing.
# Args:
#   1: Wallpaper Engine workshop directory (contains wallpaper subdirectories)
# Output:
#   Tab-separated rows:
#   <path>\t<name>\t<thumb>\t<motion>\t<dynamic>\t<id>\t<type>\t<resolution>\t<bytes>:<mtime>

set -u

if [ "$#" -lt 1 ]; then
  exit 10
fi

extract_resolution_from_name() {
  local source_name="$1"
  local res=""

  res=$(printf '%s' "$source_name" | grep -oE '[0-9]{3,4}x[0-9]{3,4}' | head -n 1)
  if [ -z "$res" ]; then printf '%s' "$source_name" | grep -qi '4k' && res='3840x2160' || true; fi
  if [ -z "$res" ]; then printf '%s' "$source_name" | grep -qi '2k' && res='2560x1440' || true; fi
  if [ -z "$res" ]; then printf '%s' "$source_name" | grep -qi '1080p' && res='1920x1080' || true; fi
  if [ -z "$res" ]; then printf '%s' "$source_name" | grep -qi '720p' && res='1280x720' || true; fi

  printf '%s' "$res"
}

dir="${1:-}"
[ -d "$dir" ] || exit 10

find "$dir" -mindepth 1 -maxdepth 1 -type d | sort | while IFS= read -r d; do
  id=$(basename "$d")
  name="$id"
  dynamic=0
  type=unknown
  resolution=unknown

  if [ -f "$d/project.json" ]; then
    if command -v jq >/dev/null 2>&1; then
      title=$(jq -r '.title // empty' "$d/project.json" 2>/dev/null || true)
      if [ -n "$title" ]; then name="$title"; fi

      dtype=$(jq -r '.type // empty' "$d/project.json" 2>/dev/null || true)
      if [ -n "$dtype" ]; then type=$(printf '%s' "$dtype" | tr '[:upper:]' '[:lower:]'); fi

      case "$type" in
        video|web)
          dynamic=1
          ;;
      esac
    else
      title=$(sed -n 's/^[[:space:]]*"title"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' "$d/project.json" | head -n 1)
      if [ -n "$title" ]; then name="$title"; fi

      dtype=$(sed -n 's/^[[:space:]]*"type"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' "$d/project.json" | tail -n 1)
      if [ -n "$dtype" ]; then type=$(printf '%s' "$dtype" | tr '[:upper:]' '[:lower:]'); fi

      grep -qi '"type"[[:space:]]*:[[:space:]]*"\(video\|web\)"' "$d/project.json" && dynamic=1 || true
    fi

    res=$(extract_resolution_from_name "$name")
    if [ -n "$res" ]; then resolution="$res"; fi
  fi

  thumb=""
  motion=""
  for f in preview.jpg preview.png preview.jpeg screenshot.jpg screenshot.png screenshot.jpeg; do
    if [ -f "$d/$f" ]; then thumb="$d/$f"; break; fi
  done
  for m in preview.gif preview.webm preview.mp4; do
    if [ -f "$d/$m" ]; then motion="$d/$m"; dynamic=1; break; fi
  done

  bytes=$(du -sb "$d" | awk '{print $1}')
  mtime=$(stat -c %Y "$d")
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$d" "$name" "$thumb" "$motion" "$dynamic" "$id" "$type" "$resolution" "$bytes:$mtime"
done
