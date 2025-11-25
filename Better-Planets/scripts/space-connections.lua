-- scripts/space-connections.lua
-- Better Planets — managing space-connection links between planets/locations.
-- Executed at data-final-fixes stage, when all mods are already loaded.
--
-- Capabilities:
--  * Removing connections between two points (remove).
--  * Creating new connections (ensure).
--  * Soft fallback: if some location doesn't exist — we do nothing.
--
-- How to connect: add to data-final-fixes.lua the line:
--   require("__Better-Planets__/scripts/space-connections")
--
-- If you want to call from another file, export is available through table
--   BetterPlanetsConnections.remove(from, to)
--   BetterPlanetsConnections.ensure(from, to, length)

local C = {}

-- Check for existence of planet/location prototype
local function proto_exists(name)
  return (data.raw.planet and data.raw.planet[name])
      or (data.raw["space-location"] and data.raw["space-location"][name])
end

-- Resolving point (returns name, if exists)
local function resolve_endpoint(name)
  return proto_exists(name) and name or nil
end

-- Removing connection between two points (in any direction)
function C.remove(a, b)
  if not (a and b) then return false end
  local resolved_a = resolve_endpoint(a)
  local resolved_b = resolve_endpoint(b)

  if not (resolved_a and resolved_b) then
    return false
  end

  local t = data.raw["space-connection"]
  if not t then return false end

  local removed = false
  for cname, conn in pairs(table.deepcopy(t)) do
    if conn and type(conn.from)=="string" and type(conn.to)=="string" then
      local is_pair = (conn.from == resolved_a and conn.to == resolved_b)
                   or (conn.from == resolved_b and conn.to == resolved_a)
      if is_pair then
        t[cname] = nil
        removed = true
      end
    end
  end

  return removed
end

-- Creating new connection between two points
-- opts:
--   length (number, default 500) — connection length
--   order  (string, optional)    — sort order
function C.ensure(from_name, to_name, opts)
  opts = opts or {}
  local length = opts.length or 500
  local order  = opts.order

  if not (from_name and to_name) then return false end

  local resolved_from = resolve_endpoint(from_name)
  local resolved_to   = resolve_endpoint(to_name)

  if not (resolved_from and resolved_to) then
    return false
  end

  local cname = "bp-conn-"..resolved_from.."__"..resolved_to

  if not data.raw["space-connection"] or not data.raw["space-connection"][cname] then
    data:extend({
      {
        type = "space-connection",
        name = cname,
        icon = "__core__/graphics/empty.png",
        icon_size = 1,
        from = resolved_from,
        to   = resolved_to,
        length = length,
        order  = order or ("zzz["..cname.."]"),
      }
    })
    return true
  end

  return false
end

-- ===================================================================
-- AUTO-REMOVAL: Remove connections that cross 0-degree line (NORTH)
-- Removes connections for planets with radius < 36 that cross the north line
-- Only applies to solar system planets (not moons, not other star systems)
-- ===================================================================

-- Load shared configuration for moon detection
local DEFAULTS = require("__Better-Planets__/config")

-- Build list of moon names from config
local MOON_NAMES = {}
for _, entry in ipairs(DEFAULTS) do
  if entry.is_moon then
    MOON_NAMES[entry.name] = true
  end
end

-- Manual exceptions: add planet/location names here to skip crossover removal
local MANUAL_EXCEPTIONS = {
  -- Examples (uncomment to use):
  -- ["planet-name"] = true,
}

-- Helper: Check if a location is a moon
local function is_moon(loc, name)
  if not loc then return false end
  -- Check subgroup
  if loc.subgroup == "satellites" then return true end
  -- Check if in moon list
  if MOON_NAMES[name] then return true end
  return false
end

-- Helper: Check if location orbits the main solar system star
local function orbits_main_star(loc)
  if not loc or not loc.orbit or not loc.orbit.parent then return false end
  local parent = loc.orbit.parent
  -- Main solar system star is typically named "star"
  return parent.type == "space-location" and parent.name == "star"
end

if data.raw["space-connection"] then
  for conn_name, conn in pairs(data.raw["space-connection"]) do
    if conn and type(conn.from) == "string" and type(conn.to) == "string" then
      local from_loc = data.raw.planet[conn.from] or data.raw["space-location"][conn.from]
      local to_loc = data.raw.planet[conn.to] or data.raw["space-location"][conn.to]

      if from_loc and to_loc then
        -- Skip if either location is in manual exceptions
        if MANUAL_EXCEPTIONS[conn.from] or MANUAL_EXCEPTIONS[conn.to] then
          goto continue
        end

        -- Skip if either location is a moon
        if is_moon(from_loc, conn.from) or is_moon(to_loc, conn.to) then
          goto continue
        end

        -- Only apply to planets that orbit the main solar system star
        if not (orbits_main_star(from_loc) and orbits_main_star(to_loc)) then
          goto continue
        end

        -- Get orientation from orbit.orientation or orientation
        local o1 = ((from_loc.orbit and from_loc.orbit.orientation) or from_loc.orientation or 0) % 1
        local o2 = ((to_loc.orbit and to_loc.orbit.orientation) or to_loc.orientation or 0) % 1

        -- Get radius from orbit.distance or distance
        local r1 = (from_loc.orbit and from_loc.orbit.distance) or from_loc.distance or 0
        local r2 = (to_loc.orbit and to_loc.orbit.distance) or to_loc.distance or 0

        -- Check if at least one planet has radius < 36
        if r1 < 36 or r2 < 36 then
          -- Check if connection crosses the north line (0/360 degree)
          -- One orientation should be close to 0, the other close to 1
          local crosses_north = (o1 <= 0.25 and o2 >= 0.75) or (o2 <= 0.25 and o1 >= 0.75)

          if crosses_north then
            data.raw["space-connection"][conn_name] = nil
          end
        end

        ::continue::
      end
    end
  end
end

-- Export for potential reuse in other mod scripts
BetterPlanetsConnections = rawget(_G, "BetterPlanetsConnections") or {}
BetterPlanetsConnections.remove = C.remove
BetterPlanetsConnections.ensure = C.ensure

-- ===================================================================
-- TEMPLATES: you can manually add or remove connections
-- ===================================================================

-- Removing connections
C.remove("sye-nexuz-sw", "solar-system-edge")
C.remove("fulgora", "dea-dia-system-edge")
C.remove("gleba", "calidus-senestella-gate-calidus")
C.remove("calidus-senestella-gate-calidus", "calidus-senestella-gate-senestella")
C.remove("solar-system-edge", "corrundum")
C.remove("maraxsis-trench", "cube2")
C.remove("vesta", "calidus-senestella-gate-calidus")

-- Creating new connections
C.ensure("calidus-senestella-gate-calidus", "dea-dia-system-edge", { length = 1000 })
C.ensure("calidus-senestella-gate-calidus", "calidus-senestella-gate-senestella", { length = 1000 })
C.ensure("fulgora", "calidus-senestella-gate-calidus", { length = 70000 })
C.ensure("gleba", "fulgora", { length = 30000 })