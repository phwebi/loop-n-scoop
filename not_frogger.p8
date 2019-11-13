pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- map
circ_orig = 63
circ_r = 55

-- player
p_radius = 59
p_sprite_start=16
p_sprite_end=20
anim_wait=2
angular_speed = .005
aim_speed = 0.002

p_leap_sprite_start = 32
p_leap_sprite_end = 33
leap_speed = 2

left = 0
right = 1
up = 2
down = 3
btn_z = 4
btn_x = 5

local moving, aiming, leaping = 0, 1, 2

p = {}
p.x = 0
p.y = 0
p.state = moving
p.aim_speed = aim_speed
p.aim = 0
p.sprite = p_sprite_start
p.timer = 0
p.flip = false
p.ccw = false
p.score = 0

-- pickups
pickup_sprites_start = 2
pickup_sprites_end = 8
bob_wait = 10
pickup_speed = 0.2

function _init()
  -- draw black pixels
  palt(0, false)
 
  -- don't draw light blue pixels
  palt(12, true)

  p.x, p.y = ang_to_pl_coord(0)

  pickups = {}
  add_pickup()
end

function pl_coord_centered()
  return p.x + 3, p.y + 3
end

function ang_to_pl_coord(angle)
  x_centered=circ_orig + p_radius * cos(angle)
  y_centered=circ_orig + p_radius * sin(angle)

  return x_centered - 3, y_centered - 3
end

function pl_coord_to_ang(x, y)
  return atan2(x - circ_orig, y - circ_orig)
end

function min_aim_angle() -- 90 deg aim range
  x, y = pl_coord_centered()
  return atan2(circ_orig - x, circ_orig - y) - 0.125
end

function max_aim_angle() -- 90 deg aim range
  return min_aim_angle() + 0.25
end

function dist_from_origin(x_o, y_o, x, y)
  return sqrt((x - x_o)*(x - x_o) + (y - y_o)*(y - y_o))
end

function on_circle(x_o, y_o, x, y, r)
  d = dist_from_origin(x_o, y_o, x, y)
  return abs(d - r) < 1 -- allow for margin of error
end

function rand_point_in_circle(originx, originy, radius)
  r = radius * sqrt(rnd(1))
  theta = rnd(1) * 2 * 3.14159
  x = originx + r * cos(theta)
  y = originy + r * sin(theta)

  return x, y
end

function add_pickup()
  local o = {}
  o.sprite = flr(rnd(pickup_sprites_end - pickup_sprites_start)) + pickup_sprites_start
  o.x, o.y = rand_point_in_circle(circ_orig, circ_orig, circ_r - 8)
  o.timer = 0
  o.direction = rnd(1) -- angular direction

  add(pickups, o)
end

function handle_pickup_movement(o)
  x = o.x + pickup_speed * cos(o.direction)
  y = o.y + pickup_speed * sin(o.direction)

  if on_circle(circ_orig, circ_orig, x, y, circ_r - 8) then
    o.direction = rnd(1)
  else
    o.x, o.y = x, y
  end

  animate_pickup(o)
end

function animate_pickup(o)
  o.timer += 1

  if o.timer == 2*bob_wait then o.timer = 0 end

  if (o.timer == 0) then
    o.y+=1
  elseif (o.timer == bob_wait) then
    o.y-=1
  end
end

function animate_player(sprite_start, sprite_end)
  p.timer+=1

  if p.timer > anim_wait then
    p.sprite+=1
    p.timer = 0
  end

  if p.sprite > sprite_end then
    p.sprite = sprite_start
  end
end

function handle_player_movement()
  updated = false
  angle = pl_coord_to_ang(pl_coord_centered())

  if (btn(left)) then
    angle+=angular_speed
    if angle > 1 then angle = 0 end
    
    p.ccw = true
    updated = true
  elseif (btn(right)) then
    if angle == 0 then angle = 1 end
    angle-=angular_speed
    if angle < 0 then angle = 1 end

    p.ccw = false
    updated = true
  end

  if not updated then return end
  
  animate_player(p_sprite_start, p_sprite_end)

  p.x, p.y = ang_to_pl_coord(angle)
  p.flip =
    (p.y > circ_orig and not p.ccw) or
    (p.y <= circ_orig and p.ccw)
end

