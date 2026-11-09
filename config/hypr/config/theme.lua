hl.config({
  general = {
    gaps_in = 2,
    gaps_out = 10,
    border_size = 2,
    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle",
    col = {
      active_border = 0xaaffffff,
      inactive_border = 0xaa595959,
    }
  },
  decoration = {
    rounding = 4,
    active_opacity = 1.0,
    inactive_opacity = 0.95,
    blur = {
      enabled = true,
      size = 4,
      passes = 2,
      vibrancy = 0.3,
    }
  },
  animations = {
    enabled = true,
  }
})
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 2,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2,  bezier = "default",  style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 2,  bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 2,  bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 2,  bezier = "default" })

-- Noctalia v5: blur en sus superficies (barra, paneles, dock, notificaciones)
-- y sin las animaciones de capa de Hyprland para que no interfieran con las suyas
hl.layer_rule({
  name = "noctalia",
  match = {
    namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
  },
  no_anim = true,
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})
