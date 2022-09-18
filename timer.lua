local elapsed = 0
local shouldTime = false
local shouldReset = false
local shouldShow = false

script.on_game_event("TIMER_START", false, function()
  shouldTime = true
  shouldReset = false
end)

script.on_game_event("TIMER_PAUSE", false, function()
  shouldTime = false
end)

script.on_game_event("TIMER_RESET", false, function()
  shouldReset = true
end)

script.on_game_event("LUATIMER_TOGGLE_ON", false, function()
  shouldShow = true
end)

script.on_game_event("LUATIMER_TOGGLE_OFF", false, function()
  shouldShow = false
end)

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
  local SPEED_FACTOR = Hyperspace.FPS.SpeedFactor / 16
  if shouldTime and not Hyperspace.Global.GetInstance():GetCApp().world.space.gamePaused then
    elapsed = elapsed + SPEED_FACTOR
  end
  if shouldReset then
    elapsed = 0
    shouldReset = false
  end
end)

script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, function() end, function()
  if shouldShow then
    Graphics.freetype.easy_print(16, 600, 150, string.format("%.1f", elapsed) .. ' SF')
  end
end)

script.on_init(function()
  if Hyperspace.ships.player:HasEquipment("var_timer_enabled") then
    shouldShow = true
  end
end)