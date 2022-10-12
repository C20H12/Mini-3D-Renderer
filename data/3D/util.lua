local GL_DrawLine, GL_DrawTriangle, GL_DrawRect = Graphics.CSurface.GL_DrawLine, Graphics.CSurface.GL_DrawTriangle, Graphics.CSurface.GL_DrawRect
local Point = Hyperspace.Point


local SCREEN_WIDTH = 1280
local SCREEN_HEIGHT = 720


function Color(r, g, b, a)
  local rr, gg, bb, aa;
  rr = r / 255
  gg = g / 255
  bb = b / 255
  aa = a
  return Graphics.GL_Color(rr, gg, bb, aa)
end

function TriangleOutline(point1, point2, point3, r, g, b)
  GL_DrawLine(point1.x, point1.y, point2.x, point2.y, 2, Color(r, g, b, 1))
  GL_DrawLine(point2.x, point2.y, point3.x, point3.y, 2, Color(r, g, b, 1))
  GL_DrawLine(point3.x, point3.y, point1.x, point1.y, 2, Color(r, g, b, 1))
end

function TriangleFill(point1, point2, point3, r, g, b)
  GL_DrawTriangle(
    Point(SCREEN_WIDTH - point1.x, SCREEN_HEIGHT - point1.y),
    Point(SCREEN_WIDTH - point2.x, SCREEN_HEIGHT - point2.y),
    Point(SCREEN_WIDTH - point3.x, SCREEN_HEIGHT - point3.y),
    Color(r, g, b, 1)
  )
end