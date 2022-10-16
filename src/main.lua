local Matrix_4x4 = require("Matrix_4x4")
local Vector3d = require("Vector3d")
local Mesh = require("Mesh")
local Triangle = require("Triangle")
local TriangleOutline, TriangleFill, GetColor, Color = require("util")()



function love.load()
  max = math.max
  sort, remove = table.sort, table.remove
  
  
  SCREEN_WIDTH = 1280
  SCREEN_HEIGHT = 720
  
  
  object = Mesh:LoadFromFile('obj/axis.obj')
  
  
  -- projection matrix
  matMeshProjection = Matrix_4x4.CreateProjection(90, SCREEN_HEIGHT / SCREEN_WIDTH, 0.1, 1000)
  
  
  
  -- camera vector
  vCamera = Vector3d:new(0, 0, 0)
  vLookDir = Vector3d:new(0, 0, 1)
  yaw = 0
  


  love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)

end



function love.update(dt)

  local isHeld = love.keyboard.isDown

  if isHeld('up') then
    vCamera.y = vCamera.y + 8 * dt
  end
  if isHeld('down') then
    vCamera.y = vCamera.y - 8 * dt
  end
  if isHeld('left') then
    vCamera.x = vCamera.x + 8 * dt
  end
  if isHeld('right') then
    vCamera.x = vCamera.x - 8 * dt
  end

  local vForward = vLookDir * 8 * dt

  if isHeld('w') then
    vCamera = vCamera + vForward
  end
  if isHeld('s') then
    vCamera = vCamera - vForward
  end
  if isHeld('a') then
    yaw = yaw - 2 * dt
  end
  if isHeld('d') then
    yaw = yaw + 2 * dt
  end
end


