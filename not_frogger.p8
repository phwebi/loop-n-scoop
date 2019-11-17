pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

left = 0
right = 1
up = 2
down = 3
btn_z = 4
btn_x = 5

-- map
circ_orig = 63
circ_r = 51

-- player
p_radius = 55
p_anim_wait=2
p_sprite_start=16
p_sprite_end=20
angular_speed = .005
aim_speed = 0.002

p_leap_sprite_start = 21
p_leap_sprite_end = 22
leap_speed = 2

p_dead_sprite = 23

local moving, aiming, leaping, dead = 0, 1, 2, 3

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
pickup_sound = 0

-- enemies
local rock, seal, shark = 0, 1, 2

rock_sprite = 49
seal_anim_wait= 10
seal_sprite_start = 32
seal_sprite_end = 34
seal_speed = .001
shark_anim_wait = 3
shark_sprite_start = 36
shark_sprite_end = 40
shark_speed = 0.5

function _init()
  -- draw black pixels
  palt(0, false)
 
  -- don't draw light blue pixels
  palt(12, true)

  p.x, p.y = ang_to_pl_coord(0)

  pickups = {}
  enemies = {}
  add_pickup()
  add_enemy(rock)
  add_enemy(seal)
  add_enemy(shark)
end

-- player functions
function min_aim_angle() -- 90 deg aim range
  return atan2(circ_orig - p.x, circ_orig - p.y) - 0.125
end

function max_aim_angle() -- 90 deg aim range
  return min_aim_angle() + 0.25
end

function regulate_aim()
  if p.aim < 0 then
    p.aim = p.aim + 1
  elseif p.aim > 1 then
    p.aim = p.aim - 1
  end

  max_a = max_aim_angle()
  min_a = min_aim_angle()

  if min_a < 0 then min_a = min_a + 1 end
  if max_a > 1 then max_a = max_a - 1 end

  printh('p.aim: ' .. p.aim)
  printh('max: ' .. max_a)
  printh('min: ' .. min_a)

  if max_a > min_a then
    if p.aim > max_a then
      p.aim_speed = -abs(p.aim_speed)
    elseif p.aim < min_a then
      p.aim_speed = abs(p.aim_speed)
    end
  else
    if p.aim > max_a and p.aim < 0.5 then
      p.aim_speed = -abs(p.aim_speed)
    elseif p.aim < min_a and p.aim > 0.5 then
      p.aim_speed = abs(p.aim_speed)
    end
  end
end

function animate_player(sprite_start, sprite_end)
  p.timer+=1

  if p.timer > p_anim_wait then
    p.sprite+=1
    p.timer = 0
  end

  if p.sprite > sprite_end then
    p.sprite = sprite_start
  end
end

function handle_player_movement()
  updated = false
  angle = pl_coord_to_ang(p.x, p.y)

  if (btn(left)) then
    angle+=angular_speed
    if angle > 1 then angle = 0 end
    
    p.ccw = true
    updated = true

    p.aim+=angular_speed
    regulate_aim()
  elseif (btn(right)) then
    if angle == 0 then angle = 1 end
    angle-=angular_speed
    if angle < 0 then angle = 1 end

    p.ccw = false
    updated = true

    p.aim-=angular_speed
    regulate_aim()
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

-- pickup functions
function add_pickup()
  local o = {}
  o.sprite = flr(rnd(pickup_sprites_end - pickup_sprites_start + 1)) + pickup_sprites_start
  o.x, o.y = rand_point_in_circle(circ_orig, circ_orig, circ_r - 4)
  o.timer = 0
  o.direction = rnd(1) -- angular direction

  add(pickups, o)
end

function handle_pickup(obj)
  if collide(obj, p) then
    sfx(pickup_sound)
    p.score+=1
    del(pickups, obj)
  end
end

function handle_pickup_movement(o)
  x = o.x + pickup_speed * cos(o.direction)
  y = o.y + pickup_speed * sin(o.direction)

  if on_circle(circ_orig, circ_orig, x, y, circ_r - 3) then
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

