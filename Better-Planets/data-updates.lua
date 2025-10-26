-- data-updates.lua
-- Новый принцип:
-- • Если УГОЛ ЗАДАН: применяем через PlanetsLib.update (для родителя-звезды), иначе прямые правки (луны).
-- • Если УГОЛ ПУСТОЙ и меняется только РАДИУС: НЕ трогаем ориентацию и орбиту. Сдвигаем ТОЛЬКО position
--   вдоль текущего направления на новый радиус. В final-fixes PlanetsLib увидит рассинхрон orbit vs position
--   и каскадно сдвинет детей. См. доки PlanetsLib (update и поведение final-fixes).

-- ===== helpers =====
local function norm01(x)
  if x == nil then return nil end
  local r = x - math.floor(x)
  if r < 0 then r = r + 1 end
  if r >= 1 then r = 0 end
  return r
end

-- CCW-градусы -> RealOrientation (CW), [0,1)
local function orientation_from_degrees(A)
  if A == nil then return nil end
  local deg = ((A % 360) + 360) % 360
  local deg_cw = (360 - deg) % 360
  return norm01(deg_cw / 360)
end

-- RealOrientation -> CCW-градусы
local function degrees_from_orientation(o)
  o = norm01(o)
  if o == nil then return nil end
  local deg_cw = o * 360
  return ((360 - deg_cw) % 360)
end

-- относительные парсеры
local function parse_angle(spec, base_deg)
  if not spec or spec=="" then return nil end
  spec = spec:gsub("%s+","")
  if spec:sub(1,1)=="*" then local k=tonumber(spec:sub(2)); if k then return (base_deg or 0)*k end
  elseif spec:sub(1,1)=="+" or spec:sub(1,1)=="-" then local d=tonumber(spec); if d then return (base_deg or 0)+d end
  else local v=tonumber(spec); if v then return v end end
  return nil
end
local function parse_radius(spec, base)
  if not spec or spec=="" then return nil end
  spec = spec:gsub("%s+","")
  if spec:sub(1,1)=="*" then local k=tonumber(spec:sub(2)); if k then return (base or 0)*k end
  elseif spec:sub(1,1)=="+" or spec:sub(1,1)=="-" then local d=tonumber(spec); if d then return (base or 0)+d end
  else local v=tonumber(spec); if v then return v end end
  return nil
end

-- настройки
local function enabled_any(name)
  local a = settings.startup["tr-enable-planet-"..name]
  local b = settings.startup["tr-enable-space-location-"..name]
  return (a and a.value) or (b and b.value) or false
end
local function values_any(name)
  -- читаем из обеих корзин; приоритет не важен: значения одинаковые по имени
  local a = settings.startup["tr-angle-planet-"..name] or settings.startup["tr-angle-space-location-"..name]
  local r = settings.startup["tr-radius-planet-"..name] or settings.startup["tr-radius-space-location-"..name]
  return (a and a.value or ""), (r and r.value or "")
end

-- доступ к tierlist
local TL = data.raw["mod-data"] and data.raw["mod-data"]["PlanetsLib-tierlist"]
local TIER_CYCLE   = 20/3
local DEG_PER_TIER = 360 / TIER_CYCLE
local function orient_from_tier_any(name)
  if not (TL and TL.data) then return nil end
  local t = (TL.data.planet and TL.data.planet[name]) or (TL.data["space-location"] and TL.data["space-location"][name])
  if t == nil then return nil end
  local deg = (((t % TIER_CYCLE) + TIER_CYCLE) % TIER_CYCLE) * DEG_PER_TIER
  return orientation_from_degrees(deg)
end

-- получить прототип и его тип
local function get_proto(name)
  local p = data.raw.planet and data.raw.planet[name]
  local s = data.raw["space-location"] and data.raw["space-location"][name]
  if p then return p, "planet" end
  if s then return s, "space-location" end
end

-- можно ли звать update: нужен родитель-звезда (space-location)
local function can_update_with_lib(proto)
  local par = proto.orbit and proto.orbit.parent
  return par and par.type=="space-location" and data.raw["space-location"] and data.raw["space-location"][par.name]
end

-- получить позицию родителя
local function parent_position(proto)
  local par = proto.orbit and proto.orbit.parent
  if not par then return {x=0, y=0} end
  local pp = data.raw[par.type] and data.raw[par.type][par.name]
  if pp and pp.position then return {x=pp.position.x or 0, y=pp.position.y or 0} end
  return {x=0, y=0}
end

