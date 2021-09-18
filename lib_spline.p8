pico-8 cartridge // http://www.pico-8.com
version 33
__lua__

--requires lib_vector.p8
--required lib_bezier.p8

local spline={}
spline.mt={__index=spline}

--r is the resolution (number of line segments). higher is better but more expensive.
function newspline(r)
 local o={}
 setmetatable(o,spline.mt)
 o.points={}
 o.r=r or 20
 return o
end

--x,y are the coordinates of the point
--c is a table containing two control points {{x1,y1},{x2,y2}}
function spline:addpoint(x,y)
 if #self.points < 4 then
  local p={x=x,y=y,index=#self.points+1}
  add(self.points, p)
  return p
 end

 -- store the previous point and its 'control point'
 -- new control points need to be aligned to the previous point's control point
 local last,lastc=self.points[#self.points],self.points[#self.points-1]
 -- get the directional vector of the previous point to the previous control point
 local vx,vy=last.x-lastc.x,last.y-lastc.y

 -- place the new point's control point halfway between the old point and new point
 local midx,midy=x-(last.x+vx),y-(last.y+vy)

 -- this is the newly created point.
 local p={x=x,y=y,index=#self.points+3}

 add(self.points, {x=last.x+vx,y=last.y+vy,index=#self.points+1})
 add(self.points, {x=x-midx/2,y=y-midy/2,index=#self.points+1})
 add(self.points, p)

 return p

end

-- if points get deleted we need to keep their 'index' true to the order of the table
function spline:reindex()
 for k,v in ipairs(self.points) do
  v.index=k
 end
end

function spline:delpoint(i)
 --only delete main points, not control points
 if (#self.points==4) return

 if (i-1)%3==0 then
  --delete in reverse order as the table will dynamically reorder itself
  if (self.points[i+1]) deli(self.points,i+1)
  deli(self.points,i)
  if (self.points[i-1]) deli(self.points,i-1)
 end
 
 self:reindex()
end

function spline:drawallpoints(radius,color)
 for k,v in ipairs(self.points) do
  circfill(v.x,v.y,radius,color)
 end
end

function spline:drawmainpoints(_radius,_color)
 local radius=_radius or 3
 for i=1,#self.points,3 do
  circfill(self.points[i].x,self.points[i].y,radius,_color)
 end
end

-- i is the index of the 'main' point whose control points we want to draw
function spline:drawcontrolpoints(i, _radius, _color)
 local radius=_radius or 2
 if (_color) color(_color)
 if (self.points[i-1]) circfill(self.points[i-1].x,self.points[i-1].y,radius)
 if (self.points[i+1]) circfill(self.points[i+1].x,self.points[i+1].y,radius)
end

function spline:drawhandles(i, _color)
 if (_color) color(_color)
 local point,cpoints=self.points[i],{}

 if (self.points[i-1]) add(cpoints,self.points[i-1])
 if (self.points[i+1]) add(cpoints,self.points[i+1])

 for k,v in pairs(cpoints) do
  local dx=v.x-point.x
  local dy=v.y-point.y
  local n=0.15
  while n<1 do
   line(point.x+n*dx,point.y+n*dy,point.x+(n+0.025)*dx,point.y+(n+0.025)*dy)
   n+=0.1
  end
 end
end

-- returns a table of t values indexed by distance along the curve, from 0 to arclen(p)
-- this lookup table is used to produce consistent linear speed along the spline
-- due to the nature of bezier curves, t is not linear in terms of distance over
-- the curve, so we gotta do this whenever we update the curve.
function spline:genlut()
 local arclen=0
 local step=1/self.r
 local p=self.points
 local lut={[1]=0}

 for s=1,#p,3 do
  if (s+3>#p) break
  local i=0
  while i+step <= 1 do
   local p1,p2,p3,p4=p[s],p[s+1],p[s+2],p[s+3]
   c1=poly_cubic_bezier_v2(p1,p2,p3,p4,i)
   c2=poly_cubic_bezier_v2(p1,p2,p3,p4,i+step)
   arclen+=dist(c1,c2)
   add(lut,arclen)
   i=mid(0,i+step,1)
  end
 end
 self.lut=lut
 return lut
end

function spline:getpoint(_t)
 local t=mid(0,_t,1)
 local i=0
 local points=self.points

 if _t == 1 then
  i=#points-4
 else
  -- multiply t by the number of segments to determine the target segment
  t*=(#points-1)/3
  -- drop the fraction to find the segment index
  i=flr(t)
  t%=1
  -- multiply to find the actual point index
  i*=3
  -- add 1 because the index starts at 1
  i+=1
 end
 return poly_cubic_bezier_v2(points[i],points[i+1],points[i+2],points[i+3],t)
end

function spline:velocity(_t)
 local t=mid(0,_t,1)
 local i=0
 local points=self.points

 if _t == 1 then
  i=#points-4
 else
  -- multiply t by the number of segments to determine the target segment
  t*=(#points-1)/3
  -- drop the fraction to find the segment index
  i=flr(t)
  t%=1
  -- multiply to find the actual point index
  i*=3
  -- add 1 because the index starts at 1
  i+=1
 end
 return poly_cubic_bezier_d_v2(points[i],points[i+1],points[i+2],points[i+3],t)
end


-- thanks to freya holmér for this function, which I stole wholesale
-- use the lookup table to find the specified point along the curve based on distance, not t
function spline:disttot(dist)
 local lut=self.lut
 local n=#lut
 local arclen=lut[n]

 for i=1,n-1 do
  if dist >= lut[i] and dist <= lut[i+1] then
   local t=i/n
   local nextt=(i+1)/n
   return (dist - lut[i]) * (nextt - t) / (lut[i+1]-lut[i]) + t
  end
 end
end

function spline:draw(_color)
 local step=1/self.r
 local t=0

 while t+step <= 1 do
  p1=self:getpoint(t)
  p2=self:getpoint(t+step)
  line(p1.x,p1.y,p2.x,p2.y,_color)
  t=mid(0,t+step,1)
 end

end

function spline:drawnormals(_length, _color)
 local step=1/self.r
 local i=0
 local length=_length or 5
 if (_color) color(_color)

 while i+step <=1 do
  p=self:getpoint(i)

  t1=self:velocity(i)
  normalize(t1)
  t1.x,t1.y=-t1.y,t1.x

  -- use the inverse of length because I want to flip the normals 'upward' by default
  line(p.x,p.y,p.x+t1.x*-length,p.y+t1.y*-length)
  i=mid(0,i+step,1)
 end
end

function spline:drawstroke(_width, _color)
 local width=_width or 5
 local step=1/self.r
 local i=0
 if (_color) color(_color)
 while i+step <=1 do
  p1=self:getpoint(i)
  p2=self:getpoint(i+step)
  t1=self:velocity(i)
  t2=self:velocity(i+step)
  normalize(t1)
  normalize(t2)
  -- 2d rotation:
  -- r_x = x * cos(t) - y * sin(t)
  -- r_y = x * sin(t) + y * cos(t)
  -- cos(90) == 0 and sin(90) == 1, so it simplifies to the swap below.
  t1.x,t1.y=-t1.y,t1.x
  t2.x,t2.y=-t2.y,t2.x

  line(p1.x+t1.x*width,p1.y+t1.y*width,p2.x+t2.x*width,p2.y+t2.y*width)
  line(p1.x-t1.x*width,p1.y-t1.y*width,p2.x-t2.x*width,p2.y-t2.y*width)

  i=mid(0,i+step,1)
 end
 color()
end

function spline:drawtangents(length, _color)
 local step=1/self.r
 local p=self.points

 for s=1,#p,3 do
  if (s+3>#p) break
  local i=0
  while i+step <= 1 do
   local p1,p2,p3,p4=p[s],p[s+1],p[s+2],p[s+3]

   c1=poly_cubic_bezier_v2(p1,p2,p3,p4,i)

   tan=poly_cubic_bezier_d_v2(p1,p2,p3,p4,i)
   normalize(tan)

   line(c1.x,c1.y,c1.x+tan.x*length,c1.y+tan.y*length,_color)

   i=mid(0,i+step,1)
  end
 end
end
 

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
