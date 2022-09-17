-- libs
local SimpleShape = mods.libs.SG.SimpleShape
local SimpleSprite = mods.libs.SG.SimpleSprite

-- constants
local WIDTH = 690
local HEIGHT = 390

-- helper functions
local function extend(oldTable)
  local newTable = {}
  for k,v in pairs(oldTable) do
    newTable[k] = v
  end
  return newTable
end


---@class Moveable
local Moveable = {
  x_pos = 0.0,
  y_pos = 0.0,
  speed_x = 0.0,
  speed_y = 0.0,
  width = 0.0,
  height = 0.0,

  move = function(self)
    self.x_pos = self.x_pos + self.speed_x
    self.y_pos = self.y_pos + self.speed_y    
  end,

  left_dist = function(self)
    return self.x_pos - self.width / 2
  end,

  right_dist = function(self)
    return self.x_pos + self.width / 2
  end,

  top_dist = function(self)
    return self.y_pos - self.height / 2
  end,

  bottom_dist = function(self)
    return self.y_pos + self.height / 2
  end
}

---@class Ball : Moveable
local Ball = {
  color = SimpleShape.colorFactory("ff0000ff"),

  new = function(self, initX, initY)
    local tempBall = extend(Moveable)
    tempBall.x_pos = initX
    tempBall.y_pos = initY
    tempBall.width = 15
    tempBall.height = 15
    return setmetatable(tempBall, {__index = self})
  end,

  display = function(self)
    SimpleShape:new('rect')
               :show({Xalign = self.x_pos - 345, -- offset to move 0,0 to the top left corner X: 690 / 2, Y: -390 / 2 - 50
                      Yalign = self.y_pos - 245, 
                      width = self.width, 
                      height = self.height, 
                      color = self.color
                    })
  end,

  collision_check = function(self)
    if self:top_dist() <= 0 then
      self.speed_y = -self.speed_y
    end
    if self:bottom_dist() >= HEIGHT then
      self.speed_y = -self.speed_y
    end
  end,

  win_check = function(self)
    if self:left_dist() <= 0 then
      self.x_pos = WIDTH / 2
      self.y_pos = HEIGHT / 2
      return 1
    end
    if self:right_dist() >= WIDTH then
      self.x_pos = WIDTH / 2
      self.y_pos = HEIGHT / 2
      return 2
    end
    return 0
  end
}

---@class Paddle : Moveable
local Paddle = {
  color = SimpleShape.colorFactory("0000ffff"),

  new = function(self, intiX, initY)
    local tempPaddle = extend(Moveable)
    tempPaddle.x_pos = intiX
    tempPaddle.y_pos = initY
    tempPaddle.width = 12
    tempPaddle.height = 90
    return setmetatable(tempPaddle, {__index = self})
  end,

  display = function(self)
    SimpleShape:new('rect')
               :show({Xalign = self.x_pos - 345,
                      Yalign = self.y_pos - 245, 
                      width = self.width, 
                      height = self.height, 
                      color = self.color
                    })
  end,

  at_edge_check = function(self)
    if self:top_dist() <= 0 then
      self.y_pos = self.height / 2
    end
    if self:bottom_dist() >= HEIGHT then
      self.y_pos = HEIGHT - self.height / 2
    end
  end
}


-- "global" variables
local should_run = false
local should_draw = false

local ball = Ball:new(345, 195)
local paddle1 = Paddle:new(10, 195)
local paddle2 = Paddle:new(680, 195)

local score1 = 0
local score2 = 0

local function draw_bg()
  if should_draw then
    SimpleShape:new('rect')
               :show({
                      width = 690, 
                      height = 390, 
                      Yalign = -50, 
                      color = SimpleShape.colorFactory("ffffffff")
                     })
  end
end

local function setup()
  if not should_run then return end

  if should_run then
    ball.speed_x = 0.1
    local randY = SimpleSprite.randint(-0.1, 0.1) * 0.1
    log(tostring(randY))
    ball.speed_y = randY == 0 and 0.2 or randY;
    should_run = false
  end