-- сдвиг позиции на новый радиус, НЕ трогая ориентацию/орбиту
local function move_by_radius_keep_direction(proto, new_dist)
  if not new_dist then return end
  local P = parent_position(proto)
  local C = proto.position and {x=proto.position.x or 0, y=proto.position.y or 0}
  local vx, vy
  if C then
    vx = C.x - P.x; vy = C.y - P.y
    local len = math.sqrt(vx*vx + vy*vy)
    if len > 1e-9 then
      vx = vx / len; vy = vy / len
    else
      -- коллинеарно с родителем — берём по ориентации
      local base_or = (proto.orbit and proto.orbit.orientation) or proto.orientation or orient_from_tier_any(proto.name) or 0
      base_or = norm01(base_or)
      local ang = base_or * 2*math.pi
      vx = math.sin(ang); vy = -math.cos(ang)
    end
  else
    local base_or = (proto.orbit and proto.orbit.orientation) or proto.orientation or orient_from_tier_any(proto.name) or 0
    base_or = norm01(base_or)
    local ang = base_or * 2*math.pi
    vx = math.sin(ang); vy = -math.cos(ang)
  end
  proto.position = { x = P.x + vx*new_dist, y = P.y + vy*new_dist }
  -- ВАЖНО: orbit.distance НЕ трогаем → PlanetsLib в final-fixes заметит рассинхрон и каскадно сдвинет детей.
end

-- основной проход по именам из настроек
local function collect_names()
  local names = {}
  for key, st in pairs(settings.startup) do
    if type(key)=="string" and key:sub(1,3)=="tr-" and st then
      local n = key:match("^tr%-%w+%-%w+%-(.+)$")
      if n then names[n]=true end
    end
  end
  local arr = {}; for n,_ in pairs(names) do table.insert(arr, n) end
  table.sort(arr); return arr
end

local function apply_one(name)
  if not enabled_any(name) then return end
  local proto, kind = get_proto(name); if not proto then return end

  local aval, rval = values_any(name)

  -- база
  local base_or = (proto.orbit and proto.orbit.orientation) or proto.orientation or orient_from_tier_any(name)
  base_or = norm01(base_or)
  local base_dist = (proto.orbit and proto.orbit.distance) or proto.distance
  local cur_deg   = base_or and degrees_from_orientation(base_or) or 0

  local new_deg    = (aval ~= "" and parse_angle(aval, cur_deg)) or nil
  local new_orient = new_deg and orientation_from_degrees(new_deg) or nil
  new_orient = norm01(new_orient)
  local new_dist   = (rval ~= "" and parse_radius(rval, base_dist or 0)) or nil

  -- НИЧЕГО не меняем без явных новых значений
  if not new_orient and not new_dist then return end

  local lib = rawget(_G, "PlanetsLib")
  local can_lib = lib and lib.update and type(lib.update)=="function" and can_update_with_lib(proto)

  -- 1) Пользователь ЗАДАЛ угол → используем update (если можно), иначе прямые правки
  if new_orient then
    if can_lib then
      local dist = (new_dist ~= nil) and new_dist or (base_dist or 0)
      lib:update{
        type = kind, name = name,
        orbit = { parent = proto.orbit.parent, orientation = new_orient, distance = dist }
      }
    else
      -- луна/иной parent: прямые правки (без каскада)
      proto.orbit = proto.orbit or {}
      proto.orientation       = new_orient
      proto.orbit.orientation = new_orient
      if new_dist ~= nil then
        proto.distance       = new_dist
        proto.orbit.distance = new_dist
      end
      -- синхронизируем position под новые значения (чтобы final-fixes не «отменил»)
      local P = parent_position(proto)
      local ang = new_orient * 2*math.pi
      local vx,vy = math.sin(ang), -math.cos(ang)
      local d = (new_dist ~= nil) and new_dist or (base_dist or 0)
      proto.position = { x = P.x + vx*d, y = P.y + vy*d }
    end
    return
  end

  -- 2) Угол ПУСТОЙ, меняем ТОЛЬКО радиус → НЕ трогаем ориентацию/орбиту, двигаем position
  if new_dist ~= nil then
    if can_lib then
      -- РАНЬШЕ: тут мы звали update с той же ориентацией — это и ломало, когда база ещё «сырая».
      -- ТЕПЕРЬ: двигаем position по текущему направлению; final-fixes сам каскадит детей.
      move_by_radius_keep_direction(proto, new_dist)
    else
      -- луна / parent не звезда: тоже двигаем position (детей у луны нет)
      move_by_radius_keep_direction(proto, new_dist)
    end
  end
end

for _, name in ipairs(collect_names()) do
  apply_one(name)
end
