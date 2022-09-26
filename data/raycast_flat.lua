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


-- libs
local sin, cos, floor, abs = math.sin, math.cos, math.floor, math.abs

-- constants
local SCREEN_WIDTH = 1280
local SCREEN_HEIGHT = 720
local MOVE_SPEED = 0.5
local ROT_SPEED = 0.05


-- functions
local function Color(r, g, b, a)
  local rr, gg, bb, aa;
  rr = r / 255
  gg = g / 255
  bb = b / 255
  aa = a
  return Graphics.GL_Color(rr, gg, bb, aa)
end

local function draw_bg()
  Graphics.CSurface.GL_DrawRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, Color(0,0,0,1)) -- bg
end

local function dim_color(color, percent)
  color.r = color.r * percent
  color.g = color.g * percent
  color.b = color.b * percent
end

local FPSf_counter = {
  tick = 0,
  oldTime = 0,
  time = 0,
  init = function(self)
    script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
      self.tick = self.tick + 1
    end)
  end,
  show_fpsf = function(self)
    self.oldTime = self.time
    self.time = self.tick
    local frameTime = (self.time - self.oldTime) / (Hyperspace.FPS.SpeedFactor / 16)
    Graphics.freetype.easy_print(16, 1000, 100, "FPSf: " .. frameTime)
  end
}


