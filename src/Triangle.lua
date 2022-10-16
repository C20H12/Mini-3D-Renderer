local Vector3d = require("Vector3d")


---@class Triangle
local Triangle = {}

Triangle.points = {}
Triangle.color = {0, 0, 0}

Triangle.new = function(self, vec1, vec2, vec3)
  local o = {points = {
    vec1 or Vector3d:new(0, 0, 0),
    vec2 or Vector3d:new(0, 0, 0),
    vec3 or Vector3d:new(0, 0, 0)
  }}

  for _, vec in ipairs(o.points) do
    if getmetatable(vec) ~= Vector3d then
      return error("Error: Triangle.new: vec is not a Vector3d")
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

  -- Get signed distance of each point in triangle to plane
  local dist1 = dist(inTri.points[1])
  local dist2 = dist(inTri.points[2])
  local dist3 = dist(inTri.points[3])

  if dist1 >= 0 then
    insidePoints[insidePointsCount + 1] = inTri.points[1]
    insidePointsCount = insidePointsCount + 1
  else
    outsidePoints[outsidePointsCount + 1] = inTri.points[1]
    outsidePointsCount = outsidePointsCount + 1
  end

  if dist2 >= 0 then
    insidePoints[insidePointsCount + 1] = inTri.points[2]
    insidePointsCount = insidePointsCount + 1
  else
    outsidePoints[outsidePointsCount + 1] = inTri.points[2]
    outsidePointsCount = outsidePointsCount + 1
  end

  if dist3 >= 0 then
    insidePoints[insidePointsCount + 1] = inTri.points[3]
    insidePointsCount = insidePointsCount + 1
  else
    outsidePoints[outsidePointsCount + 1] = inTri.points[3]
    outsidePointsCount = outsidePointsCount + 1
  end

  -- classify the triangle points, break the input triangle into smaller output triangles if required
  if insidePointsCount == 0 then
    -- All points lie on the outside of plane
    return 0, nil, nil
  end

  if insidePointsCount == 3 then
    -- All points lie on the inside of plane
    local outTri = Triangle:new(inTri.points[1], inTri.points[2], inTri.points[3])
    outTri.color = inTri.color
    return 1, outTri, nil
  end

  if insidePointsCount == 1 and outsidePointsCount == 2 then
    -- Triangle should be clipped. As two points lie outside the plane
    -- the triangle simply becomes a smaller triangle

    local outTri = Triangle:new(
      -- keep inside point
      insidePoints[1],

      -- the two new points are at the location where the original
      -- sides of the triangle (lines) intersect with the plane
      Vector3d.IntersectPlane(planeP, planeN, insidePoints[1], outsidePoints[1]),
      Vector3d.IntersectPlane(planeP, planeN, insidePoints[1], outsidePoints[2])
    )

    -- Copy appearance info to new triangle
    outTri.color = inTri.color -- {0, 0, 255}
        
    return 1, outTri, nil
  end

  if insidePointsCount == 2 and outsidePointsCount == 1 then
    -- Triangle should be clipped. As two points lie inside the plane
    -- the triangle simply becomes a "quad"

    -- the first triangle consists of inside points and a new point 
    -- determined by the location where one side of the triangle intersects with the plane
    local outTri1 = Triangle:new(
      insidePoints[1],
      insidePoints[2],
      Vector3d.IntersectPlane(planeP, planeN, insidePoints[1], outsidePoints[1])
    )

    -- the second triangle is composed of one of he inside points, a new point
    -- determined by the intersection of the other side of the triangle and the plane,
    -- and the newly created point above
    local outTri2 = Triangle:new(
      insidePoints[2],
      outTri1.points[3],
      Vector3d.IntersectPlane(planeP, planeN, insidePoints[2], outsidePoints[1])
    )

    -- Copy appearance info to new triangles
    outTri1.color =  inTri.color -- {255, 0, 0}
    outTri2.color = inTri.color  --{0, 255, 0}

    return 2, outTri1, outTri2
  end
  log("Error: Triangle.ClipAgainstPlane: Should never get here!")
end

return Triangle