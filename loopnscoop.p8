pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- penguin pete's loop n scoop
-- v0.2.0
--
---------- constants -------------------
SPRITE_TRANSPARENT_COLOR = 12

-- buttons
left = 0
right = 1
up = 2
down = 3
btn_z = 4
btn_x = 5

-- map
circ_orig = 63
circ_r = 51

-- ice cream truck
truck_sprite = 64
truck_w = 5
truck_h = 3

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

-- floating effects
bob_wait = 10

-- scoops
scoop_sprites_start = 2
scoop_sprites_end = 8
wildcard_scoop = 4
scoop_sound = 0

scoop_waiting_sprite = 9
scoop_done_sprite = 10

max_scoops = 8

-- presents
local shield, slow_time = 0, 1
slow_time_mod = 0.25

present_box_sprite = 24
present_sprites_start = 25
present_sprites_end = 26

-- enemies
local seal, shark = 0, 1

seal_anim_wait= 10
seal_sprite_start = 32
seal_sprite_end = 34
seal_speed = .001

shark_anim_wait = 3
shark_sprite_start = 36
shark_sprite_end = 40
shark_speed = 0.5

function bp()
  if (btnp(❎)) return true
  if (btnp(🅾️)) return true
end

function printo(str,x,y,c1,c2)
  for i=-1,1 do
    for j=-1,1 do
      print(str,x+i,y+j,c2)
    end
  end
  print(str,x,y,c1)
end

-- state swapping 
state, next_state, change_state = {}, {}, false

function swap_state(s)
 next_state, change_state = s, true
end

function _init()
  cartdata("loop_n_scoop")
  best=dget(0)
  swap_state(title_state)
end

function _update()
  if (change_state) then
    state, change_state = next_state, false
    state.init()
  end

  state.update()
end

function _draw()
  state.draw()
end

-- title state
first=true
local start, help = 0, 1
function init_title()
  wipe=0
  t=0
  selected = start
end

function update_title()
  t+=1

  if btnp(up) then
    selected = max(0, selected-1)
  elseif btnp(down) then
    selected = min(1, selected+1)
  end
 
  if (bp() and wipe==0) then
    wipe=1
  end
 
  if (wipe>0) then
    wipe+=1
    if (wipe>16) then
      if selected == start then swap_state(play_state) end
      if selected == help then swap_state(help_state) end
    end
  end
end

function draw_title()
  cls(7)
  map(0,0,0,0,16,16)
  
  -- exit wipe
  if (wipe>0) then
    if selected == start then
      for y=0,128,4 do
        circfill(circ_orig, circ_orig, wipe*3, 1)
      end
    elseif selected == help then
      rectfill(0,0,127,10+(wipe)*8,8)
      rectfill(2,2,125,wipe*8,15)
    end
  else
    for i = 0, 7 do
      local y = min(24, t)
      local c = (i%2 == 0) and 15 or 8
      local x_end = ((i+1)*16) - 1
      local x_start = x_end - 16

      circfill(16*(i+1)-8,y+1,8,6)
      rectfill(x_start,0,x_end,y,c)
      circfill(16*(i+1)-8-1,y,8,c)
    end

    local y = t%20 < 10 and 56 or 55
    for i=0, 15 do
      pal(i, 6)
    end
    spr(128, 4, y+1, 16, 2)
    pal()
    spr(128, 3, y, 16, 2)
    print("penguin pete's", 5, y-8, 2)

    if (t>0) then
      local c=t%16>4 and 13 or 8
      local start_color = (selected == start) and c or 13
      local help_color = (selected == help) and c or 13
      print("start", min(55,(t*3.4)-90),86,start_color)
      print("help", min(55,(t*3.4)-90),96,help_color)

      local selected_y = (selected == start) and 86 or 96
      print("❎",min(46,(t*3.4)-99), selected_y, c)
    end 

    -- best
    local str="best: "..best
    printo(str,4,max(119,160-t),7,13)
  end
end

title_state = {
  name = "title",
  init = init_title,
  update = update_title,
  draw = draw_title
}

-- help state
function init_help()
  goal, controls = 0, 1
  page = goal
end

