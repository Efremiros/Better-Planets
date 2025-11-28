-- scripts/asteroid_belts.lua
-- Better Planets — Cloned asteroid belt locations from AsteroidBelt mod
-- Allows creating multiple "exits" from asteroid belts at different positions
-- Includes technology and space connection cloning

local icon_dir = "__AsteroidBelt__/graphics/icon/"
local tech_icon_dir = "__AsteroidBelt__/graphics/technology/"

-- Check if AsteroidBelt mod is installed
if not mods["AsteroidBelt"] then
  log("[Better Planets] AsteroidBelt mod not found, skipping asteroid_belts.lua")
  return
end

-- Check if either feature is enabled
local asteroid_belt_setting = settings.startup["tr-enable-asteroid-belt-clones"]
local kuiper_belt_setting = settings.startup["tr-enable-kuiper-belt-clones"]
local enable_asteroid_belt = asteroid_belt_setting and asteroid_belt_setting.value
local enable_kuiper_belt = kuiper_belt_setting and kuiper_belt_setting.value

if not enable_asteroid_belt and not enable_kuiper_belt then
  log("[Better Planets] Both asteroid belt and Kuiper belt clones disabled by settings")
  return
end

-- ========= UTILITY FUNCTIONS =========

local function deep_copy(obj)
  if type(obj) ~= "table" then return obj end
  local res = {}
  for k, v in pairs(obj) do res[k] = deep_copy(v) end
  return res
end

local function norm01(x)
  if x == nil then return nil end
  x = x - math.floor(x)
  if x < 0 then x = x + 1 end
  if x >= 1 then x = 0 end
  return x
end

-- Convert degrees (CCW from North) to Factorio orientation (CW, [0,1))
local function orientation_from_degrees(angle_deg)
  if angle_deg == nil then return nil end
  local deg = ((angle_deg % 360) + 360) % 360
  local deg_cw = (360 - deg) % 360
  return norm01(deg_cw / 360)
end

-- Get asteroid spawn definitions from original location
local function get_asteroid_density(original_name)
  local orig = data.raw["space-location"] and data.raw["space-location"][original_name]
  if orig and orig.asteroid_spawn_definitions then
    return deep_copy(orig.asteroid_spawn_definitions)
  end
  return nil
end

-- ========= CLONE CREATION FUNCTIONS =========

-- Create a cloned space-location
local function create_location_clone(params)
  -- params: {
  --   original_name: string (e.g., "asteroid-belt-inner-edge")
  --   clone_name: string (e.g., "asteroid-belt-inner-edge-clone-1")
  --   angle: number (degrees, 0-360)
  --   radius: number (distance from sun)
  --   solar_power: number (optional, copies from original if not provided)
  --   custom_locale_key: string (optional, custom locale key for this clone)
  -- }

  local orig = data.raw["space-location"] and data.raw["space-location"][params.original_name]
  if not orig then
    log("[Better Planets] Original location not found: " .. params.original_name)
    return nil
  end

  local clone = {
    name = params.clone_name,
    type = "space-location",
    icon =
    (params.clone_name == "asteroid-belt-inner-edge-clone4"
     or params.clone_name == "asteroid-belt-inner-edge-clone5"
     or params.clone_name == "asteroid-belt-inner-edge-clone6")
    and "__Better-Planets__/graphics/KuiperBelt.png"
    or orig.icon,

    icon_size =
    (params.clone_name == "asteroid-belt-inner-edge-clone4"
     or params.clone_name == "asteroid-belt-inner-edge-clone5"
     or params.clone_name == "asteroid-belt-inner-edge-clone6")
    and 512
    or orig.icon_size,

    -- Use custom locale key if provided, otherwise use original's name
    localised_name = params.custom_locale_key and {"space-location-name." .. params.custom_locale_key} or {"space-location-name." .. params.original_name},
    localised_description = params.custom_locale_key and {"space-location-description." .. params.custom_locale_key} or {"space-location-description." .. params.original_name},

    redrawn_connections_keep = false,
    redrawn_connections_exclude = false,

    orientation = orientation_from_degrees(params.angle),
    distance = params.radius,

    starmap_icon =
    (params.clone_name == "asteroid-belt-inner-edge-clone4"
     or params.clone_name == "asteroid-belt-inner-edge-clone5"
     or params.clone_name == "asteroid-belt-inner-edge-clone6")
    and "__Better-Planets__/graphics/KuiperBelt.png"
    or orig.starmap_icon,

    starmap_icon_size =
    (params.clone_name == "asteroid-belt-inner-edge-clone4"
     or params.clone_name == "asteroid-belt-inner-edge-clone5"
     or params.clone_name == "asteroid-belt-inner-edge-clone6")
    and 512
    or orig.starmap_icon_size,

    draw_orbit = true,
    fly_condition = false,
    solar_power_in_space = params.solar_power or orig.solar_power_in_space,

    asteroid_spawn_definitions = get_asteroid_density(params.original_name)
  }

  return clone
