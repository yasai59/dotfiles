-- Definición de variables locales
local mainMod = "SUPER" -- Define la tecla "Windows" como modificador principal
local terminal = "kitty"
local fileManager = "thunar"
local ipc = "qs -c noctalia-shell ipc call"

-- Capturas de pantalla
local ss_region = "grimblast --freeze copy area"
-- hl.bind("ALT + SHIFT + S", hl.dsp.exec_cmd(ss_region))
hl.bind("ALT + SHIFT + S", hl.dsp.exec_cmd(ipc .. " plugin:screen-shot-and-record screenshot"))

-- Atajos de ejemplo comunes
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.window.close()) -- killactive ahora es close()
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" })) -- Sintaxis correcta de float
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(ipc .. " launcher toggle"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo({ action = "toggle" })) -- pseudo pertenece a window.
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(ipc .. " launcher clipboard"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(ipc .. " settings toggle"))
hl.bind("ALT + SHIFT + L", hl.dsp.exec_cmd(ipc .. " lockScreen lock"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(ipc .. " sessionMenu show"))
-- hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- Mensaje de layout si usas dwindle

-- Mover el foco con las teclas HJKL (Estilo Vim)
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }))

-- Cambiar de área de trabajo (Workspaces) del 1 al 9
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
end

-- Mover la ventana activa a un área de trabajo con mainMod + SHIFT + [0-9]
for i = 1, 9 do
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))

-- Ejemplo de área de trabajo especial (Scratchpad - Comentado)
-- hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Control de volumen usando las teclas multimedia
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))

-- Navegar por las áreas de trabajo con la rueda del ratón (mainMod + Scroll)
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mover y redimensionar ventanas manteniendo presionados los botones del ratón (bindm antiguo)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Mover ventanas utilizando el teclado (SUPER + SHIFT + HJKL)
hl.bind("SUPER + SHIFT + h", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + l", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + k", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + j", hl.dsp.window.move({ direction = "d" }))

-- Pantalla completa (fullscreen)
hl.bind(mainMod .. " + Tab", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ action = "toggle" }))

-- Aplicaciones personalizadas
hl.bind("ALT + SHIFT + F", hl.dsp.exec_cmd("helium-browser"))
hl.bind("ALT + SHIFT + V", hl.dsp.exec_cmd("code"))