function update_help()
  if bp() then swap_state(title_state) end

  if btnp(left) then
    page = max(0, page-1)
  elseif btnp(right) then
    page = min(1, page+1)
  end
end

function draw_help()
  -- draw black pixels
  palt(0, false)
 
  -- don't draw light blue pixels
  palt(SPRITE_TRANSPARENT_COLOR, true)

  rectfill(0,0,127,127,8)
  rectfill(2,2,125,125,15)

  if page == goal then
    printo("goal",10,10,7,8)
    print("RUN YOUR ICE CREAM SHOP AND",9,20,8)
    print("AVOID ARCTIC PREDATORS.",9,28,8)

    spr(truck_sprite, 41, 40, truck_w, truck_h)
    spr(scoop_sprite(1), 68, 46)
    spr(scoop_sprite(2), 62, 46)
    print("COLLECT ONLY FLAVORS NEEDED",9,70,8)
    print("FOR YOUR NEXT ORDER - OR DIE.",9,80,8)
    print("SPAWN WILDCARDS",9,95,8)
    spr(scoop_sprite(wildcard_scoop),68,94)
    print("BY GETTING",80,95,8)
    print("AN ORDER IN 1 MOVE.",9, 105,8)
  elseif page == controls then
    printo("controls",10,10,7,8)
    print("⬅️➡️ to move",9, 20, 8)
    print("🅾️   to aim",9, 30, 8)

    print("WHILE AIMING",9,50,2)
    print("🅾️   to select aim",9, 60, 8)
    print("❎   to cancel",9, 70, 8)
  end

  print("❎ close",9, 116, 13)
  print("⬅️",105, 116, page == 0 and 6 or 13)
  print("➡️",113,116, page == 1 and 6 or 13)
end

help_state = {
  name = "help",
  init = init_help,
  update = update_help,
  draw = draw_help,
}

-- play state
function init_play()
  t = 0
  broke_high = false

  p = {
    state = moving,
    aim_speed = aim_speed,
    aim = 0,
    sprite = p_sprite_start,
    timer = 0,
    flip = false,
    ccw = false,
    score = 0,
    leaps = 0,
    powerup = -1,
    power_active = -1,
  }
  p.x, p.y = ang_to_pl_coord(0)

  orders = {}
  floaters = {}
  scoops = {}
  enemies = {}
  presents = {}

  add_enemy(seal)
  add_enemy(shark)

  add_order()
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

-- presents
function add_present()
  local a = rnd(1)
  local x, y = ang_to_pl_coord(a)
  local power = {
    type = flr(rnd(2)),
    x = x,
    y = y,
    sprite = present_box_sprite,
  }

  add(presents, power)
end

function handle_present(present)
  if collide(present, p) then
    del(presents, present)
    p.powerup = present.type

    if p.powerup == slow_time then
      p.power_active = 600
    end
  end
end

-- orders
function add_order()
  local o = {
    timer = 0,
    scoop1 = flr(rnd(4)), -- 0 through 3
    scoop2 = flr(rnd(4)),
    scoop1_done = 0,
    scoop2_done = 0,
  }

  add(orders, o)
  add_scoop(o.scoop1)
  add_scoop(o.scoop2)
end

function handle_order(o)
  if o.scoop1_done > 0 and o.scoop2_done > 0 then
    p.score += 1
    del(orders, o)

    if o.scoop1_done == o.scoop2_done then
      add_scoop(wildcard_scoop)
    end

    if p.score%5 == 0 then
      add_present()
    end
  end
end

function draw_order(o)
  -- draw in truck
  spr(scoop_sprite(o.scoop2), 116, 112)
  spr(scoop_sprite(o.scoop1), 110, 112)

  if o.scoop1_done then
    if o.scoop1_done > 0 then
      spr(scoop_done_sprite, 112, 100)
    else
      spr(scoop_waiting_sprite, 112, 100)
    end
  end

  if o.scoop2_done > 0 then
    spr(scoop_done_sprite, 119, 100)
  else
    spr(scoop_waiting_sprite, 119, 100)
  end
end

function scoop_sprite(scoop)
  return scoop_sprites_start + scoop
end

