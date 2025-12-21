-- Rounds space connection lengths to nearest 5000 km
-- Conditions:
--  • Don't touch paths involving ANY of the listed satellites
--  • Don't touch lengths < 5000 (consider them predefined/special)
--  • Only modify paths where at least one end is from ORDER

-- Load shared configuration
local DEFAULTS = require("__Better-Planets__/config")

-- Generate ORDER and MOON_SKIP from DEFAULTS
local ORDER = {}
local ORDER_SET = {}
local MOON_SKIP = {}

for _, entry in ipairs(DEFAULTS) do
  table.insert(ORDER, entry.name)
  ORDER_SET[entry.name] = true

  -- Add moons to MOON_SKIP
  if entry.is_moon then
    MOON_SKIP[entry.name] = true
  end
end

-- Quick check: is location a satellite by subgroup attribute
local function is_satellite(name)
  local p = (data.raw.planet and data.raw.planet[name]) or (data.raw["space-location"] and data.raw["space-location"][name])
  return p and p.subgroup == "satellites"
end

-- Check: skip connection if it involves a satellite (or it's in MOON_SKIP)
local function connection_involves_moon(a, b)
  if MOON_SKIP[a] or MOON_SKIP[b] then return true end
  if is_satellite(a) or is_satellite(b) then return true end
  return false
end

-- Criterion for applying rounding
local function should_round(conn)
  if type(conn) ~= "table" then return false end
  local a, b = conn.from, conn.to
  if type(a) ~= "string" or type(b) ~= "string" then return false end
  if connection_involves_moon(a, b) then return false end
  if not (ORDER_SET[a] or ORDER_SET[b]) then return false end
  local L = tonumber(conn.length)
  if not L or L < 5000 then return false end
  return true
end

-- Round to nearest 5000 km
local function round_to_5000(n)
  -- example: 21000 -> 20000; 17000 -> 15000; 18000 -> 20000; 33000 -> 35000
  local step = 10000
  if n > 5000000 then
      return n
  end
  return math.floor((n + step/2) / step) * step
end

-- Apply to all space-connections
do
  local sc = data.raw["space-connection"]
  if sc then
    local changed = 0
    for name, conn in pairs(sc) do
      if should_round(conn) then
        local old = tonumber(conn.length)
        local newv = round_to_5000(old)
        if newv ~= old then
          conn.length = newv
          changed = changed + 1
          log(("[Better-Planets] round-conn: %s (%s ↔ %s): %d → %d km")
              :format(name, tostring(conn.from), tostring(conn.to), old, newv))
        end
      end
    end
    if changed > 0 then
      log(("[Better-Planets] round-conn: updated %d connection(s) to neat 5k steps"):format(changed))
    end
  end
end
