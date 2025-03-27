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

function choise(a,b)
 return rdm(0,1)==0 and a or b
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
   sfx(2,"E-2")
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

secre_states={
 idle={
  anime={302},
  update=function(self)
   self.y=100+sin(gamet/50*pi)*10 
 end},
 hack={
  anime={270},
  init=function(self) hackt=0
   sfx(16,"C-4",60,3)
  end,
  update=function(self)
   self.y=100+sin(gamet/50*pi)*9 
   hackt=hackt+1
   if hackt>30 then self:statechange("idle") end
  end
 }
}

secre={
 x=40,y=90,t,animet=0,
 statechange=function(self,state)
  self.state=state
  local ori=secre_states[state]
  if ori.init then ori.init(self) end
  self.update=ori.update
  self.animes=ori.anime
  self.animef=self.animes[1]
  self.animet=0
 end,
 hack=function(level)
  for i,word in ipairs(words.list) do
   if word.type=="answer" then word.c=6
   else table.remove(words.list,i) end   
  end
  secre:statechange("hack")
 end
}

enemies={
  list={},
  update=function(self)
   for i=#self.list,1,-1 do
    local enemy=self.list[i]
    enemy:update()
    if enemy.remove then
     table.remove(self.list,i)
    else
     for j=#lasers.list,1,-1 do
      if collide(lasers.list[j],enemy) and enemy.state~="damage" then
       enemy:statechange("damage")
       table.remove(lasers.list,j)
       break
      end
     end
    end
   end
  end,
  draw=function()
   for _,v in ipairs(enemies.list) do
    animate(v);spr(v.animef,v.x,v.y,0,1,0,0,2,2)
   end
  end
}