-- scoop functions
function add_scoop(flavor)
  local o = {
    flavor = flavor or flr(rnd(4)),
    timer = 0,
    vx = rnd(0.6) - 0.3,
    vy = rnd(0.6) - 0.3,
  }
  o.sprite = scoop_sprites_start + o.flavor
  o.x, o.y = rand_point_in_circle(circ_orig, circ_orig, circ_r - 8)

  add(scoops, o)
  add(floaters, o)
end

function handle_scoop(obj)
  if collide(obj, p) then
    sfx(scoop_sound)
    if #orders > 0 then
      local order = orders[1]
      if (order.scoop1_done == 0) and (obj.flavor == wildcard_scoop or obj.flavor == order.scoop1) then
        order.scoop1_done = p.leaps
      elseif (order.scoop2_done == 0) and (obj.flavor == wildcard_scoop or obj.flavor == order.scoop2) then
        order.scoop2_done = p.leaps
      else
        p.state = dead
      end
    end

    del(scoops, obj)
    del(floaters, obj)
  end
end

function dotpart(vx,vy,nx,ny)
  local dot = vx*nx+vy*ny
  vx = vx - dot*nx
  vy = vy - dot*ny
  return vx,vy
end

function handle_float_movement(o)
  local ovx = p.powerup != slow_time and o.vx or o.vx * slow_time_mod
  local ovy = p.powerup != slow_time and o.vy or o.vy * slow_time_mod
  o.x += ovx
  o.y += ovy

  if (not in_circle(circ_orig, circ_orig, o.x, o.y, circ_r - 7)) then
    o.vx = -o.vx
    o.vy = -o.vy

    ovx = p.powerup != slow_time and o.vx or o.vx * slow_time_mod
    ovy = p.powerup != slow_time and o.vy or o.vy * slow_time_mod

    o.x += o.vx
    o.y += o.vy
  end

  for f in all(floaters) do
    local dx = o.x-f.x
    local dy = o.y-f.y
    local sqrdist = dx*dx+dy*dy

    if sqrdist < 64 and sqrdist > 0 then
      local dist = sqrt(sqrdist)
      local nx = dy/dist
      local ny = -dx/dist

      local dd1x,dd1y=dotpart(o.vx,o.vy,nx,ny)
      local dd2x,dd2y=dotpart(f.vx,f.vy,nx,ny)

      local push = max(0,9-dist)*0.5/dist
      o.x += dx*push
      o.y += dy*push
      f.x -= dx*push
      f.y -= dy*push

      o.vx = o.vx - dd1x + dd2x
      o.vy = o.vy - dd1y + dd2y
      f.vx = f.vx - dd2x + dd1x
      f.vy = f.vy - dd2y + dd1y
    end
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
  local enemy = {
    type = enemy_type,
  }
  if enemy.type == seal then
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
    if p.powerup == shield then
      if p.power_active == -1 then
        p.power_active = 60
      else
        return
      end
    else
      p.state = dead
      p.sprite = p_dead_sprite
    end
  end
end

function enemy_speed_mod()
  if p.powerup == slow_time then
    return slow_time_mod
  end
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

function update_play()
  t+=1

  if p.powerup > -1 and p.power_active > 0 then
    p.power_active-=1
  elseif p.powerup > -1 and p.power_active == 0 then
    p.powerup = -1
    p.power_active = -1
  end

  if (p.state == moving) then
    handle_player_movement()
    if btnp(btn_z) then setup_aim() end -- press z to aim

    if #orders < 1 then add_order() end
    if #scoops < min(3 + flr(p.score/2), max_scoops) then
      add_scoop()
    end
  elseif (p.state == aiming) then
    handle_player_movement()
    if btnp(btn_x) then -- press x to cancel
      p.state = moving
    elseif btnp(btn_z) then -- press z to confirm
      p.state = leaping
      p.sprite = p_leap_sprite_start
      p.leaps+=1
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

    foreach(scoops, handle_scoop)
  end

  if not (p.state == dead) then
    foreach(scoops, handle_float_movement)
    foreach(enemies, handle_enemy)
    foreach(enemies, handle_enemy_movement)
    foreach(orders, handle_order)
    foreach(presents, handle_present)
  end

  if p.score > best then
    broke_high = true

    if p.state == dead then dset(0,p.score) end
  end

  if p.state == dead then swap_state(end_state) end
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

