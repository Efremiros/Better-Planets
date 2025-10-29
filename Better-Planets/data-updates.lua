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

local function size_factor(name)
  local st = settings.startup["tr-scale-"..name]
  if not st then return nil end
  local s = tostring(st.value or ""):gsub(",",".")
  if s == "" then return nil end -- пусто = не трогаем размер
  local v = tonumber(s)
  if not v then return nil end
  if v < 0.2 then v = 0.2 end
  if v > 5.0 then v = 5.0 end
  return v
end

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

-- ===== B) Moon assignments & Panglia detaching (SAFE) =====
-- Делает луны ТОЛЬКО если родитель реально существует. Иначе объект остаётся как есть (без subgroup="satellites").
-- Panglia возвращаем к солнцу только если она есть. Все операции — через PlanetsLib.update.

local function has_proto(name)
  return (data.raw.planet and data.raw.planet[name])
      or (data.raw["space-location"] and data.raw["space-location"][name])
end

local function proto_of(name)
  return (data.raw.planet and data.raw.planet[name])
      or (data.raw["space-location"] and data.raw["space-location"][name])
end

local function kind_of(name)
  if data.raw.planet and data.raw.planet[name] then return "planet" end
  if data.raw["space-location"] and data.raw["space-location"][name] then return "space-location" end
  return nil
end

local function safe_parent_spec(name)
  if data.raw.planet and data.raw.planet[name] then
    return {type="planet", name=name}
  end
  if data.raw["space-location"] and data.raw["space-location"][name] then
    return {type="space-location", name=name}
  end
  return nil
end

-- единый безопасный update через PlanetsLib
local function lib_update_orbit(kind, name, parent_spec, or01, dist)
  local lib = rawget(_G, "PlanetsLib")
  if not (lib and lib.update and type(lib.update)=="function") then return false end
  if not (parent_spec and parent_spec.type and parent_spec.name and has_proto(parent_spec.name)) then return false end
  local proto = data.raw[kind] and data.raw[kind][name]; if not proto then return false end

  -- зафиксировать родителя и полярные поля, position обнуляем
  proto.orbit = proto.orbit or {}
  proto.orbit.parent      = {type=parent_spec.type, name=parent_spec.name}
  local use_or = (or01 ~= nil) and ((or01 - math.floor(or01)) % 1) or ((proto.orbit.orientation or proto.orientation or 0) % 1)
  local use_d  = (dist ~= nil) and dist or (proto.orbit.distance or proto.distance or 0)
  proto.orbit.orientation = use_or
  proto.orbit.distance    = use_d
  proto.orientation       = use_or
  proto.distance          = use_d
  proto.position          = nil

  lib:update{
    type  = kind,
    name  = name,
    orbit = { parent = proto.orbit.parent, orientation = use_or, distance = use_d }
  }
  return true
end

-- назначаем «кандидатов в луны»: child -> parent (родитель ДОЛЖЕН быть планетой)
local MOONS = {
  {child="tchekor",    parent="fulgora"},
  {child="froodara",   parent="vulcanus"},
  {child="zzhora",     parent="vulcanus"},
  {child="gerkizia",   parent="gleba"},
  {child="quadromire", parent="gleba"},
  {child="tapatrion",   parent="secretas"},
  {child="ithurice",   parent="secretas"},
  {child="nekohaven",  parent="vesta"},
  {child="hexalith",   parent="vesta"},
  {child="mickora",   parent="vesta"},
  {child="corruption",   parent="vesta"},
}

-- результаты успешного «оулунивания» (используем в блоке E)
local MOON_DONE = {}