enemy_states={
  [1]={
  idle={anime={0,32},
    update=function(self)self.t=self.t+1
     self.x=(self.x+1)%256;self.y=sin(self.t/50*pi)*10
     self.sp=min(self.sp+0.5,100)
     if self.t%128==0 then self:statechange("attack") end
    end},
  attack={anime={2,34},
    init=function(self) local psp=self.sp;self.sp=self.sp-50
     if self.sp<0 then self.sp=psp;self:statechange("idle") else
      sfx(1,"G-3",-1,0,4);bullets.add(self.x+8,self.y+12,1,10) end
    end,
    update=function(self)self.t=self.t+1
     self.y=sin(self.t/50*pi)*10
     if (self.t-30)%120==0 then self:statechange("idle") end
    end},
  damage={anime={4},
    init=function(self)	self.dmg_timer=0;sfx(4,"D-5",-1,0,4)end,
    update=function(self) self.t=self.t+1;self.dmg_timer=self.dmg_timer+1
     if self.dmg_timer>30 then self.hp=self.hp-10
      if self.hp<=0 then self.remove=true;sfx(6,"B-2") else
      self:statechange("idle")
      end end end
  }},
  [2]={
  idle={anime={6,38},
    update=function(self)self.t=self.t+1
     self.x=(self.x-0.8)%256;
     self.sp=min(self.sp+1,100)
     if self.t%64==0 then self:statechange("attack") end
    end},
  attack={anime={6,6,38,38},
     init=function(self)sfx(1,"G-3",-1,0,4)
      bullets.add(self.x+8,self.y+12,2,10,self.x) end,
     update=function(self)self.t=self.t+1
      if (self.t-30)%64==0 then self:statechange("idle") end
     end},
  damage={anime={8},
     init=function(self)	self.dmg_timer=0;sfx(4,"D-5",-1,0,4) end,
     update=function(self) self.t=self.t+1;self.dmg_timer=self.dmg_timer+1
      if self.dmg_timer>30 then self.remove=true;sfx(6,"B-2") end end
    }},
     [3]={
      idle={anime={10},
        update=function(self)self.t=self.t+1
         self.x=(self.x-2)%256;self.y=20+sin(self.t/50*pi)*5
         self.sp=min(self.sp+1,150)
         if self.t%144==0 then self:statechange("attack") end
        end},
      attack={anime={12},
        init=function(self) local psp=self.sp;self.sp=self.sp-60
         if self.sp<0 then self.sp=psp;self:statechange("idle") else
          sfx(1,"G-3",-1,0,4);bullets.add(self.x+8,self.y+12,2,10,120) end
        end,
        update=function(self)self.t=self.t+1
         self.y=sin(self.t/50*pi)*10
         if (self.t-30)%120==0 then self:statechange("idle") end
        end},
      damage={anime={14},
        init=function(self)	self.dmg_timer=0;sfx(4,"D-5",-1,0,4)
        bullets.add(self.x+8,self.y+12,1,10)
        end,
        update=function(self) self.t=self.t+1;self.dmg_timer=self.dmg_timer+1
         if self.dmg_timer>30 then self.hp=self.hp-10
          if self.hp<=0 then self.remove=true;sfx(6,"B-2") else
          self:statechange("idle")
          end end end
      }},
      [4]={
      idle={anime={192},
        update=function(self)self.t=self.t+1
         self.x=(self.x-0.8)%256;self.y=20+sin(self.t/50*pi)*5
         self.sp=min(self.sp+1,150)
         if self.t%256==0 then self:statechange("attack") end
        end},
      attack={anime={196},
        init=function(self) local psp=self.sp;self.sp=self.sp-60
         if self.sp<0 then self.sp=psp;self:statechange("idle") else
          sfx(1,"G-3",-1,0,4);bullets.add(self.x+12,self.y+20,2,10,self.x+8) end
        end,
        update=function(self)self.t=self.t+1
         self.y=20+sin(self.t/50*pi)*10
         if (self.t-30)%120==0 then self:statechange("idle") end
        end},
      damage={anime={192},
        init=function(self)	self.dmg_timer=0;sfx(4,"D-5",-1,0,4)
        bullets.add(self.x+12,self.y+20,1,10)
        self.x=self.x+120
        end,
        update=function(self) self.t=self.t+1;self.dmg_timer=self.dmg_timer+1
         if self.dmg_timer>30 then self.hp=self.hp-10
          if self.hp<=0 then self.remove=true;sfx(6,"B-2") else
          self:statechange("idle")
          end end end
      }}, 
      [5]={
      idle={anime={70},
          update=function(self)self.t=self.t+1
          self.x=l[(self.t//300)%6+1][1]-8
          self.y=20+sin(self.t/100*pi)*5
          end},
      damage={anime={71},
          init=function(self)	self.dmg_timer=0;sfx(4,"D-5",-1,0,4)
          end,
          update=function(self) self.t=self.t+1;self.dmg_timer=self.dmg_timer+1
           if self.dmg_timer>30 then self.hp=self.hp-10
            if self.hp<=0 then self.remove=true;sfx(6,"B-2") else
            self:statechange("idle")
            end end end
      }}
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
  local ori=enemy_states[min(self.type,5)][state]
  if ori.init then ori.init(self) end
  self.update=ori.update
  self.animes=ori.anime
  self.animef=self.animes[1]
  self.animet=0
 end
}

status={
[1]={sp=100,hp=30},
[2]={sp=100,hp=10},
[3]={sp=150,hp=50},
[4]={sp=1000,hp=300},--boss
[5]={sp=100,hp=100},--hacking1
[6]={sp=100,hp=150},--hacking2
[7]={sp=100,hp=200},--hacking3
}

bullets={
 list={},
 add=function(x,y,type,d,tx,ty) table.insert(bullets.list,{x=x,y=y,w=2,h=2,type=type,d=d,tx=tx,ty=ty}) end,
 update=function()
  for i=#bullets.list,1,-1 do
   local v=bullets.list[i]
   if v.type==1 then v.y=v.y+1.1
   elseif v.type==2 then v.y=v.y+1.1;v.x=v.x+(120<v.tx and -0.5 or 0.5 )end
   if v.y>136 then table.remove(bullets.list,i)
   elseif collide(p:gethitbox(),v) then p.hit=v.d;table.remove(bullets.list,i) end
  end
 end,
 draw=function() for _,v in ipairs(bullets.list) do rect(v.x,v.y,v.w,v.h,11) end end
}



textbox={
 hide=true,x=24,y=12,w=192,h=54,c=14,pf=1,idx=1,text={},
 draw=function(self)
  if self.hide then return end
  rect(self.x,self.y,self.w,self.h,self.c)
  for i,v in ipairs(self.text) do print(v,6+self.x,6+self.y+12*(i-1),12) end
 end,
 changetext=function(self,idx) self.idx=idx;self.pf=paragraphs[idx].head.pf;self.c=paragraphs[idx].head.c;self.text=paragraphs[idx].body end,
 update=function(self,next)
  if btnp(4) or btnp(5) or btnp(6) or btnp(7) then
   if self.idx==section then set_stage(next);textbox.hide=true
   else self:changetext(self.idx+1) end
  end
 end
}

paragraphs={
  --1~9 story1
 {head={pf=0,c=14},body={"introduction","press left & right arrow key to move","z to shoot laser gun"}},
 {head={pf=2,c=7},body={"Finally, this day has come."}},
 {head={pf=1,c=6},body={"Yeah, I've been waiting forever."}},
 {head={pf=1,c=6},body={"Credible Smile..., today I will","expose your evil deeds to the sun"}},
 {head={pf=1,c=7},body={"You're really motivated."}},
 {head={pf=2,c=6},body={"Don't chicken out and say","you're going home now."}},
 {head={pf=1,c=7},body={"Of course not. Ever since","you saved me off the street,","I’ve decided to act for you."}},
 {head={pf=1,c=6},body={"I've heard that dozens of","times...","Hm? What's that drone?"}},
 {head={pf=1,c=14},body={"Defeat all the security drones!"}},
 --10~13 story2
 {head={pf=1,c=6},body={"What was that just now?"}},
 {head={pf=1,c=7},body={"That was probably Credible","Smile's security system.","We might be able to hack","it from that terminal."}},
 {head={pf=1,c=6},body={"Let's give it a try."}},
 {head={pf=1,c=14},body={"","desu"}},
 --14~22 story3
 {head={pf=1,c=7},body={randomstring(7).."The security has loosened a bit."}},
 {head={pf=1,c=6},body={"Much appreciated."}},
 {head={pf=1,c=7},body={"Looks like the security is","controlled by the Mother AI, Secre."}}
 {head={pf=1,c=6},body={"So, Secre is controlling this","place too..."}},
 {head={pf=1,c=6},body={" I heard it was used to operate","Credible Smile's technology,","but I never expected it to","handle security as well."}},
 {head={pf=1,c=7},body={"Credible Smile wields vast","wealth to monopolize all the","latest technology..."}},
 {head={pf=1,c=7},body={"If this continues, humanity's","progress itself will fall under its control."}},
 {head={pf=1,c=6},body={"We absolutely have to destroy","Secre."}},
 {head={pf=1,c=6},body={"No doubt about it."}},
 --23~26 story4
 {head={pf=1,c=6},body={randomstring(12),randomstring(12)}},
 {head={pf=1,c=7},body={"Are you okay? You've been","looking unwell for a while."}},
 {head={pf=1,c=7},body={randomstring(4).." I'm fine.","Lo"..randomstring(2).."Look,we're almost","at th"..randomstring(3).."the top flo"..randomstring(3).."or."}},
 {head={pf=1,c=6},body={"I see... Well, whatever. Just","stick with me till the end."}},
 --27~29 story5
 {head={pf=1,c=6},body={"No doubt about it."}},
 {head={pf=1,c=6},body={"No doubt about it."}},
 {head={pf=1,c=6},body={"No doubt about it."}},
 --30~31 story6
 {head={pf=1,c=6},body={"No doubt about it."}},
 {head={pf=1,c=6},body={"No doubt about it."}}
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
 update=function(self)
  for i=#self.list,1,-1 do
   local word=self.list[i]
   word.x=word.x+word.speed
   if word.x<-36 or word.x>240 then table.remove(self.list,i) end
   for j=#lasers.list,1,-1 do
    if collide(word,lasers.list[j]) then
     if word.type=="dummy" then
      sfx(1,"G-4",15);bullets.add(word.x+18,word.y+4,1,10,120,136)
      table.remove(lasers.list,j)
     elseif word.type=="answer" then  end
     table.remove(self.list,i);break
    end
   end
  end
 end,
 draw=function()
  for _,word in ipairs(words.list) do
   print(word.s,word.x,word.y,word.c)
  end
 end
}

stages={
 
 story1={
  init=function() textbox:changetext(1);textbox.hide=false;section=7 end,
  update=function()
   textbox:update("attack1")
  end,
  draw=function() textbox:draw() end
 },
 attack1={
  init=function() sfx(3,"G-5",180);enemies.list={};atkt=0;for i=1,4 do table.insert(enemies.list,e:new(120+20*i,30,16,16,1)) end end,
  update=function() enemies:update();lasers.update();bullets.update()
   if #enemies.list==0 and #lasers.list==0 then set_stage("story2") end
   if btnp(6) then set_stage("story2") end
  end,
  draw=function()
   enemies.draw();bullets.draw();lasers.draw();print(p.hp)
  end
 },
 story2={
  init=function() textbox:changetext(8);textbox.hide=false;section=10 end,
  update=function() textbox:update("hacking1") end,
  draw=function() stages.story1.draw() end
 },
 hacking1={
  init=function()
   hackingt=0;words.list={};enemies.list={}
   for i=0,5 do words.add(100,24+i*10,1,"noise",1) end
   table.insert(enemies.list,e:new(104,30,16,16,5))
  end,
  update=function()
   words:update();bullets.update();lasers.update();enemies:update()
   if hackingt%120==0 then secre.hack(1) end
   if hackingt%10==0 then
    local w=choise({-36,1},{240,-1})
    words.add(w[1],24+rdm(0,5)*10,1,choise(choise("answer","dummy"),"noise"),w[2]) end
   if btnp(6) then set_stage("story3") end
   if #enemies.list==0 and #lasers.list==0 then set_stage("attack2") end
   hackingt=hackingt+1
  end,
  draw=function() words.draw();bullets.draw();lasers.draw();enemies.draw() end
 },
 story3={
  init=function() textbox:changetext(11);textbox.hide=false;section=13 end,
  update=function() textbox:update("attack2") end,
  draw=function() stages.story1.draw() end
 },
 attack2={
  init=function() sfx(3,"G-5",180);enemies.list={};atkt=0;
  for i=1,3 do table.insert(enemies.list,e:new(100+25*i,40,16,16,1)) end
  for i=1,3 do table.insert(enemies.list,e:new(80-25*i,20,16,16,2)) end
  end,
  update=function() enemies:update();lasers.update();bullets.update()
   if #enemies.list==0 and #lasers.list==0 then set_stage("hacking2") end
   if btnp(6) then set_stage("hacking2") end
  end,
  draw=function() stages.attack1.draw();print("attack2",0,10) end
 },
 hacking2={
  init=function()
   hackingt=0;words.list={};enemies.list={}
   table.insert(enemies.list,e:new(104,30,16,16,6))
  end,
  update=function() words:update();bullets.update();lasers.update();enemies:update()
   if hackingt%180==0 then secre.hack(1) end
   if hackingt%7==0 then
    local w=choise({-36,1.5},{240,-1.5})
    words.add(w[1],24+rdm(0,5)*10,1,choise(choise("answer","dummy"),"noise"),w[2]) end
   if btnp(6) then set_stage("story4") end
   if #enemies.list==0 and #lasers.list==0 then set_stage("story4") end
   hackingt=hackingt+1 end,
  draw=function() stages.hacking1.draw();print("hacking2",0,10) end
 },
 story4={
  init=function() textbox:changetext(14);textbox.hide=false;section=16 end,
  update=function() textbox:update("attack3") end,
  draw=function() stages.story1.draw() end
 },
 attack3={
  init=function() sfx(3,"G-5",180);enemies.list={};atkt=0;
  for i=1,6 do table.insert(enemies.list,e:new(90+30*i,50,16,16,1)) end
  for i=1,3 do table.insert(enemies.list,e:new(150-30*i,50,16,16,3)) end
  end,
  update=function() enemies:update();lasers.update();bullets.update()
   if #enemies.list==0 and #lasers.list==0 then set_stage("hacking3") end
   if btnp(6) then set_stage("hacking3") end
  end,
  draw=function() stages.attack1.draw();print("attack3",0,10) end
 },
 hacking3={
  init=function()
   hackingt=0;words.list={};enemies.list={}
   table.insert(enemies.list,e:new(104,30,16,16,7))
  end,
  update=function() words:update();bullets.update();lasers.update();enemies:update()
   if hackingt%240==0 then secre.hack(1) end
   if hackingt%5==0 then
    local w=choise({-36,1},{240,-1})
    words.add(w[1],24+rdm(0,5)*10,1,choise(choise("answer","dummy"),"noise"),w[2]) end
   if btnp(6) then set_stage("story5") end
   if #enemies.list==0 and #lasers.list==0 then set_stage("story5") end
   hackingt=hackingt+1 end,
  draw=function() stages.hacking1.draw();print("hacking3",0,10) end
 },
 story5={
  init=function() textbox:changetext(14);textbox.hide=false;section=16 end,
  update=function() textbox:update("boss") end,
  draw=function() stages.story1.draw() end
 },
 boss={
  init=function()
   bosst=0;words.list={};enemies.list={}
   table.insert(enemies.list,e:new(104,30,16,16,4))
  end,
  update=function() words:update();bullets.update();lasers.update();enemies:update()
   if bosst%300==0 then secre.hack(1) end
   if bosst%5==0 then
    local w=choise({-36,0.5},{240,-0.5})
    words.add(w[1],24+rdm(0,5)*10,1,choise(choise("noise","dummy"),"answer"),w[2]) end
   if btnp(6) then set_stage("story6") end
   if #enemies.list==0 and #lasers.list==0 then set_stage("story6") end
   bosst=bosst+1 end,
  draw=function() words.draw();bullets.draw();lasers.draw()
   local boss=enemies.list[1]
   spr(boss.animef,boss.x,boss.y,0,1,0,0,4,4)
  end
 },
 story6={
  init=function() enemies.list={};textbox:changetext(14);textbox.hide=false;section=16 end,
  update=function()
  if btnp(4) or btnp(5) or btnp(6) or btnp(7) then
   if textbox.idx==section then set_game_state("ending")
   else textbox:changetext(textbox.idx+1) end
  end end,
  draw=function()
   map(30,0,30,17,0,0)
   textbox:draw() end
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
 elseif state=="ending" then update=ending_update;draw=ending_draw;endt=0
 elseif state=="gameover" then update=gameover_update;draw=gameover_draw end
end

l={{80},{96},{112},{128},{144},{160}}
gamet=0

function game_update()
 if btnp(4) and textbox.hide then p:statechange("attack");sfx(0,"B-4",-1,0,2) end
 if current_stage and current_stage.update then current_stage.update() end
 p:update()
 secre:update()
 gamet=gamet+1
end

function game_draw()
 cls(0)
 sprmap(0,17,12,8,72,(gamet-64)%256-64,1)
 sprmap(0,26,12,8,72,gamet%256-64,1)
 sprmap(13,17,12,8,72,(gamet+64)%256-64,1)
 sprmap(13,26,12,8,72,(gamet+128)%256-64,1)
 p.x=l[p.l][1]
 animate(p)
 spr(p.animef,p.x-8,p.y,0,1,0,0,2,2)
 animate(secre)
 if current_stage~=stages.boss then spr(secre.animef,secre.x-8,secre.y,0,1,0,0,2,2) end
 if current_stage and current_stage.draw then current_stage.draw() end
end

function menu_update() if btnp(4) then game_init() end end
function menu_draw() cls(0);spr(134,40,10,0,2,0,0,10,4)
map(0,0,17,6,2,63,0,2);print("press<z> to state",104,85,15)
end

function gameover_update() if btnp(4) then game_init() end end
function gameover_draw() cls(0);print("gameover") end

function ending_update() endt=endt+1 end
function ending_draw() cls(0);print("game clear!!") end

function BOOT() set_game_state("menu") end
function game_init()
 gamet=0;p.l=3;p.x=0;p.y=90;p.hp=40;p.hit=nil
 set_game_state("game")
 p:statechange("idle")
 secre:statechange("idle")
 set_stage("story1")
end

--Main loop
function TIC() update();draw() end