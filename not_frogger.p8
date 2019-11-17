pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
SPRITE_TRANSPARENT_COLOR = 12

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

-- floating effects
bob_wait = 10
float_speed = 0.2

-- pickups
pickup_sprites_start = 2
pickup_sprites_end = 8
pickup_sound = 0

-- enemies
local rock, seal, shark = 0, 1, 2

rock_sprite_start = 50
rock_sprite_end = 51
rock_speed = 0.2

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
  palt(SPRITE_TRANSPARENT_COLOR, true)

  p.x, p.y = ang_to_pl_coord(0)

  floaters = {}
  pickups = {}
  enemies = {}
  add_pickup()
  add_enemy(rock)
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

  local max_a = max_aim_angle()
  local min_a = min_aim_angle()

  if min_a < 0 then min_a = min_a + 1 end
  if max_a > 1 then max_a = max_a - 1 end

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
  local updated = false
  local angle = pl_coord_to_ang(p.x, p.y)

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
  o.x, o.y = rand_point_in_circle(circ_orig, circ_orig, circ_r - 8)
  o.timer = 0
  o.direction = rnd(1) -- angular direction

  add(pickups, o)
  add(floaters, o)
end

function handle_pickup(obj)
  if collide(obj, p) then
    sfx(pickup_sound)
    p.score+=1
    del(pickups, obj)
    del(floaters, obj)
  end
end

function handle_float_movement(o)
  local x = o.x + float_speed * cos(o.direction)
  local y = o.y + float_speed * sin(o.direction)

  for f in all(floaters) do
    if o != f and collide(o, f) then
      if o.direction >= 0.5 then
        o.direction -= (0.5 - o.direction - f.direction)
      else
        o.direction += (0.5 - o.direction - f.direction)
      end

      if f.direction >= 0.5 then
        o.direction -= (0.5 - o.direction - f.direction)
      else
        f.direction += (0.5 - o.direction - f.direction)
      end
    end
  end

  if on_circle(circ_orig, circ_orig, x, y, circ_r - 7) then
    o.direction = rnd(1)
  else
    o.x, o.y = x, y
  end

  animate_float(o)
end

function animate_float(o)
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
    enemy.sprite = flr(rnd(rock_sprite_end - rock_sprite_start + 1)) + rock_sprite_start
    enemy.x, enemy.y = rand_point_in_circle(circ_orig, circ_orig, circ_r - 8)
    enemy.timer = 0
    enemy.direction = rnd(1)
    add(floaters, enemy)
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
  if enemy.type == rock then
    handle_float_movement(enemy)
  elseif enemy.type == seal then
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
  if enemy.type == rock then
    animate_float(enemy)
  elseif enemy.type == seal or enemy.type == shark then
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
    handle_player_movement()
    if btnp(btn_z) then setup_aim() end -- press z to aim
  elseif (p.state == aiming) then
    handle_player_movement()
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
    foreach(pickups, handle_float_movement)
    foreach(enemies, handle_enemy)
    foreach(enemies, handle_enemy_movement)
  end

  if #pickups < 1 then
    add_pickup()
  end
end

function draw_actor(a)
  local w = a.w or 1 -- number of 8x8 sprites wide
  local h = a.h or 1 -- number of 8x8 sprites wide

  spr(a.sprite, a.x - position_offset(w), a.y - position_offset(h), w, h, a.flip) 
end

function draw_aim()
  local x = p.x
  local y = p.y
  local i = 0

  x+=leap_speed * cos(p.aim)
  y+=leap_speed * sin(p.aim)

  while in_circle(circ_orig, circ_orig, x, y, p_radius) do
    -- draw path
    if i%5 == 0 then
      circfill(x, y, 1, 12)
    end

    x+=leap_speed * cos(p.aim)
    y+=leap_speed * sin(p.aim)
    i+=1
  end

  circ(x, y, 4, 12)
end

