-- data-updates.lua
-- Исправляет визуальные орбиты и корректно применяет настройки:
-- • Репарентинг Nexuz (в т.ч. earth) – поздно, через PlanetsLib.update.
-- • Любой объект с родителем-звездой обновляется через PlanetsLib.update(orbit=...), при заранее зафиксированном proto.orbit.parent.
-- • Корневые звёзды: правим orientation/distance, чистим position, каскадно обновляем детей.
-- • Нормализация ориентации только здесь; в final-fixes геометрию не трогаем.

-- ========= utils =========
local function norm01(x)
  if x == nil then return nil end
  x = x - math.floor(x)
  if x < 0 then x = x + 1 end
  if x >= 1 then x = 0 end        -- 1.0 -> 0.0
  return x
end

-- CCW (от севера) -> RealOrientation (CW), [0,1)
local function orientation_from_degrees(A)
  if A == nil then return nil end
  local deg = ((A % 360) + 360) % 360
  local deg_cw = (360 - deg) % 360
  return norm01(deg_cw / 360)
end

local function degrees_from_orientation(o)
  o = norm01(o)
  if o == nil then return nil end
  local deg_cw = o * 360
  return ((360 - deg_cw) % 360)
end

local function enabled(name)
  local st = settings.startup["tr-enable-"..name]
  return st and st.value or false
end
local function angle_deg(name)
  local st = settings.startup["tr-angle-"..name]
  return st and st.value or nil
end
local function radius_val(name)
  local st = settings.startup["tr-radius-"..name]
  return st and st.value or nil
end

local function get_proto(name)
  local p = data.raw.planet and data.raw.planet[name]
  local s = data.raw["space-location"] and data.raw["space-location"][name]
  if p then return p, "planet" end
  if s then return s, "space-location" end
  return nil, nil
end

local function parent_exists(parent)
  return parent and parent.type=="space-location"
     and data.raw["space-location"]
     and data.raw["space-location"][parent.name] ~= nil
end

local function has_parent_space_location(proto)
  local par = proto.orbit and proto.orbit.parent
  return parent_exists(par)
end

-- ====== ХЕЛПЕРЫ — ключевой фикс визуальных колец ======

-- Единая точка: зафиксировать orbit.parent в самом прототипе, синхронизировать поля и вызвать PlanetsLib.update
local function lib_update_orbit(kind, name, parent, or01, dist)
  local lib = rawget(_G, "PlanetsLib")
  if not (lib and lib.update and type(lib.update)=="function") then return false end
  if not parent_exists(parent) then return false end

  local proto = data.raw[kind] and data.raw[kind][name]; if not proto then return false end

  -- 1) фиксируем родителя ПРЯМО В ПРОТОТИПЕ
  proto.orbit = proto.orbit or {}
  proto.orbit.parent      = {type="space-location", name=parent.name}

  -- 2) синхронизируем расстояние/угол как в orbit.* и в корневых полях
  local use_or = norm01(or01 or proto.orbit.orientation or proto.orientation or 0)
  local use_d  = (dist ~= nil) and dist or (proto.orbit.distance or proto.distance or 0)

  proto.orbit.orientation = use_or
  proto.orbit.distance    = use_d
  proto.orientation       = use_or
  proto.distance          = use_d

  -- 3) position не должен быть «авторитетным» — пусть PlanetsLib пересчитает
  proto.position = nil

  -- 4) собственно обновление — это заставит и детей/внуков корректно пересчитаться
  lib:update{
    type  = kind,
    name  = name,
    orbit = { parent = proto.orbit.parent, orientation = use_or, distance = use_d }
  }

  return true
end

-- Каскад для всех прямых детей звезды после её сдвига
local function cascade_children_of_star(star_name)
  local parent = {type="space-location", name=star_name}
  if not parent_exists(parent) then return end
  for _, kind in ipairs({"planet","space-location"}) do
    for name, proto in pairs(data.raw[kind] or {}) do
      local orb = proto.orbit
      if orb and orb.parent and orb.parent.type=="space-location" and orb.parent.name==star_name then
        -- зафиксируем parent в прототипе и дёрнем через общий helper
        lib_update_orbit(kind, name, parent, orb.orientation or proto.orientation, orb.distance or proto.distance)
      end
    end
  end
