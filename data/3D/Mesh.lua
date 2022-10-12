local insert = table.insert


---@class Mesh
Mesh = {}

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
  local file = io.open(fileName, "r")
  if not file then 
    log("Error: Mesh.LoadFromFile: file not found")
    return false 
  end

  -- cache of vertices
  local vertices = {}

  local o = {triangles = {}}

  for line in file:lines() do

    if line:sub(1, 1) == "v" then
      local verts = {}
      for vert in string.gmatch(line, "%S+") do
        insert(verts, tonumber(vert) or 'v')
      end

      local vector = Vector3d:new(verts[2], verts[3], verts[4])
      insert(vertices, vector)
    end

    if line:sub(1, 1) == "f" then
      local points = {}
      for point in string.gmatch(line, "%S+") do
        if string.find(point, '/') then
          insert(points, tonumber(string.gmatch(point, "%d+")()))
        else
          insert(points, tonumber(point) or 'f')
        end
      end

      local triangle = Triangle:new(vertices[points[2]], vertices[points[3]], vertices[points[4]])
      insert(o.triangles, triangle)
    end
  end

  file:close()
  self.__index = self
  return setmetatable(o, self)
end