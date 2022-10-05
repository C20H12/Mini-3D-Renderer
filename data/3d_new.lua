local sin, cos, tan, PI, sqrt = math.sin, math.cos, math.tan, math.pi, math.sqrt
local insert, unpack, sort = table.insert, table.unpack, table.sort
local GL_DrawLine, GL_DrawTriangle = Graphics.CSurface.GL_DrawLine, Graphics.CSurface.GL_DrawTriangle
local Point, FPS = Hyperspace.Point, Hyperspace.FPS

local SCREEN_WIDTH = 1280
local SCREEN_HEIGHT = 720



local Vector3d = {
  x = 0,
  y = 0,
  z = 0,
  w = 1,

  __add = function(self, vector)
    self.x = self.x + vector.x
    self.y = self.y + vector.y
    self.z = self.z + vector.z
    return self
  end,
  __sub = function(self, vector)
    self.x = self.x - vector.x
    self.y = self.y - vector.y
    self.z = self.z - vector.z
    return self
  end,
  __mul = function(self, number)
    self.x = self.x * number
    self.y = self.y * number
    self.z = self.z * number
    return self
  end,
  __div = function(self, number)
    self.x = self.x / number
    self.y = self.y / number
    self.z = self.z / number
    return self
  end,

  GetDotProduct = function(vector1, vector2)
    return vector1.x * vector2.x + vector1.y * vector2.y + vector1.z * vector2.z   
  end,

  GetLength = function(self)
    return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)    
  end,
  Normalize = function(self)
    local length = self:GetLength()
    return self:new(self.x / length, self.y / length, self.z / length)  
  end,

  new = function(self, x, y, z, w)
    local o = {x = x, y = y, z = z, w = w or 1}
    self.__index = self
    return setmetatable(o, self)
  end,
}

local Triangle = {
  points = {},
  color = {0, 0, 0},
  new = function(self, vec1, vec2, vec3)
    local o = {points = {vec1, vec2, vec3}}

    for _, vec in ipairs(o.points) do
      if getmetatable(vec) ~= Vector3d then
        return log("Error: Triangle.new: vec is not a Vector3d")
      end
    end

    self.__index = self
    return setmetatable(o, self)
  end,
}

local Mesh = {
  triangles = {},
  LoadFromFile = function(self, fileName)
    local file = io.open(fileName, "r")
    if not file then return false end

    -- cache of vertices
    local vertices = {}

    local o = {triangles = {}}

    for line in file:lines() do
      local string = line
      local junkChar
      
      if line:sub(1, 1) == "v" then
        local verts = {}
        for vert in string.gmatch(string, "%S+") do
          insert(verts, vert)
        end

        for i = 2, #verts do
          verts[i] = tonumber(verts[i])
        end

        junkChar = verts[1]
        local vector = Vector3d:new(verts[2], verts[3], verts[4])
        insert(vertices, vector)
      end

      if line:sub(1, 1) == "f" then
        local points = {}
        for point in string.gmatch(string, "%S+") do
          insert(points, point)
        end

        for i = 2, #points do
          points[i] = tonumber(points[i])
        end

        junkChar = points[1]
        local triangle = Triangle:new(vertices[points[2]], vertices[points[3]], vertices[points[4]])
        insert(o.triangles, triangle)
      end
    end

    file:close()
    self.__index = self
    return setmetatable(o, self)
  end,
  new = function(self, ...)
    local o = {triangles = {...}}

    for _, tri in ipairs(o.triangles) do
      if getmetatable(tri) ~= Triangle then
        return log("Error: Mesh.new: tri is not a Triangle")
      end
    end

    self.__index = self
    return setmetatable(o, self)
  end,
}

