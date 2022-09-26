local map = {
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,2,2,2,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1},
  {1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,3,0,0,0,3,0,0,0,1},
  {1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,2,2,0,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,4,0,0,0,0,5,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,4,0,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
};



local posX = 22
local posY = 12
local dirX = -1
local dirY = 0
local planeX = 0
local planeY = 0.66

local time = 0
local oldTime = 0

local W = 1280
local H = 720

local Color = mods.libs.SG.SimpleSprite.colorFactory
local SimpleShape = mods.libs.SG.SimpleShape
-- local RGB = {
--   RED = Color(255, 0, 0, 1),
--   GREEN = Color(0, 255, 0, 1),
--   BLUE = Color(0, 0, 255, 1),
--   YELLOW = Color(255, 255, 0, 1),
--   WHITE = Color(255, 255, 255, 1),
-- }

local Tick = 0
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
  Tick = Tick + 1
end)

local moveSpeed = 0.1
local rotSpeed = 0.05

local should_draw = false
script.on_game_event("CANVAS_INIT", false, function()
  should_draw = true
end)

script.on_game_event("CANVAS_END", false, function()
  should_draw = false
end)

script.on_render_event(Defines.RenderEvents.LAYER_PLAYER,
function()end,
function()
  if not should_draw then return end

  Graphics.CSurface.GL_DrawRect(0, 0, W, H, Color(0,0,0,1)) -- bg

  for x = 0, W do
    local cameraX = 2 * x / W - 1
    local rayDirX = dirX + planeX * cameraX
    local rayDirY = dirY + planeY * cameraX

    local mapX = math.floor(posX)
    local mapY = math.floor(posY)

    local sideDistX
    local sideDistY

    local deltaDistX = (rayDirX == 0) and 1e30 or math.abs(1 / rayDirX)
    local deltaDistY = (rayDirY == 0) and 1e30 or math.abs(1 / rayDirY)

    local perpWallDist

    local stepX
    local stepY

    local hit = 0
    local side

    if rayDirX < 0 then
      stepX = -1
      sideDistX = (posX - mapX) * deltaDistX
    else
      stepX = 1
      sideDistX = (mapX + 1.0 - posX) * deltaDistX
    end

    if rayDirY < 0 then
      stepY = -1
      sideDistY = (posY - mapY) * deltaDistY
    else
      stepY = 1
      sideDistY = (mapY + 1.0 - posY) * deltaDistY
    end

    while hit == 0 do
      if sideDistX < sideDistY then
        sideDistX = sideDistX + deltaDistX
        mapX = mapX + stepX
        side = 0
      else
        sideDistY = sideDistY + deltaDistY
        mapY = mapY + stepY
        side = 1
      end

      if map[mapX + 1][mapY + 1] > 0 then
        hit = 1
      end
    end

    if side == 0 then
      perpWallDist = sideDistX - deltaDistX
    else
      perpWallDist = sideDistY - deltaDistY
    end
    
    local lineHight = math.floor(H / perpWallDist)

    local drawStart = -lineHight / 2 + H / 2
    if drawStart < 0 then
      drawStart = 0
    end

    local drawEnd = lineHight / 2 + H / 2
    if drawEnd >= H then
      drawEnd = H - 1
    end

    local color
    if map[mapX + 1][mapY + 1] == 1 then
      color = Color(255, 0, 0, 1)
    elseif map[mapX + 1][mapY + 1] == 2 then
      color = Color(0, 255, 0, 1)
    elseif map[mapX + 1][mapY + 1] == 3 then
      color = Color(0, 0, 255, 1)
    elseif map[mapX + 1][mapY + 1] == 4 then
      color = Color(255, 255, 0, 1)
    else
      color = Color(255, 255, 255, 1)
    end

    if side == 0 and color then
      color.r = color.r / 2
      color.g = color.g / 2
      color.b = color.b / 2
    end

    -- Graphics.CSurface.GL_BlitImagePartial(
    --   Hyperspace.Resources:GetImageId('scratch.png'),
    --   x, drawStart, 1, drawEnd - drawStart, math.floor(Tick % 50), math.floor(Tick % 50), 0, 50, 1, color, false
    -- )

    -- Graphics.CSurface.GL_DrawLine(
    --   x, drawStart, x, drawEnd, 2, color
    -- )
    -- Graphics.freetype.easy_print(16, 1000, 150, 'x  ' .. x)
    -- Graphics.freetype.easy_print(16, 1000, 200, 'drawStart  ' .. drawStart)
    -- Graphics.freetype.easy_print(16, 1000, 250, 'drawEnd  ' .. drawEnd)
    -- Graphics.freetype.easy_print(16, 1000, 300, 'color.a' .. color.a)
  end

  oldTime = time
  time = Tick
  local frameTime = (time - oldTime) / (Hyperspace.FPS.SpeedFactor / 16)

  Graphics.freetype.easy_print(16, 1000, 100, "FPSf: " .. frameTime)

  -- moveSpeed = frameTime * 5
  -- rotSpeed = frameTime * 3

end)


script.on_game_event("STICK1_UP", false, function() -- forward
  if map[math.floor(posX + dirX * moveSpeed) + 1][math.floor(posY) + 1] == 0 then
    posX = posX + dirX * moveSpeed
  end
  if map[math.floor(posX) + 1][math.floor(posY + dirY * moveSpeed) + 1] == 0 then
    posY = posY + dirY * moveSpeed
  end
end)

script.on_game_event("STICK1_DOWN", false, function() -- backward
  if map[math.floor(posX - dirX * moveSpeed) + 1][math.floor(posY) + 1] == 0 then
    posX = posX - dirX * moveSpeed
  end
  if map[math.floor(posX) + 1][math.floor(posY - dirY * moveSpeed) + 1] == 0 then
    posY = posY - dirY * moveSpeed
  end
end)

script.on_game_event("STICK1_RIGHT", false, function()
  local oldDirX = dirX
  dirX = dirX * math.cos(-rotSpeed) - dirY * math.sin(-rotSpeed)
  dirY = oldDirX * math.sin(-rotSpeed) + dirY * math.cos(-rotSpeed)
  local oldPlaneX = planeX
  planeX = planeX * math.cos(-rotSpeed) - planeY * math.sin(-rotSpeed)
  planeY = oldPlaneX * math.sin(-rotSpeed) + planeY * math.cos(-rotSpeed)
end)

script.on_game_event("STICK1_LEFT", false, function()
  local oldDirX = dirX
  dirX = dirX * math.cos(rotSpeed) - dirY * math.sin(rotSpeed)
  dirY = oldDirX * math.sin(rotSpeed) + dirY * math.cos(rotSpeed)
  local oldPlaneX = planeX
  planeX = planeX * math.cos(rotSpeed) - planeY * math.sin(rotSpeed)
  planeY = oldPlaneX * math.sin(rotSpeed) + planeY * math.cos(rotSpeed)
end)


