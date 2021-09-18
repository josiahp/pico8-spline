pico-8 cartridge // http://www.pico-8.com
version 33
__lua__

--This file is a shambles. I have made no attempts to simplify it, and I think the interface could be confusing.
--It needs love. Here be dragons.

function lerp(a,b,t)
 return (1-t) * a + (t * b)
end

function vlerp(p1,p2,t)
 return {
  lerp(p1[1],p2[1],t),
  lerp(p1[2],p2[2],t)
 }
end

-- p is a table of {x,y} pairs
-- polynomial form
function poly_cubic_bezier(p, t)

 local terms={
  -t^3+3*t^2-3*t+1,
  3*t^3-6*t^2+3*t,
  -3*t^3+3*t^2,
  t^3
 }
 local px=p[1][1]*terms[1] + p[2][1]*terms[2]+ p[3][1]*terms[3] + p[4][1]*terms[4]
 local py=p[1][2]*terms[1] + p[2][2]*terms[2]+ p[3][2]*terms[3] + p[4][2]*terms[4]
 return {px,py}
end

-- p1,p2,p3,p4 are vectors {x=x,y=y}
-- polynomial form
function poly_cubic_bezier_v2(p1,p2,p3,p4,t)

 local terms={
  -t^3+3*t^2-3*t+1,
  3*t^3-6*t^2+3*t,
  -3*t^3+3*t^2,
  t^3
 }
 local px=p1.x*terms[1] + p2.x*terms[2]+ p3.x*terms[3] + p4.x*terms[4]
 local py=p1.y*terms[1] + p2.y*terms[2]+ p3.y*terms[3] + p4.y*terms[4]
 return {x=px,y=py}
end

function poly_cubic_bezier_d(p,t)
 local terms={
  -3*t^2 +6*t  -3,
  9*t^2  -12*t +3,
  -9*t^2 +6*t,
  3*t^2
 }
 
 local px=p[1][1]*terms[1] + p[2][1]*terms[2] + p[3][1]*terms[3] + p[4][1]*terms[4]
 local py=p[1][2]*terms[1] + p[2][2]*terms[2]+ p[3][2]*terms[3] + p[4][2]*terms[4]
 return {px,py}
end

function poly_cubic_bezier_d_v2(p1,p2,p3,p4,t)
 local terms={
  -3*t^2 +6*t  -3,
  9*t^2  -12*t +3,
  -9*t^2 +6*t,
  3*t^2
 }
 
 local px=p1.x*terms[1] + p2.x*terms[2]+ p3.x*terms[3] + p4.x*terms[4]
 local py=p1.y*terms[1] + p2.y*terms[2]+ p3.y*terms[3] + p4.y*terms[4]
 return {x=px,y=py}
end

-- c is the list of control points
-- r is the resolution (1,inf]
-- return a float
function calc_arclen(c,r)
 local arclen=0
 local step=1/r

 local lut={[0]=0}

 for t=0,1,step do
  if (t>=1) break
  
  p1=poly_cubic_bezier(c,t)
  p2=poly_cubic_bezier(c,t+step)

  arclen+=sqrt((p2[1]-p1[1])^2 + (p2[2]-p1[2])^2)
  lut[arclen]=t
 end
 return arclen
end

-- c is the list of control points
-- r is the resolution (1,inf]
-- returns a table of t values indexed by distance along the curve, from 0 to calc_arclen(p)
function calc_lut(c,r)
 local arclen=0
 local step=1/r

 local lut={[1]=0}

 for t=0,1,step do
  if (t>=1) break
  
  p1=poly_cubic_bezier(c,t)
  p2=poly_cubic_bezier(c,t+step)

  arclen+=sqrt((p2[1]-p1[1])^2 + (p2[2]-p1[2])^2)
  add(lut,arclen)
 end

 return lut
end

function disttot(lut, dist)
 local arclen=lut[#lut]
 local r=#lut

 for i=1,r-1 do
  if dist >= lut[i] and dist <= lut[i+1] then
   local t=i/r
   local nextt=(i+1)/r
   return (dist - lut[i]) * (nextt - t) / (lut[i+1]-lut[i]) + t
  end
 end
end

-- lerp form
function cubic_bezier(p, t)
 local a=vlerp(p[1],p[2],t)
 local b=vlerp(p[2],p[3],t)
 local c=vlerp(p[3],p[4],t)
 local d=vlerp(a,b,t)
 local e=vlerp(b,c,t)
 local p=vlerp(d,e,t)
 return p
end

-- p is a table of {x,y} pairs
function poly_quadratic_bezier(p, t)
 local tsq,t2=t^2,2*t
 local px=tsq*p[1][1] - t2*p[1][1] + p[1][1] -2*tsq*p[2][1] + t2*p[2][1] + tsq*p[3][1]
 local py=tsq*p[1][2] - t2*p[1][2] + p[1][2] -2*tsq*p[2][2] + t2*p[2][2] + tsq*p[3][2]

 return {px, py}
end

function quadratic_bezier(p, t)
 local a=vlerp(p[1],p[2],t)
 local b=vlerp(p[2],p[3],t)
 local p=vlerp(a,b,t)
 return p
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