-- применяем перенос в луны ТОЛЬКО при наличии и ребёнка, и родителя
do
  for _, it in ipairs(MOONS) do
    local child, parent = it.child, it.parent
    local ck, pk = kind_of(child), kind_of(parent)
    if ck and (pk == "planet" or pk == "space-location") then
      local child_proto = proto_of(child)
      local or0 = (child_proto.orbit and child_proto.orbit.orientation) or child_proto.orientation or 0
      local d0  = (child_proto.orbit and child_proto.orbit.distance)    or child_proto.distance    or 0
      local ok = lib_update_orbit(ck, child, safe_parent_spec(parent), or0, d0)
      if ok then
        -- только успешно переназначенным выставляем satellites и уменьшаем размер
        child_proto.subgroup = "satellites"
        child_proto.redrawn_connections_exclude = true
        MOON_DONE[child] = parent
      else
        -- фоллбек: ничего не меняем, subgroup НЕ трогаем (пусть остаётся обычной планетой)
        MOON_DONE[child] = false
      end
    else
      -- родителя нет → пропускаем; subgroup не трогаем
      MOON_DONE[it.child] = false
    end
  end
end

-- panglia: возвращаем на солнце ТОЛЬКО если она есть
do
  local name = "panglia"
  local k = kind_of(name)
  if k then
    local proto = proto_of(name)
    -- убираем спутниковость ВСЕГДА (если была)
    if proto.subgroup == "satellites" then proto.subgroup = nil end
    proto.redrawn_connections_exclude = false
    -- если есть центральное солнце — переносим на star
    if data.raw["space-location"] and data.raw["space-location"]["star"] then
      local or0 = (proto.orbit and proto.orbit.orientation) or proto.orientation or 0
      local d0  = (proto.orbit and proto.orbit.distance)    or proto.distance    or 0
      lib_update_orbit(k, name, {type="space-location", name="star"}, or0, d0)
    end
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
  "froodara", "zzhora", "gerkizia", "quadromire",
  "tapatrion", "ithurice",
  "nekohaven", "hexalith", "mickora", "corruption",
}

for _, n in ipairs(MOON_NAMES) do
  if MOON_DONE and MOON_DONE[n] then
    set_subgroup(n, "satellites")
  else
    set_subgroup(n, nil)
  end
end


-- panglia больше НЕ спутник:
set_subgroup("panglia", nil)         -- убираем из satellites → RSC отдаст ей обычные межпланетные связи


-- ===== D) Space connections: only parent ↔ moon, fixed length; panglia → normal network (SAFE) =====
-- Создаём/чистим связи ТОЛЬКО для тех лун, что реально стали лунами (MOON_DONE[child] == <parent_name>).
-- Для panglia очищаем старые связи и отдаём на отрисовку RSC (если мод есть) как обычную планету.

local function proto_exists_space_connection()
  return data.raw["space-connection"] ~= nil
end

local function del_space_connections_involving(nameset)
  if not proto_exists_space_connection() then return end
  local sc = data.raw["space-connection"]
  local to_del = {}
  for sc_name, def in pairs(sc) do
    local a = def.from  -- строки
    local b = def.to
    if (a and nameset[a]) or (b and nameset[b]) then
      table.insert(to_del, sc_name)
    end
  end
  for _, n in ipairs(to_del) do sc[n] = nil end
end

-- === индивидуальные длины: кодовые оверрайды ===
local MOON_CONNECTION_LENGTHS = {
  tchekor    = 4400,

  froodara   = 3000,
  zzhora     = 3500,

  gerkizia   = 5000,
  quadromire = 3800,

  tapatrion = 9000,
  ithurice = 12000,

  nekohaven  = 8000,
  hexalith   = 10000,
  mickora   = 12000,
  corruption   = 20000,
}

-- дефолт, если нет ни настройки, ни оверрайда
local DEFAULT_MOON_CONNECTION_LENGTH_KM = 3000

-- безопасно прочитаем число из стартап-настройки
local function setting_moon_length_or_nil(child)
  local key = "tr-conn-length-" .. child
  local st = settings and settings.startup and settings.startup[key]
  if not st then return nil end
  local v = tonumber(st.value)
  if not v then return nil end
  -- клампы на всякий случай
  if v < 100 then v = 100 end
  if v > 20000 then v = 20000 end
  return math.floor(v + 0.5)
end

