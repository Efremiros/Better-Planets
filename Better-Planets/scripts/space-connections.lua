-- scripts/space-connections.lua
-- Better Planets — managing space-connection links between planets/locations.
-- Executed at data-final-fixes stage, when all mods are already loaded.
--
-- Capabilities:
--  * Removing connections between two points (remove).
--  * Creating new connections (ensure).
--  * Cloning connections (source_from/source_to parameters deep-copy ALL properties including asteroid streams).
--  * Soft fallback: if some location doesn't exist — we do nothing.
--
-- How to connect: add to data-final-fixes.lua the line:
--   require("__Better-Planets__/scripts/space-connections")
--
-- If you want to call from another file, export is available through table
--   BetterPlanetsConnections.remove(from, to)
--   BetterPlanetsConnections.ensure(from, to, opts)
--     opts can include: length, order, source_from, source_to

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
--   length (number, default 500)   — connection length
--   order  (string, optional)      — sort order
--   source_from (string, optional) — source connection "from" location (where this was copied from)
--   source_to (string, optional)   — source connection "to" location (where this was copied from)
-- If source_from and source_to are provided, ALL parameters are deep-copied from the source connection
-- (including asteroid streams, length, order, etc.), unless explicitly overridden in opts.
-- If only length is provided (no source_from/source_to), and connection already exists, just override the length.
-- Works with connections from any mod or vanilla.
function C.ensure(from_name, to_name, opts)
  opts = opts or {}
  local source_from = opts.source_from
  local source_to = opts.source_to

  if not (from_name and to_name) then return false end

  local resolved_from = resolve_endpoint(from_name)
  local resolved_to   = resolve_endpoint(to_name)

  if not (resolved_from and resolved_to) then
    return false
  end

  -- If only length is provided (no source_from/source_to), try to find and update existing connection
  if opts.length and not (source_from or source_to) then
    if data.raw["space-connection"] then
      -- Search through ALL space-connections to find one matching the endpoints
      for conn_name, conn in pairs(data.raw["space-connection"]) do
        if conn and type(conn.from) == "string" and type(conn.to) == "string" then
          local matches = (conn.from == resolved_from and conn.to == resolved_to)
                       or (conn.from == resolved_to and conn.to == resolved_from)
          if matches then
            -- Found existing connection, just override the length
            conn.length = opts.length
            return true
          end
        end
      end
    end
    -- If no existing connection found and only length provided, do nothing
    return false
  end

  -- Try to find and copy from source connection if specified
  local source_connection = nil
  if source_from and source_to then
    local resolved_source_from = resolve_endpoint(source_from)
    local resolved_source_to = resolve_endpoint(source_to)

    if resolved_source_from and resolved_source_to and data.raw["space-connection"] then
      -- Search through ALL space-connections to find one matching the source endpoints
      -- (works with vanilla, mods, and bp-conn- prefixed connections)
      for conn_name, conn in pairs(data.raw["space-connection"]) do
        if conn and type(conn.from) == "string" and type(conn.to) == "string" then
          local matches = (conn.from == resolved_source_from and conn.to == resolved_source_to)
                       or (conn.from == resolved_source_to and conn.to == resolved_source_from)
          if matches then
            source_connection = conn
            break
          end
        end
      end
    end
  end

  local cname = "bp-conn-"..resolved_from.."__"..resolved_to

  if not data.raw["space-connection"] or not data.raw["space-connection"][cname] then
    local connection

    -- If we have a source connection, deep copy ALL its properties (including asteroid streams)
    if source_connection then
      connection = table.deepcopy(source_connection)
    else
      connection = {}
    end

    -- Override required fields
    connection.type = "space-connection"
    connection.name = cname
    connection.icon = "__core__/graphics/empty.png"
    connection.icon_size = 1
    connection.from = resolved_from
    connection.to = resolved_to

    -- Apply length and order: use opts if provided, otherwise keep from source, otherwise use defaults
    if opts.length then
      connection.length = opts.length
    elseif not connection.length then
      connection.length = 500
    end

    if opts.order then
      connection.order = opts.order
    elseif not connection.order then
      connection.order = "zzz["..cname.."]"
    end

    -- Add source endpoints if provided (for tracking where connection was copied from)
    if source_from and source_to then
      connection.source_from = source_from
      connection.source_to = source_to
    end

    data:extend({ connection })
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