function love.draw()

  local theta = 0

  -- rotation matrices
  local matRotationZ = Matrix_4x4.CreateRotationZ(theta * 0.5)
  local matRotationX = Matrix_4x4.CreateRotationX(theta)

  -- translation matrix
  local matTranslation = Matrix_4x4.CreateTranslation(0, 0, 10)

  -- world matrix
  local matWorld = Matrix_4x4.CreateIdentity()
  matWorld = matRotationZ * matRotationX
  matWorld = matWorld * matTranslation


  -- camera movements 
  local vUp = Vector3d:new(0, 1, 0)
  local vTarget = Vector3d:new(0, 0, 1)
  local matCameraRot = Matrix_4x4.CreateRotationY(yaw)
  vLookDir = matCameraRot * vTarget
  vTarget = vCamera + vLookDir

  local matCamera = Matrix_4x4.PointAt(vCamera, vTarget, vUp)

  local matView = Matrix_4x4.QuickInverse(matCamera)


  -- store triangle for rastering later
  local trianglesToDraw = {}


  -- draw triangles
  for i = 1, #object.triangles do
    local triangle = object.triangles[i]
    
    local triangleTransformed = Triangle:new(
      matWorld * triangle.points[1],
      matWorld * triangle.points[2],
      matWorld * triangle.points[3]
    )

    
    -- get lines from triangle
    local line1 = triangleTransformed.points[2] - triangleTransformed.points[1]
    local line2 = triangleTransformed.points[3] - triangleTransformed.points[1]

    
    -- take cross product of lines to get normal to the triangle face
    local normal = Vector3d.GetCrossProduct(line1, line2):Normalize()


    -- get the ray from the camera to the triangle
    local vCameraRay = triangleTransformed.points[1] - vCamera

    -- if ray i aligned with the normal, then the triangle is visible
    if Vector3d.GetDotProduct(normal, vCameraRay) < 0 then

      -- lighting source
      local vLightDirection = Vector3d:new(0, 1, -1):Normalize()


      -- how aligned are the light direction and the triangle normal?
      local dotProduct = max(0.1, Vector3d.GetDotProduct(vLightDirection, normal))


      -- choose color
      triangleTransformed.color = GetColor(dotProduct)


      -- convert world space --> view space
      local triangleViewed = Triangle:new(
        matView * triangleTransformed.points[1],
        matView * triangleTransformed.points[2],
        matView * triangleTransformed.points[3]
      )
      triangleViewed.color = triangleTransformed.color


      -- clip viewed triangle against near plane, this could form two 
      -- additional triangles
      local clippedTrianglesCount = 0
      local triangleClipped = {}
      clippedTrianglesCount, triangleClipped[1], triangleClipped[2] = Triangle.ClipAgainstPlane(
        Vector3d:new(0, 0, 0.1), Vector3d:new(0, 0, 1), triangleViewed
      )


      -- project as many clipped triangles as we have
      for j = 1, clippedTrianglesCount do
        
        -- project the 3D --> 2D
        local triangleProjected = Triangle:new(
          matMeshProjection * triangleClipped[j].points[1],
          matMeshProjection * triangleClipped[j].points[2],
          matMeshProjection * triangleClipped[j].points[3]
        )
        triangleProjected.color = triangleClipped[j].color


        -- scale into view, manual normalising
        triangleProjected.points[1] = triangleProjected.points[1] / triangleProjected.points[1].w
        triangleProjected.points[2] = triangleProjected.points[2] / triangleProjected.points[2].w
        triangleProjected.points[3] = triangleProjected.points[3] / triangleProjected.points[3].w
        

        -- scale into view
        local vOffsetView = Vector3d:new(1, 1, 0)
        triangleProjected.points[1] = triangleProjected.points[1] + vOffsetView
        triangleProjected.points[2] = triangleProjected.points[2] + vOffsetView
        triangleProjected.points[3] = triangleProjected.points[3] + vOffsetView

        triangleProjected.points[1].x = triangleProjected.points[1].x * (0.5 * SCREEN_WIDTH)
        triangleProjected.points[1].y = triangleProjected.points[1].y * (0.5 * SCREEN_HEIGHT)
        triangleProjected.points[2].x = triangleProjected.points[2].x * (0.5 * SCREEN_WIDTH)
        triangleProjected.points[2].y = triangleProjected.points[2].y * (0.5 * SCREEN_HEIGHT)
        triangleProjected.points[3].x = triangleProjected.points[3].x * (0.5 * SCREEN_WIDTH)
        triangleProjected.points[3].y = triangleProjected.points[3].y * (0.5 * SCREEN_HEIGHT)
        

        -- store the triangle for sorting and drawing
        trianglesToDraw[#trianglesToDraw + 1] = triangleProjected
      end
    end
  end

  -- sort the triangles from back to front
  sort(trianglesToDraw, function(t1, t2)
    local zAvg1 = (t1.points[1].z + t1.points[2].z + t1.points[3].z) / 3
    local zAvg2 = (t2.points[1].z + t2.points[2].z + t2.points[3].z) / 3
    return zAvg1 > zAvg2
  end)

  -- draw triangles in order of distance from the camra, from the queue
  for i = 1, #trianglesToDraw do
    local triangleToRaster = trianglesToDraw[i]

    -- clip triangles against all edges of the screen, and add initial triangle
    local triangleClipped = {}
    local listTriangles = {triangleToRaster}
    local newTriangles = 1

    for p = 1, 4 do
      
      local trianglesToAdd = 0

      while newTriangles > 0 do
        -- take triangle from front of queue
        local test = remove(listTriangles, 1)
        newTriangles = newTriangles - 1

        -- Clip it against a plane. We only need to test each 
        -- subsequent plane, against subsequent new triangles
        -- as all triangles after a plane clip are guaranteed
        -- to lie on the inside of the plane
        if p == 1 then
          trianglesToAdd, triangleClipped[1], triangleClipped[2] = Triangle.ClipAgainstPlane(
            Vector3d:new(0, 0, 0), Vector3d:new(0, 1, 0), test
          )
        elseif p == 2 then
          trianglesToAdd, triangleClipped[1], triangleClipped[2] = Triangle.ClipAgainstPlane(
            Vector3d:new(0, SCREEN_HEIGHT - 1, 0), Vector3d:new(0, -1, 0), test
          )
        elseif p == 3 then
          trianglesToAdd, triangleClipped[1], triangleClipped[2] = Triangle.ClipAgainstPlane(
            Vector3d:new(0, 0, 0), Vector3d:new(1, 0, 0), test
          )
        elseif p == 4 then
          trianglesToAdd, triangleClipped[1], triangleClipped[2] = Triangle.ClipAgainstPlane(
            Vector3d:new(SCREEN_WIDTH - 1, 0, 0), Vector3d:new(-1, 0, 0), test
          )
        end
        
        -- add new triangles to the back of the queue
        for w = 1, trianglesToAdd do
          listTriangles[#listTriangles + 1] = triangleClipped[w]
        end
      end

      newTriangles = #listTriangles
    end

    
    -- draw the transformed, viewed, clipped, projected, sorted, clipped triangles
    for t = 1, #listTriangles do
      local triangle = listTriangles[t]
      local color = triangle.color
      TriangleFill(triangle.points[1], triangle.points[2], triangle.points[3], color[1], color[2], color[3])
      TriangleOutline(triangle.points[1], triangle.points[2], triangle.points[3], 0, 0, 0)
    end
  end

end