function _draw()
  map(0,0,0,0,16,16)
  circfill(circ_orig,circ_orig,circ_r,1)
  circ(circ_orig, circ_orig, circ_r, 6)

  foreach(pickups, draw_actor)
  foreach(enemies, draw_actor)
  draw_actor(p)

  if p.state == aiming then
    draw_aim()
  elseif p.state == dead then
    print("you ded", 4, 4, 1)
    -- TODO: Make a better end game screen
  end

  print(p.score, 112, 4, 6)
  print(p.score, 112, 3, 13)
end

-- utils
function dist_from_origin(x_o, y_o, x, y)
  return sqrt((x - x_o)*(x - x_o) + (y - y_o)*(y - y_o))
end

function on_circle(x_o, y_o, x, y, r)
  local d = dist_from_origin(x_o, y_o, x, y)
  return abs(d - r) < 1 -- allow for margin of error
end

function in_circle(x_o, y_o, x, y, r)
  local d = dist_from_origin(x_o, y_o, x, y)
  return d < r
end

function rand_point_in_circle(originx, originy, radius)
  local r = radius * sqrt(rnd(1))
  local theta = rnd(1) * 2 * 3.14159
  local x = originx + r * cos(theta)
  local y = originy + r * sin(theta)

  return x, y
end

function ang_to_pl_coord(angle)
  local x_centered=circ_orig + p_radius * cos(angle)
  local y_centered=circ_orig + p_radius * sin(angle)

  return x_centered, y_centered
end

function pl_coord_to_ang(x, y)
  return atan2(x - circ_orig, y - circ_orig)
end

function position_offset(pos)
  return ((pos or 1)*8/2) - 1
end

function collide(o1, o2)
  local x1 = o1.x - position_offset(o1.w)
  local y1 = o1.y - position_offset(o1.h)
  local x2 = o2.x - position_offset(o2.w)
  local y2 = o2.y - position_offset(o2.h)

  return collide_pixel(o1, o2, x2 - x1, y2 - y1)
end	

function collide_pixel(o1,o2,xoff,yoff)
  local sh1 = sprite_sheet_coord(o1.sprite)
  local sh2 = sprite_sheet_coord(o2.sprite)

  local a = nil
  local b = nil
  local collision_count = 0

  local x1_end = ((o1.w or 1) * 8) - 1
  local y1_end = ((o1.h or 1) * 8) - 1
  local x2_end = ((o2.w or 1) * 8) - 1
  local y2_end = ((o2.h or 1) * 8) - 1
  
  local xstart = 0
  local xend = max(x1_end, x2_end)
  local ystart = 0
  local yend = max(y1_end, y2_end)
  local x1off = 0
  local x2off = 0
  local y1off = 0
  local y2off = 0
  
  -- narrow range of collision test based on offset of two sprites
  if(xoff > 0) then
    xend-=xoff
    x1off = xoff
  elseif(xoff < 0) then
    xend+=xoff
    x2off = -xoff
  end
  if(yoff > 0) then
    yend-=yoff
    y1off = yoff
  elseif(yoff < 0) then
    yend+=yoff
    y2off = -yoff
  end

  for x = xstart, xend do
    for y = ystart, yend do
      local x1, y1, x2, y2 = x+x1off, y+y1off, x+x2off, y+y2off
      local a, b = SPRITE_TRANSPARENT_COLOR, SPRITE_TRANSPARENT_COLOR

      if (x1 <= x1_end) and (y2 <= y1_end) then
        a = sget(sh1.x + x1, sh1.y + y1)
      end

      if (x2 <= x2_end) and (y2 <= y2_end) then
        b = sget(sh2.x + x1, sh2.y + y1)
      end

      if(a != SPRITE_TRANSPARENT_COLOR and b != SPRITE_TRANSPARENT_COLOR) then collision_count += 1 end
    end
  end

  return collision_count > 0
 end

 -- return object with x,y pixel coords on sprite sheet of given sprite number
 function sprite_sheet_coord(sprite)
  local sh = {}
  sh.x = (sprite%16)*8
  sh.y = flr(sprite/16)*8
  return sh
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
