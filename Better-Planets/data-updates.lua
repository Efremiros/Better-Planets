-- data-updates.lua — угол -> orientation, радиус -> distance. Ничего не делаем, если поля не заданы.

local tiers_md = data.raw["mod-data"] and data.raw["mod-data"]["PlanetsLib-tierlist"]
if tiers_md and not tiers_md.data then
  tiers_md.data = { default = 3, planet = {}, ["space-location"] = {} }
end

local function angle_from_tier(tier) return (tier or 0) * 360 / 6 end
local function orientation_from_angle_deg(A)
  -- Orientation (0..1), 0=восток, 0.25=юг, 0.5=запад, 0.75=север. Наш угол A — от севера против часовой.
  local deg = ((270 - A) % 360); return deg / 360
end

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

local function find_type(kind_hint, name)
  if data.raw[kind_hint] and data.raw[kind_hint][name] then return kind_hint end
  local other = (kind_hint == "planet") and "space-location" or "planet"
  if data.raw[other] and data.raw[other][name] then return other end
  return nil
end

local function apply_for(kind, name)
  local akey, rkey = "tr-angle-"..kind.."-"..name, "tr-radius-"..kind.."-"..name
  local aval = settings.startup[akey] and settings.startup[akey].value or ""
  local rval = settings.startup[rkey] and settings.startup[rkey].value or ""

  local t = find_type(kind, name); if not t then return end
  local proto = data.raw[t][name]; if not proto then return end

  if aval ~= "" then
    local tier = tonumber(aval)
    if tier then
      if tiers_md then
        tiers_md.data[t] = tiers_md.data[t] or {}
        tiers_md.data[t][name] = tier
      end
      local A = angle_from_tier(tier)
      local o = orientation_from_angle_deg(A)
      proto.orientation = o
      if proto.orbit then proto.orbit.orientation = o end
    end
  end

  if rval ~= "" then
    local nd = parse_radius(rval, proto.distance)
    if nd then
      proto.distance = nd
      if proto.orbit then proto.orbit.distance = nd end
    end
  end
end

local PLANETS = {
  "nauvis","vulcanus","fulgora","gleba","aquilo",
  "akularis","gerkizia","quadromire","foliax","mickora","erimos-prime","vicrox","pelagos","froodara","tchekor",
  "jahtra","nekohaven","zzhora","igrys","arig","janus","shchierbin","ithurice","corrundum","moshine","castra","tapatrion",
  "tenebris","cubium","rubia","paracelsin","hexalith","vesta","maraxsis","frozeta","panglia","omnia","naufulglebunusilo","arrakis","tiber",
  "aiur","char"
}
local SPACE_LOCS = {
  "shattered-planet","solar-system-edge",
  "slp-solar-system-sun","slp-solar-system-sun2","calidus-senestella-gate-calidus","secretas",
  "neumann-v","nix","circa","mirandus"
}

for _,n in ipairs(PLANETS)    do apply_for("planet", n) end
for _,n in ipairs(SPACE_LOCS) do apply_for("space-location", n) end
