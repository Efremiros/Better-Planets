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

-- ===== B) Moon assignments & Panglia detaching =====
-- Переназначаем родителя через PlanetsLib.update, синхронизируя orbit/корневые поля и обнуляя position.
-- Дополнительно подправляем "magnitude" как простой визуальный масштаб на звёздной карте.

local function norm01(x)
  if x == nil then return nil end
  x = x - math.floor(x)
  if x < 0 then x = x + 1 end
  if x >= 1 then x = 0 end
  return x
end

local function safe_parent_spec(name)
  -- Для планет используем {type="planet", name=...}, для звёзд — {type="space-location", name=...}
  if data.raw.planet and data.raw.planet[name] then
    return {type="planet", name=name}
  end
  if data.raw["space-location"] and data.raw["space-location"][name] then
    return {type="space-location", name=name}
  end
  return nil
end

local function lib_update_orbit(kind, name, parent_spec, or01, dist)
  local lib = rawget(_G, "PlanetsLib")
  if not (lib and lib.update and type(lib.update)=="function") then return false end
  if not parent_spec then return false end
  local proto = data.raw[kind] and data.raw[kind][name]; if not proto then return false end

  -- зафиксировать родителя прямо в прототипе
  proto.orbit = proto.orbit or {}
  proto.orbit.parent = parent_spec

  local use_or = norm01(or01 or proto.orbit.orientation or proto.orientation or 0)
  local use_d  = dist or proto.orbit.distance or proto.distance or 0

  proto.orbit.orientation = use_or
  proto.orbit.distance    = use_d
  proto.orientation       = use_or
  proto.distance          = use_d

  proto.position = nil  -- позиция не должна быть «авторитетной»

  lib:update{
    type  = kind,
    name  = name,
    orbit = { parent = parent_spec, orientation = use_or, distance = use_d }
  }
  return true
end

local function set_magnitude(name, factor)
  -- Меняем визуальный масштаб; если величины нет — задаём от 1.0
  local p = (data.raw.planet and data.raw.planet[name]) or (data.raw["space-location"] and data.raw["space-location"][name])
  if not p then return end
  local base = p.magnitude or 1.0
  p.magnitude = math.max(0.3, math.min(4.0, base * factor))
end

-- карты переназначений
local MOONS = {
  {child="tchekor",   parent="fulgora"},
  {child="froodara",  parent="vulcanus"},
  {child="zzhora",    parent="vulcanus"},
  {child="gerkizia",  parent="gleba"},
  {child="quadromire",parent="gleba"},
  {child="nekohaven", parent="vesta"},
  {child="hexalith",  parent="vesta"},
}

local DETACH_TO_SUN = { "panglia" } -- вернуть к ванильному солнцу

-- применить переназначения (луны)
do
  for _, item in ipairs(MOONS) do
    local child, parent = item.child, item.parent
    -- определяем типы прототипов
    local kind = (data.raw.planet and data.raw.planet[child]) and "planet" or ((data.raw["space-location"] and data.raw["space-location"][child]) and "space-location" or nil)
    if kind then
      local proto = data.raw[kind][child]
      local par_spec = safe_parent_spec(parent)
      if par_spec then
        local or0 = (proto.orbit and proto.orbit.orientation) or proto.orientation or 0
        local d0  = (proto.orbit and proto.orbit.distance)    or proto.distance    or 0
        -- Просто переносим орбиту как есть (сохраняем угол/радиус); при необходимости можно добавить коэффициент для "лунных" дистанций.
        lib_update_orbit(kind, child, par_spec, or0, d0)
        -- сделать визуально меньше
        set_magnitude(child, 0.7)
      end
    end
  end
end

-- отсоединить panglia от gleba → вернуть на солнце
do
  local name = "panglia"
  local kind = (data.raw.planet and data.raw.planet[name]) and "planet" or ((data.raw["space-location"] and data.raw["space-location"][name]) and "space-location" or nil)
  if kind then
    local proto = data.raw[kind][name]
    local par_spec = {type="space-location", name="star"} -- ванильное солнце
    local or0 = (proto.orbit and proto.orbit.orientation) or proto.orientation or 0
    local d0  = (proto.orbit and proto.orbit.distance)    or proto.distance    or 0
    lib_update_orbit(kind, name, par_spec, or0, d0)
    -- сделать визуально больше
    set_magnitude(name, 1.3)
  end
end


-- ===== C) Space connections correctness: mark moons as satellites, unmark panglia =====
-- RSC ориентируется на subgroup "satellites" для спутников: тогда он оставляет только связь "луна ↔ родитель".
-- Для планет (не спутников) subgroup должен быть НЕ "satellites" (можно nil).

local function set_subgroup(name, value_or_nil)
  local p = (data.raw.planet and data.raw.planet[name]) or (data.raw["space-location"] and data.raw["space-location"][name])
  if p then p.subgroup = value_or_nil end
end

-- те, кого мы сделали лунами:
local MOON_NAMES = {
  "tchekor",
  "froodara", "zzhora",
  "gerkizia", "quadromire",
  "nekohaven", "hexalith",
}

for _, n in ipairs(MOON_NAMES) do
  set_subgroup(n, "satellites")     -- пометили как спутник → RSC оставит только связь с родителем