-- class
local RayCaster = {
  posX = 22, -- x and y start position
  posY = 12,
  dirX = -1, -- initial direction vector
  dirY = 0,
  planeX = 0, -- the 2d raycaster version of camera plane
  planeY = 0.66,

  raycast = function(self) -- raycasting loop, loops through every x 
    for x = 0, SCREEN_WIDTH do
      -- calculate ray position and direction:
      local cameraX = 2 * x / SCREEN_WIDTH - 1 -- x-coordinate in camera space

      local rayDirX = self.dirX + self.planeX * cameraX
      local rayDirY = self.dirY + self.planeY * cameraX
  
      -- which box of the map we're in
      local mapX = floor(self.posX)
      local mapY = floor(self.posY)
  
      -- length of ray from current position to next x or y-side
      local sideDistX
      local sideDistY
      
      -- length of ray from one x or y-side to next x or y-side
      local deltaDistX = (rayDirX == 0) and 1e30 or abs(1 / rayDirX)
      local deltaDistY = (rayDirY == 0) and 1e30 or abs(1 / rayDirY)
  
      local perpWallDist
      
      -- what direction to step in x or y-direction (either +1 or -1)
      local stepX
      local stepY
  
      -- was there a wall hit?
      local hit = 0
      -- was a lighted or a non-lighted wall hit?
      local side
  
      if rayDirX < 0 then
        stepX = -1
        sideDistX = (self.posX - mapX) * deltaDistX
      else
        stepX = 1
        sideDistX = (mapX + 1.0 - self.posX) * deltaDistX
      end
  
      if rayDirY < 0 then
        stepY = -1
        sideDistY = (self.posY - mapY) * deltaDistY
      else
        stepY = 1
        sideDistY = (mapY + 1.0 - self.posY) * deltaDistY
      end
  
      -- perform DDA
      while hit == 0 do
        -- jump to next map square, OR in x-direction, OR in y-direction
        if sideDistX < sideDistY then
          sideDistX = sideDistX + deltaDistX
          mapX = mapX + stepX
          side = 0
        else
          sideDistY = sideDistY + deltaDistY
          mapY = mapY + stepY
          side = 1
        end
        
        -- check if ray has hit a wall
        if map[mapX + 1][mapY + 1] > 0 then
          hit = 1
        end
      end
  
      -- calculate distance projected on camera direction
      if side == 0 then
        perpWallDist = sideDistX - deltaDistX
      else
        perpWallDist = sideDistY - deltaDistY
      end
      
      -- calculate height of line to draw on screen
      local lineHight = floor(SCREEN_HEIGHT / perpWallDist)
      
      -- calculate lowest and highest pixel to fill in current stripe
      local drawStart = -lineHight / 2 + SCREEN_HEIGHT / 2
      if drawStart < 0 then
        drawStart = 0
      end
  
      local drawEnd = lineHight / 2 + SCREEN_HEIGHT / 2
      if drawEnd >= SCREEN_HEIGHT then
        drawEnd = SCREEN_HEIGHT - 1
      end
  
      -- choose wall color
      local color
      if map[mapX + 1][mapY + 1] == 1 then
        color = Color(255, 0, 0, 1) -- red
      elseif map[mapX + 1][mapY + 1] == 2 then
        color = Color(0, 255, 0, 1) -- green
      elseif map[mapX + 1][mapY + 1] == 3 then
        color = Color(0, 0, 255, 1) -- blue
      elseif map[mapX + 1][mapY + 1] == 4 then
        color = Color(255, 255, 0, 1) -- yellow
      else
        color = Color(255, 255, 255, 1) -- white
      end
  
      -- give x and y sides different brightness
      if side == 0 then
        dim_color(color, 0.5)
      end
      
      -- draw the pixels of the stripe as a vertical line
      Graphics.CSurface.GL_DrawLine(
        x, drawStart, x, drawEnd, 2, color
      )
    end
  end,

  move = function(self, direction)
    local new_dirX = self.dirX * MOVE_SPEED
    local new_dirY = self.dirY * MOVE_SPEED

    if direction == "fw" then
      local isWallInFrontX = map[floor(self.posX + self.dirX * MOVE_SPEED) + 1][floor(self.posY) + 1] ~= 0
      local isWallInFrontY = map[floor(self.posX) + 1][floor(self.posY + self.dirY * MOVE_SPEED) + 1] ~= 0
      if not isWallInFrontX then
        self.posX = self.posX + new_dirX
      end
      if not isWallInFrontY then
        self.posY = self.posY + new_dirY
      end
    end

    if direction == "bw" then
      local isWallInFrontX = map[floor(self.posX - self.dirX * MOVE_SPEED) + 1][floor(self.posY) + 1] ~= 0
      local isWallInFrontY = map[floor(self.posX) + 1][floor(self.posY - self.dirY * MOVE_SPEED) + 1] ~= 0
      if not isWallInFrontX then
        self.posX = self.posX - new_dirX
      end
      if not isWallInFrontY then
        self.posY = self.posY - new_dirY
      end
    end
  end,

  turn = function(self, dir)
    local oldDirX = self.dirX
    local oldPlaneX = self.planeX

    local actual_rotSpeed = ROT_SPEED
    if dir == "right" then
      actual_rotSpeed = -ROT_SPEED
    end

    self.dirX = self.dirX * cos(actual_rotSpeed) - self.dirY * sin(actual_rotSpeed)
    self.dirY = oldDirX * sin(actual_rotSpeed) + self.dirY * cos(actual_rotSpeed)
    self.planeX = self.planeX * cos(actual_rotSpeed) - self.planeY * sin(actual_rotSpeed)
    self.planeY = oldPlaneX * sin(actual_rotSpeed) + self.planeY * cos(actual_rotSpeed)
  end,
}

-- start script stuff
local should_draw = false

script.on_game_event("CANVAS_INIT", false, function()
  should_draw = true
end)

script.on_game_event("CANVAS_END", false, function()
  should_draw = false
end)

FPSf_counter:init()

script.on_render_event(Defines.RenderEvents.LAYER_PLAYER,
function()end,
function()
  if should_draw then
    draw_bg()
    FPSf_counter:show_fpsf()
    RayCaster:raycast()
  end
end)

script.on_game_event("STICK1_UP", false, function() -- forward
  RayCaster:move("fw")
end)

script.on_game_event("STICK1_DOWN", false, function() -- backward
  RayCaster:move("bw")
end)

script.on_game_event("STICK1_LEFT", false, function() -- turn left
  RayCaster:turn("left")
end)

script.on_game_event("STICK1_RIGHT", false, function() -- turn right
  RayCaster:turn("right")
end)