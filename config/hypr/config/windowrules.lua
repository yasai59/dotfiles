hl.window_rule({
  match = {
    class = "equibop"
  },
  workspace = "6",
  no_initial_focus = true,
})

hl.window_rule({
  match = {
    class = "steam"
  },
  workspace = "5",
  no_initial_focus = true
})

-- Noctalia v5: su ventana de ajustes (dev.noctalia.Noctalia) como flotante
hl.window_rule({
  match = { class = "dev.noctalia.Noctalia" },
  float = true,
  size = { 1080, 920 },
})
