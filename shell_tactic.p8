pico-8 cartridge // http://www.pico-8.com
version 18
__lua__


-- TODO move all this into a global
s_turret=5
m_turret=7
h_turret=9
winner = 0
mapWon = false
interactCooldown = 10
nextInteract = 0
canInteract = true
state = 0 -- 0 menu, 1 game, 2 help, 3 color selector, 4 map select, 5 campaing
select = 0 -- 0 game, 1 help
clr_select = 0 -- 0 none, 1 plr 1, 2 plr
clr_selector = 0
colors = {1,2,3,4,6,8,9,10,11,12,13,14,15}
clr_player = 0 -- ply 1 select, plr 2 select
level_selector = 0



drop_rnd = 100
next_drop = 0
drop_in = 0
enemySpawnPoints = {}
playerSpawnPoints = {}
playerCount = 1 -- todo 2,3,4
campaingLevel = 1
enemiesSpawned = 0
spawnIndex = 1
nextSpawn = 0
enemiesKilled = 0

player1 = {
	id = 0,
	x = 5,
	y = 1,
	sp = 0,
	-- 0 frame 1, 1 frame 2
	sp_def = 1,
	speed = 0.1,
	direction = 2, 
	-- 0 up, 1 left, 2 down, 3 right
	turret = s_turret,
	turret_color = 14,
	life = 1,
	bullets = 7,
	shield = 0,
	wpcd = 0,
	tpe = "player",
	active = true
}
player2 = {
	id = 1,
	x = 5,
	y = 14,
	sp = 0,
	-- 0 frame 1, 1 frame 2
	sp_def = 1,
	speed = 0.1,
	direction = 0, 
	-- 0 up, 1 left, 2 down, 3 right
	turret = s_turret,
	turret_color = 12,
	life = 1,
	bullets = 4,
	shield = 1,
	wpcd = 0,
	tpe = "player",
	active = true
}

players={}
add(players,player1)
add(players,player2)

crect = {
 x1 = 0,
 x2 = 0,
 y1 = 0,
 y2 = 0
}

entities={}
particles={}
upgrades={}
bullets={}
foliageCollection={}
add(entities,player1)
add(entities,player2)


-- TODO maybe do this in an iteration
wallIDList = {64,65,67,68,69}
waterIDList = {80,81,82,96,97,98,112,113,114}
playerSpawnIndicatorList = {48,49,50,51}

-- campaing map strings
campainMapCollection = {
	"64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,52,0,0,0,67,23,39,39,55,67,0,0,0,0,64,64,0,65,65,0,0,23,39,39,55,0,0,67,0,48,64,64,0,65,0,66,66,23,39,39,55,65,0,67,0,50,64,64,0,0,0,67,66,23,39,39,55,65,0,66,66,0,64,64,52,0,0,67,66,23,39,39,55,65,0,65,65,65,64,64,0,0,0,67,66,23,39,39,55,65,0,66,66,0,64,64,0,65,0,66,66,23,39,39,55,65,0,67,0,49,64,64,0,65,65,0,0,23,39,39,55,0,0,67,0,51,64,64,52,0,0,0,67,23,39,39,55,67,0,0,0,0,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"
}
campaignMapSpawnNumbers = {10}
campaignMapSpawnCooldown = {3}

function parse_map(_mapString)
	local mapString = _mapString
	local actualMap = {}
	while #mapString > 0 do	
		local firstToken=sub(mapString,1,1)
		local cut = 2
		if (firstToken!=",") then
			local workString = sub(mapString,2)
			local secondToken = sub(workString,1,1)
			if (secondToken!=",") then
				local workString = sub(mapString,3)
				local thirdToken = sub(workString,1,1)
				if (thirdToken!=",") then
					local actualToken = firstToken..secondToken..thirdToken
					add(actualMap,actualToken)
					cut = 4
				else
					local actualToken = firstToken..secondToken
					add(actualMap,actualToken)
					cut = 3
				end
			else
				add(actualMap,firstToken)
				cut = 2
			end
		end
		mapString=sub(mapString,cut)
	end
	return actualMap
end

function load_campaing_map(_index)
	local mapString = parse_map(campainMapCollection[_index])
	x = 0
	y = 0
	for id in all(mapString) do
		id = tonum(id)
		for wallID in all(wallIDList) do
			if id == wallID then
				mset(y,x,id)
			end
		end
		for waterID in all(waterIDList) do
			if id == waterID then
				mset(y,x,id)
			end
		end

		-- if id = 66 create foliage
		if id == 66 then
			add_foliage(y,x,66)
		end
		-- load enemy spawn point
		if id == 52 then
			local point = {
				xPos = y,
				yPos = x
			}
			add(enemySpawnPoints,point)
		end
		-- load player spawn point
		for spawnPointID in all(playerSpawnIndicatorList) do
			if id == spawnPointID then
				local point = {
					xPos = y,
					yPos = x
				}
				add(playerSpawnPoints,point)
			end
		end

		x += 1
		if (x > 15) then
			x = 0
			y +=1
		end
	end


	spawn_players(playerCount)

end

function unload_map()
	-- reset map
	for x=0,15 do
		for y=0,15 do
			mset(x,y,0)
		end
	end
	-- reset player spawn points
	playerSpawnPoints = {}
	-- reset enemy spawn points
	enemySpawnPoints = {}
	-- unload all the stuff
	entities={}
	particles={}
	upgrades={}
	bullets={}
	foliageCollection={}
end

function _init()
	code()
	for player in all(players) do
		player.life = 3
		player.bullets = 8
		player.shield = 0
		player.turret = s_turret
	end
	winner = 0
end

function spawn_players(count)
	local spawnedPlayers = 0
	player1.x = playerSpawnPoints[1].xPos
	player1.y = playerSpawnPoints[1].yPos
	add(entities,player1)

end

function reset_option()
	clr_player = 0
	level_selector = 0
	clr_select = 0 -- 0 none, 1 plr 1, 2 plr
	clr_selector = 0
end

function code()
	local mapstring = ""
	for x=0,15 do
		for y=0,15 do
			mapstring = mapstring..mget(x,y)..","
		end
	end
	--add(mapstring,12)
	--printh(tostr(mapstring))
	--printh(mapstring)
end