local Matrix_4x4 = {
  matrix = {},

  MultiplyByVector = function(mat, vec)
    return Vector3d:new(
      vec.x * mat.matrix[1][1] + vec.y * mat.matrix[2][1] + vec.z * mat.matrix[3][1] + vec.w * mat.matrix[4][1],
      vec.y * mat.matrix[1][2] + vec.y * mat.matrix[2][2] + vec.z * mat.matrix[3][2] + vec.w * mat.matrix[4][2],
      vec.z * mat.matrix[1][3] + vec.y * mat.matrix[2][3] + vec.z * mat.matrix[3][3] + vec.w * mat.matrix[4][3],
      vec.w * mat.matrix[1][4] + vec.y * mat.matrix[2][4] + vec.z * mat.matrix[3][4] + vec.w * mat.matrix[4][4]
    )
  end,

  CreateIdentity = function()
    return self:new(
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    )
  end,

  CreateRotationX = function(angle)
    return self:new(
      1,    0,              0,            0,
      0,    cos(theta/2),   sin(theta/2), 0,
      0,    -sin(theta/2),  cos(theta/2), 0,
      0,    0,              0,            1
    )
  end,

  CreateRotationY = function(theta)
    return self:new(
      cos(theta/2),   0,    sin(theta/2),   0,
      0,              1,    0,              0,
      -sin(theta/2),  0,    cos(theta/2),   0,
      0,              0,    0,              1
    )
  end,

  CreateRotationZ = function(theta)
    return self:new(
      cos(theta),   sin(theta),   0,    0,
      -sin(theta),  cos(theta),   0,    0,
      0,            0,            1,    0,
      0,            0,            0,    1
    )
  end,

  CreateTranslation = function(x, y, z)
    return self:new(
      1,  0,  0,  0,
      0,  1,  0,  0,
      0,  0,  1,  0,
      x,  y,  z,  1
    )
  end,

  CreateProjection = function(fov, ar, nearPlane, farPlane)
    local fovRad = 1 / tan(fov * 0.5 / 180 * pi)
    return self:new(
      ar * fovRad,      0.0,      0.0,                                                  0.0,
      0.0,              fovRad,   0.0,                                                  0.0,
      0.0,              0.0,      farPlane / (farPlane - nearPlane),                    1.0,
      0.0,              0.0,      (-farPlane * nearPlane) / (farPlane - nearPlane),     0.0
    )
  end,

  __mul = function(self, mat)
    local tempMat = self:new(0)
    for i=1, 4 do
      for j=1, 4 do
        tempMat.matrix[j][i] = self.matrix[j][1] * mat.matrix[1][i] + 
                               self.matrix[j][2] * mat.matrix[2][i] + 
                               self.matrix[j][3] * mat.matrix[3][i] + 
                               self.matrix[j][4] * mat.matrix[4][i];
      end
    end
    return tempMat
  end,

  new = function(self, ...)
    local temp = {...}
    local o = { matrix = {
      {temp[1], temp[2], temp[3], temp[4]}, 
      {temp[5], temp[6], temp[7], temp[8]}, 
      {temp[9], temp[10], temp[11], temp[12]}, 
      {temp[13], temp[14], temp[15], temp[16]}
    } }
    self.__index = self
    return setmetatable(o, self)
  end,
}



local function Color(r, g, b, a)
  local rr, gg, bb, aa;
  rr = r / 255
  gg = g / 255
  bb = b / 255
  aa = a
  return Graphics.GL_Color(rr, gg, bb, aa)
end

local function TriangleOutline(point1, point2, point3, r, g, b)
  GL_DrawLine(point1.x, point1.y, point2.x, point2.y, 2, Color(r, g, b, 1))
  GL_DrawLine(point2.x, point2.y, point3.x, point3.y, 2, Color(r, g, b, 1))
  GL_DrawLine(point3.x, point3.y, point1.x, point1.y, 2, Color(r, g, b, 1))
end

local function TriangleFill(point1, point2, point3, r, g, b)
  GL_DrawTriangle(
    Point(point1.x, point1.y),
    Point(point2.x, point2.y),
    Point(point3.x, point3.y),
    Color(r, g, b, 1)
  )
end

local function MultiplyMatrixByVector(v, m)
  local output = Vector3d:new(0, 0, 0)
  output.x = v.x * m.matrix[1][1] + v.y * m.matrix[2][1] + v.z * m.matrix[3][1] + m.matrix[4][1]
  output.y = v.x * m.matrix[1][2] + v.y * m.matrix[2][2] + v.z * m.matrix[3][2] + m.matrix[4][2]
  output.z = v.x * m.matrix[1][3] + v.y * m.matrix[2][3] + v.z * m.matrix[3][3] + m.matrix[4][3]
  local w = v.x * m.matrix[1][4] + v.y * m.matrix[2][4] + v.z * m.matrix[3][4] + m.matrix[4][4]

  if w ~= 0 then
    output.x = output.x / w
    output.y = output.y / w
    output.z = output.z / w
  end

  return output
end

local function copy(table)
  local out = {}
  for k, v in pairs(table) do
    out[k] = v
  end
  return out
end



local nearPlane = 0.1
local farPlane = 1000.0
local fov = 90.0
local aspectRatio = SCREEN_HEIGHT / SCREEN_WIDTH
local fovRad = 1.0 / tan(fov * 0.5 / 180.0 * PI)


