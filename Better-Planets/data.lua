-- data.lua
-- 1) Если пользователь задал угол (градусы CCW от севера) — конвертируем в tier и пишем в tierlist.
-- 2) Если угол НЕ задан — добиваем ТОЛЬКО отсутствующие tier-записи из фактической ориентации прототипа.
--    Ничьих значений не перетираем. data.default НЕ используем.

local TL = data.raw["mod-data"] and data.raw["mod-data"]["PlanetsLib-tierlist"]
if not (TL and TL.data) then return end

local TIER_CYCLE   = 20/3                 -- 6.666666...
local DEG_PER_TIER = 360 / TIER_CYCLE     -- ~54.000054

local function norm_tier(t) local c=TIER_CYCLE; return ((t % c)+c)%c end

local function degrees_from_orientation(o)
  if o == nil then return nil end
  local cw = ((o % 1) + 1) % 1 * 360
  return ((360 - cw) % 360)            -- CCW от севера
end

local function tier_from_degrees(deg) return norm_tier((deg % 360) / DEG_PER_TIER) end

local function set_tier_override(kind, name, t)
  TL.data[kind] = TL.data[kind] or {}
  TL.data[kind][name] = t
end
local function set_tier_missing(kind, name, t)
  TL.data[kind] = TL.data[kind] or {}
  if TL.data[kind][name] == nil then TL.data[kind][name] = t end
end

local function get_known_tier(name)
  local d = TL.data
  if d.planet and d.planet[name] ~= nil then return d.planet[name] end
  if d["space-location"] and d["space-location"][name] ~= nil then return d["space-location"][name] end
  return nil
end

local function angle_setting_for(name)
  local s = settings.startup
  return (s["tr-angle-planet-"..name] and s["tr-angle-planet-"..name].value)
      or (s["tr-angle-space-location-"..name] and s["tr-angle-space-location-"..name].value)
      or ""
end

-- относительный парсер для угла (в градусах, CCW)
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

-- 1) применяем ЯВНЫЕ углы пользователя (переписываем tier)
for _, kind in ipairs({"planet","space-location"}) do
  for name,_ in pairs(data.raw[kind] or {}) do
    local aval = angle_setting_for(name)
    if aval ~= "" then
      local known   = get_known_tier(name)
      local base_deg= known and (known * DEG_PER_TIER) or 0
      local new_deg = parse_angle(aval, base_deg)
      if new_deg then
        local t = tier_from_degrees(new_deg)
        local wrote = false
        if data.raw[kind] and data.raw[kind][name] then set_tier_override(kind, name, t); wrote = true end
        local other = (kind=="planet") and "space-location" or "planet"
        if data.raw[other] and data.raw[other][name] then set_tier_override(other, name, t); wrote = true end
        if not wrote then
          set_tier_override("planet", name, t)
          set_tier_override("space-location", name, t)
        end
      end
    end
  end
end

-- 2) добиваем МИССИНГ tier из фактической ориентации (если угол не задан и записи нет)
for _, kind in ipairs({"planet","space-location"}) do
  for name, proto in pairs(data.raw[kind] or {}) do
    if angle_setting_for(name) == "" then
      if not (TL.data[kind] and TL.data[kind][name] ~= nil) then
        local base_or = (proto.orbit and proto.orbit.orientation) or proto.orientation
        local deg = degrees_from_orientation(base_or)
        if deg then set_tier_missing(kind, name, tier_from_degrees(deg)) end
      end
    end
  end
end