function collide_map(object,width,heigth,direction,flag)

	local x = object.x*8
	local y = object.y*8
	local w = width
	local h = heigth
	local x1 = 0
	local x2 = 0
	local y1 = 0
	local y2 = 0

	if direction==0 then --left
	   x1=x-1  	y1=y
	   x2=x-1    y2=y+h-1

	elseif direction==1 then --rigth
	   x1=x+w    y1=y
	   x2=x+w  y2=y+h-1

	elseif direction==2 then --up
		x1=x    y1=y-1
		x2=x+w-1  y2=y-1

	elseif direction==3 then --down
		x1=x 		y1=y+h
		x2=x+w-2    y2=y+h
	end


	crect.x1 = x1
	crect.x2 = x2
	crect.y1 = y1
	crect.y2 = y2

	x1/=8
	x2/=8
	y1/=8
	y2/=8

	if fget(mget(x1,y1), flag)
	or fget(mget(x1,y2), flag)
	or fget(mget(x2,y1), flag)
	or fget(mget(x2,y2), flag) then
	    return true
	else
	    return false
	end
end

function destroy_bricks(object,width,heigth,direction,flag)

	local x = object.x*8
	local y = object.y*8
	local w = width
	local h = heigth
	local x1 = 0
	local x2 = 0
	local y1 = 0
	local y2 = 0

	if direction==0 then --left
	   x1=x-1  	y1=y
	   x2=x-1    y2=y+h-1

	elseif direction==1 then --rigth
	   x1=x+w    y1=y
	   x2=x+w  y2=y+h-1

	elseif direction==2 then --up
		x1=x    y1=y-1
		x2=x+w-1  y2=y-1

	elseif direction==3 then --down
		x1=x 		y1=y+h
		x2=x+w-2    y2=y+h
	end


	crect.x1 = x1
	crect.x2 = x2
	crect.y1 = y1
	crect.y2 = y2

	x1/=8
	x2/=8
	y1/=8
	y2/=8


	local whiteBrick_0 = 67
	local whiteBrick_1 = 68
	local whiteBrick_2 = 69
	if fget(mget(x1,y1), flag) then
		if flag == 1 then
			mset(x1,y1,0)
			for i=0,10,1 do
				add_part(x1*8,y1*8,20,{4,2,5},0)
			end
		elseif flag == 2 then
			if mget(x1,y1) == whiteBrick_0 then
				mset(x1,y1,whiteBrick_1)
				for i=0,10,1 do
					add_part(x1*8,y1*8,5,{7,6,5},0)
				end
			elseif mget(x1,y1) == whiteBrick_1 then
				mset(x1,y1,whiteBrick_2)
				for i=0,10,1 do
					add_part(x1*8,y1*8,10,{7,6,5},0)
				end
			elseif mget(x1,y1) == whiteBrick_2 then
				mset(x1,y1,0)
				for i=0,10,1 do
					add_part(x1*8,y1*8,20,{7,6,5},0)
				end
			end
		end
		return true
	elseif fget(mget(x1,y2), flag) then
		if flag == 1 then
			mset(x1,y2,0)
			for i=0,10,1 do
				add_part(x1*8,y2*8,20,{4,2,5},0)
			end
		elseif flag == 2 then
			if mget(x1,y2) == whiteBrick_0 then
				mset(x1,y2,whiteBrick_1)
				for i=0,10,1 do
					add_part(x1*8,y2*8,5,{7,6,5},0)
				end
			elseif mget(x1,y2) == whiteBrick_1 then
				mset(x1,y2,whiteBrick_2)
				for i=0,10,1 do
					add_part(x1*8,y2*8,10,{7,6,5},0)
				end
			elseif mget(x1,y2) == whiteBrick_2 then
				mset(x1,y2,0)
				for i=0,10,1 do
					add_part(x1*8,y2*8,20,{7,6,5},0)
				end
			end
		end
		return true
	elseif fget(mget(x2,y1), flag) then
		if flag == 1 then
			mset(x2,y1,0)
			for i=0,10,1 do
				add_part(x2*8,y1*8,20,{4,2,5},0)
			end
		elseif flag == 2 then
			if mget(x2,y1) == whiteBrick_0 then
				mset(x2,y1,whiteBrick_1)
				for i=0,10,1 do
					add_part(x2*8,y1*8,5,{7,6,5},0)
				end
			elseif mget(x2,y1) == whiteBrick_1 then
				mset(x2,y1,whiteBrick_2)
				for i=0,10,1 do
					add_part(x2*8,y1*8,10,{7,6,5},0)
				end
			elseif mget(x2,y1) == whiteBrick_2 then
				mset(x2,y1,0)
				for i=0,10,1 do
					add_part(x2*8,y1*8,20,{7,6,5},0)
				end
			end
		end
		return true
	elseif fget(mget(x2,y2), flag) then
		if flag == 1 then
			mset(x2,y2,0)
			for i=0,10,1 do
				add_part(x2*8,y2*8,20,{4,2,5},0)
			end
		elseif flag == 2 then
			if mget(x2,y2) == whiteBrick_0 then
				mset(x2,y2,whiteBrick_1)
				for i=0,10,1 do
					add_part(x2*8,y2*8,5,{7,6,5},0)
				end
			elseif mget(x2,y2) == whiteBrick_1 then
				mset(x2,y2,whiteBrick_2)
				for i=0,10,1 do
					add_part(x2*8,y2*8,10,{7,6,5},0)
				end
			elseif mget(x2,y2) == whiteBrick_2 then
				mset(x2,y2,0)
				for i=0,10,1 do
					add_part(x2*8,y2*8,20,{7,6,5},0)
				end
			end
		end
		return true
	else
	    return false
	end
end

function add_enemy(_x,_y,_s,_t,_c,_cd)
	local enemy = {
		x = _x,
		y = _y,
		sp = 0,
		sp_def = 1,
		speed = _s,
		direction = 0,
		turret = _t,
		turret_color = _c,
		tpe = "enemy",
		direction = 2,
		life = 1,
		wpcd = _cd,
		ccd = 0,
		active = true
	}
	add(entities,enemy)

end

function add_part(_x,_y,_maxage,_color,_type)
	local particle = {
		x = _x,
		y = _y,
		lifetime = 0,
		maxage = _maxage,
		color_range = _color,
		clr = _color[1],
		tpe = _type
	}
	add(particles,particle)
end

function add_upgrade(_x,_y,_maxage,_type)
	local upgrade = {
		x = _x,
		y = _y,
		lifetime = 0,
		maxage = _maxage,
		tpe = _type
	}
	--printh("Upgrade placed: ".._x.." ".._y.." type ".._type)
	add(upgrades,upgrade)
end

function add_bullet(_x,_y,_dir,_player_id,_dmg)
	local bullet = {
		x = _x,
		y = _y,
		direction = _dir,
		id = _player_id,
		dmg = _dmg
	}
	add(bullets,bullet)
end

function add_foliage(_x,_y,_spr)
	local foliage = {
		x = _x*8,
		y = _y*8,
		spr = _spr
	}
	add(foliageCollection,foliage)
end

