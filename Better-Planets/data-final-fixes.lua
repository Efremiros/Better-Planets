-- data-final-fixes.lua
-- 1) Спрайты-иконки для настроек [img=tr-picon-<name>]
-- 2) Страховка: нормализуем orientation/orbit.orientation в [0,1) (без PlanetsLib).
-- Ни PlanetsLib.extend, ни PlanetsLib.update здесь НЕ вызываем (см. доки).

local function first_proto(name)
  for _,k in ipairs({"planet","space-location"}) do
    local p = data.raw[k] and data.raw[k][name]
    if p then return p end
  end
end

local function pick_from_table(t, depth)
  depth = (depth or 0) + 1
  if depth > 4 or type(t) ~= "table" then return nil end
  if t.filename then
    local sz = t.size or t.icon_size or t.width or t.height
    local mm = t.mipmap_count or t.icon_mipmaps or 0
    return t.filename, sz, mm
  end
  if t.layers and t.layers[1] then
    local f,s,m = pick_from_table(t.layers[1], depth); if f then return f,s,m end
  end
  if t.hr_version then
    local f,s,m = pick_from_table(t.hr_version, depth); if f then return f,s,m end
  end
  for _,v in pairs(t) do
    local f,s,m = pick_from_table(v, depth); if f then return f,s,m end
  end
  return nil
end

local function ensure_sprite(name)
  local id = "tr-picon-"..name
  if data.raw.sprite and data.raw.sprite[id] then return end
  local p = first_proto(name); if not p then return end

  local filename, size, mm
  if p.starmap_icon then
    if type(p.starmap_icon) == "string" then
      filename = p.starmap_icon
      size = p.starmap_icon_size or p.icon_size or 64
      mm = p.icon_mipmaps or 0
    else
      filename, size, mm = pick_from_table(p.starmap_icon)
      size = size or p.starmap_icon_size or p.icon_size or 64
    end
  end
  if (not filename) and p.icon then
    if type(p.icon) == "string" then
      filename = p.icon
      size = p.icon_size or 64
      mm = p.icon_mipmaps or 0
    else
      filename, size, mm = pick_from_table(p.icon)
      size = size or p.icon_size or 64
    end
  end
  if (not filename) and p.icons and p.icons[1] then
    local ic = p.icons[1]
    if type(ic.icon) == "string" then
      filename = ic.icon
      size = ic.icon_size or p.icon_size or 64
      mm = ic.icon_mipmaps or p.icon_mipmaps or 0
    else
      filename, size, mm = pick_from_table(ic)
      size = size or ic.icon_size or p.icon_size or 64
    end
  end
  if not filename then filename, size, mm = pick_from_table(p) end
  if not filename then return end

  data:extend{{
    type = "sprite",
    name = id,
    filename = filename,
    size = tonumber(size) or 64,
    mipmap_count = tonumber(mm) or 0,
    flags = {"gui-icon"}
  }}
end

-- спрайты для всех имён из настроек
local names = {}
for k,_ in pairs(settings.startup) do
  if type(k)=="string" and k:sub(1,3)=="tr-" then
    local n = k:match("^tr%-%w+%-%w+%-(.+)$")
    if n then names[n]=true end
  end
end
for n,_ in pairs(names) do ensure_sprite(n) end

-- safety: нормализуем ориентации в [0,1)
local function norm01(x)
  if x == nil then return nil end
  local r = x - math.floor(x)
  if r < 0 then r = r + 1 end
  if r >= 1 then r = 0 end
  return r
end

for _, kind in ipairs({"planet","space-location"}) do
  local bucket = data.raw[kind]
  if bucket then
    for _, proto in pairs(bucket) do
      if proto.orientation ~= nil then proto.orientation = norm01(proto.orientation) end
      if proto.orbit and proto.orbit.orientation ~= nil then
        proto.orbit.orientation = norm01(proto.orbit.orientation)
      end
    end
  end
end
