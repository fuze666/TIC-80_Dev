--コードの大体の作りです。1ファイルにまとめなければならないので読みにくいです

-- title:   sky scraper
-- author:  ageonigiri,fuze666,kumori,
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

-- current game state
game_state="menu"

-- Change game state
function set_game_state(state)
 game_state=state
 if state=="menu" then
  update=menu_update
  draw=menu_draw
 elseif state=="game" then
  update=game_update
  draw=game_draw
 elseif state=="gameover" then
  update=gameover_update
  draw=gameover_draw
 end
end

-- Define player states
player_states={
 idle={
  anime={256,258,260,258},
  update=function(self)
   if self.hit then
    self:statechange("damage")
   end
   if btnp(2) then p.l=max(p.l-1,1) end
   if btnp(3) then p.l=min(p.l+1,#l) end
  end
 },
 attack={
  anime={262,264},
  init=function(self)
   atkt=0
   lasers.add(self.x,self.y,1)
  end,
  update=function(self)
  atkt=atkt+1
  if atkt>30 then self:statechange("idle") end
  end
 },
 damage={
  anime={266,268},
  init=function(self)
   dmgt=0
   self.hp=self.hp-self.hit
   self.hit=nil
   if self.hp<=0 then gameover_init() end
  end,
  update=function(self)
  dmgt=dmgt+1
  if dmgt>30 then self:statechange("idle") end
  if btnp(2) then p.l=max(p.l-1,1) end
  if btnp(3) then p.l=min(p.l+1,#l) end
  end
 }
}

-- Player object
p={
 l=3,
 x=0,
 y=90,
 hp=100,
 hit=nil,
 gethitbox=function(self)
  return{x=self.x-2,y=self.y+2,w=4,h=12}
 end,
 statechange=function(self,state)
  self.state=state
  local ori=player_states[state]
  if ori.init then ori.init(self) end
  self.update=ori.update
  self.animes=ori.anime
  self.animef=self.animes[1]
  self.animet=0
 end
}

-- lasers system
lasers={
 list={},
 add=function(x,y,d)
  local new={x=x,y=y,w=1,h=5,d=d}
  table.insert(lasers.list,new)
 end,
 update=function()
  for i=#lasers.list,1,-1 do
   local v=lasers.list[i]
   v.y=v.y-1
   if v.y<0 then
    table.remove(lasers.list,i)
   end
  end
 end,
 draw=function()
  for _,v in ipairs(lasers.list) do
   rect(v.x,v.y,v.w,v.h,11)
  end
 end
}

-- Define enemy states
enemy_states={
 [1]={
  idle={
   anime={0,32},
   init=function()
   end,
   update=function(self)
    self.t=self.t+1
    self.x=(self.x+1)%256
    self.y=sin(self.t/50*pi)*10
    self.sp=min(self.sp+1,100)
    if self.t%128==0 then
     self:statechange("attack")
    end
   end
  },
  attack={
   anime={2,34},
   init=function(self)
    local psp=self.sp
    self.sp=self.sp-10
    if self.sp<0 then
     self.sp=psp
     self:statechange("idle")
    else
     sfx(1,"G-3",15)
     bullets.add(self.x+8,self.y+12,1,10,120,136)
    end
   end,
   update=function(self)
    self.t=self.t+1
    self.y=sin(self.t/50*pi)*10
    if (self.t-30)%120==0 then
     self:statechange("idle")
    end
   end
  },
  damage={
   anime={4},
   init=function(self)
   end,
   update=function(self)
    self.t=self.t+1
   end
  }
 }
}

-- Enemy object
e={
 new=function(self,x,y,w,h,type)
  local new={
   x=x,y=y,w=w,h=h,t=0,
   type=type,
   sp=status[type].sp,
   hp=status[type].hp
  }
  new.statechange=self.statechange
  new:statechange("idle")
  return new
 end,
 statechange=function(self,state)
  self.state=state
  local ori=enemy_states[self.type][state]
  if ori.init then ori.init(self) end
  self.update=ori.update
  self.animes=ori.anime
  self.animef=self.animes[1]
  self.animet=0
 end
}

-- Enemy stats
status={[1]={sp=100,hp=100}}

-- Bullets system
bullets={
 list={},
 add=function(x,y,type,d,tx,ty)
  local new={x=x,y=y,w=2,h=2,type=type,d=d,tx=tx,ty=ty}
  table.insert(bullets.list,new)
 end,
 update=function()
  for i=#bullets.list,1,-1 do
   local v=bullets.list[i]
   v.y=v.y+1
   if v.y>136 then
    table.remove(bullets.list,i)
   elseif collide(p:gethitbox(),v) then
    p.hit=v.d
    table.remove(bullets.list,i)
   end
  end
 end,
 draw=function()
  for _,v in ipairs(bullets.list) do
   rect(v.x,v.y,v.w,v.h,11)
  end
 end
}

-- Define stages
stages={
-- Attack stages
attack1={
init=function()
 enemies={}
 atkt=0
 for i=1,4 do
  table.insert(enemies,e:new(120+20*i,30,16,16,1))
 end
end,
   update=function()
    for i,enemy in ipairs(enemies) do
     enemy:update()
     for j,laser in ipairs(lasers.list) do
      if collide(laser,enemy) then
       table.remove(enemies,i)
       table.remove(lasers.list,j)
      end
     end
    end
    bullets.update()
    -- trigger
    if #enemies==0 then set_stage("story1") end
    if btnp(6) then set_stage("story1") end
   end,
   draw=function()
    for i,v in ipairs(enemies) do
     animate(v)
     spr(v.animef,v.x,v.y,0,1,0,0,2,2)
    end
    bullets.draw()
    print(p.hp)
   end
  },
  attack2={
   init=function()
    enemies={}
    for i=1,6 do
     table.insert(enemies,e:new(120+20*i,30,16,16,1))
    end
   end,
   update=function()
    for _,enemy in ipairs(enemies) do
     enemy.y=enemy.y+1 -- Move down
    end
    if btnp(6) then set_stage("story2") end
   end,
   draw=function()
    for _,enemy in ipairs(enemies) do
    end
   end
  },
  -- Story stages
  story1={
   init=function()
    story_text="The beginning..."
    text_pos=0
    storyt=0
   end,
   update=function()
    if btnp(6) then set_stage("hacking1") end
   end,
   draw=function()
    print(story_text,10,60+text_pos,7) -- Draw text (white)
   end
  },
  story2={
   init=function()
    storyt=0
    story_text="The journey continues..."
    text_pos=0
   end,
   update=function()
    if btnp(6) then set_stage("hacking2") end
   end,
   draw=function()
    print(story_text,20,70+text_pos,6) -- Draw text (gray)
   end
  },
  -- Hacking stages
  hacking1={
   init=function()
   end,
   update=function()
    if btnp(6) then set_stage("attack2") end
   end,
   draw=function()
    print("Hacking:",40,60,14) -- Draw text (cyan)
   end
  },
  hacking2={
   init=function()
   end,
   update=function()
    if btnp(6) then set_stage("attack1") end
   end,
   draw=function()
    print("Hacking: ",40,60,14) -- Draw text (cyan)
   end
  }
}
  
-- Manage current stage
current_stage=nil

-- Switch stage
function set_stage(stage_name)
 if stages[stage_name] then
  current_stage=stages[stage_name]
  if current_stage.init then current_stage.init() end
 else
  trace("Stage not found: "..stage_name)
 end
end

-- Define lanes
l={{80},{96},{112},{128},{144},{160}}

-- Game update
function game_update()
 if btnp(4) then p:statechange("attack") end
 if current_stage and current_stage.update then
  current_stage.update()
 end
 lasers.update()
 p:update()
 gamet=gamet+1
end

-- Game draw
function game_draw()
 cls(0)
 sprmap(0,17,12,8,72,(gamet-64)%256-64,1)
 sprmap(0,26,12,8,72,gamet%256-64,1)
 sprmap(13,17,12,8,72,(gamet+64)%256-64,1)
 sprmap(13,26,12,8,72,(gamet+128)%256-64,1)
 if current_stage and current_stage.draw then
  current_stage.draw()
 end
 p.x=l[p.l][1]
 animate(p)
 spr(p.animef,p.x-8,p.y,0,1,0,0,2,2)
 lasers.draw()
end

-- Utility functions
min,max,rnd,sin,cos,pi=math.min,math.max,math.dandom,math.sin,math.cos,math.pi

function animate(e)
 e.animet=e.animet+1
 e.animef=e.animes[1+(e.animet//5)%#e.animes]
end

function collide(e1,e2)
 return e1.y<e2.y+e2.h and e1.y+e1.h>e2.y and e1.x<e2.x+e2.w and e1.x+e1.w>e2.x
end

function sprmap(x,y,w,h,sx,sy,ck,scale)
 for my=0, h-1 do
  for mx=0, w-1 do
   local tile=peek(0x8000+(x+mx)+(y+my)*240)
   if tile~=255 then
     spr(tile+256,sx+mx*8,sy+my*8,ck or 0,scale or 1)
   end
  end
 end
end

-- Game initialization
function BOOT()
 set_game_state("menu")
end

-- Main loop
function TIC()
 update()
 draw()
end

-- Menu functions
function menu_init()
 set_game_state("menu")
end

function menu_update()
 if btnp(4) then game_init() end
end

function menu_draw()
 cls(2)
end

-- Start game
function game_init()
 gamet=0
 p.l=3
 p.x=0
 p.y=90
 p.hp=40
 p.hit=nil
 set_game_state("game")
 p:statechange("idle")
 if current_stage then
 else 
  set_stage("attack1")
 end
end

--Game over

function gameover_init()
 set_game_state("gameover")
end

function gameover_update()
 if btnp(4) then game_init() end
end

function gameover_draw()
 cls(0)
 print("gameover")
end