-- enemy functions
function add_enemy(enemy_type)
  local enemy = {}
  enemy.type = enemy_type
  if enemy.type == rock then
    enemy.sprite = rock_sprite
    enemy.x, enemy.y = rand_point_in_circle(circ_orig, circ_orig, circ_r - 8)
  elseif enemy.type == seal then
    enemy.sprite = seal_sprite_start
    enemy.sprite_start = seal_sprite_start
    enemy.sprite_end = seal_sprite_end
    enemy.anim_wait = seal_anim_wait
    enemy.timer = 0
    enemy.flip = false
    enemy.h = 1
    enemy.w = 2
    enemy.x, enemy.y = ang_to_pl_coord(0.5)
  elseif enemy.type == shark then
    enemy.sprite = shark_sprite_start
    enemy.sprite_start = shark_sprite_start
    enemy.sprite_end = shark_sprite_end
    enemy.anim_wait = shark_anim_wait
    enemy.timer = 0
    enemy.flip = false
    enemy.h = 2
    enemy.w = 2
    enemy.x, enemy.y = circ_orig, circ_orig
  end

  add(enemies, enemy)
end

function handle_enemy(enemy)
  if collide(enemy, p) then
    p.state = dead
    p.sprite = p_dead_sprite
  end
end

function enemy_speed_mod()
  return (p.score + 2)/2
end

function handle_enemy_movement(enemy)
  if enemy.type == seal then
    angle = pl_coord_to_ang(enemy.x, enemy.y)
    angle+=min(seal_speed * enemy_speed_mod(), 0.008)

    if angle > 1 then angle = 0 end

    enemy.x, enemy.y = ang_to_pl_coord(angle)
    enemy.flip = enemy.y < circ_orig
  elseif enemy.type == shark then
    x = enemy.x + min(shark_speed * enemy_speed_mod(), 1)

    if enemy.flip then
      x = enemy.x - min(shark_speed * enemy_speed_mod(), 1)
    end

    if on_circle(circ_orig, circ_orig, x, enemy.y, circ_r - 7) then
      enemy.flip = not enemy.flip
    else
      enemy.x = x
    end
  end

  animate_enemy(enemy)
end

function animate_enemy(enemy)
  if enemy.type == seal or enemy.type == shark then
    enemy.timer+=1

    if enemy.timer > enemy.anim_wait then
      enemy.sprite+=enemy.w
      enemy.timer = 0
    end

    if enemy.sprite > enemy.sprite_end then
      enemy.sprite = enemy.sprite_start
    end
  end
end

function _update()
  if (p.state == moving) then
    if btnp(btn_z) then setup_aim() end -- press z to aim
  elseif (p.state == aiming) then
    if btnp(btn_x) then -- press x to cancel
      p.state = moving
    elseif btnp(btn_z) then -- press z to confirm
      p.state = leaping
      p.sprite = p_leap_sprite_start
    else -- update cursor
      p.aim += p.aim_speed
      regulate_aim()
    end
  elseif (p.state == leaping) then
    -- update player location
    p.x += leap_speed * cos(p.aim)
    p.y += leap_speed * sin(p.aim)

    if on_circle(circ_orig, circ_orig, p.x, p.y, p_radius) then
      p.state = moving
      p.sprite = p_sprite_start
      p.timer = 0
    else
      animate_player(p_leap_sprite_start, p_leap_sprite_end)
    end

    foreach(pickups, handle_pickup)
  end

  if not (p.state == dead) then
    handle_player_movement()

    foreach(pickups, handle_pickup_movement)
    foreach(enemies, handle_enemy)
    foreach(enemies, handle_enemy_movement)
  end

  if #pickups < 1 then
    add_pickup()
  end
end

function draw_actor(a)
  w = a.w or 1 -- number of 8x8 sprites wide
  h = a.h or 1 -- number of 8x8 sprites wide

  x_offset = (w * 8 / 2) - 1
  y_offset = (h * 8 / 2) - 1
  spr(a.sprite, a.x - x_offset, a.y - y_offset, w, h, a.flip) 
end

function _draw()
  map(0,0,0,0,16,16)
  circfill(circ_orig,circ_orig,circ_r,1)
  circ(circ_orig, circ_orig, circ_r, 6)

  foreach(pickups, draw_actor)
  foreach(enemies, draw_actor)
  draw_actor(p)

  if p.state == aiming then
    aim_x=p.x + 200 * cos(p.aim)
    aim_y=p.y + 200 * sin(p.aim)
    line(p.x, p.y, aim_x, aim_y, 8)
  elseif p.state == dead then
    print("you ded", 4, 4, 1)
    -- TODO: Make a better end game screen
  end

  print(p.score, 112, 4, 1)
end

-- utils
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

function ang_to_pl_coord(angle)
  x_centered=circ_orig + p_radius * cos(angle)
  y_centered=circ_orig + p_radius * sin(angle)

  return x_centered, y_centered
end