-- If the zero-degree connection removal feature is enabled
local remove_zero_degree_enabled = settings.startup["tr-enable-remove-zero-degree-connections"]
  and settings.startup["tr-enable-remove-zero-degree-connections"].value

if remove_zero_degree_enabled and data.raw["space-connection"] then
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
--
-- Example usage of source parameters:
--
--   1. Clone entire connection (including asteroid streams):
--      C.ensure("new-planet-a", "new-planet-b", {
--        source_from = "asteroid-belt-inner-edge",
--        source_to = "asteroid-belt-outer-edge"
--      })
--      This deep-copies ALL properties: length, order, asteroid streams, etc.
--
--   2. Clone connection but override specific parameters:
--      C.ensure("new-planet-a", "new-planet-b", {
--        length = 2000,  -- Override with custom length
--        source_from = "asteroid-belt-inner-edge",
--        source_to = "asteroid-belt-outer-edge"
--      })
--      This copies everything from source (including asteroid streams), but uses custom length.
--
-- The 'source_from' and 'source_to' parameters identify which connection to deep-copy from.
-- ALL properties (including asteroid streams) are automatically copied unless explicitly overridden in opts.


-- Removing connections

--Incorrect Nexus connections
C.remove("solar-system-edge", "sye-nexuz-sw")
--C.remove("sye-nauvis-ne", "maraxsis")
C.remove("maraxsis-trench", "cube2")
C.remove("sye-nauvis-ne", "earth")

--Refactoring Redstar & Dea Dia connections to one Gate connection
C.remove("fulgora", "dea-dia-system-edge")
C.ensure("calidus-senestella-gate-calidus", "calidus-senestella-gate-senestella", { length = 1000 })
C.ensure("calidus-senestella-gate-calidus", "dea-dia-system-edge", { source_from = "calidus-senestella-gate-calidus", source_to = "calidus-senestella-gate-senestella" })

--Other fixes
C.remove("vesta", "cube1")
C.remove("solar-system-edge", "sye-nauvis-ne")
C.remove("secretas", "sye-nauvis-ne")
C.remove("vesta", "asteroid-belt-inner-edge-clone5")
C.remove("omnia", "sye-nauvis-ne")
C.ensure("sye-nauvis-ne", "sye-nexuz-sw", { length = 300000 })

--New exits from asteroid belt
C.ensure("asteroid-belt-inner-edge", "asteroid-belt-outer-edge", { length = 20000 })
C.ensure("asteroid-belt-inner-edge-clone1", "asteroid-belt-outer-edge-clone1", { source_from = "asteroid-belt-inner-edge", source_to = "asteroid-belt-outer-edge" })
C.ensure("asteroid-belt-inner-edge-clone2", "asteroid-belt-outer-edge-clone2", { source_from = "asteroid-belt-inner-edge", source_to = "asteroid-belt-outer-edge"})
C.ensure("asteroid-belt-inner-edge-clone3", "asteroid-belt-outer-edge-clone3", { source_from = "asteroid-belt-inner-edge", source_to = "asteroid-belt-outer-edge" })

--Kuiper belt
C.ensure("asteroid-belt-inner-edge-clone4", "solar-system-edge", { length = 100000})
C.ensure("asteroid-belt-inner-edge-clone5", "calidus-senestella-gate-calidus", { source_from = "asteroid-belt-inner-edge-clone4", source_to = "solar-system-edge"})
C.ensure("asteroid-belt-inner-edge-clone6", "sye-nauvis-ne", { source_from = "asteroid-belt-inner-edge-clone4", source_to = "solar-system-edge"})