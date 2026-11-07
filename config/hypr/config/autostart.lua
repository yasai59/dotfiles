local commands = {
  "noctalia-shell",
  "udiskie",
  "dex -a",
  "clipboard-sync",
  "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
  "fcitx5",
  "xrandr --output DP-2 --primary",
  "hyprctl setcursor Bibata-Modern-Classic 22",
  "qpwgraph -a /home/yasai/Music/mezcla.qpwgraph -m",
  "equibop",
  "kdeconnect-indicator",
}


hl.on("hyprland.start", function ()
	for _, cmd in ipairs(commands) do
		hl.exec_cmd(cmd)
	end
end)