function line_of_sight(x0,y0,x1,y1)
	local walls = {49,50,51,52,53}
  local sx,sy,dx,dy

  if x0 < x1 then
    sx = 1
    dx = x1 - x0
  else
    sx = -1
    dx = x0 - x1
  end

  if y0 < y1 then
    sy = 1
    dy = y1 - y0
  else
    sy = -1
    dy = y0 - y1
  end

  local err, e2 = dx-dy, nil

  	for id in all(walls) do
  		if (mget(x0, y0) == walls) then return false end
	end

  while not(x0 == x1 and y0 == y1) do
    e2 = err + err
    if e2 > -dy then
      err = err - dy
      x0  = x0 + sx
    end
    if e2 < dx then
      err = err + dx
      y0  = y0 + sy
    end
    for id in all(walls) do
  		if (mget(x0, y0) == walls) then return false end
	end
  end

  return true
end

function place_upgrade()
	local placed = 0
	occupied = false
	while placed == 0 do
		repeat
			occupied = false
			x = flr( 1+(level_selector*16) + (rnd(9)))
			y = flr(rnd(14)+1)
			if (mget(x,y) == 0) then -- can be placed, this is floor tile
				-- check for other bullets
				for up in all(upgrades) do
					if ((up.x == x) and (up.y == y)) occupied = true -- there is one already 
				end
			else -- not floor tile
				occupied = true
			end
		until not occupied
		-- if not occupied, place it
		add_upgrade(x,y,300,flr(rnd(4)))
		placed = 1
	end
end

function move(entity)
	entity.sp += 1
	if entity.sp > 1 then
		entity.sp = 0
	end
end

function pickup_upgrade(_player,_upgrade)
	if _upgrade.tpe == 0 then
		if _player.bullets < 8 then
			_player.bullets = 8
		end
	elseif _upgrade.tpe == 1 then
		if _player.shield < 4 then
			_player.shield += 1
		end
	elseif _upgrade.tpe == 2 then
		if _player.life < 4 then
			_player.life += 1
		end
	elseif _upgrade.tpe == 3 then
		if _player.turret == s_turret then
			_player.turret = m_turret
		elseif _player.turret == m_turret then
			_player.turret = h_turret 
		end
	end
end

function to_rect(sp,w,h)
 local r = {}
 r.x1 = sp.x * 8
 r.y1 = sp.y * 8
 r.x2 = sp.x * 8 + w - 1
 r.y2 = sp.y * 8 + h - 1
 return r
end

function collide_rect(r1,r2)
 if((r1.x1 > r2.x2) or
    (r2.x1 > r1.x2) or
    (r1.y1 > r2.y2) or
    (r2.y1 > r1.y2)) then
  return false
 end
 return true
end

-- ========
-- update
-- ========

function move_player(idx)
	local id = idx
	idx += 1
	if players[idx].active == true then
		if btn(0,id) then
	    add_part(players[idx].x*8+8,players[idx].y*8+4,20,{13,5},0)
	    if (not collide_map(players[idx],8,8,0,0)) players[idx].x -= players[idx].speed
	    move(players[idx])
	    players[idx].direction = 1
	    sfx(0)
	elseif btn(1,id) then
	  	add_part(players[idx].x*8,players[idx].y*8+4,20,{13,5},0)
	    if (not collide_map(players[idx],8,8,1,0)) players[idx].x += players[idx].speed
	    move(players[idx])
	    players[idx].direction = 3
	    sfx(0)
	elseif btn(2,id) then
	  	add_part(players[idx].x*8+4,players[idx].y*8+8,20,{13,5},0)
	    if (not collide_map(players[idx],8,8,2,0)) players[idx].y -= players[idx].speed
	    move(players[idx])
	    players[idx].direction = 0
	    sfx(0)
	elseif btn(3,id) then
	  	add_part(players[idx].x*8+4,players[idx].y*8,20,{13,5},0)
	    if (not collide_map(players[idx],8,8,3,0)) players[idx].y += players[idx].speed
	    move(players[idx])
	    players[idx].direction = 2
	    sfx(0)
	end
	if btnp(5,id) then
		if winner > 0 then
			reload(0x2000, 0x2000, 0x1000)
			state = 4
			winner = 0
			camera(0,0)
		elseif players[idx].wpcd <= 0 then
			if players[idx].turret == m_turret then
				dmg = 2
			elseif players[idx].turret == h_turret then
				dmg = 3
			end
			if state == 5 then
				add_bullet(players[idx].x,players[idx].y,players[idx].direction,id,dmg)
				players[idx].wpcd = 20	
			else
				if players[idx].bullets > 0 then
					local dmg = 1
					add_bullet(players[idx].x,players[idx].y,players[idx].direction,id,dmg)
					players[idx].bullets -= 1
					players[idx].wpcd = 20	
				end
			end
		end
	end
	if btnp(4,id) then
		if winner > 0 then
			reload(0x2000, 0x2000, 0x1000)
			state = 0
			camera(0,0)
		end
	end
	if players[idx].wpcd > 0 then
		players[idx].wpcd -= 1
	end

	if not mapWon then
		if players[idx].life <= 0 then
			if players[idx].id == 0 then
				mapWon = true
				nextInteract = time() + interactCooldown
				winner = 2
			else
				mapWon = true
				nextInteract = time() + interactCooldown
				winner = 1
			end
		end
	end

	for up in all(upgrades) do
		if (collide_rect(to_rect(players[idx],7,7),to_rect(up,7,7))) then
				pickup_upgrade(players[idx],up)
				del(upgrades,up)
			end
		end
	end
end


function _update()
	if state == 0 then
		update_menu()
	elseif state == 1 then
		if not mapWon then
			update_game()
		end
		if nextInteract < time() then
			canInteract = true
		end
	elseif state == 2 then
		update_help()
	elseif state == 3 then
		update_clr_select()
	elseif state == 4 then
		update_map_select()
	elseif state == 5 then
		if not mapWon then
			update_campaing()
		end
		if nextInteract < time() then
			canInteract = true
		end
	end
end

function update_map_select()
	if btnp(4) then
		state = 1
		for player in all(players) do
			player.x = 5 + (level_selector*16)
		end
		players[1].y = 1
		players[1].direction = 2
		players[2].y = 14
		players[2].direction = 0
		_init()
	end
	if btnp(2) then
		level_selector -= 1
		if level_selector < 0 then
			level_selector = 7
		end
	elseif btnp(3) then
		level_selector += 1
		if level_selector > 7 then
			level_selector = 0
		end
	end
end

