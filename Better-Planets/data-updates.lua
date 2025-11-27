-- Reparenting Nexuz (including earth) - via PlanetsLib.update
-- Any object with a star parent is updated via PlanetsLib.update(orbit=...), with pre-fixed proto.orbit.parent
-- Stars: orientation/distance, position, cascade update children
-- Orientation normalization

-- Import DEFAULTS configuration
local DEFAULTS = require("__Better-Planets__/config")

-- Create DEFAULTS_LOOKUP table for fast access
local DEFAULTS_LOOKUP = {}
for _, entry in ipairs(DEFAULTS) do
  DEFAULTS_LOOKUP[entry.name] = entry
end

-- ========= utils =========
local function norm01(x)
  if x == nil then return nil end
  x = x - math.floor(x)
  if x < 0 then x = x + 1 end
  if x >= 1 then x = 0 end        -- 1.0 -> 0.0
  return x
end

-- CCW (from north) -> RealOrientation (CW), [0,1)
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
  if s == "" then return nil end
  local v = tonumber(s)
  if not v then return nil end
  if v < 0.2 then v = 0.2 end
  if v > 5.0 then v = 5.0 end
  return v
end

-- Single point: fix orbit.parent in the prototype itself, synchronize fields and call PlanetsLib.update
local function lib_update_orbit(kind, name, parent, or01, dist)
  local lib = rawget(_G, "PlanetsLib")
  if not (lib and lib.update and type(lib.update)=="function") then return false end
  if not parent_exists(parent) then return false end

  local proto = data.raw[kind] and data.raw[kind][name]; if not proto then return false end

  -- 1) fix parent in PROTOTYPE
  proto.orbit = proto.orbit or {}
  proto.orbit.parent      = {type="space-location", name=parent.name}

  -- 2) synchronize distance/angle in both orbit.* and root fields
  local use_or = norm01(or01 or proto.orbit.orientation or proto.orientation or 0)
  local use_d  = (dist ~= nil) and dist or (proto.orbit.distance or proto.distance or 0)

  proto.orbit.orientation = use_or
  proto.orbit.distance    = use_d
  proto.orientation       = use_or
  proto.distance          = use_d

  -- 3) position should not be 'authoritative' - PlanetsLib will recalculate
  proto.position = nil

  -- 4) update - this will force children/grandchildren to recalculate correctly
  lib:update{
    type  = kind,
    name  = name,
    orbit = { parent = proto.orbit.parent, orientation = use_or, distance = use_d }
  }

  return true
end

-- Cascade for all direct children of star after its shift
local function cascade_children_of_star(star_name)
  local parent = {type="space-location", name=star_name}
  if not parent_exists(parent) then return end
  for _, kind in ipairs({"planet","space-location"}) do
    for name, proto in pairs(data.raw[kind] or {}) do
      local orb = proto.orbit
      if orb and orb.parent and orb.parent.type=="space-location" and orb.parent.name==star_name then
        lib_update_orbit(kind, name, parent, orb.orientation or proto.orientation, orb.distance or proto.distance)
      end
    end
  end
end

-- ========= A) Reparenting to Nexuz (includes earth) =========
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
-- Makes moons ONLY if parent actually exists. Otherwise object remains as is (without subgroup="satellites").
-- Return Panglia to sun only if it exists. All operations - via PlanetsLib.update.

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

-- update via PlanetsLib
local function lib_update_orbit(kind, name, parent_spec, or01, dist)
  local lib = rawget(_G, "PlanetsLib")
  if not (lib and lib.update and type(lib.update)=="function") then return false end
  if not (parent_spec and parent_spec.type and parent_spec.name and has_proto(parent_spec.name)) then return false end
  local proto = data.raw[kind] and data.raw[kind][name]; if not proto then return false end

  -- fixing parent and polar fields, zeroing position
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

-- assign 'moon candidates': child -> parent
local MOONS = {
  {child="tchekor",    parent="fulgora"},

  {child="froodara",   parent="vulcanus"},
  {child="zzhora",     parent="vulcanus"},

  {child="gerkizia",   parent="gleba"},

  {child="tapatrion",   parent="secretas"},
  {child="ithurice",   parent="secretas"},

  {child="quadromire", parent="vesta"},
  {child="nekohaven",  parent="vesta"},
  {child="hexalith",   parent="vesta"},
  {child="mickora",   parent="vesta"},
  {child="corruption",   parent="vesta"},
}

-- moon results (block E)
local MOON_DONE = {}