function draw_play()
  -- draw black pixels
  palt(0, false)
 
  -- don't draw light blue pixels
  palt(SPRITE_TRANSPARENT_COLOR, true)

  map(0,0,0,0,16,16)
  circfill(circ_orig,circ_orig,circ_r,1)
  circ(circ_orig, circ_orig, circ_r, 6)


  foreach(presents, draw_actor)
  foreach(scoops, draw_actor)
  foreach(enemies, draw_actor)

  draw_actor(p)
  if p.powerup == shield and p.power_active > 0 then
    circ(p.x, p.y, 5, 9)
  end

  if p.state == aiming then
    draw_aim()
  end

  spr(truck_sprite, 89, 106, truck_w, truck_h)

  foreach(orders, draw_order)

  print("score",2,111,2)
  local d1=flr(p.score/100)
  local d2=flr((p.score-d1*100)/10)
  local d3=p.score-d2*10-d1*100
  pal(0,1)
  spr(69+d1,3,118)
  spr(69+d2,3+8,118)
  spr(69+d3,3+16,118)
  pal(0,broke_high and (t%16<8 and 7 or 9) or 13)
  spr(69+d1,2,117)
  spr(69+d2,2+8,117)
  spr(69+d3,2+16,117)

  if p.power_active < 0 then
    pal(9, 13)
    pal(10, 6)
  end
  if p.powerup >=0 then spr(present_sprites_start + p.powerup, 4, 4) end

  pal()
end

play_state = {
  name = "play",
  init = init_play,
  update = update_play,
  draw = draw_play
}

-- end state
function init_end()
  t = 0
  wipe = 0
end

function update_end()
  t+=1
 
  if (bp() and wipe==0) then
    wipe=1
  end
 
  if (wipe>0) then
    wipe+=1
    if (wipe>=32) swap_state(play_state)
  end
end

function draw_end()
  map(0,0,0,0,16,16)
  circfill(circ_orig,circ_orig,circ_r,1)
  circ(circ_orig, circ_orig, circ_r, 6)

  if (wipe > 0 and wipe<=32)then
    rectfill(0,0+(wipe)*4,128,128,8)
    rectfill(0,10+(wipe)*4,128,128,15)
  else
    draw_play()

    if (t>0) then
      local c=t%16>4 and 7 or 12
      print("❎ restart ",min(38,(t*3.4)-90),90,c)

      local y = min(40, t-42)
      rectfill(0,y, 128, y+42, 8)
      rectfill(0,y+4, 128, y+38, 15)
      printo("game over", 45, y+20, 7, 8)
    end 
  end
end


