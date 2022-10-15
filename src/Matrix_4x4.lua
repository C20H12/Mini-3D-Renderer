local sin, cos, tan, PI = math.sin, math.cos, math.tan, math.pi


---@class Matrix_4x4
Matrix_4x4 = {}

Matrix_4x4.matrix = {}

Matrix_4x4.new = function(self, ...)
  local temp = {...}
  local o = { matrix = {
    {temp[1], temp[2], temp[3], temp[4]}, 
    {temp[5], temp[6], temp[7], temp[8]}, 
    {temp[9], temp[10], temp[11], temp[12]}, 
    {temp[13], temp[14], temp[15], temp[16]}
  } }
  self.__index = self
  return setmetatable(o, self)
end

Matrix_4x4.__mul = function(self, matOrVec)
  if matOrVec.x and matOrVec.y and matOrVec.z then
    local vec = matOrVec
    return Vector3d:new(
      vec.x * self.matrix[1][1] + vec.y * self.matrix[2][1] + vec.z * self.matrix[3][1] + vec.w * self.matrix[4][1],
      vec.x * self.matrix[1][2] + vec.y * self.matrix[2][2] + vec.z * self.matrix[3][2] + vec.w * self.matrix[4][2],
      vec.x * self.matrix[1][3] + vec.y * self.matrix[2][3] + vec.z * self.matrix[3][3] + vec.w * self.matrix[4][3],
      vec.x * self.matrix[1][4] + vec.y * self.matrix[2][4] + vec.z * self.matrix[3][4] + vec.w * self.matrix[4][4]
    )
  end

  local mat = matOrVec
  local tempMat = self.CreateIdentity()
  for i=1, 4 do
    for j=1, 4 do
      tempMat.matrix[j][i] = self.matrix[j][1] * mat.matrix[1][i] + 
                             self.matrix[j][2] * mat.matrix[2][i] + 
                             self.matrix[j][3] * mat.matrix[3][i] + 
                             self.matrix[j][4] * mat.matrix[4][i];
    end
  end
  return tempMat
end

Matrix_4x4.CreateIdentity = function()
  return Matrix_4x4:new(
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  )
end

Matrix_4x4.CreateRotationX = function(theta)
  return Matrix_4x4:new(
    1,    0,              0,            0,
    0,    cos(theta/2),   sin(theta/2), 0,
    0,    -sin(theta/2),  cos(theta/2), 0,
    0,    0,              0,            1
  )
end

Matrix_4x4.CreateRotationY = function(theta)
  return Matrix_4x4:new(
    cos(theta/2),   0,    sin(theta/2),   0,
    0,              1,    0,              0,
    -sin(theta/2),  0,    cos(theta/2),   0,
    0,              0,    0,              1
  )
end

Matrix_4x4.CreateRotationZ = function(theta)
  return Matrix_4x4:new(
    cos(theta),   sin(theta),   0,    0,
    -sin(theta),  cos(theta),   0,    0,
    0,            0,            1,    0,
    0,            0,            0,    1
  )
end

Matrix_4x4.CreateTranslation = function(x, y, z)
  return Matrix_4x4:new(
    1,  0,  0,  0,
    0,  1,  0,  0,
    0,  0,  1,  0,
    x,  y,  z,  1
  )
end

Matrix_4x4.CreateProjection = function(fov, ar, nearPlane, farPlane)
  local fovRad = 1 / tan(fov * 0.5 / 180 * PI)
  return Matrix_4x4:new(
    ar * fovRad,      0.0,      0.0,                                                  0.0,
    0.0,              fovRad,   0.0,                                                  0.0,
    0.0,              0.0,      farPlane / (farPlane - nearPlane),                    1.0,
    0.0,              0.0,      (-farPlane * nearPlane) / (farPlane - nearPlane),     0.0
  )
end

Matrix_4x4.PointAt = function(pos, target, up)
  -- calculate new forward direction
  local vNewForward = (target - pos):Normalize()

  -- calculate new up direction
  local a = vNewForward * Vector3d.GetDotProduct(up, vNewForward)
  local vNewUp = (up - a):Normalize()

  -- calculate new right direction
  local vNewRight = Vector3d.GetCrossProduct(vNewUp, vNewForward)

  -- construct Dimensioning and Translation matrix
  local matrix = Matrix_4x4:new(
    vNewRight.x,      vNewRight.y,     vNewRight.z,     0,
    vNewUp.x,         vNewUp.y,        vNewUp.z,        0,
    vNewForward.x,    vNewForward.y,   vNewForward.z,   0,
    pos.x,            pos.y,           pos.z,           1
  )
  
  return matrix
end

Matrix_4x4.QuickInverse = function(m)
  local matrix = Matrix_4x4:new(
    m.matrix[1][1], m.matrix[2][1], m.matrix[3][1], 0,
    m.matrix[1][2], m.matrix[2][2], m.matrix[3][2], 0,
    m.matrix[1][3], m.matrix[2][3], m.matrix[3][3], 0,
    0,              0,              0,              1
  )
  
  matrix.matrix[4][1] = -( m.matrix[4][1] * matrix.matrix[1][1] + m.matrix[4][2] * matrix.matrix[2][1] + m.matrix[4][3] * matrix.matrix[3][1] )
  matrix.matrix[4][2] = -( m.matrix[4][1] * matrix.matrix[1][2] + m.matrix[4][2] * matrix.matrix[2][2] + m.matrix[4][3] * matrix.matrix[3][2] )
  matrix.matrix[4][3] = -( m.matrix[4][1] * matrix.matrix[1][3] + m.matrix[4][2] * matrix.matrix[2][3] + m.matrix[4][3] * matrix.matrix[3][3] )

  return matrix
end

return Matrix_4x4