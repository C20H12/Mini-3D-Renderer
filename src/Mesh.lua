local Triangle = require("Triangle")
local Vector3d = require("Vector3d")
local Vector2d = require("Vector2d")
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

Mesh.LoadFromFile = function(self, fileName, hasTex)
  hasTex = hasTex or false

  -- cache of vertices
  local vertices = {}
  local textures = {}

  local o = {triangles = {}}

  for line in love.filesystem.lines(fileName) do
    local junkChar
    
    if line:sub(1, 1) == "v" then
      if line:sub(2, 2) == "t" then
        local vts = {}
        for vt in string.gmatch(line, "%S+") do
          insert(vts, vt)
        end

        for i = 2, #vts do
          vts[i] = tonumber(vts[i])
        end

        local vector = Vector2d:new(vts[2], 1 - vts[3])
        insert(textures, vector)
      else
        local verts = {}
        for vert in string.gmatch(line, "%S+") do
          insert(verts, vert)
        end
        
        for i = 2, #verts do
          verts[i] = tonumber(verts[i])
        end
        
        junkChar = verts[1]
        local vector = Vector3d:new(verts[2], verts[3], verts[4])
        insert(vertices, vector)
      end
    end

    if line:sub(1, 1) == "f" then
      if not hasTex then
        local points = {}
        for point in string.gmatch(line, "%S+") do
          insert(points, point)
        end
        
        for i = 2, #points do
          points[i] = tonumber(points[i])
        end
        
        junkChar = points[1]
        local triangle = Triangle:new(vertices[points[2]], vertices[points[3]], vertices[points[4]])
        insert(o.triangles, triangle)
      else
        local points = {}
        for face in string.gmatch(line, "%S+") do
          local v, vt, vn = string.match(face, "(%d*)/?(%d*)/?(%d*)")
          insert(points, {v = v, vt = vt, vn = vn})
        end

        for i = 2, #points do
          points[i].v = tonumber(points[i].v)
          points[i].vt = tonumber(points[i].vt)
          points[i].vn = tonumber(points[i].vn)
        end
        
        local triangle = Triangle:new(
          vertices[points[2].v], vertices[points[3].v], vertices[points[4].v],
          textures[points[2].vt], textures[points[3].vt], textures[points[4].vt]
        )
        
        insert(o.triangles, triangle)
      end
    end
  end

  self.__index = self
  return setmetatable(o, self)
end

return Mesh