end

-- Create a cloned technology
local function create_technology_clone(params)
  -- params: {
  --   original_tech: string (e.g., "space-discovery-asteroid-belt")
  --   clone_tech: string (e.g., "space-discovery-asteroid-belt-clone-1")
  --   unlock_locations: table of strings (space locations to unlock)
  --   localised_name_suffix: string (e.g., " - Exit 1")
  --   custom_locale_key: string (optional, custom locale key for this clone)
  -- }

  local orig = data.raw.technology and data.raw.technology[params.original_tech]
  if not orig then
    log("[Better Planets] Original technology not found: " .. params.original_tech)
    return nil
  end

  local clone = {
    name = params.clone_tech,
    type = "technology",
    icon =
    (params.clone_tech == "space-discovery-asteroid-belt-clone4"
     or params.clone_tech == "space-discovery-asteroid-belt-clone5"
     or params.clone_tech == "space-discovery-asteroid-belt-clone6")
    and "__Better-Planets__/graphics/KuiperBelt.png"
    or orig.icon,

    icon_size =
    (params.clone_tech == "space-discovery-asteroid-belt-clone4"
     or params.clone_tech == "space-discovery-asteroid-belt-clone5"
     or params.clone_tech == "space-discovery-asteroid-belt-clone6")
    and 512
    or orig.icon_size,

    localised_name = params.custom_locale_key and {"technology-name." .. params.custom_locale_key} or {"", {"technology-name." .. params.original_tech}, params.localised_name_suffix or ""},
    localised_description = params.custom_locale_key and {"technology-description." .. params.custom_locale_key} or {"technology-description." .. params.original_tech},

    essential = orig.essential,
    prerequisites = deep_copy(orig.prerequisites),
    unit = deep_copy(orig.unit),
    effects = {}
  }

  -- Add unlock effects for specified locations
  for _, location in ipairs(params.unlock_locations) do
    table.insert(clone.effects, {
      type = "unlock-space-location",
      space_location = location
    })
  end

  return clone
end

-- ========= CLONE DEFINITIONS =========
-- Define all clones here with their parameters