end_state = {
  name = "end",
  init = init_end,
  update = update_end,
  draw = draw_end,
}

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
0000000077777777ccceeeccccc999cccccdddccccc444cccccdd8ccccc333ccccc888ccc99cccccc33ccccc0000000000000000000000000000000000000000
0000000077777767cceef7eccc99a79cccdd67dccc44f74cccdde79ccc33b73ccc88e78c9a79cccc3b73cccc0000000000000000000000000000000000000000
0070070077777777ceeeef7ec9999a79cdddd67dc4444f74cdd88a73c3333b73c8888e789aa9cccc3bb3cccc0000000000000000000000000000000000000000
0007700077777777c2eeeefec49999a9c2dddd6dc24444f4c28899b3c03333b3c28888e8c99cccccc33ccccc0000000000000000000000000000000000000000
0007700076777777c22eeeeec4499999c22dddddc2244444c2299333c0033333c2288888cccccccccccccccc0000000000000000000000000000000000000000
0070070077777777cc222eeccc44499ccc222ddccc22244ccc44033ccc00033ccc22288ccccccccccccccccc0000000000000000000000000000000000000000
0000000077776777c222eeeec4449999c222ddddc2224444c2203333c0003333c2228888cccccccccccccccc0000000000000000000000000000000000000000
0000000077777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc33c33c999aaaccc99999cc0000000000000000000000000000000000000000
ccdd55ccccdd55ccccdd55ccccdd55ccccdd55ccccdd55ccccdd55cccc50555cceeebe7c9aa77a6c9aaaa79c0000000000000000000000000000000000000000
cdddd55ccdddd55ccdddd55ccdddd55ccdddd55ccdddd55ccdddd55cc550774cc28838ec9aa77a6c9aa9aa960000000000000000000000000000000000000000
cdd0705ccdd0705ccdd0705ccdd0705ccdd0705ccdd0705ccdd0705cc5d7974cc28838ec9aa77a6c9aa9aa960000000000000000000000000000000000000000
cde7972ccde7972ccde7972ccde7972ccde7972ccde7972cdde79725cdd0777cc03333bc9aa77a6c9aaa9a960000000000000000000000000000000000000000
cdd7775ccdd77744cdd77744c997775ccd99775cddd77755cdd7775ccdd0dd9cc28838ecc9a7a66c9aaaaa960000000000000000000000000000000000000000
cd997744cd99775cc997775ccdd77744cdd77744cd99744ccd99744cccdddd9cc22202eccc9a66ccc99999660000000000000000000000000000000000000000
c666666cc666666cc666666cc666666cc666666cccccccccccccccccccccccccccccccccccc66ccccc66666c0000000000000000000000000000000000000000
ccccccc5d5555cccccccccc5d5555ccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000
ccccc555555555ccccccc555555555cccccccc5555cccccccccccc5555cccccccccccc5555cccccc000000000000000000000000000000000000000000000000
ccccd5d75666655cccccd5d75666655cccccc666555cccccccccc666555cccccccccc666555ccccc000000000000000000000000000000000000000000000000
ccc555756066065cccc555756066065ccccc67666555cccccccc67666555cccccccc67666555cccc000000000000000000000000000000000000000000000000
ccc55d556666665cc5c55d556666665cccc6766666555cccccc6766666555cccccc6766666555ccc000000000000000000000000000000000000000000000000
cc5d555dddddddcc555d555dddddddcccc666666666555cccc666666666555cccc666666666555cc000000000000000000000000000000000000000000000000
c555dddddddddcccc555dddddddddcccc66666666666555cc66666666666555cc66666666666555c000000000000000000000000000000000000000000000000
cc5cccccccccccccccccccccccccccccc66600666600655cc66600666600655cc66600666600655c000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccc66660066660065556666006666006555666600666600655500000000000000000000000000033000ccc65ccccccccccc
cccccccccccccccccccccccccccccccc666666666666655566666666666665556666666666666555000000000000000000000000000bb000cc6655cccccccccc
cc7766ccccc776ccccccc76ccccccccc6666666666666655666666666666665566666666666666550000000000000000000000000007b000c666655cccc45ccc
c777766ccc77766cccc7776ccc7776cc66666777777666556666677777766655666667777776665500000000000000000000000000b79b0066066055cc455ccc
77677666c7777766cc777766c777766c66667788887766556666778888776655666677888877665500000000000000000000000000b99b0066666665cc4555cc
77777776c7677776cc777776c777776c66677888888776556667788888877655666778888887765500000000000000000000000000b77b0066777765c45550cc
7766667677767776cc7777767767776666678888888876556667888888887655666788888888765500000000000000000000000000b99b00678888751555001c
7777777677777776c777777677677776cccc8888cccc765566cccc8888cccc556667cccc8888cccc000000000000000000000000000bb000ccccccccc11111cc
ccccccccc2222222222222222222222222222cccc0000ccccc00ccccc0000cccc0000ccccccc00cc00000cccc0000ccc000000ccc0000cccc0000ccc00000000
ccccccccc2777777772777777777777777772ccc000000ccc000cccc000000cc000000cc00cc00cc00000ccc00000ccc000000cc000000cc000000cc00000000
ccccccccc277777777277888ff88ff88ff882ccc00cc00cccc00cccc00cc00cc00cc00cc00cc00cc00cccccc00cccccccccc00cc00cc00cc00cc00cc00000000
ccccccccc2777777772776688ff88ff88ff88ccc00cc00cccc00ccccccc000ccccc00ccc000000cc00000ccc00000ccccc0000ccc0000ccc000000cc00000000
ccccceeeeeee8888882777688ff88ff88ff88ccc00cc00cccc00cccccc000cccccc00ccc000000cc000000cc000000cccc0000ccc0000cccc00000cc00000000
ccccc1d7dddd1d7df82771111111111111112ccc00cc00cccc00ccccc000cccc00cc00cccccc00cccccc00cc00cc00cccccc00cc00cc00cccccc00cc00000000
cccc1d7dddd1dd7df82771111111111111112ccc000000ccc0000ccc000000cc000000cccccc00cc000000cc000000cccccc00cc000000ccc00000cc00000000
cccc1d7dddd1dd7df82771111111111111112cccc0000cccc0000ccc000000ccc0000ccccccc00cc00000cccc0000ccccccc00ccc0000cccc0000ccc00000000
cccc1d7dddd1dd7df82771111111111111112ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc1d7dddd1ddd7df82771111111111111112ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cceffffff8fffffff82771111111111111112ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ceffffff8ffffffff82771111111111111112ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c676767f8ffffffff82d71111111111111112ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
767676777ffffffff827d7777777777777772ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a676767aaefefefef82dddddddddd222dddd2ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e6767678eeee555ee82ddddddddd25552ddd2ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
effffff8ee858885e82dddddddd2588852dd2ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ceeeeeee8885858588222222222258585222cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc5555550058885cccc5555550058885ccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc5555cc00555cccccc5555cc00555cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc66666666666666666666666666666666666ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc66666666666666666666666666666666666c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccc66666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccc6666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000ddd000000000eeeeee0000999999000044444400000000ddd0ddddd00000000000eeeeee00009999990000dddddd00004444440000eeeeee000000000000
000ddddd000000eeeeeeeeee9999999999444444444400000dddddddddddd0000000eeeeeeeeee9999999999dddddddddd4444444444eeeeeeeeee0000000000
00ddd67dd0000eeeeeeeef799999999a74444444497440000ddddddddd67dd00000eeeeeeeef799999999a7dddddddd674444444497eeeeeeeef7ee000000000
00dddd67d0000eeeeeeeeef999999999a4444444449740000dddddddddd67d00000eeeeeeeeef999999999addddddddd64444444449eeeeeeeeef7e000000000
00ddddd6d000eeeeeeeeee999999999944444444444944000ddddddddddd6dd0000eeeeeeeee9999999999dddddddddd4444444444eeeeeeeeeeefee00000000
00ddddddd000eeeeeeeeee999999999944444444444444000dddddddddddddd00000eeeeeeee9999999999dddddddddd4444444444eeeeeeeeeeeeee00000000
00ddddddd000eeeeeeeeee999999999944444400444444000dddddddddddddd000000eeeee0e9999990000dddddddddd4444444444eeeeee00eeeeee00000000
00ddddddd000eeeeeeeeee999999999944444400444444000dddddddddddddd0000ee0eeeee09999990000dddddddddd4444444444eeeeee00eeeeee00000000
00ddddddddddeeeeeeeeee999999999944444444444444000dddddddddddddd000eeee0eeeee9999999999dddddddddd4444444444eeeeeeeeeeeeee00000000
00dddddddddddeeeeeeeeee99999999944444444444444000dddddddddddddd000eeeeeeeeee99999999999dddddddddd444444444eeeeeeeeeeeeee00000000
002dddddddddd2eeeeeeeee499999999244444444444400002ddddd00dddddd0000eeeeeeeeee49999999992ddddddddd2444444442eeeeeeeeeeee000000000
0022dddddddd22222eeeee44444999992444444444444000022dddd00dddddd000022eeeeeeee44999999922222ddddd22222444442eeeeeeeeeeee000000000
00222ddddddd222eeeeeee444999999924444444444400000222ddd00dddddd00000222eeeeeee44499999222ddddddd22244444442eeeeeeeeeee0000000000
00022222ddddd2ee0eeee0049909999022444444440000000022220000dddd00000000222222000044444402dd0dddd0024404444022eeeeeeee000000000000
0000000000000000000000000000000022244400000000000000000000000000000000000000000000000000000000000000000000222eee0000000000000000
00000000000000000000000000000000022220000000000000000000000000000000000000000000000000000000000000000000000222200000000000000000
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
