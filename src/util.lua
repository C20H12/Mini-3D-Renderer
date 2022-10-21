local abs = math.abs

local SCREEN_WIDTH = 1280
local SCREEN_HEIGHT = 720


local function TriangleOutline(point1, point2, point3, r, g, b)
  love.graphics.setLineWidth(2)
  love.graphics.setColor(r, g, b)

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
  love.graphics.setColor(r, g, b)
  love.graphics.polygon(
    'fill', 
    SCREEN_WIDTH - point1.x, SCREEN_HEIGHT - point1.y, 
    SCREEN_WIDTH - point2.x, SCREEN_HEIGHT - point2.y, 
    SCREEN_WIDTH - point3.x, SCREEN_HEIGHT - point3.y
  )
end

local function GetColor(dp)
  return {dp ^ 1.5, dp ^ 1.5, dp ^ 1.5}
end

local function PrintAvgZ(triangle)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(
    (triangle.points[1].z + triangle.points[2].z + triangle.points[3].z) / 3, 
    SCREEN_WIDTH - ((triangle.points[1].x + triangle.points[2].x + triangle.points[3].x) / 3), 
    SCREEN_HEIGHT - ((triangle.points[1].y + triangle.points[2].y + triangle.points[3].y) / 3)
  )
end

local function TriangleTextured(
  x1, y1, u1, v1,
  x2, y2, u2, v2,
  x3, y3, u3, v3,
  texture
)
  local textureWidth, textureHeight = texture:getDimensions()

  if y2 < y1 then
    y1, y2 = y2, y1
    x1, x2 = x2, x1
    u1, u2 = u2, u1
    v1, v2 = v2, v1
  end

  if y3 < y1 then
    y1, y3 = y3, y1
    x1, x3 = x3, x1
    u1, u3 = u3, u1
    v1, v3 = v3, v1
  end

  if y3 < y2 then
    y2, y3 = y3, y2
    x2, x3 = x3, x2
    u2, u3 = u3, u2
    v2, v3 = v3, v2
  end

  local dy1 = y2 - y1
  local dx1 = x2 - x1
  local dv1 = v2 - v1
  local du1 = u2 - u1

  local dy2 = y3 - y1
  local dx2 = x3 - x1
  local dv2 = v3 - v1
  local du2 = u3 - u1

  local dax_step, dbx_step = 0, 0
  local du1_step, dv1_step = 0, 0
  local du2_step, dv2_step = 0, 0

  local tex_final_u, tex_final_v = 0, 0

  if dy1 ~= 0 then dax_step = dx1 / abs(dy1) end
  if dy2 ~= 0 then dbx_step = dx2 / abs(dy2) end

  if dy1 ~= 0 then du1_step = du1 / abs(dy1) end
  if dy1 ~= 0 then dv1_step = dv1 / abs(dy1) end

  if dy2 ~= 0 then du2_step = du2 / abs(dy2) end
  if dy2~= 0 then dv2_step = dv2 / abs(dy2) end

  if dy1 ~= 0 then

    for i = y1, y2 do
      local ax = x1 + (i - y1) * dax_step
      local bx = x1 + (i - y1) * dbx_step

      local tex_start_u = u1 + (i - y1) * du1_step
      local tex_start_v = v1 + (i - y1) * dv1_step

      local tex_end_u = u1 + (i - y1) * du2_step
      local tex_end_v = v1 + (i - y1) * dv2_step

      if ax > bx then
        ax, bx = bx, ax
        tex_start_u, tex_end_u = tex_end_u, tex_start_u
        tex_start_v, tex_end_v = tex_end_v, tex_start_v
      end

      tex_final_u = tex_start_u
      tex_final_v = tex_start_v
      
      local tstep = 1 / (bx - ax)
      local t = 0

      for j = ax, bx do
        tex_final_u = (1 - t) * tex_start_u + t * tex_end_u
        tex_final_v = (1 - t) * tex_start_v + t * tex_end_v

        local r, g, b, a = texture:getPixel(tex_final_u * (textureWidth - 1), tex_final_v * (textureHeight - 1))
        -- local r, g, b, a = 1, 1, 1, 1
        love.graphics.points { {SCREEN_WIDTH - j, SCREEN_HEIGHT - i, r, g, b, a} }

        t = t + tstep
      end
    end


    -- second half, drawing the bottom part of the triangle
    dy1 = y3 - y2
    dx1 = x3 - x2
    dv1 = v3 - v2
    du1 = u3 - u2
    
    if dy1 ~= 0 then dax_step = dx1 / abs(dy1) end
    if dy2 ~= 0 then dbx_step = dx2 / abs(dy2) end

    du1_step, dv1_step = 0, 0

    if dy1 ~= 0 then du1_step = du1 / abs(dy1) end
    if dy1 ~= 0 then dv1_step = dv1 / abs(dy1) end

    for i = y2, y3 do
      local ax = x2 + (i - y2) * dax_step
      local bx = x1 + (i - y1) * dbx_step

      local tex_start_u = u2 + (i - y2) * du1_step
      local tex_start_v = v2 + (i - y2) * dv1_step

      local tex_end_u = u1 + (i - y1) * du2_step
      local tex_end_v = v1 + (i - y1) * dv2_step

      if ax > bx then
        ax, bx = bx, ax
        tex_start_u, tex_end_u = tex_end_u, tex_start_u
        tex_start_v, tex_end_v = tex_end_v, tex_start_v
      end

      tex_final_u = tex_start_u
      tex_final_v = tex_start_v
      
      local tstep = 1 / (bx - ax)
      local t = 0

      for j = ax, bx do
        tex_final_u = (1 - t) * tex_start_u + t * tex_end_u
        tex_final_v = (1 - t) * tex_start_v + t * tex_end_v

        print(tex_final_u * textureWidth, tex_final_v*textureHeight)
        local r, g, b, a = texture:getPixel(tex_final_u * (textureWidth - 1), tex_final_v * (textureHeight - 1))
        -- local r, g, b, a = 0.5, 0.5, 0.5, 1
        love.graphics.points { {SCREEN_WIDTH - j, SCREEN_HEIGHT - i, r, g, b, a} }

        t = t + tstep
      end
    end

  end

end

return function() return TriangleOutline, TriangleFill, GetColor, TriangleTextured end