local max = math.max
local sort = table.sort
local GL_DrawRect = Graphics.CSurface.GL_DrawRect
local Point, FPS = Hyperspace.Point, Hyperspace.FPS


local SCREEN_WIDTH = 1280
local SCREEN_HEIGHT = 720



local object = Mesh:LoadFromFile('axis.obj')


-- projection matrix
local matMeshProjection = Matrix_4x4.CreateProjection(90, SCREEN_HEIGHT / SCREEN_WIDTH, 0.1, 1000)



local should_draw = false
local elapsed_time = 0

-- script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
--   elapsed_time = elapsed_time + (FPS.SpeedFactor / 16)
-- end)


-- camera vector
local vCamera = Vector3d:new(0, 0, 0)
local vLookDir = Vector3d:new(0, 0, 1)
local yaw = 0

script.on_game_event("STICK1_UP", false, function() -- forward
  vCamera.y = vCamera.y + 1
end)

script.on_game_event("STICK1_DOWN", false, function() -- backward
  vCamera.y = vCamera.y - 1
end)

script.on_game_event("STICK1_LEFT", false, function() -- left
  vCamera.x = vCamera.x + 1
end)

script.on_game_event("STICK1_RIGHT", false, function() -- right
  vCamera.x = vCamera.x - 1
end)


local vForward = vLookDir * 8

script.on_game_event("STICK2_UP", false, function() -- foward
  vCamera = vCamera + vForward
end)

script.on_game_event("STICK2_DOWN", false, function() -- backward
  vCamera = vCamera - vForward
end)

script.on_game_event("STICK2_LEFT", false, function() -- turn left
  yaw = yaw - 1
end)

script.on_game_event("STICK2_RIGHT", false, function() -- turn right
  yaw = yaw + 1
end)

script.on_render_event(Defines.RenderEvents.LAYER_PLAYER, function()end, function()
  if not should_draw then return end

  GL_DrawRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, Color(0, 0, 0, 1))

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


      -- convert world space --> view space
      local triangleViewed = Triangle:new(
        matView * triangleTransformed.points[1],
        matView * triangleTransformed.points[2],
        matView * triangleTransformed.points[3]
      )


      -- project the 3D --> 2D
      local triangleProjected = Triangle:new(
        matMeshProjection * triangleViewed.points[1],
        matMeshProjection * triangleViewed.points[2],
        matMeshProjection * triangleViewed.points[3]
      )


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
      triangleProjected.color = {dotProduct ^ 2 * 255, dotProduct ^ 2 * 255, dotProduct ^ 2 * 255}
      trianglesToDraw[#trianglesToDraw + 1] = triangleProjected
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
    local triangle = trianglesToDraw[i]
    local color = triangle.color
    TriangleFill(triangle.points[1], triangle.points[2], triangle.points[3], color[1], color[2], color[3])
    -- TriangleOutline(triangle.points[1], triangle.points[2], triangle.points[3], 0, 0, 0)
  end
  
end)


script.on_game_event("CANVAS_INIT", false, function()
  should_draw = true
end)

script.on_game_event("CANVAS_END", false, function()
  should_draw = false
end)
