
---@class Vector2d
local Vector2d = {}

Vector2d.u = 0
Vector2d.v = 0
Vector2d.w = 1

Vector2d.new = function(self, u, v, w)
  local o = {u = u or 0, v = v or 0, w = w or 1}
  self.__index = self
  return setmetatable(o, self)
end

return Vector2d