-- apply moon transfer ONLY when both child and parent exist
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
        -- only for successfully reassigned set satellites and reduce size
        child_proto.subgroup = "satellites"
        child_proto.redrawn_connections_exclude = true
        MOON_DONE[child] = parent
      else
        -- fallback: change nothing, DON'T touch subgroup (let it remain a regular planet)
        MOON_DONE[child] = false
      end
    else
      -- no parent → skip; don't touch subgroup
      MOON_DONE[it.child] = false
    end
  end
end

-- panglia: return to sun ONLY if it exists
do
  local name = "panglia"
  local k = kind_of(name)
  if k then
    local proto = proto_of(name)
    -- remove satellite connection (if existed)
    if proto.subgroup == "satellites" then proto.subgroup = nil end
    proto.redrawn_connections_exclude = false
    -- if central sun exists - transfer to star
    if data.raw["space-location"] and data.raw["space-location"]["star"] then
      local or0 = (proto.orbit and proto.orbit.orientation) or proto.orientation or 0
      local d0  = (proto.orbit and proto.orbit.distance)    or proto.distance    or 0
      lib_update_orbit(k, name, {type="space-location", name="star"}, or0, d0)
    end
  end
end

-- ===== C) Space connections correctness: mark moons as satellites, unmark panglia =====
-- RSC uses subgroup "satellites" for moons: then it leaves only "moon ↔ parent" connection.
-- For planets (not satellites) subgroup should NOT be "satellites" (can be nil).

local function set_subgroup(name, value_or_nil)
  local p = (data.raw.planet and data.raw.planet[name]) or (data.raw["space-location"] and data.raw["space-location"][name])
  if p then p.subgroup = value_or_nil end
end

-- moons: extract from MOONS array
local MOON_NAMES = {}
for _, it in ipairs(MOONS) do
  table.insert(MOON_NAMES, it.child)
end

for _, n in ipairs(MOON_NAMES) do
  if MOON_DONE and MOON_DONE[n] then
    set_subgroup(n, "satellites")
  else
    set_subgroup(n, nil)
  end
end


-- panglia is NO longer a satellite:
set_subgroup("panglia", nil)


-- ===== D) Space connections: only parent ↔ moon, fixed length; panglia → normal network (SAFE) =====
-- Create/clean connections ONLY for those moons that actually became moons (MOON_DONE[child] == <parent_name>).
-- For panglia, clear old connections and give to RSC for rendering (if mod exists) as normal planet.

local function proto_exists_space_connection()
  return data.raw["space-connection"] ~= nil
end

local function del_space_connections_involving(nameset)
  if not proto_exists_space_connection() then return end
  local sc = data.raw["space-connection"]
  local to_del = {}
  for sc_name, def in pairs(sc) do
    local a = def.from  -- strings
    local b = def.to
    if (a and nameset[a]) or (b and nameset[b]) then
      table.insert(to_del, sc_name)
    end
  end
  for _, n in ipairs(to_del) do sc[n] = nil end
end

-- default if no setting (all values configured in settings.lua via DEFAULTS)
local DEFAULT_MOON_CONNECTION_LENGTH_KM = 3000

-- final length determination: setting → default
-- Settings are created in settings.lua with default values from MOON_DEFAULT_LEN
local function resolve_moon_connection_length(child_name)
  local key = "tr-conn-length-" .. child_name
  local st = settings and settings.startup and settings.startup[key]
  if st then
    local v = tonumber(st.value)
    if v then
      -- clamps just in case
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

-- connection "parent ↔ moon" with its own length and icon
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

-- Removing ALL old connections from those who became moons, and from panglia (if exists)
do
  local rm = {}
  for child, parent in pairs(MOON_DONE) do
    if parent then rm[child] = true end
  end
  if has_proto("panglia") then rm["panglia"] = true end
  if next(rm) then del_space_connections_involving(rm) end
end

-- Adding connection "parent ↔ moon" ONLY to those who actually became moons
do
  for child, parent in pairs(MOON_DONE) do
    if kind_of(parent) and proto_of(child) then
      add_space_connection_unique(parent, child, true)
    end
  end
end

BP_OVERRIDDEN = BP_OVERRIDDEN or {}
-- ========= E) Applying user settings =========

-- Helper function to check if custom parameters should be used
local function use_custom_parameters()
  local st = settings.startup["tr-use-custom-parameters"]
  return st and st.value or false
end