end

-- panglia больше НЕ спутник:
set_subgroup("panglia", nil)         -- убираем из satellites → RSC отдаст ей обычные межпланетные связи


-- ===== D) Space connections: спутники ↔ только родитель, panglia → обычные маршруты =====
-- Спутники (subgroup="satellites") RSC исключает из перерисовки -> их существующие связи остаются как есть.
-- Поэтому: удаляем им ВСЕ старые связи и создаём ровно одну "родитель ↔ луна".
-- Для panglia снимаем "спутниковость"/исключение и удаляем старые связи — RSC построит обычную сеть.

local function proto_of(name)
  return (data.raw.planet and data.raw.planet[name]) or (data.raw["space-location"] and data.raw["space-location"][name])
end

local function kind_of(name)
  if data.raw.planet and data.raw.planet[name] then return "planet" end
  if data.raw["space-location"] and data.raw["space-location"][name] then return "space-location" end
  return nil
end

-- Удаляем все space-connection, где участвует кто-то из множества nameset (имена — СТРОКИ)
local function del_space_connections_involving(nameset)
  local sc = data.raw["space-connection"] or {}
  local to_del = {}
  for sc_name, def in pairs(sc) do
    local a = def.from  -- строки!
    local b = def.to
    if (a and nameset[a]) or (b and nameset[b]) then
      table.insert(to_del, sc_name)
    end
  end
  for _, n in ipairs(to_del) do sc[n] = nil end
end

-- === helper: взять иконку для узла (планета/локация) ===
local function resolve_icon_for(name)
  local p = proto_of(name)
  if not p then return "__core__/graphics/empty.png", 1 end
  -- приоритет: starmap_icon -> icon -> icons[1].icon
  if p.starmap_icon then
    if type(p.starmap_icon) == "string" then
      return p.starmap_icon, (p.starmap_icon_size or p.icon_size or 64)
    elseif type(p.starmap_icon) == "table" and p.starmap_icon.filename then
      return p.starmap_icon.filename, (p.starmap_icon.size or p.icon_size or 64)
    end
  end
  if p.icon then
    return p.icon, (p.icon_size or 64)
  end
  if p.icons and p.icons[1] and p.icons[1].icon then
    return p.icons[1].icon, (p.icons[1].icon_size or p.icon_size or 64)
  end
  return "__core__/graphics/empty.png", 1
end

-- === helper: оценка длины маршрута (км) для parent↔child ===
local function connection_length_for(parent_name, child_name)
  local child = proto_of(child_name)
  if child and child.orbit and child.orbit.distance then
    local d = tonumber(child.orbit.distance) or 0
    if d > 0 then return math.floor(d + 0.5) end
  end
  return 100 -- безопасный фолбэк
end

-- === REPLACE this: create connection with required icon fields ===
local function add_space_connection_unique(parent_name, child_name, keep_flag)
  if not (proto_of(parent_name) and proto_of(child_name)) then return end
  local name = ("bp-conn-%s__%s"):format(parent_name, child_name)
  if data.raw["space-connection"] and data.raw["space-connection"][name] then return end

  local length_km = connection_length_for(parent_name, child_name)
  local icon, icon_size = resolve_icon_for(child_name) -- для коннекта берём иконку «ребёнка»

  data:extend{{
    type   = "space-connection",
    name   = name,
    from   = parent_name,   -- ОБЯЗАТЕЛЬНО СТРОКИ
    to     = child_name,
    length = length_km,     -- чтобы RSC не падал при сортировке
    icon   = icon,          -- ← добавлено
    icon_size = icon_size,  -- ← добавлено
    redrawn_connections_keep = keep_flag ~= false
  }}
end

-- 1) Карта "луна → родитель-планета"
local MOON_PARENT = {
  tchekor    = "fulgora",
  froodara   = "vulcanus",
  zzhora     = "vulcanus",
  gerkizia   = "gleba",
  quadromire = "gleba",
  nekohaven  = "vesta",
  hexalith   = "vesta",
}

-- 2) Помечаем лун как satellites и исключаем их из редроинга RSC
for child,_ in pairs(MOON_PARENT) do
  local p = proto_of(child)
  if p then
    p.subgroup = "satellites"
    p.redrawn_connections_exclude = true  -- страховка; у satellites и так true по умолчанию
  end
end

-- 3) Panglia — больше НЕ спутник и НЕ исключение
do
  local p = proto_of("panglia")
  if p then
    if p.subgroup == "satellites" then p.subgroup = nil end
    p.redrawn_connections_exclude = false
  end
end

-- 4) Удаляем существующие связи у всех наших лун и у panglia
do
  local rm = {}
  for child,_ in pairs(MOON_PARENT) do rm[child] = true end
  rm["panglia"] = true
  del_space_connections_involving(rm)
end

-- 5) Добавляем по ОДНОЙ связи "родитель ↔ луна" (строки!)
for child, parent in pairs(MOON_PARENT) do
  if kind_of(parent) == "planet" and proto_of(child) then
    add_space_connection_unique(parent, child, true)
  end
end


-- ========= E) Применение пользовательских настроек =========
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