-- финальное определение длины: настройка → таблица → дефолт
local function resolve_moon_connection_length(child_name)
  local v = setting_moon_length_or_nil(child_name)
  if v then return v end
  v = MOON_CONNECTION_LENGTHS[child_name]
  if v then
    v = tonumber(v)
    if v then
      if v < 100 then v = 100 end
      if v > 20000 then v = 20000 end
      return math.floor(v + 0.5)
    end
  end
  return DEFAULT_MOON_CONNECTION_LENGTH_KM
end

local function resolve_icon_for(name)
  local p = proto_of(name)
  if not p then return "__core__/graphics/empty.png", 1 end
  if p.starmap_icon then
    if type(p.starmap_icon) == "string" then
      return p.starmap_icon, (p.starmap_icon_size or p.icon_size or 64)
    elseif type(p.starmap_icon) == "table" and p.starmap_icon.filename then
      return p.starmap_icon.filename, (p.starmap_icon.size or p.icon_size or 64)
    end
  end
  if p.icon then return p.icon, (p.icon_size or 64) end
  if p.icons and p.icons[1] and p.icons[1].icon then
    return p.icons[1].icon, (p.icons[1].icon_size or p.icon_size or 64)
  end
  return "__core__/graphics/empty.png", 1
end

-- создаём связь "родитель ↔ луна" со своей длиной и иконкой
local function add_space_connection_unique(parent_name, child_name, keep_flag)
  if not (proto_exists_space_connection() and has_proto(parent_name) and has_proto(child_name)) then return end
  local name = ("bp-conn-%s__%s"):format(parent_name, child_name)
  if data.raw["space-connection"][name] then return end

  local icon, icon_size = resolve_icon_for(child_name)
  local length_km = resolve_moon_connection_length(child_name)

  data:extend{{
    type   = "space-connection",
    name   = name,
    from   = parent_name,
    to     = child_name,
    length = length_km,
    icon   = icon,
    icon_size = icon_size,
    redrawn_connections_keep = keep_flag ~= false
  }}
end

-- Сначала удаляем ВСЕ старые связи у тех, кто стал лунами, и у panglia (если есть)
do
  local rm = {}
  for child, parent in pairs(MOON_DONE) do
    if parent then rm[child] = true end   -- только реально «оулуневшие»
  end
  if has_proto("panglia") then rm["panglia"] = true end
  if next(rm) then del_space_connections_involving(rm) end
end

-- Затем добавляем по ОДНОЙ связи «родитель ↔ луна» ТОЛЬКО тем, кто реально стал луной
do
  for child, parent in pairs(MOON_DONE) do
    if kind_of(parent) and proto_of(child) then
      add_space_connection_unique(parent, child, true)
    end
  end
end

BP_OVERRIDDEN = BP_OVERRIDDEN or {}
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
    do
      local changed = (new_deg ~= nil) or (new_r ~= nil and new_r ~= 0)  -- угол 0° = валидное значение!
      if changed then BP_OVERRIDDEN[name] = true end
    end
    return
  end

  -- 2) Любой объект с родителем-звездой — ВСЕГДА через lib_update_orbit(...)
  if has_parent_space_location(proto) then
    local base_or = (proto.orbit and proto.orbit.orientation) or proto.orientation or 0
    local base_d  = (proto.orbit and proto.orbit.distance)    or proto.distance    or 0
    local use_or  = (new_deg ~= nil) and orientation_from_degrees(new_deg) or base_or
    local use_d   = (new_r   ~= nil) and new_r or base_d
    lib_update_orbit(kind, name, proto.orbit.parent, use_or, use_d)
    do
      local changed = (new_deg ~= nil) or (new_r ~= nil and new_r ~= 0)
      if changed then BP_OVERRIDDEN[name] = true end
    end
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
    do
      local changed = (new_deg ~= nil) or (new_r ~= nil and new_r ~= 0)
      if changed then BP_OVERRIDDEN[name] = true end
    end
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