function setup_aim()
  p.state = aiming
  p.aim = min_aim_angle()
  p.aim_speed = aim_speed
end

function collide(o1, o2)
  local l = max(o1.x, o2.x)
  local r = min(o1.x+8,  o2.x+8)
  local t = max(o1.y,o2.y)
  local b = min(o1.y+8,  o2.y+8)

  -- they overlapped if the area of intersection is greater than 0
  if l < r and t < b then
    return true
  end
					
	return false
end	

function handle_pickup(obj)
  if collide(obj, p) then
    p.score+=1
    del(pickups, obj)
  end
end

function _update()
  if (p.state == moving) then
    handle_player_movement()

    if btnp(btn_z) then setup_aim() end -- press z to aim
  elseif (p.state == aiming) then
    if btnp(btn_x) then -- press x to cancel
      p.state = moving
    elseif btnp(btn_z) then -- press z to confirm
      p.state = leaping
      p.sprite = p_leap_sprite_start
    else -- update cursor
      p.aim += p.aim_speed

      if (p.aim > max_aim_angle()) or (p.aim < min_aim_angle()) then
        p.aim_speed = -p.aim_speed
      end
    end
  elseif (p.state == leaping) then
    -- update player location
    p.x += leap_speed * cos(p.aim)
    p.y += leap_speed * sin(p.aim)

    x, y = pl_coord_centered()
    if on_circle(circ_orig, circ_orig, x, y, p_radius) then
      p.state = moving
      p.sprite = p_sprite_start
      p.timer = 0
    else
      animate_player(p_leap_sprite_start, p_leap_sprite_end)
    end

    foreach(pickups, handle_pickup)
  end

  foreach(pickups, handle_pickup_movement)

  if #pickups < 1 then
    add_pickup()
  end
end

function draw_actor(a)
  spr(a.sprite,a.x,a.y) 
end

function _draw()
  map(0,0,0,0,16,16)
  circfill(circ_orig,circ_orig,circ_r,1)
  circ(circ_orig, circ_orig, circ_r, 6)

  -- spr(ice_sprite, 63, 63)
  foreach(pickups, draw_actor)

  spr(p.sprite,p.x,p.y,1,1,p.flip) 

  if p.state == aiming then
    aim_x=p.x + 200 * cos(p.aim)
    aim_y=p.y + 200 * sin(p.aim)
    x, y = pl_coord_centered()
    line(x, y, aim_x, aim_y, 8)
  end

  print(p.score, 112, 4, 1)
end
__gfx__
0000000077777777ccceeeccccc999cccccdddccccc444cccccfffccccc333ccccc888cccccccccc000000000000000000000000000000000000000000000000
0000000077777767cceef7eccc99a79cccdd67dccc44f74cccffa7fccc33b73ccc88e78ccccccccc000000000000000000000000000000000000000000000000
0070070077777777ceeeef7ec9999a79cdddd67dc4444f74cffffa7fc3333b73c8888e78ccc45ccc000000000000000000000000000000000000000000000000
0007700077777777c2eeeefec49999a9c2dddd6dc24444f4c4ffffafc03333b3c28888e8cc455ccc000000000000000000000000000000000000000000000000
0007700076777777c22eeeeec4499999c22dddddc2244444c44fffffc0033333c2288888cc4555cc000000000000000000000000000000000000000000000000
0070070077777777cc222eeccc44499ccc222ddccc22244ccc444ffccc00033ccc22288cc45550cc000000000000000000000000000000000000000000000000
0000000077776777c222eeeec4449999c222ddddc2224444c444ffffc0003333c22288881555001c000000000000000000000000000000000000000000000000
0000000077777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111cc000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccdd55ccccdd55ccccdd55ccccdd55ccccdd55cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cdddd55ccdddd55ccdddd55ccdddd55ccdddd55c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cdd0705ccdd0705ccdd0705ccdd0705ccdd0705c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cde7972ccde7972ccde7972ccde7972ccde7972c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cdd7775ccdd77744cdd77744c997775ccd99775c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cd997744cd99775cc997775ccdd77744cdd777440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c666666cc666666cc666666cc666666cc666666c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccdd55ccccdd55cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cdddd55ccdddd55c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cdd0705ccdd0705c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cde7972cdde797250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd77755cdd7775c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cd99744ccd99744c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc6655c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc666655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c6666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
