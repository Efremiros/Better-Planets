-- data-final-fixes.lua
-- 1) Создаём GUI-спрайты [img=tr-picon-<name>] из starmap_icon/icon/любой-табличной-иконки.
-- 2) На самой поздней стадии применяем угол/радиус к реальному прототипу (planet или space-location).
-- 3) Для лун чинём отсутствующего родителя (Nauvis/Fulgora).

local function first_proto(name)
  for _,k in ipairs({"planet","space-location"}) do
    local p = data.raw[k] and data.raw[k][name]
    if p then return p, k end
  end
end

-- глубокий поиск filename/size/mipmaps в таблице
local function pick_from_table(t, depth)
  depth = (depth or 0) + 1
  if depth > 4 or type(t) ~= "table" then return nil end
  if t.filename then
    local sz = t.size or t.icon_size or t.width or t.height
    local mm = t.mipmap_count or t.icon_mipmaps or 0
    return t.filename, sz, mm
  end
  if t.layers and t.layers[1] then
    local f,s,m = pick_from_table(t.layers[1], depth)
    if f then return f,s,m end
  end
  if t.hr_version then
    local f,s,m = pick_from_table(t.hr_version, depth)
    if f then return f,s,m end
  end
  for _,v in pairs(t) do
    local f,s,m = pick_from_table(v, depth)
    if f then return f,s,m end
  end
  return nil
end

local function ensure_sprite(name)
  if data.raw["sprite"] and data.raw["sprite"]["tr-picon-"..name] then return end
  local proto = first_proto(name)
  if not proto then return end
  proto = select(1, proto)

  local filename, size, mipmaps

  -- 1) starmap_icon (строка или таблица)
  if proto.starmap_icon then
    if type(proto.starmap_icon) == "string" then
      filename = proto.starmap_icon
      size     = proto.starmap_icon_size or proto.icon_size or 64
      mipmaps  = proto.icon_mipmaps or 0
    else
      filename, size, mipmaps = pick_from_table(proto.starmap_icon)
      size = size or proto.starmap_icon_size or 64
    end
  end

  -- 2) обычные icon / icons
  if not filename and proto.icon then
    if type(proto.icon) == "string" then
      filename = proto.icon
      size     = proto.icon_size or 64
      mipmaps  = proto.icon_mipmaps or 0
    else
      filename, size, mipmaps = pick_from_table(proto.icon)
      size = size or proto.icon_size or 64
    end
  end
  if not filename and proto.icons and proto.icons[1] then
    local ic = proto.icons[1]
    if type(ic.icon) == "string" then
      filename = ic.icon
      size     = ic.icon_size or proto.icon_size or 64
      mipmaps  = ic.icon_mipmaps or proto.icon_mipmaps or 0
    else
      filename, size, mipmaps = pick_from_table(ic)
      size = size or ic.icon_size or proto.icon_size or 64
    end
  end

  -- 3) как крайний случай — ищем filename где угодно в прототипе
  if not filename then
    filename, size, mipmaps = pick_from_table(proto)
  end

  if not filename then
    log("[TierAndRadiusOverrides] no icon for "..name.." (planet/space-location)")
    return
  end

  data:extend{{
    type="sprite",
    name="tr-picon-"..name,
    filename=filename,
    size=tonumber(size) or 64,
    mipmap_count=tonumber(mipmaps) or 0,
    flags={"gui-icon"}
  }}
end

local function angle_to_orientation(tier)
  if not tier then return nil end
  local A = (tier * 360 / 6) % 360
  local deg = ((270 - A) % 360)
  return deg / 360
end

local function parse_radius(spec, base)
  if not spec or spec == "" then return nil end
  spec = spec:gsub("%s+","")
  if spec:sub(1,1) == "*" then
    local k = tonumber(spec:sub(2)); if k then return (base or 0) * k end
  elseif spec:sub(1,1) == "+" or spec:sub(1,1) == "-" then
    local d = tonumber(spec); if d then return (base or 0) + d end
  else
    local v = tonumber(spec); if v then return v end
  end
  return nil
end

-- автоподстановка родителя для лун (если нужно)
local MOON_DEFAULT_PARENT = {
  muluna   = {type="planet", name="nauvis"},
  lignumis = {type="planet", name="nauvis"},
  ceris    = {type="planet", name="fulgora"}, -- луна Фульгоры
}

-- читаем «галочку» и значения из любого набора ключей (planet/space-location)
local function enabled_any(name)
  local a = settings.startup["tr-enable-planet-"..name]
  local b = settings.startup["tr-enable-space-location-"..name]
  return (a and a.value) or (b and b.value) or false
end
local function values_any(kind, name)
  local k1 = "planet"; local k2 = "space-location"
  if kind == "space-location" then k1, k2 = k2, k1 end
  local a = settings.startup["tr-angle-" ..k1.."-"..name] or settings.startup["tr-angle-" ..k2.."-"..name]
  local r = settings.startup["tr-radius-"..k1.."-"..name] or settings.startup["tr-radius-"..k2.."-"..name]
  return (a and a.value or ""), (r and r.value or "")
end

-- тело → применить
local function apply_for(name)
  ensure_sprite(name)
  local proto, kind = first_proto(name)
  if not proto then return end

  if not enabled_any(name) then return end

  local aval, rval = values_any(kind, name)

  -- если это луна — подставим валидного родителя
  local defp = MOON_DEFAULT_PARENT[name]
  if defp then
    proto.orbit = proto.orbit or {}
    local p = proto.orbit.parent
    local ok = p and p.type == "planet" and p.name and data.raw.planet and data.raw.planet[p.name]
    if not ok then proto.orbit.parent = {type=defp.type, name=defp.name} end
  end

  if aval ~= "" then
    local t = tonumber(aval)
    if t then
      local o = angle_to_orientation(t)
      if o then
        proto.orientation = o
        proto.orbit = proto.orbit or {}
        proto.orbit.orientation = o
      end
    end
  end

  if rval ~= "" then
    local nd = parse_radius(rval, proto.distance)
    if nd then
      proto.distance = nd
      proto.orbit = proto.orbit or {}
      proto.orbit.distance = nd
    end
  end
end

-- всё, чем умеем управлять
local BODIES = {
  -- Vanilla
  "nauvis","vulcanus","fulgora","gleba","aquilo",
  -- moons
  "muluna","lignumis","ceris",

  -- Metal and Stars (systems)
  "neumann-v","nix","circa","mirandus",

  -- Dyson Sphere
  "sun-orbit","sun-orbit-close",

  -- Shattered planet & co
  "shattered-planet","shattered-planet-approach","lost-beyond","solar-system-edge",

  -- Dea Dia system
  "dea-dia",        -- сама система (если такое имя у прототипа)
  "prosephina","lemures",

  -- Single-planet mods / Nexuz pack etc.
  "tenebris","maraxsis","arrakis","tiber","janus","corrundum","naufulglebunusilo","aiur","char",
  "pelagos","omnia","panglia","rubia","terrapalus","earth","shchierbin","igrys",
  "moshine","paracelsin","vesta","secretas","frozeta",
  "froodara","gerkizia","hexalith","ithurice","mickora","nekohaven","quadromire",
}

for _, name in ipairs(BODIES) do apply_for(name) end
