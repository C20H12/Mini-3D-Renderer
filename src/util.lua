
local SCREEN_WIDTH = 1280
local SCREEN_HEIGHT = 720


local function Color(r, g, b, a)
  local rr, gg, bb, aa;
  rr = r / 255
  gg = g / 255
  bb = b / 255
  aa = a
  return rr, gg, bb, aa
end

local function TriangleOutline(point1, point2, point3, r, g, b)
  love.graphics.setLineWidth(2)
  love.graphics.setColor(Color(r, g, b))

  love.graphics.line(
    SCREEN_WIDTH - point1.x, SCREEN_HEIGHT - point1.y, 
    SCREEN_WIDTH - point2.x, SCREEN_HEIGHT - point2.y
  )
  love.graphics.line(
    SCREEN_WIDTH - point2.x, SCREEN_HEIGHT - point2.y, 
    SCREEN_WIDTH - point3.x, SCREEN_HEIGHT - point3.y
  )
  love.graphics.line(
    SCREEN_WIDTH - point3.x, SCREEN_HEIGHT - point3.y, 
    SCREEN_WIDTH - point1.x, SCREEN_HEIGHT - point1.y
  )
end

local function TriangleFill(point1, point2, point3, r, g, b)
  love.graphics.setColor(Color(r, g, b))
  love.graphics.polygon(
    'fill', 
    SCREEN_WIDTH - point1.x, SCREEN_HEIGHT - point1.y, 
    SCREEN_WIDTH - point2.x, SCREEN_HEIGHT - point2.y, 
    SCREEN_WIDTH - point3.x, SCREEN_HEIGHT - point3.y
  )
end

local function GetColor(dp)
  return {dp ^ 2 * 255, dp ^ 2 * 255, dp ^ 2 * 255}
end

return function() return TriangleOutline, TriangleFill, GetColor, Color end