-- local cube = Mesh:new(
--   -- SOUTH
--   Triangle:new( Vector3d:new(0.0, 0.0, 0.0),    Vector3d:new(0.0, 1.0, 0.0),    Vector3d:new(1.0, 1.0, 0.0) ),
--   Triangle:new( Vector3d:new(0.0, 0.0, 0.0),    Vector3d:new(1.0, 1.0, 0.0),    Vector3d:new(1.0, 0.0, 0.0) ),
  
--   -- EAST                                                      
--   Triangle:new( Vector3d:new(1.0, 0.0, 0.0),    Vector3d:new(1.0, 1.0, 0.0),    Vector3d:new(1.0, 1.0, 1.0) ),
--   Triangle:new( Vector3d:new(1.0, 0.0, 0.0),    Vector3d:new(1.0, 1.0, 1.0),    Vector3d:new(1.0, 0.0, 1.0) ),
  
--   -- NORTH                                                     
--   Triangle:new( Vector3d:new(1.0, 0.0, 1.0),    Vector3d:new(1.0, 1.0, 1.0),    Vector3d:new(0.0, 1.0, 1.0) ),
--   Triangle:new( Vector3d:new(1.0, 0.0, 1.0),    Vector3d:new(0.0, 1.0, 1.0),    Vector3d:new(0.0, 0.0, 1.0) ),
  
--   -- WEST                                                      
--   Triangle:new( Vector3d:new(0.0, 0.0, 1.0),    Vector3d:new(0.0, 1.0, 1.0),    Vector3d:new(0.0, 1.0, 0.0) ),
--   Triangle:new( Vector3d:new(0.0, 0.0, 1.0),    Vector3d:new(0.0, 1.0, 0.0),    Vector3d:new(0.0, 0.0, 0.0) ),
  
--   -- TOP                                                       
--   Triangle:new( Vector3d:new(0.0, 1.0, 0.0),    Vector3d:new(0.0, 1.0, 1.0),    Vector3d:new(1.0, 1.0, 1.0) ),
--   Triangle:new( Vector3d:new(0.0, 1.0, 0.0),    Vector3d:new(1.0, 1.0, 1.0),    Vector3d:new(1.0, 1.0, 0.0) ),
  
--   -- BOTTOM                                                    
--   Triangle:new( Vector3d:new(1.0, 0.0, 1.0),    Vector3d:new(0.0, 0.0, 1.0),    Vector3d:new(0.0, 0.0, 0.0) ),
--   Triangle:new( Vector3d:new(1.0, 0.0, 1.0),    Vector3d:new(0.0, 0.0, 0.0),    Vector3d:new(1.0, 0.0, 0.0) )
-- )

local object = Mesh:LoadFromFile('VideoShip.obj')

-- projection matrix
local meshProjection = Matrix_4x4:new(
  aspectRatio * fovRad,  0.0,      0.0,                                                  0.0,
  0.0,                   fovRad,   0.0,                                                  0.0,
  0.0,                   0.0,      farPlane / (farPlane - nearPlane),                    1.0,
  0.0,                   0.0,      (-farPlane * nearPlane) / (farPlane - nearPlane),     0.0
)




local should_draw = false
local elapsed_time = 0

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
  elapsed_time = elapsed_time + (FPS.SpeedFactor / 16)
end)

