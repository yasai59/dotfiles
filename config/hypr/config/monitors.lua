
-- Monitor central 
hl.monitor({
  output = "DP-2",
  mode = "2560x1440@165",
  position = "0x0",
  scale = 1,
})

-- Monitor derecho
hl.monitor({
  output = "DP-1",
  mode = "1920x1080@144",
  position = "2560x190",
  scale = 1,
})

-- monitor cama
hl.monitor({
  output = "HDMI-A-1",
  mode = "2560x1440@144",
  position = "10000x0", 
  scale = 1,
})
-- workspaces 
hl.workspace_rule({
  workspace = "1",
  monitor = "DP-2",
  persistent = true,
  default = true,
})

hl.workspace_rule({
  workspace = "2",
  monitor = "DP-2",
  persistent = true,
})

hl.workspace_rule({
  workspace = "3",
  monitor = "DP-2",
  persistent = true,
})

hl.workspace_rule({
  workspace = "4",
  monitor = "DP-2",
  persistent = true,
})

hl.workspace_rule({
  workspace = "5",
  monitor = "DP-2",
  persistent = true,
})

hl.workspace_rule({
  workspace = "6",
  monitor = "DP-1",
  persistent = true,
})

hl.workspace_rule({
  workspace = "7",
  monitor = "DP-1",
  persistent = true,
})

hl.workspace_rule({
  workspace = "8",
  monitor = "HDMI-A-1",
  persistent = true,
})

hl.workspace_rule({
  workspace = "9",
  monitor = "HDMI-A-1",
  persistent = true,
})