function update_clr_select()
	if btnp(1) then
		clr_selector += 1
		if clr_selector > 13 then
			clr_selector = 0
		end
	elseif btnp(0) then
	 	clr_selector -= 1
		if clr_selector < 0 then
			clr_selector = 13
		end
	end
	if btnp(5) then
		if clr_select == 0 then
			clr_select = 1
			clr_player = 1
			players[1].turret_color = colors[clr_selector+1]
		elseif clr_select == 1 then
			clr_select = 2
			players[2].turret_color = colors[clr_selector+1]
		elseif clr_select == 2 then
			clr_select = 0
			clr_player = 0 
			clr_selector = 0
		end
	end
	if btnp(4) then
		state = 4
	end
end

function update_help()
	cls()
	if btnp(4) then
		state = 0
	end
end

function update_menu()
	if btnp(4) then
		if select == 1 then -- game select
			state = 3 -- color selector
			reset_option()
		elseif select == 0 then -- campaing
			state = 5
			unload_map()
			load_campaing_map(campaingLevel)
		else
			state = 2
		end
	end


	if btnp(2) then
		select -= 1 
		if select < 0 then
			select = 2
		end
	elseif btnp(3) then
		select += 1 
		if select > 2 then
			select = 0
		end
	end
end

function update_game()
	for idx=0,1,1 do
  		move_player(idx)
  	end
  	--update_enemy()
 	update_particle()
  	update_upgrade()
  	update_bullet()
  	if time() > next_drop then
  		place_upgrade()
  		next_drop = time()+rnd(drop_rnd)
  	end
  	if time() < next_drop then
  		drop_in = (next_drop - time())/30
  		next_drop -= 1
  	end
end

function update_campaing()
	for idx=0,1,1 do
  		move_player(idx)
  	end
  	update_enemy()
 	update_particle()
  	update_bullet()
  	for player in all(players) do
  		if player.life <= 0 then
  			player.active = false
  		end
  	end
end

