local sqrt = math.sqrt


---@class Vector3d
Vector3d = {}

Vector3d.x = 0
Vector3d.y = 0
Vector3d.z = 0
Vector3d.w = 1

Vector3d.new = function(self, x, y, z, w)
  local o = {x = x or 0, y = y or 0, z = z or 0, w = w or 1}
  self.__index = self
  return setmetatable(o, self)
end

Vector3d.__add = function(self, vector)
  return Vector3d:new(self.x + vector.x, self.y + vector.y, self.z + vector.z)
end
Vector3d.__sub = function(self, vector)
  return Vector3d:new(self.x - vector.x, self.y - vector.y, self.z - vector.z)
end
Vector3d.__mul = function(self, number)
  return Vector3d:new(self.x * number, self.y * number, self.z * number)
end
Vector3d.__div = function(self, number)
  return Vector3d:new(self.x / number, self.y / number, self.z / number)
end

Vector3d.GetDotProduct = function(vector1, vector2)
  return vector1.x * vector2.x + vector1.y * vector2.y + vector1.z * vector2.z   
end

Vector3d.GetCrossProduct = function(vector1, vector2)
  return Vector3d:new(
    vector1.y * vector2.z - vector1.z * vector2.y,
    vector1.z * vector2.x - vector1.x * vector2.z,
    vector1.x * vector2.y - vector1.y * vector2.x
  )
end

Vector3d.GetLength = function(self)
  return sqrt(self.GetDotProduct(self, self))
end

Vector3d.Normalize = function(self)
  local length = self:GetLength()
  self.x = self.x / length
  self.y = self.y / length
  self.z = self.z / length
  return self
end

Vector3d.IntersectPlane = function(planeP, planeN, lineStart, lineEnd)
  planeN = Vector3d:new(planeN.x, planeN.y, planeN.z):Normalize()
  local planeD = -Vector3d.GetDotProduct(planeN, planeP)
  local ad = Vector3d.GetDotProduct(lineStart, planeN)
  local bd = Vector3d.GetDotProduct(lineEnd, planeN)
  local t = (-planeD - ad) / (bd - ad)
  local lineStartToEnd = lineEnd - lineStart
  local lineToIntersect = lineStartToEnd * t
  return lineStart + lineToIntersect
end

return Vector3d