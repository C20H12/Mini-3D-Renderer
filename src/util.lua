local abs, floor = math.abs, math.floor


local function TriangleOutline(point1, point2, point3, r, g, b)
  love.graphics.setLineWidth(2)
  love.graphics.setColor(r, g, b)

  love.graphics.line(
    point1.x, point1.y, 
    point2.x, point2.y
  )
  love.graphics.line(
    point2.x, point2.y, 
    point3.x, point3.y
  )
  love.graphics.line(
    point3.x, point3.y, 
    point1.x, point1.y
  )
end

local function TriangleFill(point1, point2, point3, r, g, b)
  love.graphics.setColor(r, g, b)
  love.graphics.polygon(
    'fill', 
    point1.x, point1.y, 
    point2.x, point2.y, 
    point3.x, point3.y
  )
end

local function GetColor(dp)
  return {dp ^ 1.5, dp ^ 1.5, dp ^ 1.5}
end

local function PrintAvgZ(triangle)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(
    (triangle.points[1].z + triangle.points[2].z + triangle.points[3].z) / 3, 
    (triangle.points[1].x + triangle.points[2].x + triangle.points[3].x) / 3, 
    (triangle.points[1].y + triangle.points[2].y + triangle.points[3].y) / 3
  )
end

local function TriangleTextured(
  x1, y1, u1, v1, w1,
  x2, y2, u2, v2, w2,
  x3, y3, u3, v3, w3,
  texture, textureWidth, textureHeight,
  lightR, lightG, lightB,
  buffer
)
  -- these should be integers
  x1, y1, x2, y2, x3, y3 = floor(x1), floor(y1), floor(x2), floor(y2), floor(x3), floor(y3)

  -- sort the points by highest y, manually
  if y2 < y1 then
    y1, y2 = y2, y1
    x1, x2 = x2, x1
    u1, u2 = u2, u1
    v1, v2 = v2, v1
    w1, w2 = w2, w1
  end

  if y3 < y1 then
    y1, y3 = y3, y1
    x1, x3 = x3, x1
    u1, u3 = u3, u1
    v1, v3 = v3, v1
    w1, w3 = w3, w1
  end

  if y3 < y2 then
    y2, y3 = y3, y2
    x2, x3 = x3, x2
    u2, u3 = u3, u2
    v2, v3 = v3, v2
    w2, w3 = w3, w2
  end

  -- find the difference between the 1st and 2nd points
  local dy1 = y2 - y1
  local dx1 = x2 - x1
  local dv1 = v2 - v1
  local du1 = u2 - u1
  local dw1 = w2 - w1

  local dy2 = y3 - y1
  local dx2 = x3 - x1
  local dv2 = v3 - v1
  local du2 = u3 - u1
  local dw2 = w3 - w1

  -- final points to sample from
  local tex_final_u, tex_final_v, tex_final_w = 0, 0, 0

  -- step value on how much to move for each line
  local dax_step, dbx_step = 0, 0
  local du1_step, dv1_step = 0, 0
  local du2_step, dv2_step = 0, 0
  local dw1_step, dw2_step = 0, 0

  -- if the line between these two points is horizontal, there is no dx
  if dy1 ~= 0 then dax_step = dx1 / abs(dy1) end
  if dy2 ~= 0 then dbx_step = dx2 / abs(dy2) end

  if dy1 ~= 0 then du1_step = du1 / abs(dy1) end
  if dy1 ~= 0 then dv1_step = dv1 / abs(dy1) end
  if dy1 ~= 0 then dw1_step = dw1 / abs(dy1) end

  if dy2 ~= 0 then du2_step = du2 / abs(dy2) end
  if dy2 ~= 0 then dv2_step = dv2 / abs(dy2) end
  if dy2 ~= 0 then dw2_step = dw2 / abs(dy2) end
  
  -- as long as the line is not horizontal, draw the top half
  if dy1 ~= 0 then
    -- loop from the top to either the bottom or the middle
    for i = y1, y2 do
      -- determine the x of the line starting from the original, 
      -- plus the step based on how many rows we've gone
      local ax = floor(x1 + (i - y1) * dax_step)
      local bx = floor(x1 + (i - y1) * dbx_step)

      local tex_start_u = u1 + (i - y1) * du1_step
      local tex_start_v = v1 + (i - y1) * dv1_step
      local tex_start_w = w1 + (i - y1) * dw1_step

      local tex_end_u   = u1 + (i - y1) * du2_step
      local tex_end_v   = v1 + (i - y1) * dv2_step
      local tex_end_w   = w1 + (i - y1) * dw2_step

      -- sort along the x axis, 
      -- to ensure a smaller x value is drawn before a larger x
      if ax > bx then
        ax, bx = bx, ax
        tex_start_u, tex_end_u = tex_end_u, tex_start_u
        tex_start_v, tex_end_v = tex_end_v, tex_start_v
        tex_start_w, tex_end_w = tex_end_w, tex_start_w
      end

      -- the final points to sample from, they are the starting values at first
      tex_final_u = tex_start_u
      tex_final_v = tex_start_v
      tex_final_w = tex_start_w
      
      -- 1 over the length of the current line
      local tstep = 1 / (bx - ax)
      local t = 0

      -- loop through the current line
      for j = ax, bx - 1 do
        -- to fix rounding errors
        if floor(t) == 1 then t = 1 end

        -- interpolate the final points to sample from
        tex_final_u = (1 - t) * tex_start_u + t * tex_end_u
        tex_final_v = (1 - t) * tex_start_v + t * tex_end_v
        tex_final_w = (1 - t) * tex_start_w + t * tex_end_w

        -- if the point is larger than the current pixel's z buffer value, draw it
        -- TODO: check later if abs is needed
        if tex_final_w > buffer[abs(i * SCREEN_WIDTH + j)] then
          -- perspective correct texture mapping by dividing the u and v by the w
          local r, g, b, a = texture:getPixel(
            (tex_final_u / tex_final_w) * (textureWidth - 1),
            (tex_final_v / tex_final_w) * (textureHeight - 1)
          )

          -- multiply the color by the lighting
          r, g, b = r * lightR, g * lightG, b * lightB

          -- draw the pixel
          love.graphics.points { {j, i, r, g, b, a} }

          -- update the z buffer
          buffer[abs(i * SCREEN_WIDTH + j)] = tex_final_w
        end
        
        -- increment t every time a new pixel is reached
        t = t + tstep
      end
    end
  end

  -- second half, drawing the bottom part of the triangle
  dy1 = y3 - y2
  dx1 = x3 - x2
  dv1 = v3 - v2
  du1 = u3 - u2
  dw1 = w3 - w2
  
  if dy1 ~= 0 then dax_step = dx1 / abs(dy1) end
  if dy2 ~= 0 then dbx_step = dx2 / abs(dy2) end

  du1_step, dv1_step = 0, 0

  if dy1 ~= 0 then du1_step = du1 / abs(dy1) end
  if dy1 ~= 0 then dv1_step = dv1 / abs(dy1) end
  if dy1 ~= 0 then dw1_step = dw1 / abs(dy1) end

  if dy1 ~= 0 then
    for i = y2, y3 do
      local ax = floor(x2 + (i - y2) * dax_step)
      local bx = floor(x1 + (i - y1) * dbx_step)

      local tex_start_u = u2 + (i - y2) * du1_step
      local tex_start_v = v2 + (i - y2) * dv1_step
      local tex_start_w = w2 + (i - y2) * dw1_step

      local tex_end_u   = u1 + (i - y1) * du2_step
      local tex_end_v   = v1 + (i - y1) * dv2_step
      local tex_end_w   = w1 + (i - y1) * dw2_step

      if ax > bx then
        ax, bx = bx, ax
        tex_start_u, tex_end_u = tex_end_u, tex_start_u
        tex_start_v, tex_end_v = tex_end_v, tex_start_v
        tex_start_w, tex_end_w = tex_end_w, tex_start_w
      end

      tex_final_u = tex_start_u
      tex_final_v = tex_start_v
      tex_final_w = tex_start_w
      
      local tstep = 1 / (bx - ax)
      local t = 0

      for j = ax, bx - 1 do
        if floor(t) == 1 then t = 1 end
        
        tex_final_u = (1 - t) * tex_start_u + t * tex_end_u
        tex_final_v = (1 - t) * tex_start_v + t * tex_end_v
        tex_final_w = (1 - t) * tex_start_w + t * tex_end_w

        if tex_final_w > buffer[abs(i * SCREEN_WIDTH + j)] then
          local r, g, b, a = texture:getPixel(
            (tex_final_u / tex_final_w) * (textureWidth - 1),
            (tex_final_v / tex_final_w) * (textureHeight - 1)
          )
          r, g, b = r * lightR, g * lightG, b * lightB
          love.graphics.points { {j, i, r, g, b, a} }
          buffer[abs(i * SCREEN_WIDTH + j)] = tex_final_w
        end

        t = t + tstep
      end
    end
  end

end

return function() return TriangleOutline, TriangleFill, GetColor, TriangleTextured end