-- === Финальный проход: применить масштаб (magnitude) ко всем включённым ===
do
  local function size_factor_final(name)
    local st = settings.startup["tr-scale-"..name]
    if not st then return nil end
    local s = tostring(st.value or ""):gsub(",",".")
    if s == "" then return nil end  -- пусто = не менять
    local v = tonumber(s); if not v then return nil end
    if v < 0.2 then v = 0.2 end
    if v > 5.0 then v = 5.0 end
    return v
  end

  for _, kind in ipairs({"planet","space-location"}) do
    for name, proto in pairs(data.raw[kind] or {}) do
      local opt = settings.startup["tr-enable-"..name]
      if opt and opt.value then
        local f = size_factor_final(name)
        if f then
          local base = tonumber(proto.magnitude) or 1.0
          proto.magnitude = math.max(0.3, math.min(5.0, base * f))
        end
      end
    end
  end
end

-- === Better-Planets: Orbit sprites (moons r1..7 then r20..100; Nexuz r30..100; exclude r8,r9,r10) ===
-- Ставить ПОСЛЕ всех PlanetsLib:update/репарентов/радиусов и т.п.
do
  -- МАЛЫЕ спрайты (реальные размеры PNG), корректная геометрия через компенсацию пикселей.
  local RINGS_SMALL = {
    { r=1, file="__Better-Planets__/graphics/orbits/orbit-unit-ring1.png",  size=262  },
    { r=2, file="__Better-Planets__/graphics/orbits/orbit-unit-ring2.png",  size=518  },
    { r=3, file="__Better-Planets__/graphics/orbits/orbit-unit-ring3.png",  size=774  },
    { r=4, file="__Better-Planets__/graphics/orbits/orbit-unit-ring4.png",  size=1030 },
    { r=5, file="__Better-Planets__/graphics/orbits/orbit-unit-ring5.png",  size=1286 },
    { r=6, file="__Better-Planets__/graphics/orbits/orbit-unit-ring6.png",  size=1542 },
    { r=7, file="__Better-Planets__/graphics/orbits/orbit-unit-ring7.png",  size=1798 },
  }

  -- БОЛЬШИЕ спрайты (4096 px) С РЕКОМЕНДОВАННЫМ scale для их базового радиуса (s_base).
  -- ВНИМАНИЕ: r8,r9,r10 ИСКЛЮЧЕНЫ как «слишком жирные».
  local RINGS_BIG_20_100 = {
    { r=20,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring20.png",  size=4096, s=0.31268310546875  },
    { r=30,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring30.png",  size=4096, s=0.46893310546875  },
    { r=40,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring40.png",  size=4096, s=0.62518310546875  },
    { r=50,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring50.png",  size=4096, s=0.78143310546875  },
    { r=60,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring60.png",  size=4096, s=0.93768310546875  },
    { r=70,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring70.png",  size=4096, s=1.09393310546875  },
    { r=80,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring80.png",  size=4096, s=1.25018310546875  },
    { r=90,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring90.png",  size=4096, s=1.40643310546875  },
    { r=100, file="__Better-Planets__/graphics/orbits/orbit-unit-ring100.png", size=4096, s=1.5626831054687502 },
  }

  -- Для Nexuz используем только r>=30 (толще, но точные по радиусу).
  local RINGS_BIG_30_100 = {
    RINGS_BIG_20_100[2], RINGS_BIG_20_100[3], RINGS_BIG_20_100[4],
    RINGS_BIG_20_100[5], RINGS_BIG_20_100[6], RINGS_BIG_20_100[7],
    RINGS_BIG_20_100[8], RINGS_BIG_20_100[9],
  }

  -- Эталон PlanetsLib генератора для r=100, 4096 px:
  local REF_R, REF_PX, REF_SCALE = 100, 4096, 1.5626831054687502

  -- Полные запреты (и «детям» shattered-planet тоже не рисуем)
  local NO_ORBIT_SELF = {
    ["shattered-planet"] = true,
    ["mirandus-a"]       = true,
    ["cube1"]       = true,
    ["cube2"]       = true,
  }
  local function parent_is_shattered(proto)
    local p = proto.orbit and proto.orbit.parent
    return p and p.type == "space-location" and p.name == "shattered-planet"
  end

  -- Белые списки (как договаривались)
  local ORBIT_WHITELIST_COND = {
    muluna = true, lignumis = true, terrapalus = true, cerys = true,
    frozeta = true, prosephina = true, lemures = true,
  }
  local ORBIT_WHITELIST_FORCE = {
    -- луны/планеты, которым всегда рисуем:
    tchekor = true, quadromire = true, gerkizia = true, froodara = true, zzhora = true,
    hexalith = true, nekohaven = true, mickora = true, corruption = true, tapatrion = true,
    ithurice = true,
    -- системы:
    arrakis = true, aiur = true, char = true, earth = true, corrundum = true,
    maraxsis = true, tiber = true, tenebris = true, ["planet-dea-dia"] = true,
    shipyard = true, nix = true,
  }

  -- Наш набор лун (единое «семейство»)
  local MOONS = {
    muluna=true, lignumis=true, terrapalus=true, cerys=true,
    frozeta=true, prosephina=true, lemures=true,
    tchekor=true, quadromire=true, gerkizia=true, froodara=true, zzhora=true,
    hexalith=true, nekohaven=true, mickora=true, corruption=true, tapatrion=true,
    ithurice=true,
  }

  -- Специальные родительские системы
  local PARENT_STYLE = {
    ["nexuz-background"] = "nexuz",
    ["redstar"]          = "system",
    ["star-dea-dia"]     = "system",
  }

  local function is_central_star(par)
    return par and par.type == "space-location" and par.name == "star"
  end

  -- Масштаб для МАЛЫХ PNG через компенсацию пикселей (правильный радиус для любого dist):
  -- scale = REF_SCALE * (dist / 100) * (4096 / base.size)
  local function scale_small(dist, base_px)
    if not (dist and dist > 0 and base_px and base_px > 0) then return nil end
    return REF_SCALE * (dist / REF_R) * (REF_PX / base_px)
  end

  -- Масштаб для БОЛЬШИХ PNG по их рекомендованному s_base для base.r:
  -- scale = s_base * (dist / base.r)
  local function scale_big_by_base(dist, base)
    if not (dist and dist > 0 and base and base.s and base.r and base.r > 0) then return nil end
    return base.s * (dist / base.r)
  end

  -- Выбор «пола» для малых (r1..r7): максимальный r_base ≤ dist
  local function pick_small_floor(dist)
    if type(dist) ~= "number" or dist <= 0 then return nil end
    local best = RINGS_SMALL[1]
    for _, t in ipairs(RINGS_SMALL) do
      if t.r <= dist and t.r > best.r then best = t end
    end
    return best
  end

  -- Выбор «потолка» для больших (r20..r100), с минимальным порогом min_r (20 или 30)
  local function pick_big_ceil_with_min(dist, list, min_r)
    if type(dist) ~= "number" or dist <= 0 then return nil end
    local candidate = nil
    for _, t in ipairs(list) do
      if t.r >= math.max(dist, min_r) and (not candidate or t.r < candidate.r) then
        candidate = t
      end
    end
    return candidate or list[#list]
  end

  local function ensure_orbit_fields(proto)
    proto.orbit = proto.orbit or {}
    if proto.distance    and proto.orbit.distance    == nil then proto.orbit.distance    = proto.distance    end
    if proto.orientation and proto.orbit.orientation == nil then proto.orbit.orientation = proto.orientation end
  end

  -- безопасный доступ к настройкам (fallback, если BP_OVERRIDDEN не проставлен)
  local function get_setting(key)
    local s = settings and settings.startup
    return (s and s[key]) and s[key].value or nil
  end
  local function our_override_from_settings(name)
    local en = get_setting("bp:"..name..":enable")
              or get_setting("bp-"..name.."-enable")
              or get_setting("bp-"..name.."-enabled")
    local r  = get_setting("bp:"..name..":radius")
              or get_setting("bp-"..name.."-radius")
              or get_setting("bp-"..name.."-r")
    local a  = get_setting("bp:"..name..":angle")
              or get_setting("bp-"..name.."-angle")
              or get_setting("bp-"..name.."-deg")
              or get_setting("bp-"..name.."-orientation")
              or get_setting("bp:"..name..":deg")
    local r_changed = (type(r)=="number" and r ~= 0)
    local a_changed = (type(a)=="number" and a ~= 0)
    return (en == true) or r_changed or a_changed
  end
  local function cond_enabled(name)
    if (type(BP_OVERRIDDEN)=="table" and BP_OVERRIDDEN[name]) then return true end
    return our_override_from_settings(name)
  end

  for _, kind in ipairs({"planet","space-location"}) do
    for name, proto in pairs(data.raw[kind] or {}) do
      -- 0) запреты и «дети» shattered-planet
      if NO_ORBIT_SELF[name] or parent_is_shattered(proto) then
        proto.draw_orbit   = false
        if proto.orbit then proto.orbit.sprite = nil end
        goto continue
      end

      -- 1) нужен orbit.parent
      if not (proto.orbit and proto.orbit.parent) then goto continue end
      ensure_orbit_fields(proto)

      local par  = proto.orbit.parent
      local dist = proto.orbit.distance

      -- 2) у центрального солнца — ваниль
      if is_central_star(par) then
        proto.draw_orbit   = true
        proto.orbit.sprite = nil
        goto continue
      end

      -- 3) решаем по белым спискам
      local must_draw = false
      if ORBIT_WHITELIST_FORCE[name] then
        must_draw = true
      elseif ORBIT_WHITELIST_COND[name] and cond_enabled(name) then
        must_draw = true
      end
      if not (must_draw and type(dist)=="number" and dist > 0) then
        proto.orbit.sprite = nil
        goto continue
      end

      -- 4) стиль выбора
      local style = (par and PARENT_STYLE[par.name]) or "system"
      if MOONS[name] then style = "moon" end

      if style == "moon" then
        if dist <= 15 then
          -- ближние луны: малые PNG (видимые, но аккуратные)
          local base = pick_small_floor(dist)
          local sc = base and scale_small(dist, base.size) or nil
          if base and sc and sc > 0 then
            proto.draw_orbit = true
            proto.orbit.sprite = {
              filename = base.file,
              size     = base.size,   -- 262..1798
              scale    = sc,
              allow_forced_downscale = true
            }
          else
            proto.orbit.sprite = nil
          end
        else
          -- дальние луны: большие PNG, НО без r8..r10 → r20..r100 (тонко, но не «невидимо»)
          local base = pick_big_ceil_with_min(dist, RINGS_BIG_20_100, 20)
          local sc = base and scale_big_by_base(dist, base) or nil
          if base and sc and sc > 0 then
            proto.draw_orbit = true
            proto.orbit.sprite = {
              filename = base.file,
              size     = base.size,   -- 4096
              scale    = sc,
              allow_forced_downscale = true
            }
          else
            proto.orbit.sprite = nil
          end
        end

      elseif style == "nexuz" then
        -- Nexuz: большие PNG r30..r100 (толще, чем r100), точный радиус.
        local base = pick_big_ceil_with_min(dist, RINGS_BIG_30_100, 30)
        local sc = base and scale_big_by_base(dist, base) or nil
        if base and sc and sc > 0 then
          proto.draw_orbit = true
          proto.orbit.sprite = {
            filename = base.file,
            size     = base.size,   -- 4096
            scale    = sc,
            allow_forced_downscale = true
          }
        else
          proto.orbit.sprite = nil
        end

      else
        -- Остальные системы: r100 (как ты и говорил — «супер» для metal-and-stars)
        local base = RINGS_BIG_20_100[#RINGS_BIG_20_100] -- r=100
        local sc = scale_big_by_base(dist, base)
        if sc and sc > 0 then
          proto.draw_orbit = true
          proto.orbit.sprite = {
            filename = base.file,
            size     = base.size,   -- 4096
            scale    = sc,
            allow_forced_downscale = true
          }
        else
          proto.orbit.sprite = nil
        end
      end

      ::continue::
    end
  end
end
