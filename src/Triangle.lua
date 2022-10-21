local Vector3d = require("Vector3d")
local Vector2d = require("Vector2d")


---@class Triangle
local Triangle = {}

Triangle.points = {}
Triangle.color = {0, 0, 0}
Triangle.texture = {}

Triangle.new = function(self, vec1, vec2, vec3, tex1, tex2, tex3)
  local o = {
    points = {
      vec1 or Vector3d:new(0, 0, 0),
      vec2 or Vector3d:new(0, 0, 0),
      vec3 or Vector3d:new(0, 0, 0)
    },
    texture = {
      tex1 or Vector2d:new(0, 0, 0),
      tex2 or Vector2d:new(0, 0, 0),
      tex3 or Vector2d:new(0, 0, 0)
    }
  }

  for _, vec in ipairs(o.points) do
    if getmetatable(vec) ~= Vector3d then
      return error("Error: Triangle.new: vec is not a Vector3d")
    end
  end

  for _, vec in ipairs(o.texture) do
    if getmetatable(vec) ~= Vector2d then
      return error("Error: Triangle.new: vec is not a Vector2d")
    end
  end

  self.__index = self
  return setmetatable(o, self)
end

Triangle.ClipAgainstPlane = function(planeP, planeN, inTri)
  -- Make sure plane normal is indeed normal
  planeN = Vector3d:new(planeN.x, planeN.y, planeN.z):Normalize()

  -- get the signed distance from point to plane
  local dist = function(p)
    local n = Vector3d:new(p.x, p.y, p.z):Normalize()
    return (planeN.x * p.x + planeN.y * p.y + planeN.z * p.z - Vector3d.GetDotProduct(planeN, planeP))
  end

  -- Create two temporary storage arrays to classify points either side of plane
  -- If distance sign is positive, point lies on "inside" of plane
  local insidePoints = {}
  local outsidePoints = {}
  local insidePointsCount = 0
  local outsidePointsCount = 0

  local insideTextures = {}
  local outsideTextures = {}
  local insideTexturesCount = 0
  local outsideTexturesCount = 0


  -- Get signed distance of each point in triangle to plane
  local distances = {dist(inTri.points[1]), dist(inTri.points[2]), dist(inTri.points[3])}

  for i = 1, 3 do
    if distances[i] >= 0 then
      insidePoints[insidePointsCount + 1] = inTri.points[i]
      insidePointsCount = insidePointsCount + 1
      insideTextures[insideTexturesCount + 1] = inTri.texture[i]
      insideTexturesCount = insideTexturesCount + 1
    else
      outsidePoints[outsidePointsCount + 1] = inTri.points[i]
      outsidePointsCount = outsidePointsCount + 1
      outsideTextures[outsideTexturesCount + 1] = inTri.texture[i]
      outsideTexturesCount = outsideTexturesCount + 1
    end
  end

  -- classify the triangle points, break the input triangle into smaller output triangles if required
  if insidePointsCount == 0 then
    -- All points lie on the outside of plane
    return 0, nil, nil
  end

  if insidePointsCount == 3 then
    -- All points lie on the inside of plane
    local outTri = Triangle:new(
      inTri.points[1], inTri.points[2], inTri.points[3], inTri.texture[1], inTri.texture[2], inTri.texture[3]
    )
    outTri.color = inTri.color
    return 1, outTri, nil
  end

  if insidePointsCount == 1 and outsidePointsCount == 2 then
    -- Triangle should be clipped. As two points lie outside the plane
    -- the triangle simply becomes a smaller triangle
    local outTri = Triangle:new()

    
    -- keep inside point
    outTri.points[1] = insidePoints[1]
    outTri.texture[1] = insideTextures[1]

    
    -- the two new points are at the location where the original
    -- sides of the triangle (lines) intersect with the plane
    local point2, t = Vector3d.IntersectPlane(planeP, planeN, insidePoints[1], outsidePoints[1])
    outTri.points[2] = point2
    outTri.texture[2].u = t * (outsideTextures[1].u - insideTextures[1].u) + insideTextures[1].u
    outTri.texture[2].v = t * (outsideTextures[1].v - insideTextures[1].v) + insideTextures[1].v
    outTri.texture[2].w = t * (outsideTextures[1].w - insideTextures[1].w) + insideTextures[1].w

    local point3, t = Vector3d.IntersectPlane(planeP, planeN, insidePoints[1], outsidePoints[2])
    outTri.points[3] = point3
    outTri.texture[3].u = t * (outsideTextures[2].u - insideTextures[1].u) + insideTextures[1].u
    outTri.texture[3].v = t * (outsideTextures[2].v - insideTextures[1].v) + insideTextures[1].v
    outTri.texture[3].w = t * (outsideTextures[2].w - insideTextures[1].w) + insideTextures[1].w

    
    -- Copy appearance info to new triangle
    outTri.color = inTri.color -- {0, 0, 255}
        
    return 1, outTri, nil
  end

  if insidePointsCount == 2 and outsidePointsCount == 1 then
    -- Triangle should be clipped. As two points lie inside the plane
    -- the triangle simply becomes a "quad"
    local outTri1 = Triangle:new()
    local outTri2 = Triangle:new()

    
    -- the first triangle consists of inside points and a new point 
    -- determined by the location where one side of the triangle intersects with the plane
    outTri1.points[1] = insidePoints[1]
    outTri1.points[2] = insidePoints[2]
    
    outTri1.texture[1] = insideTextures[1]
    outTri1.texture[2] = insideTextures[2]

    local tri1_point3, t = Vector3d.IntersectPlane(planeP, planeN, insidePoints[1], outsidePoints[1])
    outTri1.points[3] = tri1_point3
    outTri1.texture[3].u = t * (outsideTextures[1].u - insideTextures[1].u) + insideTextures[1].u
    outTri1.texture[3].v = t * (outsideTextures[1].v - insideTextures[1].v) + insideTextures[1].v
    outTri1.texture[3].w = t * (outsideTextures[1].w - insideTextures[1].w) + insideTextures[1].w


    -- the second triangle is composed of one of he inside points, a new point
    -- determined by the intersection of the other side of the triangle and the plane,
    -- and the newly created point above
    outTri2.points[1] = insidePoints[2]
    outTri2.points[2] = Vector3d:new(tri1_point3.x, tri1_point3.y, tri1_point3.z)
    
    outTri2.texture[1] = insideTextures[2]
    outTri2.texture[2] = Vector2d:new(outTri1.texture[3].u, outTri1.texture[3].v, outTri1.texture[3].w)

    local tri2_point3, t = Vector3d.IntersectPlane(planeP, planeN, insidePoints[2], outsidePoints[1])
    outTri2.points[3] = tri2_point3
    outTri2.texture[3].u = t * (outsideTextures[1].u - insideTextures[2].u) + insideTextures[2].u
    outTri2.texture[3].v = t * (outsideTextures[1].v - insideTextures[2].v) + insideTextures[2].v
    outTri2.texture[3].w = t * (outsideTextures[1].w - insideTextures[2].w) + insideTextures[2].w

    
    -- Copy appearance info to new triangles
    outTri1.color =  inTri.color -- {255, 0, 0}
    outTri2.color = inTri.color  --{0, 255, 0}

    return 2, outTri1, outTri2
  end
  log("Error: Triangle.ClipAgainstPlane: Should never get here!")
end

return Triangle