function pl_coord_to_ang(x, y)
  return atan2(x - circ_orig, y - circ_orig)
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

__gfx__
0000000077777777ccceeeccccc999cccccdddccccc444cccccfffccccc333ccccc888cc00000000000000000000000000033000000000000000000000000000
0000000077777767cceef7eccc99a79cccdd67dccc44f74cccffa7fccc33b73ccc88e78c000000000000000000000000000bb000000000000000000000000000
0070070077777777ceeeef7ec9999a79cdddd67dc4444f74cffffa7fc3333b73c8888e780000000000000000000000000007b000000000000000000000000000
0007700077777777c2eeeefec49999a9c2dddd6dc24444f4c4ffffafc03333b3c28888e800000000000000000000000000b79b00000000000000000000000000
0007700076777777c22eeeeec4499999c22dddddc2244444c44fffffc0033333c228888800000000000000000000000000b99b00000000000000000000000000
0070070077777777cc222eeccc44499ccc222ddccc22244ccc444ffccc00033ccc22288c00000000000000000000000000b77b00000000000000000000000000
0000000077776777c222eeeec4449999c222ddddc2224444c444ffffc0003333c222888800000000000000000000000000b99b00000000000000000000000000
0000000077777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000bb000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
ccdd55ccccdd55ccccdd55ccccdd55ccccdd55ccccdd55ccccdd55cccc50555c0000000000000000000000000000000000000000000000000000000000000000
cdddd55ccdddd55ccdddd55ccdddd55ccdddd55ccdddd55ccdddd55cc550774c0000000000000000000000000000000000000000000000000000000000000000
cdd0705ccdd0705ccdd0705ccdd0705ccdd0705ccdd0705ccdd0705cc5d7974c0000000000000000000000000000000000000000000000000000000000000000
cde7972ccde7972ccde7972ccde7972ccde7972ccde7972cdde79725cdd0777c0000000000000000000000000000000000000000000000000000000000000000
cdd7775ccdd77744cdd77744c997775ccd99775cddd77755cdd7775ccdd0dd9c0000000000000000000000000000000000000000000000000000000000000000
cd997744cd99775cc997775ccdd77744cdd77744cd99744ccd99744cccdddd9c0000000000000000000000000000000000000000000000000000000000000000
c666666cc666666cc666666cc666666cc666666ccccccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
ccccccc5d5555cccccccccc5d5555ccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000
ccccc555555555ccccccc555555555cccccccc5555cccccccccccc5555cccccccccccc5555cccccc000000000000000000000000000000000000000000000000
ccccd5d75666655cccccd5d75666655cccccc666555cccccccccc666555cccccccccc666555ccccc000000000000000000000000000000000000000000000000
ccc555756066065cccc555756066065ccccc67666555cccccccc67666555cccccccc67666555cccc000000000000000000000000000000000000000000000000
ccc55d556666665cc5c55d556666665cccc6766666555cccccc6766666555cccccc6766666555ccc000000000000000000000000000000000000000000000000
cc5d555dddddddcc555d555dddddddcccc666666666555cccc666666666555cccc666666666555cc000000000000000000000000000000000000000000000000
c555dddddddddcccc555dddddddddcccc66666666666555cc66666666666555cc66666666666555c000000000000000000000000000000000000000000000000
cc5cccccccccccccccccccccccccccccc66600666600655cc66600666600655cc66600666600655c000000000000000000000000000000000000000000000000
ccc65ccccccccccccccccccccccccccc666600666600655566660066660065556666006666006555000000000000000000000000000000000000000000000000
cc6655cccccccccccccccccccccccccc666666666666655566666666666665556666666666666555000000000000000000000000000000000000000000000000
c666655cccc45cccccccc76ccccccccc666666666666665566666666666666556666666666666655000000000000000000000000000000000000000000000000
66066055cc455cccccc7776ccc7776cc666667777776665566666777777666556666677777766655000000000000000000000000000000000000000000000000
66666665cc4555cccc777766c777766c666677888877665566667788887766556666778888776655000000000000000000000000000000000000000000000000
66777765c45550cccc777776c777776c666778888887765566677888888776556667788888877655000000000000000000000000000000000000000000000000
678888751555001ccc77777677777766666788888888765566678888888876556667888888887655000000000000000000000000000000000000000000000000
ccccccccc11111ccc777777677777776cccc8888cccc765566cccc8888cccc556667cccc8888cccc000000000000000000000000000000000000000000000000
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
__sfx__
000100000000012050120501205012050120501305015050180501c0501c050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