local clones_to_create = {
  -- Pair 1: North
  {
    inner = {
      original_name = "asteroid-belt-inner-edge",
      clone_name = "asteroid-belt-inner-edge-clone1",
      angle = 1,
      radius = 31,
      solar_power = 75
    },
    outer = {
      original_name = "asteroid-belt-outer-edge",
      clone_name = "asteroid-belt-outer-edge-clone1",
      angle = 1,
      radius = 36,
      solar_power = 70
    },
    technology = {
      original_tech = "space-discovery-asteroid-belt",
      clone_tech = "space-discovery-asteroid-belt-clone1",
      custom_locale_key = "space-discovery-asteroid-belt-clone1"
    }
  },

  -- Pair 2: West
  {
    inner = {
      original_name = "asteroid-belt-inner-edge",
      clone_name = "asteroid-belt-inner-edge-clone2",
      angle = 90,
      radius = 31,
      solar_power = 75
    },
    outer = {
      original_name = "asteroid-belt-outer-edge",
      clone_name = "asteroid-belt-outer-edge-clone2",
      angle = 87,
      radius = 36,
      solar_power = 70
    },
    technology = {
      original_tech = "space-discovery-asteroid-belt",
      clone_tech = "space-discovery-asteroid-belt-clone2",
      custom_locale_key = "space-discovery-asteroid-belt-clone2"
    }
  },

  -- Pair 3: South
  {
    inner = {
      original_name = "asteroid-belt-inner-edge",
      clone_name = "asteroid-belt-inner-edge-clone3",
      angle = 180,
      radius = 31,
      solar_power = 75
    },
    outer = {
      original_name = "asteroid-belt-outer-edge",
      clone_name = "asteroid-belt-outer-edge-clone3",
      angle = 180,
      radius = 36,
      solar_power = 70
    },
    technology = {
      original_tech = "space-discovery-asteroid-belt",
      clone_tech = "space-discovery-asteroid-belt-clone3",
      custom_locale_key = "space-discovery-asteroid-belt-clone3"
    }
  },

  -- Outer asteroid belt #1 (Solar system - shattered planet) - Kuiper belt
  {
    inner = {
      original_name = "asteroid-belt-inner-edge",
      clone_name = "asteroid-belt-inner-edge-clone4",
      angle = 270,
      radius = 56,
      solar_power = 5,
      custom_locale_key = "kuiper-belt-4"
    },
    technology = {
      original_tech = "space-discovery-asteroid-belt",
      clone_tech = "space-discovery-asteroid-belt-clone4",
      custom_locale_key = "space-discovery-asteroid-belt-clone4"
    }
  },

  -- Outer asteroid belt #2 (Solar system - Dea Dia / Redstar) - Kuiper belt
  {
    inner = {
      original_name = "asteroid-belt-inner-edge",
      clone_name = "asteroid-belt-inner-edge-clone5",
      angle = 110,
      radius = 56,
      solar_power = 5,
      custom_locale_key = "kuiper-belt-5"
    },
    technology = {
      original_tech = "space-discovery-asteroid-belt",
      clone_tech = "space-discovery-asteroid-belt-clone5",
      custom_locale_key = "space-discovery-asteroid-belt-clone5"
    }
  },

  -- Outer asteroid belt #3 (Secretas - Nexus ) - Kuiper belt
  {
    inner = {
      original_name = "asteroid-belt-inner-edge",
      clone_name = "asteroid-belt-inner-edge-clone6",
      angle = 330,
      radius = 56,
      solar_power = 5,
      custom_locale_key = "kuiper-belt-6"
    },
    technology = {
      original_tech = "space-discovery-asteroid-belt",
      clone_tech = "space-discovery-asteroid-belt-clone6",
      custom_locale_key = "space-discovery-asteroid-belt-clone6"
    }
  },

}


-- ========= CREATE CLONES =========

local locations_to_extend = {}
local technologies_to_extend = {}

for i, pair in ipairs(clones_to_create) do
  -- Determine if this clone should be created based on settings
  -- Clones 1-3 are asteroid belt, clones 4-6 are Kuiper belt
  local is_asteroid_belt_clone = (i >= 1 and i <= 3)
  local is_kuiper_belt_clone = (i >= 4 and i <= 6)

  local should_create = (is_asteroid_belt_clone and enable_asteroid_belt) or (is_kuiper_belt_clone and enable_kuiper_belt)

  if should_create then
    -- Create inner location clone
    if pair.inner then
      local inner_clone = create_location_clone(pair.inner)
      if inner_clone then
        table.insert(locations_to_extend, inner_clone)
      end
    end

    -- Create outer location clone
    if pair.outer then
      local outer_clone = create_location_clone(pair.outer)
      if outer_clone then
        table.insert(locations_to_extend, outer_clone)
      end
    end

    -- Create technology clone
    if pair.technology then
      local unlock_locations = {}
      if pair.inner then table.insert(unlock_locations, pair.inner.clone_name) end
      if pair.outer then table.insert(unlock_locations, pair.outer.clone_name) end

      local tech_clone = create_technology_clone({
        original_tech = pair.technology.original_tech,
        clone_tech = pair.technology.clone_tech,
        unlock_locations = unlock_locations,
        localised_name_suffix = pair.technology.localised_name_suffix,
        custom_locale_key = pair.technology.custom_locale_key
      })
      if tech_clone then
        table.insert(technologies_to_extend, tech_clone)
      end
    end
  end
end

-- Apply all clones to the game
if #locations_to_extend > 0 then
  data:extend(locations_to_extend)
  log("[Better Planets] Created " .. #locations_to_extend .. " cloned asteroid belt locations")
end

if #technologies_to_extend > 0 then
  data:extend(technologies_to_extend)
  log("[Better Planets] Created " .. #technologies_to_extend .. " cloned technologies")
end