end


local function render()
  if should_draw then
    ball:move()
    ball:display()
    ball:collision_check()

    paddle1:move()
    paddle1:display()
    paddle1:at_edge_check()
    
    paddle2:move()
    paddle2:display()
    paddle2:at_edge_check()

    if ball:left_dist() < paddle1:right_dist() and ball.y_pos > paddle1:top_dist() and ball.y_pos < paddle1:bottom_dist() then
      ball.speed_x = -ball.speed_x
      ball.speed_y = -ball.speed_y
    end
    if ball:right_dist() > paddle2:left_dist() and ball.y_pos > paddle2:top_dist() and ball.y_pos < paddle2:bottom_dist() then
      ball.speed_x = -ball.speed_x
      ball.speed_y = -ball.speed_y
    end

    local win = ball:win_check()
    if win == 1 then
      score1 = score1 + 1
      should_run = true
    elseif win == 2 then
      score2 = score2 + 1
      should_run = true      
    end

    Graphics.freetype.easy_print(16, 550, 150, string.format("%i", score1) .. ' Pts')
    Graphics.freetype.easy_print(16, 750, 150, string.format("%i", score2) .. ' Pts')

    if score1 == 3 or score2 == 3 then
      should_draw = false
      Graphics.freetype.easy_print(20, 400, 200, 'Game Over, ' .. (score1 == 3 and 'Player 1' or 'Player 2') .. ' Wins!')
    end
  end
end

script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, function()end, function()
  draw_bg()
  setup()
  render()
end)

script.on_game_event("PLAY_PONG", false, function()
  should_draw = true
end)

script.on_game_event("PONG_START", false, function()
  should_run = true
end)

script.on_game_event("PONG_P1_PADDLE_UP", false, function()
  paddle1.y_pos = paddle1.y_pos + 10
end)

script.on_game_event("PONG_P1_PADDLE_DOWN", false, function()
  paddle1.y_pos = paddle1.y_pos - 10
end)

script.on_game_event("PONG_P2_PADDLE_UP", false, function()
  paddle2.y_pos = paddle2.y_pos + 10
end)

script.on_game_event("PONG_P2_PADDLE_DOWN", false, function()
  paddle2.y_pos = paddle2.y_pos - 10
end)


-- local Game = {

--   PADDLE_SIZE = {12, 95},
--   BALL_SIZE = {15, 15},
--   PLAY_AREA_SIZE = {690, 390},
--   BALL_START_POS = {345, 195},
  
--   ball_x_vel = 0,
--   ball_y_vel = 0,

--   draw_bg = function(self)
--     SimpleShape:new('rect'):show({width = self.PLAY_AREA_SIZE[1], height = self.PLAY_AREA_SIZE[2], Yalign = -50, color = SimpleShape.colorFactory("ffffffff")})
--   end,

--   draw_paddle = function(self, yMove)
--     local xOffset = self.PLAY_AREA_SIZE[1] / 2 * -1
--     local yOffset = self.PADDLE_SIZE[2] / 2 + yMove
--     if yOffset < self.PLAY_AREA_SIZE[2] or yOffset > -self.PLAY_AREA_SIZE[2] then return end
--     SimpleShape:new('rect'):show({width = self.PADDLE_SIZE[1], height = self.PADDLE_SIZE[2], Xalign = xOffset, Yalign = yOffset, color = SimpleShape.colorFactory("000000ff")})
--   end,

-- }

-- local paddle_pos = 0

-- script.on_game_event("PONG_P1_PADDLE_UP", false, function()
--   paddle_pos = paddle_pos + 10
-- end)

-- script.on_game_event("PONG_P1_PADDLE_DOWN", false, function()
--   paddle_pos = paddle_pos - 10
-- end)

-- script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, function()end, function()
--   Game:draw_bg()
--   Game:draw_paddle(paddle_pos)
-- end)