-- data-final-fixes.lua
-- 1) Создаём GUI-спрайты [img=tr-picon-<name>] из любой подходящей иконки прототипа.
-- 2) Применяем угол (в ГРАДУСАХ, CCW от севера) и/или радиус к real-прототипу (planet/space-location), если включено.
-- 3) Для лун подставляем валидного parent, если не задан.

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

-- ВВОД: градусы от севера против часовой (0..360)
-- ВЫВОД: RealOrientation (0..1), от севера по часовой
local function orientation_from_degrees(A)
  if A == nil then return nil end
  local deg_cw = ((360 - (A % 360)) % 360)
  return deg_cw / 360
end

-- RealOrientation (0..1, от севера по часовой) -> градусы CCW от севера
local function degrees_from_orientation(o)
  if o == nil then return nil end
  local deg_cw = ((o % 1) + 1) % 1 * 360
  return ((360 - deg_cw) % 360)
end

-- angle string -> абсолютные градусы (поддержка +Δ / -Δ / *k)
local function parse_angle(spec, base_deg)
  if not spec or spec == "" then return nil end
  spec = spec:gsub("%s+","")
  if spec:sub(1,1) == "*" then
    local k = tonumber(spec:sub(2)); if k then return (base_deg or 0) * k end
  elseif spec:sub(1,1) == "+" or spec:sub(1,1) == "-" then
    local d = tonumber(spec);        if d then return (base_deg or 0) + d end
  else
    local v = tonumber(spec);        if v then return v end
  end
  return nil
end

-- radius: число | +d | -d | *k
local function parse_radius(spec, base)
  if not spec or spec == "" then return nil end
  spec = spec:gsub("%s+","")
  if spec:sub(1,1) == "*" then
    local k = tonumber(spec:sub(2)); if k then return (base or 0) * k end
  elseif spec:sub(1,1) == "+" or spec:sub(1,1) == "-" then
    local d = tonumber(spec);        if d then return (base or 0) + d end
  else
    local v = tonumber(spec);        if v then return v end
  end
  return nil
end

-- автоподстановка родителя для лун (если нужно)
local MOON_DEFAULT_PARENT = {
  muluna   = {type="planet", name="nauvis"},
  lignumis = {type="planet", name="nauvis"},
  cerys    = {type="planet", name="fulgora"},
}

-- флаг включения: берём любой из возможных ключей
local function enabled_any(name)
  local a = settings.startup["tr-enable-planet-"..name]
  local b = settings.startup["tr-enable-space-location-"..name]
  return (a and a.value) or (b and b.value) or false
end

-- значения из настроек (ищем и planet, и space-location варианты)
local function values_any(kind, name)
  local k1 = "planet"; local k2 = "space-location"
  if kind == "space-location" then k1, k2 = k2, k1 end
  local a = settings.startup["tr-angle-" ..k1.."-"..name] or settings.startup["tr-angle-" ..k2.."-"..name]
  local r = settings.startup["tr-radius-"..k1.."-"..name] or settings.startup["tr-radius-"..k2.."-"..name]
  return (a and a.value or ""), (r and r.value or "")
end

-- ПРИМЕНЕНИЕ к прототипу
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

-- угол (в градусах, CCW от севера) -> верхний уровень + orbit
if aval ~= "" then
  -- текущее значение угла в градусах (CCW), чтобы работать с +Δ/-Δ/*k
  local cur_deg = degrees_from_orientation(proto.orientation)
  if not cur_deg and proto.orbit then
    cur_deg = degrees_from_orientation(proto.orbit.orientation)
  end
  cur_deg = cur_deg or 0

  local new_deg = parse_angle(aval, cur_deg)
  if new_deg then
    new_deg = ((new_deg % 360) + 360) % 360
    local o = orientation_from_degrees(new_deg)
    proto.orientation = o
    proto.orbit = proto.orbit or {}
    proto.orbit.orientation = o
  end
end

  -- радиус -> верхний уровень + orbit
  if rval ~= "" then
    local nd = parse_radius(rval, proto.distance)
    if nd then
      proto.distance = nd              -- ВАЖНО: верхний уровень
      proto.orbit = proto.orbit or {}
      proto.orbit.distance = nd
    end
  end
end  -- <<< закрыл apply_for ✅

-- Собрать имена из наших настроек (поддерживаем оба типа ключей)
local function collect_all_names_from_settings()
  local names = {}
  local function push(n) names[n] = true end
  for key, st in pairs(settings.startup) do
    if type(key) == "string" and key:sub(1,3) == "tr-" and st then
      local n =
        key:match("^tr%-enable%-planet%-(.+)$") or
        key:match("^tr%-enable%-space%-location%-(.+)$") or
        key:match("^tr%-angle%-planet%-(.+)$") or
        key:match("^tr%-angle%-space%-location%-(.+)$") or
        key:match("^tr%-radius%-planet%-(.+)$") or
        key:match("^tr%-radius%-space%-location%-(.+)$")
      if n then push(n) end
    end
  end
  local arr = {}
  for n,_ in pairs(names) do table.insert(arr, n) end
  table.sort(arr)
  return arr
end

-- Основной проход: из настроек; если пусто — фолбэк по реальным прототипам
local names = collect_all_names_from_settings()
if #names == 0 then
  -- Фолбэк: соберём имена из реальных прототипов, но применим только если есть наш bool-переключатель
  for kind, t in pairs{["planet"]=data.raw.planet, ["space-location"]=data.raw["space-location"]} do
    if t then
      for n,_ in pairs(t) do
        local en = settings.startup["tr-enable-planet-"..n] or settings.startup["tr-enable-space-location-"..n]
        if en then table.insert(names, n) end
      end
    end
  end
  table.sort(names)
end

for _, name in ipairs(names) do
  apply_for(name)
end
