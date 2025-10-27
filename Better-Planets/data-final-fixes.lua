-- data-final-fixes.lua
-- 1) Создаём спрайты [img=tr-picon-<name>] для ВСЕХ планет/локаций + алиасы для звёзд.
-- 2) НИЧЕГО не трогаем в геометрии (position/orbit) — это важно для PlanetsLib.
-- 3) В самом конце — лёгкий санитайзер ориентаций (1.0 -> 0.0), чтобы не ловить крэш на границе.

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

local function first_proto(name)
  for _,k in ipairs({"planet","space-location"}) do
    local p = data.raw[k] and data.raw[k][name]
    if p then return p end
  end
end

local function best_icon_for(proto)
  if not proto then return nil end
  -- приоритет: starmap_icon -> icon -> icons -> любой слой внутри
  if proto.starmap_icon then
    if type(proto.starmap_icon) == "string" then
      return proto.starmap_icon, (proto.starmap_icon_size or proto.icon_size or 64), (proto.icon_mipmaps or 0)
    else
      local f,s,m = pick_from_table(proto.starmap_icon)
      return f, (s or proto.starmap_icon_size or proto.icon_size or 64), m
    end
  end
  if proto.icon then
    if type(proto.icon) == "string" then
      return proto.icon, (proto.icon_size or 64), (proto.icon_mipmaps or 0)
    else
      local f,s,m = pick_from_table(proto.icon)
      return f, (s or proto.icon_size or 64), m
    end
  end
  if proto.icons and proto.icons[1] then
    local ic = proto.icons[1]
    if type(ic.icon) == "string" then
      return ic.icon, (ic.icon_size or proto.icon_size or 64), (ic.icon_mipmaps or proto.icon_mipmaps or 0)
    else
      local f,s,m = pick_from_table(ic)
      return f, (s or ic.icon_size or proto.icon_size or 64), m
    end
  end
  local f,s,m = pick_from_table(proto)
  return f, (s or proto.icon_size or 64), m
end

local function ensure_sprite_from_proto(target_sprite_name, source_proto_name)
  if data.raw.sprite and data.raw.sprite[target_sprite_name] then return true end
  local src = first_proto(source_proto_name)
  if not src then return false end
  local filename, size, mm = best_icon_for(src)
  if not filename then return false end
  data:extend{{
    type = "sprite",
    name = target_sprite_name,
    filename = filename,
    size = tonumber(size) or 64,
    mipmap_count = tonumber(mm) or 0,
    flags = {"gui-icon"}
  }}
  return true
end

-- 1) Базовые спрайты: для КАЖДОГО прототипа создаём [img=tr-picon-<его_имя>]
for _, kind in ipairs({"planet","space-location"}) do
  for name,_ in pairs(data.raw[kind] or {}) do
    ensure_sprite_from_proto("tr-picon-"..name, name)
  end
end

-- 2) Алиасы для звёзд, как просили:
--    star-dea-dia -> иконка от dea-dia-system-edge
--    nexuz-background -> иконка от sye-nexuz-sw
--    redstar -> иконка от calidus-senestella-gate-senestella
local STAR_ALIAS = {
  ["star-dea-dia"]     = "dea-dia-system-edge",
  ["nexuz-background"] = "sye-nexuz-sw",
  ["redstar"]          = "calidus-senestella-gate-senestella",
}
for star, src in pairs(STAR_ALIAS) do
  ensure_sprite_from_proto("tr-picon-"..star, src)
end

-- === sanity: только привести ориентации к полуинтервалу [0,1), ничего больше не трогаем ===
local function norm01(x)
  if type(x) ~= "number" then return x end
  x = x - math.floor(x)
  if x < 0 then x = x + 1 end
  if x >= 1 then x = 0 end  -- 1.0 -> 0.0
  return x
end

for _, kind in ipairs({"planet","space-location"}) do
  for _, proto in pairs(data.raw[kind] or {}) do
    if proto.orientation ~= nil then
      proto.orientation = norm01(proto.orientation)
    end
    if proto.orbit and proto.orbit.orientation ~= nil then
      proto.orbit.orientation = norm01(proto.orbit.orientation)
    end
  end
end

-- === Disable vanilla orbit rings for non-vanilla star systems ===
-- Ваниль рисует кольца вокруг центрального солнца (0,0).
-- Если у объекта parent не "star", отключаем его ванильное кольцо.
do
  local planets   = data.raw.planet or {}
  local locations = data.raw["space-location"] or {}

  local function disable_orbit_if_nonvanilla_parent(proto)
    if not proto then return end
    local orb = proto.orbit
    local par = orb and orb.parent
    if par and par.type == "space-location" and par.name ~= "star" then
      proto.draw_orbit = false
    end
  end

  for _, proto in pairs(planets)   do disable_orbit_if_nonvanilla_parent(proto) end
  for _, proto in pairs(locations) do disable_orbit_if_nonvanilla_parent(proto) end
end
