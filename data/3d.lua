local SimpleShape = mods.libs.SG.SimpleShape
local SimpleSprite = mods.libs.SG.SimpleSprite
local math_sin, math_cos, math_tan, sqrt, HUGE, PI = math.sin, math.cos, math.tan, math.sqrt, math.huge, math.pi
local sort = table.sort

local should_draw = false

local CustomMath = {
  sin = function(x)
    return math_sin(x * PI / 180)
  end,
  cos = function(x)
    return math_cos(x * PI / 180)
  end,
  tan = function(x)
    return math_tan(x * PI / 180)
  end,
  toDeg = function(x)
    return x * 180 / PI
  end,
  toRad = function(x)
    return x * PI / 180
  end,
}

local sin, cos, tan = CustomMath.sin, CustomMath.cos, CustomMath.tan

local Camra = {
  camra_x = 0,
  camra_y = 0,
  camra_z = 0,

  camra_dir_y = 0,
  camra_dir_x = 0,

  dist_to_screen = 300,

  camra_move_forward = function(self, value)
    self.camra_x = self.camra_x + value * sin(self.camra_dir_y)
    self.camra_z = self.camra_z + value * cos(self.camra_dir_y)
  end,

  camra_move_horizontal = function(self, value)
    self.camra_x = self.camra_x + value * cos(self.camra_dir_y)
    self.camra_z = self.camra_z - value * sin(self.camra_dir_y)
  end,

  camra_move_vertical = function(self, value)
    self.camra_y = self.camra_y + value
  end,

  camra_rotate_y = function(self, value)
    self.camra_dir_y = self.camra_dir_y + value
  end,
  
  camra_rotate_x = function(self, value)
    self.camra_dir_x = self.camra_dir_x + value
  end,

  camra_rotate_z = function(self, value)
    self.camra_dir_z = self.camra_dir_z + value
  end,
}


local Object = {
  
  obj_x = 0,
  obj_y = 0,
  obj_z = 0,

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
    local actual_x = x * Camra.dist_to_screen / z
    local actual_y = y * Camra.dist_to_screen / z
    local scale = Camra.dist_to_screen / z

    if actual_x ~= actual_x then
      actual_x = 0
    end
    if actual_y ~= actual_y then
      actual_y = 0
    end
    if scale == HUGE then
      scale = 1
    end

    self.shared_x = actual_x
    self.shared_y = actual_y

    return actual_x, actual_y, scale
  end,

  display = function(self)
    if should_draw then
      local rotated_x, rotated_y, rotated_z = self:rotate_matrix()
      local x, y, scale = self:get_projection(rotated_x, rotated_y, rotated_z)

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

  rotate_matrix = function(self)
    local x = self.obj_x - Camra.camra_x
    local y = self.obj_y - Camra.camra_y
    local z = self.obj_z - Camra.camra_z
    local dir_y = 0 - Camra.camra_dir_y
    local dir_x = 0 - Camra.camra_dir_x
    local rotated_x = z * sin(dir_y) + x * cos(dir_y)
    local rotated_z = z * cos(dir_y) - x * sin(dir_y) * cos(dir_x) - y * sin(dir_x)
    local rotated_y = rotated_z * sin(dir_x) + y * cos(dir_x)
    return rotated_x, rotated_y, rotated_z
  end,

  compute_distance = function(self)
    return sqrt((self.obj_x - Camra.camra_x) ^ 2 + (self.obj_y - Camra.camra_y) ^ 2 + (self.obj_z - Camra.camra_z) ^ 2)
  end,

  sort_objects = function(array)
    sort(array, function(a, b)
      return a:compute_distance() > b:compute_distance()
    end)
  end,
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

local function draw_horizon()
  if should_draw then
    local x_pos = 0
    local y_pos = tan(0 - Camra.camra_dir_x) * Camra.dist_to_screen
    SimpleSprite:new('bg')
                :show({
                        Xalign = x_pos,
                        Yalign = y_pos,
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

script.on_render_event(Defines.RenderEvents.LAYER_PLAYER, function()end, function()
  draw_horizon()
  

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

script.on_game_event("CANVAS_END", false, function()
  should_draw = false
end)

script.on_game_event("STICK1_UP", false, function() -- forward
  Camra:camra_move_forward(5)
end)

script.on_game_event("STICK1_DOWN", false, function() -- backward
  Camra:camra_move_forward(-5)
end)

script.on_game_event("STICK1_LEFT", false, function() -- left strafe
  Camra:camra_move_horizontal(-5)
end)

script.on_game_event("STICK1_RIGHT", false, function() -- right strafe
  Camra:camra_move_horizontal(5)
end)

script.on_game_event("STICK2_UP", false, function() -- up rotate
  if Camra.camra_dir_x > 45 then return end
  Camra:camra_rotate_x(5)
end)

script.on_game_event("STICK2_DOWN", false, function() -- down rotate
  if Camra.camra_dir_x < -45 then return end
  Camra:camra_rotate_x(-5)
end)

script.on_game_event("STICK2_LEFT", false, function() -- left rotate
  Camra:camra_rotate_y(-5)
end)

script.on_game_event("STICK2_RIGHT", false, function() -- right rotate
  Camra:camra_rotate_y(5)
end)

script.on_game_event("STICK3_UP", false, function() -- up move
  Camra:camra_move_vertical(5)
end)

script.on_game_event("STICK3_DOWN", false, function() -- down move
  Camra:camra_move_vertical(-5)
end)

script.on_game_event("STICK3_LEFT", false, function() -- left move
  Camra:camra_rotate_z(-5)
end)

script.on_game_event("STICK3_RIGHT", false, function() -- right move
  Camra:camra_rotate_z(5)
end)
