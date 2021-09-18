pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
#include lib_vector2.p8
#include lib_bezier.p8
#include lib_spline.p8

showpoints=true
showline=true
shownormals=false

menuitem(1,"toggle points", function()
 showpoints=not showpoints
end)

menuitem(2,"toggle line", function()
 showline=not showline
end)

menuitem(3,"toggle normals", function()
 shownormals=not shownormals
end)

s=newspline(20)

s:addpoint(16,60)
s:addpoint(16,16)
s:addpoint(60,16)
s:addpoint(60,60)
s:addpoint(112,60)

lut=s:genlut()
hit=false
selected=nil

mxhold,myhold=nil,nil
mtimeout=time()
k=nil
velocity={x=0,y=0}

ballstep=0

mytime=time()
dt=time()

function _init()
 poke(0x5f2d, 0x1)
end

function _update()
 dt=time()-mytime
 mytime=time()
 local mv={x=stat(32),y=stat(33)}
 local m1=stat(34)&0x1==0x1
 local m2=stat(34)&0x2==0x2
 
 -- keyboard input
 if (stat(30)) k=stat(31)
 
 -- left click released
 if mholdx and mholdy and not m1 then
  mholdx,mholdy=nil,nil
  hit=nil
 end

 -- left click while not held 
 if not mholdx and not mholdy and m1 then
  updateselected=true
  for k,v in ipairs(s.points) do
   if dist(mv,v)<4 then
    if (v.index-1)%3==0 then
     selected=v
    end
    hit=v
    mholdx=mv.x
    mholdy=mv.y
    updateselected=false
   end
  end
  if (updateselected) selected=nil
 end
 
 -- drag
 if mholdx and mholdy and m1 then
  --only allow the ends to move
  if (hit.index-1)%3==0 then
   for i=hit.index-1,hit.index+1,1 do
    if s.points[i] then
     s.points[i].x+=mv.x-mholdx
     s.points[i].y+=mv.y-mholdy
    end
   end
  elseif (hit.index-1)%3==1 then
   if hit.index>2 then
    s.points[hit.index-2].x-=mv.x-mholdx
    s.points[hit.index-2].y-=mv.y-mholdy
   end
   hit.x+=mv.x-mholdx
   hit.y+=mv.y-mholdy
  elseif (hit.index-1)%3==2 then
   if hit.index+2<#s.points then
    s.points[hit.index+2].x-=mv.x-mholdx
    s.points[hit.index+2].y-=mv.y-mholdy
   end
   hit.x+=mv.x-mholdx
   hit.y+=mv.y-mholdy
  end
  
  mholdx=mv.x
  mholdy=mv.y
 end

 -- right click 
 if not mholdx and not mholdy and m2 and not (time()-mtimeout < 0.3) then
  selected=s:addpoint(mv.x,mv.y)
  mtimeout=time()
 end
 
 if k=="x" and selected then
  s:delpoint(selected.index)
  k=nil
  selected=nil
 end

 ballstep+=dt/5
 if ballstep > 1 then
  ballstep%=1
  velocity={x=0,y=0}
 end

 velocity=s:velocity(ballstep)
 normalize(velocity)

 s:genlut()
end

function _draw()
 cls()
 if shownormals then
  s:drawnormals()
 end
 if showline then
  s:drawstroke(2, 2)
  s:drawstroke(1, 14)
  s:draw(7)
 end
 if showpoints then
  s:drawmainpoints(3,2)
  s:drawmainpoints(2,14)
  s:drawmainpoints(1,7)
 end

 
 if hit then
  circfill(hit.x,hit.y,2,14)
 end
 
 if selected then
  circ(selected.x,selected.y,2,8)
  s:drawhandles(selected.index, 6)
  s:drawcontrolpoints(selected.index, 2, 6)
 end

-- draw a ball following the path
-- we want a linear speed along the path so we use the arclength to calculate the desired t value
local mydist=ballstep*s.lut[#s.lut]
local t=s:disttot(mydist)
local myp=s:getpoint(t)
circfill(myp.x,myp.y,4,13)
circ(myp.x,myp.y,3,5)
circ(myp.x,myp.y,4,0)
line(myp.x,myp.y,myp.x+velocity.x*5,myp.y+velocity.y*5,8)

 --draw mouse
 palt(14,true)
 palt(0,false)
 spr(2,stat(32),stat(33))

 color(6)
 print("length:"..s.lut[#s.lut])
 print("velocity:"..velocity.x..", "..velocity.y)
 --print("angle:"..(timet*360).." ("..timet..")")
 print("x to delete selected", 0,110) 
 print("left-click to select/move",0,116)
 print("right-click to create",0,122)
end
__gfx__
0000000000000000e0eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000070eeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000770eeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000000000007770eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000000000077770ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000777770e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000077000ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000e0070eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000077700000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007700000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000070000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000700000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000007000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000070000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000700000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000070000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000070000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000700000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000700000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000070000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000070000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000070000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000070000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000
00000000000000077700000000000000000000000000000000000000000777000000000000000000000000000000000000000000000000077700000000000000
00000000000000777770000000000000000000000000000000000000007777700000000000000000000000000000000000000000000000777770000000000000
00000000000000777770000000000000000000000000000000000000007777700000000000000000000000000000000000000000000000777770000000000000
00000000000000777770000000000000000000000000000000000000007777700000000000000000000000000000000000000000000000777770000000000000
00000000000000077700000000000000000000000000000000000000000777000000000000000000000000000000000000000000000007077700000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000070000000000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000700000000000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000077000000000000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000700000000000000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000007000000000000000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000770000000000000000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000007000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000070000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000007700000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000070000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000700000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000077000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000700000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007000000000000000000000000000007000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000700000000000000000000000000070000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000700000000000000000000000000700000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000700000000000000000000000077000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000070000000000000000000007700000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007000000000000000000770000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000700000000000000077000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000070000000000077700000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000007700000077700000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000077777700000000000000000000000000000000000000000000000000000
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
60600000666006600000660066606000666066606660000006606660600066600660666066606600000000000000000000000000000000000000000000000000
60600000060060600000606060006000600006006000000060006000600060006000060060006060000000000000000000000000000000000000000000000000
06000000060060600000606066006000660006006600000066606600600066006000060066006060000000000000000000000000000000000000000000000000
60600000060060600000606060006000600006006000000000606000600060006000060060006060000000000000000000000000000000000700000000000000
60600000060066000000666066606660666006006660000066006660666066600660060066606660000000000000000000000000000000000770000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777000000000000
60006660666066600000066060006660066060600000666006600000066066606000666006606660006066600660606066600000000000000777700000000000
60006000600006000000600060000600600060600000060060600000600060006000600060000600060066606060606060000000000000000777770000000000
60006600660006006660600060000600600066000000060060600000666066006000660060000600060060606060606066000000000000000770000000000000
60006000600006000000600060000600600060600000060060600000006060006000600060000600060060606060666060000000000000000007000000000000
66606660600006000000066066606660066060600000060066000000660066606660666006600600600060606600060066600000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606660066060606660000006606000666006606060000066600660000006606660666066606660666000000000000000000000000000000000000000000000
60600600600060600600000060006000060060006060000006006060000060006060600060600600600000000000000000000000000000000000000000000000
66000600600066600600666060006000060060006600000006006060000060006600660066600600660000000000000000000000000000000000000000000000
60600600606060600600000060006000060060006060000006006060000060006060600060600600600000000000000000000000000000000000000000000000
60606660666060600600000006606660666006606060000006006600000006606060666060600600666000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