script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, function()end, function()
  if not should_draw then return end

  Graphics.CSurface.GL_DrawRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, Color(0, 0, 0, 1))

  local theta = elapsed_time

  local rotationZ = Matrix_4x4:new(
    cos(theta),   sin(theta),   0,    0,
    -sin(theta),  cos(theta),   0,    0,
    0,            0,            1,    0,
    0,            0,            0,    1
  )
  local rotationX = Matrix_4x4:new(
    1,    0,              0,            0,
    0,    cos(theta/2),   sin(theta/2), 0,
    0,    -sin(theta/2),  cos(theta/2), 0,
    0,    0,              0,            1
  )

  local vCamra = Vector3d:new(0, 0, 0)

  local trianglesToDraw = {}

  -- draw triangles
  for _, triangle in ipairs(object.triangles) do

    -- rotate in the Z axis
    local triangleRotatedZ = Triangle:new(
      MultiplyMatrixByVector(triangle.points[1], rotationZ),
      MultiplyMatrixByVector(triangle.points[2], rotationZ),
      MultiplyMatrixByVector(triangle.points[3], rotationZ)
    )

    -- rotate in the X axis
    local triangleRotatedZX = Triangle:new(
      MultiplyMatrixByVector(triangleRotatedZ.points[1], rotationX),
      MultiplyMatrixByVector(triangleRotatedZ.points[2], rotationX),
      MultiplyMatrixByVector(triangleRotatedZ.points[3], rotationX)
    )

    -- translate the triangle out to where we can see it
    local triangleTranslated = Triangle:new(
      Vector3d:new(triangleRotatedZX.points[1].x, triangleRotatedZX.points[1].y, triangleRotatedZX.points[1].z + 8),
      Vector3d:new(triangleRotatedZX.points[2].x, triangleRotatedZX.points[2].y, triangleRotatedZX.points[2].z + 8),
      Vector3d:new(triangleRotatedZX.points[3].x, triangleRotatedZX.points[3].y, triangleRotatedZX.points[3].z + 8)
    )

    
    local line1 = Vector3d:new(
      triangleTranslated.points[2].x - triangleTranslated.points[1].x, 
      triangleTranslated.points[2].y - triangleTranslated.points[1].y, 
      triangleTranslated.points[2].z - triangleTranslated.points[1].z
    )

    local line2 = Vector3d:new(
      triangleTranslated.points[3].x - triangleTranslated.points[1].x, 
      triangleTranslated.points[3].y - triangleTranslated.points[1].y, 
      triangleTranslated.points[3].z - triangleTranslated.points[1].z
    )

    local normalX = line1.y * line2.z - line1.z * line2.y
    local normalY = line1.z * line2.x - line1.x * line2.z
    local normalZ = line1.x * line2.y - line1.y * line2.x
    local normalLength = sqrt(normalX ^ 2 + normalY ^ 2 + normalZ ^ 2)
    local normal = Vector3d:new(
      normalX / normalLength,
      normalY / normalLength,
      normalZ / normalLength
    )

    -- if normal.z < 0 then
    -- if the dot product between the normal and the line from the camra to the triangle is less than 0, the triangle is facing the camra
    -- point on the triangle does not matter because they are on the same plane
    if (normal.x * (triangleTranslated.points[1].x - vCamra.x) +
        normal.y * (triangleTranslated.points[1].y - vCamra.y) +
        normal.z * (triangleTranslated.points[1].z - vCamra.z)) < 0 then

      -- lighting
      local lightDirection = Vector3d:new(0, 0, -1)
      local lightLength = sqrt(lightDirection.x ^ 2 + lightDirection.y ^2 + lightDirection.z ^ 2)
      lightDirection.x = lightDirection.x / lightLength
      lightDirection.y = lightDirection.y / lightLength
      lightDirection.z = lightDirection.z / lightLength

      local dotProduct = normal.x * lightDirection.x + normal.y * lightDirection.y + normal.z * lightDirection.z


      -- project the 3D --> 2D
      local triangleProjected = Triangle:new(
        MultiplyMatrixByVector(triangleTranslated.points[1], meshProjection),
        MultiplyMatrixByVector(triangleTranslated.points[2], meshProjection),
        MultiplyMatrixByVector(triangleTranslated.points[3], meshProjection)
      )

      -- scale into view
      triangleProjected.points[1].x = triangleProjected.points[1].x + 1
      triangleProjected.points[1].y = triangleProjected.points[1].y + 1
      triangleProjected.points[2].x = triangleProjected.points[2].x + 1
      triangleProjected.points[2].y = triangleProjected.points[2].y + 1
      triangleProjected.points[3].x = triangleProjected.points[3].x + 1
      triangleProjected.points[3].y = triangleProjected.points[3].y + 1

      triangleProjected.points[1].x = triangleProjected.points[1].x * 0.5 * SCREEN_WIDTH
      triangleProjected.points[1].y = triangleProjected.points[1].y * 0.5 * SCREEN_HEIGHT
      triangleProjected.points[2].x = triangleProjected.points[2].x * 0.5 * SCREEN_WIDTH
      triangleProjected.points[2].y = triangleProjected.points[2].y * 0.5 * SCREEN_HEIGHT
      triangleProjected.points[3].x = triangleProjected.points[3].x * 0.5 * SCREEN_WIDTH
      triangleProjected.points[3].y = triangleProjected.points[3].y * 0.5 * SCREEN_HEIGHT

      if dotProduct < 0 then dotProduct = 0 end
      
      -- store the triangle for sorting and drawing
      triangleProjected.color = {dotProduct * 255, dotProduct * 255, dotProduct * 255}
      insert(trianglesToDraw, triangleProjected)
    end

    -- sort the triangles from back to front
    sort(trianglesToDraw, function(t1, t2)
      local zAvg1 = (t1.points[1].z + t1.points[2].z + t1.points[3].z) / 3
      local zAvg2 = (t2.points[1].z + t2.points[2].z + t2.points[3].z) / 3
      return zAvg1 > zAvg2
    end)

    -- draw triangles in order of distance from the camra, from the queue
    for _, triangle in ipairs(trianglesToDraw) do
      local color = triangle.color
      TriangleFill(triangle.points[1], triangle.points[2], triangle.points[3], unpack(color))
      -- TriangleOutline(triangle.points[1], triangle.points[2], triangle.points[3], 0, 0, 0)
    end
  end
end)


script.on_game_event("CANVAS_INIT", false, function()
  should_draw = true
end)

script.on_game_event("CANVAS_END", false, function()
  should_draw = false
end)

-- -- log(tostring(object.triangles))
-- for _, tri in ipairs(object.triangles) do
--   for _, point in ipairs(tri.points) do
--     log("x: " .. point.x .. ", y: " .. point.y .. ", z: " .. point.z)
--   end
--   log('---')
-- end