local function apply_object(name)
  -- Check master toggle first
  local use_custom = use_custom_parameters()

  local proto, kind = get_proto(name); if not proto then return end

  -- Determine values based on master toggle
  local new_deg, new_r

  if use_custom then
    -- Custom parameters enabled: read from settings (original behavior)
    if not enabled(name) then return end
    new_deg = angle_deg(name)      -- 0..360 (can be 0)
    new_r   = radius_val(name)     -- 0..5000
  else
    -- Custom parameters disabled: use defaults from DEFAULTS array
    local default_entry = DEFAULTS_LOOKUP[name]
    if default_entry then
      new_deg = default_entry.angle
      new_r   = default_entry.radius
      -- Skip if no meaningful values (both nil or both 0) - let other mods decide placement
      if (not new_deg and not new_r) or ((new_deg == 0 or not new_deg) and (new_r == 0 or not new_r)) then
        return
      end
    else
      -- No default for this object, skip
      return
    end
  end

  -- 1) Root star (no parent): change polar fields and clear position + cascade children
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
      local changed = (new_deg ~= nil) or (new_r ~= nil and new_r ~= 0)  -- angle 0° = valid value
      if changed then BP_OVERRIDDEN[name] = true end
    end
    return
  end

  -- 2) Any object with star parent - via lib_update_orbit(...)
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
    if kind=="space-location" then cascade_children_of_star(name) end
    return
  end

  -- 3) Others (without star-parent): direct edits + position from parent (if exists)
  local base_or = (proto.orbit and proto.orbit.orientation) or proto.orientation or 0
  local base_d  = (proto.orbit and proto.orbit.distance)    or proto.distance    or 0
  local use_or  = (new_deg ~= nil) and orientation_from_degrees(new_deg) or base_or
  local use_d   = (new_r   ~= nil) and new_r or base_d

  proto.orbit = proto.orbit or {}

  local par = proto.orbit.parent

  -- If object has a planet parent (moon of planet), use lib_update_orbit like case 2
  if par and par.type=="planet" and data.raw.planet[par.name] then
    lib_update_orbit(kind, name, proto.orbit.parent, use_or, use_d)
    do
      local changed = (new_deg ~= nil) or (new_r ~= nil and new_r ~= 0)
      if changed then BP_OVERRIDDEN[name] = true end
    end
    return
  end

  -- Otherwise, set fields directly and calculate position
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
    -- position recalculation from actual parent position (for final stability)
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

-- Iterate not over settings, but over actual prototype names that have our keys.
local function for_each_configured_name(apply_fn)
  local seen = {}

  -- When custom parameters enabled, iterate based on settings
  if use_custom_parameters() then
    for _, kind in ipairs({"planet","space-location"}) do
      for name,_ in pairs(data.raw[kind] or {}) do
        if settings.startup["tr-enable-"..name] then
          seen[name] = true
        end
      end
    end
  else
    -- When using defaults, iterate over DEFAULTS entries
    for _, entry in ipairs(DEFAULTS) do
      local name = entry.name
      -- Only add if the prototype actually exists
      if (data.raw.planet and data.raw.planet[name]) or
         (data.raw["space-location"] and data.raw["space-location"][name]) then
        seen[name] = true
      end
    end
  end

  for name,_ in pairs(seen) do apply_fn(name) end
end

for_each_configured_name(apply_object)

-- === Final pass: apply scale (magnitude) to all enabled ===
do
  local function size_factor_final(name)
    local st = settings.startup["tr-scale-"..name]
    if not st then return nil end
    local s = tostring(st.value or ""):gsub(",",".")
    if s == "" then return nil end  -- empty = don't change
    local v = tonumber(s); if not v then return nil end
    if v < 0.2 then v = 0.2 end
    if v > 5.0 then v = 5.0 end
    return v
  end

  -- Apply scale based on master toggle
  if use_custom_parameters() then
    -- Custom parameters enabled: use settings
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
  else
    -- Custom parameters disabled: use defaults
    for _, kind in ipairs({"planet","space-location"}) do
      for name, proto in pairs(data.raw[kind] or {}) do
        local default_entry = DEFAULTS_LOOKUP[name]
        if default_entry and default_entry.scale then
          local f = tonumber(default_entry.scale)
          if f then
            if f < 0.2 then f = 0.2 end
            if f > 5.0 then f = 5.0 end
            local base = tonumber(proto.magnitude) or 1.0
            proto.magnitude = math.max(0.3, math.min(5.0, base * f))
          end
        end
      end
    end
  end
end

-- Load asteroid belt clones if enabled
if settings.startup["tr-enable-asteroid-belt-clones"] and settings.startup["tr-enable-asteroid-belt-clones"].value then
  require("__Better-Planets__/scripts/asteroid-belts")
end

require("__Better-Planets__/scripts/orbit-drawer")
