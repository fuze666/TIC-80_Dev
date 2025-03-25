--title:sky scraper
--author:ageonigiri,fuze666,kumori,
--desc:short description
--site:website link
--license:MIT License
--version:0.1
--script:lua

--Math utilities
min,max,rdm,sin,cos,pi=math.min,math.max,math.random,math.sin,math.cos,math.pi

function animate(e)
 e.animet=e.animet+1
 e.animef=e.animes[1+(e.animet//5)%#e.animes]
end

function collide(e1,e2)
 return e1.y<e2.y+e2.h and e1.y+e1.h>e2.y and e1.x<e2.x+e2.w and e1.x+e1.w>e2.x
end

function sprmap(x,y,w,h,sx,sy,ck,scale)
 for my=0,h-1 do
  for mx=0,w-1 do
   local tile=peek(0x8000+(x+mx)+(y+my)*240)
   if tile~=255 then
    spr(tile+256,sx+mx*8,sy+my*8,ck or 0,scale or 1)
   end
  end
 end
end

function randomstring(n)
 local s=""
 for _=1,n do
  s=s..string.char(rdm(33,126))
 end
 return s
end

player_states={
 idle={
  anime={256,258,260,258},
  update=function(self)
   if self.hit then self:statechange("damage") end
   if btnp(2) then self.l=max(self.l-1,1) end
   if btnp(3) then self.l=min(self.l+1,#l) end
  end
 },
 attack={
  anime={262,264},
  init=function(self) atkt=0;lasers.add(self.x,self.y,1) end,
  update=function(self)
   atkt=atkt+1
   if atkt>30 then self:statechange("idle") end
  end
 },
 damage={
  anime={266,268},
  init=function(self)
   dmgt=0
   self.hp=self.hp-(self.hit or 0)
   self.hit=nil
   if self.hp<=0 then set_game_state("gameover") end
  end,
  update=function(self)
   dmgt=dmgt+1
   if dmgt>30 then self:statechange("idle") end
   if btnp(2) then self.l=max(self.l-1,1) end
   if btnp(3) then self.l=min(self.l+1,#l) end
  end
 }
}

p={
 l=3,x=0,y=90,hp=100,hit=nil,animet=0,
 gethitbox=function(self) return {x=self.x-2,y=self.y+2,w=4,h=12} end,
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

lasers={
 list={},
 add=function(x,y,d) table.insert(lasers.list,{x=x,y=y,w=1,h=5,d=d}) end,
 update=function()
  for i=#lasers.list,1,-1 do
   local v=lasers.list[i]
   v.y=v.y-1
   if v.y<0 then table.remove(lasers.list,i) end
  end
 end,
 draw=function() for _,v in ipairs(lasers.list) do rect(v.x,v.y,v.w,v.h,11) end end
}

enemy_states={
 [1]={
  idle={
   anime={0,32},
   update=function(self)
    self.t=self.t+1
    self.x=(self.x+1)%256
    self.y=sin(self.t/50*pi)*10
    self.sp=min(self.sp+1,100)
    if self.t%128==0 then self:statechange("attack") end
   end
  },
  attack={
   anime={2,34},
   init=function(self)
    local psp=self.sp
    self.sp=self.sp-10
    if self.sp<0 then self.sp=psp;self:statechange("idle") else
     sfx(1,"G-3",15)
     bullets.add(self.x+8,self.y+12,1,10,120,136)
    end
   end,
   update=function(self)
    self.t=self.t+1
    self.y=sin(self.t/50*pi)*10
    if (self.t-30)%120==0 then self:statechange("idle") end
   end
  },
  damage={anime={4},update=function(self) self.t=self.t+1 end}
 }
}

e={
 new=function(self,x,y,w,h,type)
  local new={x=x,y=y,w=w,h=h,t=0,type=type,sp=status[type].sp,hp=status[type].hp,animet=0}
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

status={[1]={sp=100,hp=100}}

bullets={
 list={},
 add=function(x,y,type,d,tx,ty) table.insert(bullets.list,{x=x,y=y,w=2,h=2,type=type,d=d,tx=tx,ty=ty}) end,
 update=function()
  for i=#bullets.list,1,-1 do
   local v=bullets.list[i]
   v.y=v.y+1
   if v.y>136 then table.remove(bullets.list,i)
   elseif collide(p:gethitbox(),v) then p.hit=v.d;table.remove(bullets.list,i) end
  end
 end,
 draw=function() for _,v in ipairs(bullets.list) do rect(v.x,v.y,v.w,v.h,11) end end
}

textbox={
 hide=true,x=24,y=12,w=192,h=54,c=14,idx=1,text={},
 draw=function(self)
  if self.hide then return end
  rect(self.x,self.y,self.w,self.h,self.c)
  for i,v in ipairs(self.text) do print(v,self.x,self.y+6*(i-1),12) end
 end,
 changetext=function(self,idx) self.idx=idx;self.text=paragraphs[idx].body end
}

paragraphs={
 {head={pf=1,c=14},body={"test1","desu"}},
 {head={pf=1,c=14},body={"test2","desu","yabe"}},
 {head={pf=1,c=14},body={"test3","desu"}},
 {head={pf=1,c=14},body={"test4","desu"}},
 {head={pf=1,c=14},body={"test5","desu"}},
 {head={pf=1,c=14},body={"test6","desu"}},
 {head={pf=1,c=14},body={"test7","desu"}},
 {head={pf=1,c=14},body={"test8","desu"}},
 {head={pf=1,c=14},body={"test9","desu"}},
 {head={pf=1,c=14},body={"test10","desu"}},
 {head={pf=1,c=14},body={"test11","desu"}},
 {head={pf=1,c=14},body={"test12","desu"}},
 {head={pf=1,c=14},body={"test13","desu"}},
 {head={pf=1,c=14},body={"test14","desu"}},
 {head={pf=1,c=14},body={"test15","desu","daze"}},
 {head={pf=1,c=14},body={"test","desu"}}
}

pazzle={
 [1]={dummy={"dummy","dummy","dummy","dummy","dummy"},a="answer"},
 [2]={dummy={"fake","false","wrong","nope","nah"},a="efgh"},
 [3]={dummy={"xyz","abc","123","456","789"},a="true"},
 [4]={dummy={"code","hack","data","info","bit"},a="9876"}
}

words={
 list={},
 add=function(x,y,level,type,speed)
  local new={x=x,y=y,w=36,h=8,lv=level,type=type,t=0,c=9,speed=speed or 1}
  if type=="dummy" then new.s=pazzle[level].dummy[rdm(1,5)]
  elseif type=="answer" then new.s=pazzle[level].a;new.c=15
  elseif type=="noise" then new.s=randomstring(6)
  else trace("word add error") end
  table.insert(words.list,new)
 end,
 update=function()
  for i,word in ipairs(words.list) do
   word.x=((word.x+word.speed)+word.x//100)%200
  end
 end,
 draw=function()
  for _,word in ipairs(words.list) do
   rect(word.x,word.y,word.w,word.h,10)
   print(word.s,word.x,word.y,word.c)
  end
 end
}

stages={
 attack1={
  init=function() enemies={};atkt=0;for i=1,4 do table.insert(enemies,e:new(120+20*i,30,16,16,1)) end end,
  update=function()
   for i=#enemies,1,-1 do
    local enemy=enemies[i]
    enemy:update()
    for j=#lasers.list,1,-1 do
     if collide(lasers.list[j],enemy) then
      table.remove(enemies,i)
      table.remove(lasers.list,j)
      break
     end
    end
   end
   lasers.update();bullets.update()
   if #enemies==0 and #lasers.list==0 then set_stage("story1") end
   if btnp(6) then set_stage("story1") end
  end,
  draw=function()
   for _,v in ipairs(enemies) do animate(v);spr(v.animef,v.x,v.y,0,1,0,0,2,2) end
   bullets.draw();lasers.draw();print(p.hp)
  end
 },
 attack2={
  init=function() enemies={};atkt=0;for i=1,5 do table.insert(enemies,e:new(100+25*i,40,16,16,1)) end end,
  update=function() stages.attack1.update() end,
  draw=function() stages.attack1.draw() end
 },
 attack3={
  init=function() enemies={};atkt=0;for i=1,6 do table.insert(enemies,e:new(90+20*i,50,16,16,1)) end end,
  update=function() stages.attack1.update() end,
  draw=function() stages.attack1.draw() end
 },
 attack4={
  init=function() enemies={};atkt=0;for i=1,7 do table.insert(enemies,e:new(80+20*i,60,16,16,1)) end end,
  update=function() stages.attack1.update() end,
  draw=function() stages.attack1.draw() end
 },
 story1={
  init=function() textbox:changetext(1);textbox.hide=false;section=7 end,
  update=function()
   if btnp(4) or btnp(5) or btnp(6) or btnp(7) then
    if textbox.idx==section then set_stage("hacking1")
    else textbox:changetext(textbox.idx+1) end
   end
  end,
  draw=function() textbox:draw() end
 },
 story2={
  init=function() textbox:changetext(8);textbox.hide=false;section=10 end,
  update=function() stages.story1.update() end,
  draw=function() stages.story1.draw() end
 },
 story3={
  init=function() textbox:changetext(11);textbox.hide=false;section=13 end,
  update=function() stages.story1.update() end,
  draw=function() stages.story1.draw() end
 },
 story4={
  init=function() textbox:changetext(14);textbox.hide=false;section=16 end,
  update=function() stages.story1.update() end,
  draw=function() stages.story1.draw() end
 },
 hacking1={
  init=function()
   hackingt=0;words.list={}
   for i=1,5 do words.add(64*i,30+6*i,1,"dummy",1);words.add(12*i,30+6*i,1,"noise",0.5) end
   words.add(96,30,1,"answer",2)
  end,
  update=function()
   for i=#words.list,1,-1 do
    local word=words.list[i]
    for j=#lasers.list,1,-1 do
     if collide(word,lasers.list[j]) then
      if word.type=="dummy" then
       sfx(1,"G-5",15);bullets.add(word.x+18,word.y+4,1,10,120,136)
       table.remove(lasers.list,j)
      elseif word.type=="answer" then trace("its answer") end
      table.remove(words.list,i);break
     end
    end
   end
   words.update();bullets.update();lasers.update()
   if btnp(6) then set_stage("attack1") end
   hackingt=hackingt+1
  end,
  draw=function() words.draw();bullets.draw();lasers.draw() end
 },
 hacking2={
  init=function()
   hackingt=0;words.list={}
   for i=1,4 do words.add(50*i,40+5*i,2,"dummy",1.5);words.add(15*i,40+5*i,2,"noise",0.8) end
   words.add(100,40,2,"answer",2.5)
  end,
  update=function() stages.hacking1.update() end,
  draw=function() stages.hacking1.draw() end
 },
 hacking3={
  init=function()
   hackingt=0;words.list={}
   for i=1,6 do words.add(40*i,20+7*i,3,"dummy",1);words.add(10*i,20+7*i,3,"noise",0.6) end
   words.add(120,20,3,"answer",3)
  end,
  update=function() stages.hacking1.update() end,
  draw=function() stages.hacking1.draw() end
 },
 hacking4={
  init=function()
   hackingt=0;words.list={}
   for i=1,5 do words.add(60*i,50+6*i,4,"dummy",2);words.add(20*i,50+6*i,4,"noise",1) end
   words.add(90,50,4,"answer",1.5)
  end,
  update=function() stages.hacking1.update() end,
  draw=function() stages.hacking1.draw() end
 }
}

current_stage=nil
function set_stage(stage_name)
 if stages[stage_name] then
  current_stage=stages[stage_name]
  if current_stage.init then current_stage.init() end
 else trace("Stage not found: "..stage_name) end
end

--Game state
game_state="menu"
function set_game_state(state)
 game_state=state
 if state=="menu" then update=menu_update;draw=menu_draw
 elseif state=="game" then update=game_update;draw=game_draw
 elseif state=="gameover" then update=gameover_update;draw=gameover_draw end
end

l={{80},{96},{112},{128},{144},{160}}
gamet=0

function game_update()
 if btnp(4) then p:statechange("attack") end
 if current_stage and current_stage.update then current_stage.update() end
 p:update()
 gamet=gamet+1
end

function game_draw()
 cls(0)
 sprmap(0,17,12,8,72,(gamet-64)%256-64,1)
 sprmap(0,26,12,8,72,gamet%256-64,1)
 sprmap(13,17,12,8,72,(gamet+64)%256-64,1)
 sprmap(13,26,12,8,72,(gamet+128)%256-64,1)
 if current_stage and current_stage.draw then current_stage.draw() end
 p.x=l[p.l][1]
 animate(p)
 spr(p.animef,p.x-8,p.y,0,1,0,0,2,2)
end

function menu_update() if btnp(4) then game_init() end end
function menu_draw() cls(2) end

function gameover_update() if btnp(4) then game_init() end end
function gameover_draw() cls(0);print("gameover") end

function BOOT() set_game_state("menu") end
function game_init()
 gamet=0;p.l=3;p.x=0;p.y=90;p.hp=40;p.hit=nil
 set_game_state("game")
 p:statechange("idle")
 set_stage("attack1")
end

--Main loop
function TIC() update();draw() end