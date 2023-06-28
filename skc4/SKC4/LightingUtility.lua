local LightingUtility = {}


function LightingUtility.from_rgb_to_hsv(r, g, b)
  -- source: https://www.had2know.org/technology/hsv-rgb-conversion-formula-calculator.html
  local maxValue = math.max(r,g,b)
  local minValue = math.min(r,g,b)
  local v = maxValue / 255
  
  -- if M == 0 -> S = 0
  local s = 0 
  -- else evaluate right value
  if (maxValue > 0 ) then
    s = 1- (minValue/maxValue)
  end
  
  local h = 0
  local dist = math.sqrt( r*r + g*g + b*b - r*g -r*b - g*b )
  if (dist > 0) then
    h = math.deg( math.acos( (r- 0.5*g-0.5*b) / dist ) ) 
    if (b > g) then
      h = 360 - h
    end
  end

  return h,s,v
end

function LightingUtility.from_hsv_to_rgb(h, s, v)
  -- source: https://www.had2know.org/technology/hsv-rgb-conversion-formula-calculator.html

  -- normalize
  h = h % 360
  if h < 0 then
    h = h + 360
  end

  local M = 255*v
  local m = M*(1-s)

  local z = (M-m) * ( 1 - math.abs( (h/60) % 2 - 1) )

  local r = 0
  local g = 0
  local b = 0

  if ( h >= 0 and h < 60) then
    r = M
    g = z + m
    b = m
  elseif ( h >= 60 and h < 120) then 
    r = z + m
    g = M
    b = m
  elseif ( h >= 120 and h < 180) then
    r = m
    g = M
    b = z + m
  elseif ( h >= 180 and h < 240) then
    r = m
    g = z + m
    b = M
  elseif ( h >= 240 and h < 300 ) then
    r = z + m
    g = m
    b = M
  elseif ( h >= 300 and  h < 360) then
    r = M
    g = m
    b = z + m
  end
  r = LightingUtility.round(r)
  g = LightingUtility.round(g)
  b = LightingUtility.round(b)
  return r, g, b
end


LightingUtility.SingleToRGBTable = {[0]={0, 0, 0}, {255, 15.3, 0}, {255, 30.6, 0}, {255, 45.9, 0}, {255, 61.2, 0}, {255, 76.5, 0}, {255, 91.8, 0}, {255, 107.1, 0}, {255, 122.4, 0}, {255, 137.7, 0}, {255, 153, 0}, {255, 168.3, 0}, {255, 183.6, 0}, {255, 198.9, 0}, {255, 214.2, 0}, {255, 229.5, 0}, {255, 244.8, 0}, {249.9, 255, 0}, {234.6, 255, 0}, {219.3, 255, 0}, {204, 255, 0}, {188.7, 255, 0}, {173.4, 255, 0}, {158.1, 255, 0}, {142.8, 255, 0}, {127.5, 255, 0}, {112.2, 255, 0}, {96.9, 255, 0}, {81.6, 255, 0}, {66.3, 255, 0}, {51, 255, 0}, {35.7, 255, 0}, {20.4, 255, 0}, {5.1, 255, 0}, {0, 255, 10.2}, {0, 255, 25.5}, {0, 255, 40.8}, {0, 255, 56.1}, {0, 255, 71.4}, {0, 255, 86.7}, {0, 255, 102}, {0, 255, 117.3}, {0, 255, 132.6}, {0, 255, 147.9}, {0, 255, 163.2}, {0, 255, 178.5}, {0, 255, 193.8}, {0, 255, 209.1}, {0, 255, 224.4}, {0, 255, 239.7}, {0, 255, 255}, {0, 239.7, 255}, {0, 224.4, 255}, {0, 209.1, 255}, {0, 193.8, 255}, {0, 178.5, 255}, {0, 163.2, 255}, {0, 147.9, 255}, {0, 132.6, 255}, {0, 117.3, 255}, {0, 102, 255}, {0, 86.7, 255}, {0, 71.4, 255}, {0, 56.1, 255}, {0, 40.8, 255}, {0, 25.5, 255}, {0, 10.2, 255}, {5.1, 0, 255}, {20.4, 0, 255}, {35.7, 0, 255}, {51, 0, 255}, {66.3, 0, 255}, {81.6, 0, 255}, {96.9, 0, 255}, {112.2, 0, 255}, {127.5, 0, 255}, {142.8, 0, 255}, {158.1, 0, 255}, {173.4, 0, 255}, {188.7, 0, 255}, {204, 0, 255}, {219.3, 0, 255}, {234.6, 0, 255}, {249.9, 0, 255}, {255, 0, 244.8}, {255, 0, 229.5}, {255, 0, 214.2}, {255, 0, 198.9}, {255, 0, 183.6}, {255, 0, 168.3}, {255, 0, 153}, {255, 0, 137.7}, {255, 0, 122.4}, {255, 0, 107.1}, {255, 0, 91.8}, {255, 0, 76.5}, {255, 0, 61.2}, {255, 0, 45.9}, {255, 0, 30.6}, {255, 0, 15.3}, {255, 0, 0}}

function LightingUtility.single_value_form_RGB(r, g, b)
  threshold = {10, 10, 10}
  --questa funzione prende i numeri dall'interfaccia dalcnet e trova il valore più vicino corrispondente nella nostra tabella HSV
  DCC = {r, g, b}
    local smallestSoFar, smallestIndex
  --qui devo mettere qualcosa per trovare 0 come valore più vicino quando ho [0,0,0]
  for i, c in ipairs(LightingUtility.SingleToRGBTable) do
  --for i, c in next, ColorHSV do
    if not smallestSoFar or ((math.abs(DCC[1] - c[1]) + math.abs(DCC[2] - c[2]) + math.abs(DCC[3] - c[3])) < smallestSoFar) then
          smallestSoFar = math.abs(DCC[1] - c[1]) + math.abs(DCC[2] - c[2]) + math.abs(DCC[3] - c[3])
          color = i
      end
  end
  --se ho tutti e tre i valorei sotto una soglia, => spengo tutto
  if (DCC[1] < threshold[1] and DCC[2] < threshold[2] and DCC[3] < threshold[3])then 
    color = 0 
  end
  DbgSK('findClosest >  color is '..color..' due to a combination of '.. r..' '..g..' '..b)
  return color
end

function LightingUtility.round(value)
  local rounded = math.floor(value)
  if (value-rounded > 0.5) then
    rounded = math.ceil(value)
  end
  return rounded
end

function LightingUtility.radians_to_degrees(rad)
  return math.deg(rad)
end

function LightingUtility.degrees_to_radians(deg)
  return math.rad(deg)
end


return LightingUtility