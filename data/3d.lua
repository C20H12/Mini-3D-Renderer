local SimpleShape = mods.libs.SG.SimpleShape
local SimpleSprite = mods.libs.SG.SimpleSprite

local should_draw = false

local Object = {
  camra_x = 0,
  camra_y = 0,
  camra_z = 0,
  obj_x = 0,
  obj_y = 0,
  obj_z = 0,
  
  dist_to_screen = 300,

  camra_dir = 0,

  shared_x = 0,
  shared_y = 0,
  shared_is_visible = false,

  new = function(self, initX, initY, initZ)
    local tempObj = {}
    tempObj.obj_x = initX
    tempObj.obj_y = initY
    tempObj.obj_z = initZ
    return setmetatable(tempObj, {__index = self})
  end,

  get_projection = function(self, x, y, z)
    local actual_x = x * self.dist_to_screen / z
    local actual_y = y * self.dist_to_screen / z
    local scale = self.dist_to_screen / z

    if actual_x ~= actual_x then
      actual_x = 0
    end
    if actual_y ~= actual_y then
      actual_y = 0
    end
    if scale == math.huge then
      scale = 1
    end

    self.shared_x = actual_x
    self.shared_y = actual_y

    return actual_x, actual_y, scale
  end,

  display = function(self)
    if should_draw then
      local rotated_x, rotated_z = self:rotate_matrix(self.obj_x - self.camra_x, self.obj_z - self.camra_z, 0 - self.camra_dir)
      local x, y, scale = self:get_projection(rotated_x, self.obj_y - self.camra_y, rotated_z)

      if rotated_z > 25 and (x < 680 and x > -680) and (y < 360 and y > -360) then
        self.shared_is_visible = true
        SimpleSprite:new('scratch')
                    :show({
                            Xalign = x,
                            Yalign = y - 50, 
                            width = 50 * scale,
                            height = 50 * scale,
                          })
      else
        self.shared_is_visible = false
      end
    end
  end,

  rotate_matrix = function(self, x, z, dir)
    local rotated_x = z * math.sin(dir) + x * math.cos(dir)
    local rotated_z = z * math.cos(dir) - x * math.sin(dir)
    return rotated_x, rotated_z
  end,

  set_camra_rotation = function(self, value)
    self.camra_x = self.camra_x + value * math.sin(self.camra_dir)
    self.camra_z = self.camra_z + value * math.cos(self.camra_dir)
  end,

  compute_distance = function(self)
    return math.sqrt((self.obj_x - self.camra_x) ^ 2 + (self.obj_y - self.camra_y) ^ 2 + (self.obj_z - self.camra_z) ^ 2)
  end,

  sort_objects = function(array)
    table.sort(array, function(a, b)
      return a:compute_distance() > b:compute_distance()
    end)
  end
}



local function draw_bg()
  if should_draw then
    SimpleShape:new('rect')
               :show({
                      width = 690, 
                      height = 390, 
                      Yalign = -50, 
                      color = SimpleShape.colorFactory("ffffffff")
                     })
  end
end



local objects = {
  Object:new(100, 100, 200),
  Object:new(-100, 100, 200),
  Object:new(100, -100, 200),
  Object:new(-100, -100, 200),
  Object:new(100, 100, 100),
  Object:new(-100, 100, 100),
  Object:new(100, -100, 100),
  Object:new(-100, -100, 100),
}

script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, function()end, function()
  draw_bg()
  
  -- for _, obj in ipairs(objects) do
  --   obj:display()
  -- end
  Object.sort_objects(objects)

  for i = 1, 8 do
    objects[i]:display()

    -- local next = i == 8 and 1 or i + 1
    -- SimpleShape:new('line'):show({point1 = {objects[i].shared_x, objects[i].shared_y}, point2 = {objects[next].shared_x, objects[next].shared_y}, color=SimpleShape.colorFactory("00ff00ff")})

    for j = 1, 8 do
      if i ~= j and objects[i].shared_is_visible and objects[j].shared_is_visible then
        local color = SimpleShape.colorFactory("00ff00ff")
        local dist1 = objects[i]:compute_distance()
        local dist2 = objects[j]:compute_distance()

        if dist1 < dist2 then
          color = SimpleShape.colorFactory("ff0000ff")
        elseif dist1 == dist2 then
          color = SimpleShape.colorFactory("00ffffff")
        else
          color = SimpleShape.colorFactory("ffff00ff")
        end
        SimpleShape:new('line')
        :show({
                point1 = {objects[i].shared_x, objects[i].shared_y - 50},
                point2 = {objects[j].shared_x, objects[j].shared_y - 50}, 
                color = color
              })
      end
    end
  
  end

  
  

end)

script.on_game_event("CANVAS_INIT", false, function()
  should_draw = true
end)


script.on_game_event("STICK1_UP", false, function()
  for _, obj in ipairs(objects) do
    obj:set_camra_rotation(5)
  end
end)

script.on_game_event("STICK1_DOWN", false, function()
  for _, obj in ipairs(objects) do
    obj:set_camra_rotation(-5)
  end
end)

script.on_game_event("STICK1_LEFT", false, function()
  for _, obj in ipairs(objects) do
    obj.camra_dir = obj.camra_dir - 0.1
  end
end)

script.on_game_event("STICK1_RIGHT", false, function()
  for _, obj in ipairs(objects) do
    obj.camra_dir = obj.camra_dir + 0.1
  end
end)

script.on_game_event("STICK2_LEFT", false, function()
  for _, obj in ipairs(objects) do
    obj.camra_x = obj.camra_x + 10
  end
end)

script.on_game_event("STICK2_RIGHT", false, function()
  for _, obj in ipairs(objects) do
    obj.camra_x = obj.camra_x - 10
  end
end)