end

-- ========= A) Репарентинг в Nexuz (ПОЗДНО; включает earth) =========
do
  local nex = {type="space-location", name="nexuz-background"}
  if parent_exists(nex) then
    local LIST = {
      arrakis=true, aiur=true, char=true, corrundum=true,
      maraxsis=true, ["maraxsis-trench"]=true, tiber=true, tenebris=true,
      earth=true
    }
    for _, kind in ipairs({"planet","space-location"}) do
      for name, proto in pairs(data.raw[kind] or {}) do
        if LIST[name] then
          local or0 = (proto.orbit and proto.orbit.orientation) or proto.orientation or 0
          local d0  = (proto.orbit and proto.orbit.distance)    or proto.distance    or 0
          lib_update_orbit(kind, name, nex, or0, d0)
        end
      end
    end
  end
end

-- ========= B) Применение пользовательских настроек =========
local function apply_object(name)
  if not enabled(name) then return end
  local proto, kind = get_proto(name); if not proto then return end

  local new_deg = angle_deg(name)      -- 0..360 (может быть 0)
  local new_r   = radius_val(name)     -- 0..5000

  -- 1) Корневая звезда (нет parent): меняем polar-поля и чистим position + каскад детей
  local is_root_star = (kind=="space-location") and not (proto.orbit and proto.orbit.parent)
  if is_root_star then
    local use_or = (new_deg ~= nil) and orientation_from_degrees(new_deg)
                   or norm01(proto.orientation or (proto.orbit and proto.orbit.orientation) or 0)
    local use_d  = (new_r   ~= nil) and new_r
                   or (proto.distance or (proto.orbit and proto.orbit.distance) or 0)
    proto.orientation = use_or
    proto.distance    = use_d
    proto.position    = nil
    cascade_children_of_star(name)
    return
  end

  -- 2) Любой объект с родителем-звездой — ВСЕГДА через lib_update_orbit(...)
  if has_parent_space_location(proto) then
    local base_or = (proto.orbit and proto.orbit.orientation) or proto.orientation or 0
    local base_d  = (proto.orbit and proto.orbit.distance)    or proto.distance    or 0
    local use_or  = (new_deg ~= nil) and orientation_from_degrees(new_deg) or base_or
    local use_d   = (new_r   ~= nil) and new_r or base_d
    lib_update_orbit(kind, name, proto.orbit.parent, use_or, use_d)
    -- если это «дочерняя звезда», подтолкнём её детей сразу
    if kind=="space-location" then cascade_children_of_star(name) end
    return
  end

  -- 3) Прочие (без star-parent): прямые правки + позиция от родителя (если он есть)
  local base_or = (proto.orbit and proto.orbit.orientation) or proto.orientation or 0
  local base_d  = (proto.orbit and proto.orbit.distance)    or proto.distance    or 0
  local use_or  = (new_deg ~= nil) and orientation_from_degrees(new_deg) or base_or
  local use_d   = (new_r   ~= nil) and new_r or base_d

  proto.orbit = proto.orbit or {}
  proto.orientation       = norm01(use_or)
  proto.orbit.orientation = norm01(use_or)
  proto.distance          = use_d
  proto.orbit.distance    = use_d

  local par = proto.orbit.parent
  if par and par.type=="space-location" and data.raw["space-location"][par.name] then
    -- пересчёт позиции от реального положения родителя (для стабильности в финале)
    local P = data.raw[par.type][par.name]
    local px,py = 0,0
    if P and P.position then px = P.position.x or 0; py = P.position.y or 0 end
    local ang = proto.orientation * 2*math.pi
    local vx,vy = math.sin(ang), -math.cos(ang)
    proto.position = { x = px + vx*use_d, y = py + vy*use_d }
  else
    proto.position = nil
  end
end

-- Итерируемся не по settings, а по реальным именам прототипов, у которых вообще есть наши ключи.
local function for_each_configured_name(apply_fn)
  local seen = {}
  for _, kind in ipairs({"planet","space-location"}) do
    for name,_ in pairs(data.raw[kind] or {}) do
      if settings.startup["tr-enable-"..name] then
        seen[name] = true
      end
    end
  end
  for name,_ in pairs(seen) do apply_fn(name) end
end

for_each_configured_name(apply_object)
