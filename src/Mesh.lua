local Triangle = require("Triangle")
local insert = table.insert


---@class Mesh
local Mesh = {}

Mesh.triangles = {}

Mesh.new = function(self, ...)
  local o = {triangles = {...}}

  for _, tri in ipairs(o.triangles) do
    if getmetatable(tri) ~= Triangle then
      return log("Error: Mesh.new: tri is not a Triangle")
    end
  end

  self.__index = self
  return setmetatable(o, self)
end

Mesh.LoadFromFile = function(self, fileName)
  -- cache of vertices
  local vertices = {}

  local o = {triangles = {}}

  for line in love.filesystem.lines(fileName) do
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

  self.__index = self
  return setmetatable(o, self)
end

return Mesh