function update_particle()
	for particle in all(particles) do
		if particle.tpe == 0 then
			particle.x = particle.x + sin(rnd())
			particle.y = particle.y + sin(rnd())
			particle.lifetime += 1
			if particle.lifetime > particle.maxage then
				del(particles,particle)
			else
				if #particle.color_range == 1 then
					particle.clr = particle.color_range[1]
				else
					local idx = particle.lifetime / particle.maxage
					idx = 1 + flr(idx*#particle.color_range)
					particle.clr = particle.color_range[idx] 
				end
			end
		elseif particle.tpe == 1 then
			particle.lifetime += 1
			if particle.lifetime > particle.maxage then
				del(particles,particle)
			else
				if #particle.color_range == 1 then
					particle.clr = particle.color_range[1]
				else
					local idx = particle.lifetime / particle.maxage
					idx = 1 + flr(idx*#particle.color_range)
					particle.clr = particle.color_range[idx] 
				end
			end
		elseif particle.tpe == 2 then
			particle.lifetime += 1
			if particle.lifetime > particle.maxage then
				del(particles,particle)
			else
				if #particle.color_range == 1 then
					particle.clr = particle.color_range[1]
				else
					local idx = particle.lifetime / particle.maxage
					idx = 1 + flr(idx*#particle.color_range)
					particle.clr = particle.color_range[idx] 
				end
			end
		end
	end
end

function update_upgrade()
	for upgrade in all(upgrades) do
		upgrade.lifetime+=1
		if upgrade.lifetime > upgrade.maxage then
			del(upgrades,upgrade)
		end
	end
end

function update_bullet()
	local spd = 0.3
	for bullet in all(bullets) do
		if (bullet.direction == 0) then
			bullet.y -= spd
			if (rnd() > 0.2) add_part(bullet.x*8+3,bullet.y*8+5,10,{10,9,8},1)
			if collide_map(bullet,8,6,2,0) then 
				destroy_bricks(bullet,8,8,2,1)
				destroy_bricks(bullet,8,8,2,2)
				for i=0,10,1 do
					add_part(bullet.x*8+4,bullet.y*8+4,8,{7,9,10},0)
				end
				del(bullets,bullet)
				sfx(1)
			end
		elseif bullet.direction == 1 then
			bullet.x -= spd
			if (rnd() > 0.2) add_part(bullet.x*8+5,bullet.y*8+3,10,{10,9,8},1)
			if collide_map(bullet,8,8,0,0) then
				destroy_bricks(bullet,8,8,0,1)
				destroy_bricks(bullet,8,8,0,2)
				for i=0,10,1 do
					add_part(bullet.x*8+4,bullet.y*8+4,8,{7,9,10},0)
				end
				del(bullets,bullet)
				sfx(1)
			end
		elseif bullet.direction == 2 then
			bullet.y += spd
			if (rnd() > 0.2) add_part(bullet.x*8+3,bullet.y*8+2,10,{10,9,8},1)
			if collide_map(bullet,8,8,3,0) then
				destroy_bricks(bullet,8,8,3,1)
				destroy_bricks(bullet,8,8,3,2)
				for i=0,10,1 do
					add_part(bullet.x*8+4,bullet.y*8+4,8,{7,9,10},0)
				end
				del(bullets,bullet)
				sfx(1)
			end
		elseif bullet.direction == 3 then
			bullet.x += spd	 
			if (rnd() > 0.2) add_part( bullet.x*8+2 , bullet.y*8+3,10,{10,9,8},1)
			if collide_map(bullet,8,8,1,0) then
				destroy_bricks(bullet,8,8,1,1)
				destroy_bricks(bullet,8,8,1,2)
				for i=0,10,1 do
					add_part(bullet.x*8+4,bullet.y*8+4,8,{7,9,10},0)
				end
				del(bullets,bullet)
				sfx(1)
			end
		end
		for player in all(players) do
			if (collide_rect(to_rect(bullet,7,7),to_rect(player,7,7))) and ((not (player.id == bullet.id)) or bullet.id == "e") then
				if player.shield > 0 then
					player.shield -= bullet.dmg
				else
					player.life -= bullet.dmg
				end
				for i=0,10,1 do
					add_part(bullet.x*8+4,bullet.y*8+4,20,{10,9,8,2,5},0)
				end
				sfx(1)
				del(bullets,bullet)
			end
		end
		for enemy in all(entities) do
			if enemy.tpe == "enemy" then
				if (collide_rect(to_rect(bullet,7,7),to_rect(enemy,7,7)) and   (bullet.id == 0 or bullet.id == 1)) then
					enemy.life -= 1
					for i=0,10,1 do
						add_part(bullet.x*8+4,bullet.y*8+4,20,{10,9,8,2,5},0)
					end
					sfx(1)
					del(bullets,bullet)
				end
			end
		end
		for other_bullet in all(bullets) do
			if not (bullet == other_bullet) then
				if (collide_rect(to_rect(bullet,7,7),to_rect(other_bullet,7,7))) then
					del(bullets,bullet)
					del(bullets,other_bullet)
					break
				end
			end
		end

	end
end

function update_enemy()
	local dmg = 1
	local enemyNumber = 0
	for enemy in all(entities) do
		if enemy.tpe == "enemy" then
			enemyNumber += 1
			if enemy.life <= 0 then
				del(entities,enemy)
				enemiesKilled += 1
			end
			move(enemy)
			-- 0 up, 1 left, 2 down, 3 right
			enemy.ccd -= 1
			if enemy.ccd < 0 then
				enemy.ccd = 0
			end

			if enemy.turret == m_turret then
  				dmg = 2
			elseif enemy.turret == h_turret then
				dmg = 3
			end
			if enemy.direction == 0 then
				-- no wall collision
				if not collide_map(enemy,8,8,2,0) then
					enemy.y -= enemy.speed
				-- else change direction
				elseif rnd() < 0.7 then
					enemy.direction = flr(rnd(4))
				-- or shoot wall
				else
					if enemy.ccd <= 0 then
						add_bullet(enemy.x,enemy.y,enemy.direction,"e",dmg)
						enemy.ccd = enemy.wpcd
					end
				end
			elseif enemy.direction == 1 then
				-- no wall collision
				if not collide_map(enemy,8,8,0,0) then
					enemy.x -= enemy.speed
				-- else change direction
				elseif rnd() < 0.7 then
					enemy.direction = flr(rnd(4))
				-- or shoot wall
				else
					if enemy.ccd <= 0 then
						add_bullet(enemy.x,enemy.y,enemy.direction,"e",dmg)
						enemy.ccd = enemy.wpcd
					end
				end
			elseif enemy.direction == 2 then
				-- no wall collision
				if not collide_map(enemy,8,8,3,0) then
					enemy.y += enemy.speed
				-- else change direction
				elseif rnd() < 0.7 then
					enemy.direction = flr(rnd(4))
				-- or shoot wall
				else
					if enemy.ccd <= 0 then
						add_bullet(enemy.x,enemy.y,enemy.direction,"e",dmg)
						enemy.ccd = enemy.wpcd
					end
				end
			elseif enemy.direction == 3 then
				-- no wall collision
				if not collide_map(enemy,8,8,1,0) then
					enemy.x += enemy.speed
				-- else change direction
				elseif rnd() < 0.7 then
					enemy.direction = flr(rnd(4))
				-- or shoot wall
				else
					if enemy.ccd <= 0 then
						add_bullet(enemy.x,enemy.y,enemy.direction,"e",dmg)
						enemy.ccd = enemy.wpcd
					end
				end
			end
			if rnd() < 0.01 then
					enemy.direction = flr(rnd(4))
				-- or shoot wall
			end
		end
	end
	if enemiesKilled < campaignMapSpawnNumbers[campaingLevel]-1 then
		if enemyNumber < 4 then
			if spawnIndex > 3 then
					spawnIndex = 1
			end
			local x = enemySpawnPoints[spawnIndex].xPos
			local y = enemySpawnPoints[spawnIndex].yPos
			if nextSpawn < time() then
				add_enemy(x,y,0.1,s_turret,8,20)
				--function add_part(_x,_y,_maxage,_color,_type)
				
				spawnIndex += 1
				nextSpawn = time() + campaignMapSpawnCooldown[campaingLevel]
			elseif nextSpawn == (time() + 1) then
				add_part(x*8+4+sin(rnd(1)),y*8+4+cos(rnd(1)),25,{10,9,8},2)
				add_part(x*8+4+sin(rnd(1)),y*8+4+cos(rnd(1)),20,{10,9,8},2)
				add_part(x*8+4+sin(rnd(1)),y*8+4+cos(rnd(1)),15,{10,9,8},2)
			end
		end
	end
end

function enemy_shoot(enemy)
	add_bullet(enemy.x,enemy.y,enemy.direction,"e",dmg)
end

-- ========
-- draw
-- ========

function _draw()
	if state == 0 then
		draw_menu()
	elseif state == 1 then
		draw_game()
	elseif state == 2 then
		draw_help()
	elseif state == 3 then
		draw_clr_select()
	elseif state == 4 then
		draw_map_select()
	elseif state == 5 then
		draw_game()
	end
end

function draw_map_select()
	cls()
	print("select map",0,0,8)
	print("1, river ransom",20,10,5)
	print("2, brick arena",20,20,5)
	print("3, creek forest",20,30,5)
	print("4, through the wall",20,40,5)
	print("5, forest barricade",20,50,5)
	print("6, white plains",20,60,5)
	print("7, jungle battle",20,70,5)
	print("8, direct sight",20,80,5)

	spr(12,10,10+(10*level_selector))
	print("press \142 to continue like this",0,120,8)
end

function draw_clr_select()
	cls()
	local idx = 0
	for clr in all(colors) do
		rectfill(0+idx*8,12,(idx*8)+8,20,clr)
		rectfill(0+idx*8,72,(idx*8)+8,80,clr)
		
		idx += 1
	end

	-- drawing tank for player 1
	for x=0,7,1 do
		for y=0,7,1 do
	  		if sget( 6 * 8 + x, 0 + y) == 7 then
	  			sset( 6 * 8 + x, 0 + y,players[1].turret_color)
	  		end
	 	end
	end
	spr(3,0,32)
	spr(6,0,32)
	for x=0,7,1 do
		for y=0,7,1 do
	  		if sget( 6 * 8 + x, 0 + y) == players[1].turret_color then
	  			sset( 6 * 8 + x, 0 + y,7)
	  		end
	 	end
	end

	-- drawing tank for player 2
	for x=0,7,1 do
		for y=0,7,1 do
	  		if sget( 6 * 8 + x, 0 + y) == 7 then
	  			sset( 6 * 8 + x, 0 + y,players[2].turret_color)
	  		end
	 	end
	end
	spr(3,0,92)
	spr(6,0,92)
	for x=0,7,1 do
		for y=0,7,1 do
	  		if sget( 6 * 8 + x, 0 + y) == players[2].turret_color then
	  			sset( 6 * 8 + x, 0 + y,7)
	  		end
	 	end
	end


	print("player 1 color: ",0,0,8)
	print("player 2 color: ",0,60,8)
	spr(11,clr_selector*8,22+(clr_player*60))
	if(clr_select < 2) then
		print("press \151 to select color",0,112,9)
	else
		print("press \151 to start over",0,112,9)
	end
	print("press \142 to continue like this",0,120,8)
end

function draw_help()
	cls()
	print("player 1 controls:",0,0,8)
	print("arrows - move" ,0,8,5)
	print("m - shoot" ,0,16,5)

	rectfill(0,24,128,24,6)

	print("player 1 controls:",0,28,8)
	print("esdf - move" ,0,36,5)
	print("q - shoot" ,0,44,5)

	rectfill(0,52,128,52,6)

	spr(57,0,59)
	print(" - gives 1 ammo",10,59,5)
	spr(58,0,67)
	print(" - gives 1 shield",10,67,5)
	spr(59,0,75)
	print(" - gives 1 health",10,75,5)
	spr(60,0,83)
	print(" - upgrades turret",10,83,5)
	spr(6,0,91)
	print(" - lvl 1 turret. deals 1 dmg",10,91,5)
	spr(8,0,99)
	print(" - lvl 2 turret. deals 2 dmg",10,99,5)
	spr(10,0,107)
	print(" - lvl 3 turret. deals 3 dmg",10,107,5)


	if(time()%1 > 0.5) then
		print("press \142 to return",54,120,8)
	end
end

function draw_menu()
	cls()
	for i=0,4 do
		spr(192+i,47+i*8,20,1,1)
	end

	for i=0,5 do
		spr(208+i,43+i*8,30,1,1)
	end

	rectfill(20,27,40,27,5)
	rectfill(95,27,118,27,5)

	rectfill(10,29,40,29,8)
	rectfill(95,29,128,29,8)

	rectfill(20,31,40,31,5)
	rectfill(95,31,118,31,5)

	if(time()%1 > 0.5) then
		print("press \142 to select",35,96,8)
	end


	if select == 0 then
		spr(47,32,55)
	elseif select == 1 then
		spr(47,37,63)
	else 
		spr(47,48,71)
	end

	print("new campaign",42,56,5)
	print("new versus",47,64,5)
	print("help",58,72,5)

	if(time()%0.2 > 0.05) then
		spr(3,24,80)
		spr(224,24,80)

		spr(3,104,80,1,1,true)
		spr(225,104,80)		
	else
		spr(4,24,80)
		spr(224,24,80)
	

		spr(4,104,80,1,1,true)
		spr(225,104,80)
	end

	


	print("made by: bela toth - achie72",8,112,2)
end

function draw_game()
	cls()
 	map()
 	camera((level_selector*16)*8,0)
 	draw_entites()
 	draw_ui()
 	draw_upgrade()
 	draw_part()
 	draw_bullet()
 	draw_foliage()
 	if winner > 0 then
	 	rectfill(32+ ((level_selector*16)*8),60,96+ ((level_selector*16)*8),89,7)
	    rectfill(33+ ((level_selector*16)*8),61,95+ ((level_selector*16)*8),88,0)
	    print("player "..winner.." wins!",38+ ((level_selector*16)*8),64,players[winner].turret_color)
	    print("\142 - exit",38+ ((level_selector*16)*8),72,players[winner].turret_color)
	    print("\151 - rematch",38+ ((level_selector*16)*8),80,players[winner].turret_color)
 	end
 	rect(crect.x1,crect.y1,crect.x2,crect.y2,7)
end

function draw_entites()
	for entity in all(entities) do
		if not entity.active == false then
			if entity.direction == 0 then
				sspr( (entity.sp_def*8) + (entity.sp *8), 0, 8,8, entity.x*8,entity.y*8,8,8,false,false)
			elseif entity.direction == 1 then
				sspr( (entity.sp_def*8) + (entity.sp *8)+16, 0, 8,8, entity.x*8,entity.y*8,8,8,true,false)
			elseif entity.direction == 2 then
				sspr( (entity.sp_def*8) + (entity.sp *8), 0, 8, 8, entity.x*8,entity.y*8,8,8,false,true)
			elseif (entity.direction == 3) then
				sspr( (entity.sp_def*8) + (entity.sp *8)+16, 0, 8, 8, entity.x*8,entity.y*8,8,8,false,false)
			end
			draw_turret(entity,entity.direction)
		end
	end
end

function draw_turret(entity,direction)
	
	local sp_def = entity.turret
	local sp = 0
	
	if (direction == 1) or (direction == 3) then
		sp = 1
	end

	for x=0,7,1 do
		for y=0,7,1 do
	  		if sget( (entity.turret+sp) * 8 + x, 0 + y) == 7 then
	  			sset( (entity.turret+sp) * 8 + x, 0 + y,entity.turret_color)
	  		end
	 	end
	end

	if direction == 0 then
		sspr( (sp_def*8) + (sp *8), 0, 8,8, entity.x*8,entity.y*8,8,8,false,false)
	elseif direction == 1 then
		sspr( (sp_def*8) + (sp *8), 0, 8,8, entity.x*8,entity.y*8,8,8,true,false)
	elseif direction == 2 then
		sspr( (sp_def*8) + (sp *8), 0, 8, 8, entity.x*8,entity.y*8,8,8,false,true)
	elseif (direction == 3) then
		sspr( (sp_def*8) + (sp *8), 0, 8, 8, entity.x*8,entity.y*8,8,8,false,false)
	end

	for x=0,7,1 do
		for y=0,7,1 do
	  		if sget( (entity.turret+sp) * 8 + x, 0 + y) == entity.turret_color then
	  			sset( (entity.turret+sp) * 8 + x, 0 + y,7)
	  		end
	 	end
	end
end

function draw_foliage()
	for foliage in all(foliageCollection) do
		spr(foliage.spr,foliage.x,foliage.y)
	end
end

function draw_ui()

	for player in all(players) do
		for idx=0,player.life-1,1 do
	 		spr(63,90+idx*8 + ((level_selector*16)*8),8+(player.id*68))
		end
		for idx=0,player.shield-1,1 do
	 		spr(61,90+idx*8 + ((level_selector*16)*8),16+(player.id*68))
		end
		if state == 5 then
			spr(62,90,26+(player.id*68))
			print(" : inf",96,27+(player.id*68),6)
		else
			for idx=0,player.bullets-1,1 do
		 		if(idx > 3) then
		 			spr(62,90+(idx-4)*8 + ((level_selector*16)*8),34+(player.id*68))
		 		else
		 		 	spr(62,90+idx*8+ ((level_selector*16)*8),26+(player.id*68))
		 		end
			end
		end

	end
	rectfill(88+ ((level_selector*16)*8),0,88+ ((level_selector*16)*8),127,6) -- leftside line
	print("player 1",90+ ((level_selector*16)*8),0,5)
	rectfill(88+ ((level_selector*16)*8),6,128+ ((level_selector*16)*8),6,6) -- line under player
	rectfill(127+ ((level_selector*16)*8),0,127+ ((level_selector*16)*8),127,6) -- player 1 right
	rectfill(88+ ((level_selector*16)*8),56,127+ ((level_selector*16)*8),56,6) --player 1 bottom
	


	rectfill(88+ ((level_selector*16)*8),57,127+ ((level_selector*16)*8),65,0) --black seperator
	if state == 5 then
		print("enemies "..(campaignMapSpawnNumbers[campaingLevel] - enemiesKilled),89+ ((level_selector*16)*8), 59, 9)
	else
		print("drop: "..drop_in,89+ ((level_selector*16)*8), 59, 9)
	end
	rectfill(88+ ((level_selector*16)*8),66,127+ ((level_selector*16)*8),66,6) -- player 2 start	
	print("player 2",90+ ((level_selector*16)*8),68,5)
	rectfill(88+ ((level_selector*16)*8),74,127+ ((level_selector*16)*8),74,6) --player 2 underline
	--print(stat(1),0,0)
	--print(stat(0),0,8)
	print(stat(1),0,0,6)
end

function draw_part()
	for particle in all(particles) do
		if particle.tpe == 2 then
			circ(particle.x,particle.y,flr(particle.lifetime/3),particle.clr)
		else
	 		pset(particle.x,particle.y,particle.clr)
	 	end
	end
end

function draw_upgrade()
	for upgrade in all(upgrades) do
		if (upgrade.lifetime / upgrade.maxage) > 0.6 then
		 	blink_rate = upgrade.lifetime / upgrade.maxage
			rng = rnd()
			if rng > blink_rate then
				spr(57+upgrade.tpe,upgrade.x*8,upgrade.y*8)
			end
		else
			spr(57+upgrade.tpe,upgrade.x*8,upgrade.y*8)
		end
	end
end

function draw_bullet()

	for bullet in all(bullets) do
		local sp_def = 11
		local sp = 0
		
		if (bullet.direction == 1) or (bullet.direction == 3) then
			sp = 1
		end

		if bullet.direction == 0 then	
			sspr( (sp_def*8) + (sp *8), 0, 8,8, bullet.x*8,bullet.y*8,8,8,false,false)
		elseif bullet.direction == 1 then			
			sspr( (sp_def*8) + (sp *8), 0, 8,8, bullet.x*8,bullet.y*8+1,8,8,true,false)
		elseif bullet.direction == 2 then		
			sspr( (sp_def*8) + (sp *8), 0, 8, 8, bullet.x*8,bullet.y*8,8,8,false,true)
		elseif (bullet.direction == 3) then			
			sspr( (sp_def*8) + (sp *8), 0, 8, 8, bullet.x*8,bullet.y*8+1,8,8,false,false)
		end	
	end
end

__gfx__
00000000000000000000000056565650656565600007000000000000007770000000000000777000000000000000000000000000000000000000000000000000
00000000500000506000006005555000055550000007000000000000000700000000000000070000077000000006000000000000000000000000000000000000
00700700600000605000005005555000055550000007000077770000000700007777000700070000777770070005000000000560000000000000000000000000
00077000555555506555556005555000055550000007000075777777000700007577777700777000757777770000000000000000000000000000000000000000
00077000655555605555555005555000055550000077700077770000007770007777000700777000777770070000000000000000000000000000000000000000
00700700555555506555556005555000055550000077700000000000007770000000000007777700077000000000000000000000000000000000000000000000
00000000655555605555555056565650656565600075700000000000007570000000000007757700000000000000000000000000000000000000000000000000
00000000500000506000006000000000000000000077700000000000007770000000000000777000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000110011011100110000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000111111111111111100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001111111111111111111110000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001111111111111111111111000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001111111111111111111111000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000111111111111111111111000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000111111111111111111111000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000011111111111111111111000000000000000000000000000000000000000000000000066666900
00000000000000000000000000000000000000000000000000111111111111111111110000000000000000000000000000000000000000000000000066666990
000000000000000000000000000000000000000000000000001111111111111111111100000000000000000000000000000000000000000000000000ddddd990
00000000000000000000000000000000000000000000000001111111111111111111110000000000000000000000000000000000000000000000000055555900
00000000000000000000000000000000000000000000000001111111111111111111111000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001111111111111111111111000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001111111111111111111111005555550055555500555555005555550000000000000000000000000
000c0000000b0000000a0000000e0000000800000000000001111111111111111111111050000005500000055000000550000005066666600006600000088000
00c0c00000b0b00000a0a00000e0e000008080000000000000111111111111111111110050066005506666055008800550006605065555600066660000088000
0c000c000b000b000a000a000e000e00080008000000000000011110000111101111000050066005506556055088880550055605065555600066660008888880
c00c00c0b00b00b0a00a00a0e00e00e0800800800000000000000000000000000000000050066005506556055088880550555005065555600066660008888880
0c000c000b000b000a000a000e000e00080008000000000000000000000000000000000050055005500660055008800550850005006556000055550000088000
00c0c00000b0b00000a0a00000e0e000008080000000000000000000000000000000000050000005500000055000000558000005000660000055550000088000
000c0000000b0000000a0000000e0000000800000000000000000000000000000000000005555550055555500555555005555550000000000000000000000000
5555555524442444b0b0b0b067776777677767776777677700000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555222222220303030366666666666666666066606600000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555444244420b0b0b0b77767776777600767070000600000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555222222223030303066666666606006666000006600000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555524442444b0b0b0b067776777670007776000007700000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555222222220303030366666666666006666000066600000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555444244420b0b0b0b77767776777607767700000600000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555222222223030303066666666666666666666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00110011011100110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011110000111101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880888008880888888008000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000080080000800800008008000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000000080000800800000008000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880088888800888800008000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000080080000800800000008000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000080080000800800008008000080080000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880888008880888888008888880088888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888888088888800888888008888888008888800888888000000000000000000000000000000000000000000000000000000000000000000000000000000000
08008008080000800800008008008008000080000800008000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008008080000800800000000008008000080000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000088888800800000000008000000080000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000080000800800000000008000000080000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000080000800800008000008000000080000800008000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088800888008880888888000088800008888800888888000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888800000000cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
85888888cccccc5c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888800000000cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000088888808880088808888880080000000800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000080000800800008008000080080000000800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000080000000800008008000000080000000800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000088888800888888008888000080000000800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000800800008008000000080000000800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000080000800800008008000080080000800800008000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000088888808880088808888880088888800888888000000000000000000000000000000000000000000
00000000000000000000555555555555555555555000000000000000000000000000000000000000000000000000000555555555555555555555555000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888888888888888888888888888888000000000000000000000000000000000000000000000000000000888888888888888888888888888888888
00000000000000000000000000000000000000000000888888808888880088888800888888800888880088888800000000000000000000000000000000000000
00000000000000000000555555555555555555555000800800808000080080000800800800800008000080000800000555555555555555555555555000000000
00000000000000000000000000000000000000000000000800808000080080000000000800800008000080000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000800008888880080000000000800000008000080000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000800008000080080000000000800000008000080000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000800008000080080000800000800000008000080000800000000000000000000000000000000000000
00000000000000000000000000000000000000000000008880088800888088888800008880000888880088888800000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000005500555050500000055055505550555000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000066666900005050500050500000500050505550500000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000066666990005050550050500000500055505050550000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000ddddd990005050500055500000505050505050500000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055555900005050555055500000555050505050555000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000050505550500055500000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000050505000500050500000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000055505500500055500000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000050505000500050000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000050505550555050000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000056565650000000000000000000000000000000000000000000000000000000000000000000000000056565650000000000000000
00000000000000000000000005555000000000000000000000000000000000000000000000000000000000000000000000000000000555500000000000000000
000000000000000000000000888850000000000000000000000000000000000000000000000000000000000000000000000000000005cccc0000000000000000
00000000000000000000000085888888000000000000000000000000000000000000000000000000000000000000000000000000cccccc5c0000000000000000
000000000000000000000000888850000000000000000000000000000000000000000000000000000000000000000000000000000005cccc0000000000000000
00000000000000000000000005555000000000000000000000000000000000000000000000000000000000000000000000000000000555500000000000000000
00000000000000000000000056565650000000000000000000000000000000000000000000000000000000000000000000000000056565650000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000888088808880088008800000088888000000888008800000088088808000888008808880000000000000000000000
00000000000000000000000000000000000808080808000800080000000880008800000080080800000800080008000800080000800000000000000000000000
00000000000000000000000000000000000888088008800888088800000880808800000080080800000888088008000880080000800000000000000000000000
00000000000000000000000000000000000800080808000008000800000880008800000080080800000008080008000800080000800000000000000000000000
00000000000000000000000000000000000800080808880880088000000088888000000080088000000880088808880888008800800000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000222022202200222000002220202000000000222022202000222000002220022022202020000000000000222002202020222022202220222000000000
00000000222020202020200000002020202002000000202020002000202000000200202002002020000000000000202020002020020020000020002000000000
00000000202022202020220000002200222000000000220022002000222000000200202002002220000022200000222020002220020022000020222000000000
00000000202020202020200000002020002002000000202020002000202000000200202002002020000000000000202020002020020020000020200000000000
00000000202020202220222000002220222000000000222022202220202000000200220002002020000000000000202002202020222022200020222000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000101010101050000000000000000000001030005050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4040404040404040404040000000000030303030303030303030300000000000303030303030303030303000000000003030303030303030303030000000000030303030303030303030300000000000303030303030303030303000000000003030303030303030303030000000000030303030303030303030300000000000
4034000000340000003440000000000030323200000000003232300000000000303232000000000026283000000000003000320000000000320030000000000030000000000000000000300000000000300000000000000000003000000000003000000000000000000030000000000030000000000000000000300000000000
4000414100000041410040000000000030323200333333003232300000000000303232000000000026283000000000003032313200000032313230000000000030320000313131000032300000000000300033330000003333003000000000003000000033333300000030000000000030003333000000333300300000000000
4000410000000000410040000000000030000000000000000000300000000000303200003333330026283000000000003000320000000000320030000000000030323200000000003232300000000000300033000033000033003000000000003031310000000000313130000000000030000000000000000000300000000000
4000004243434342000040000000000030313131000000313131300000000000300000000000000026283000000000003000003131313131000030000000000030313131000000313131300000000000300000003333330000003000000000003032323232323232323230000000000030313100000000003131300000000000
4043004242424242004340000000000030000000000000000000300000000000300000000000000026283000000000003000003333333333000030000000000030380000000000000036300000000000303133000033000033313000000000003032323232323232323230000000000030161800000000001618300000000000
4017171717171717171740000000000030000033333333330000300000000000303131311617171727283000000000003000000000000000000030000000000030000031313131310000300000000000303133330000003333313000000000003000333300000033330030000000000030363831323232313638300000000000
4027272727272727272740000000000030310000003100000031300000000000300000002633273737383000000000003033313131003131313330000000000030000000000000000000300000000000300000003131310000003000000000003031000000310000003130000000000030313332323232323331300000000000
4027272727272727272740000000000030310000003100000031300000000000301617172733280000003000000000003033313131003131313330000000000030000000000000000000300000000000303133330000003333313000000000003031000000310000003130000000000030313332323232323331300000000000
4037373737373737373740000000000030000033333333330000300000000000302627373737383131313000000000003000000000000000000030000000000030000031313131310000300000000000303133000000000033313000000000003000333300000033330030000000000030161831323232311618300000000000
4043004141414141004340000000000030000000000000000000300000000000302628000000000000003000000000003000003333333333000030000000000030180000000000000016300000000000300000000033000000003000000000003032323232323232323230000000000030363800000000003638300000000000
4000000000000000000040000000000030313131000000313131300000000000302628000000000000003000000000003000003131313131000030000000000030313131000000313131300000000000300000003333330000003000000000003032323232323232323230000000000030313100000000003131300000000000
4000434342414243430040000000000030000000000000000000300000000000302628003333330000323000000000003000320000000000320030000000000030323200000000003232300000000000300033000033000033003000000000003031310000000000313130000000000030000000000000000000300000000000
4000000042414200000040000000000030323200333333003232300000000000302628000000000032323000000000003032313200000032313230000000000030320000313131000032300000000000300033330000003333003000000000003000000033333300000030000000000030003333000000333300300000000000
4000303200410031330040000000000030323200000000003232300000000000302628000000000032323000000000003000320000000000320030000000000030000000000000000000300000000000300000000000000000003000000000003000000000000000000030000000000030000000000000000000300000000000
4040404040404040404040000000000030303030303030303030300000000000303030303030303030303000000000003030303030303030303030000000000030303030303030303030300000000000303030303030303030303000000000003030303030303030303030000000000030303030303030303030300000000000
__sfx__
00010000120500d050120501205012050120500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003165528655216551a6551665513655106550e6550b6550864505635036350262501615016150160501605016050160501605016050160501605016050060500605006050060500605006050060500605
011000000f053060530f0530f053060530f053060530f0530f053060530f053060530f0530f053060530f053060530f0530f053060530f053060530f0530f053060530f053060530f0530f053060530f05306052
011000000300003054030500300003050030000305003054000000305403050030000305003000030500305400000030540305003000030500300003050030540000003054030500300003050030000305003054
011000001b3551e3251b325003051b3251b3251b315003051b3551e3251b3231b3231b3051b313063050a3031b3551e3251b325003051b3251b3251b315003051b3551e3251b3231b3231b3051b313063050a303
011000001b3551e3251b325003051b3251b3251b31500305223552032520323203231b3002032300300003051b3551e3251b325003051b3251b3251b31500305223552032520323203231b303203230030000305
__music__
01 02030444
02 02030544

