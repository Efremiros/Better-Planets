-- scripts/planet-properties.lua
-- Better Planets — managing surface properties for planets/locations.
-- Executed at data-final-fixes stage, when all mods are already loaded.
--
-- Surface properties include:
-- temperature=Temperature in Kelvin
-- gravity=Gravity
-- pressure=Pressure
-- magnetic-field=Magnetic field
-- solar-power=Solar power in atmosphere
-- solar-power-in-space=Solar power in space
-- day-night-cycle=Day night cycle

-- ===================================================================
-- HELPER FUNCTIONS
-- ===================================================================

-- Safe property setter: only sets if planet exists and property is defined in the game
local function set_property(planet_name, property_name, value)
  if not data.raw.planet then return false end
  local planet = data.raw.planet[planet_name]
  if not planet then return false end

  -- Special case: solar-power-in-space is a direct property of space-location, not a surface property
  if property_name == "solar-power-in-space" then
    planet.solar_power_in_space = value
    return true
  end

  -- Check if the property actually exists in the game
  if not (data.raw["surface-property"] and data.raw["surface-property"][property_name]) then
    -- Property doesn't exist (e.g., cerys-ambient-radiation without Cerys mod)
    return false
  end

  -- Initialize surface_properties if needed
  planet.surface_properties = planet.surface_properties or {}

  -- Set the property
  planet.surface_properties[property_name] = value
  return true
end

-- ===================================================================
-- PLANET PROPERTIES CONFIGURATION
-- ===================================================================

local PLANET_PROPERTIES = {
  -- Vanilla Planets
  ["nauvis"] = {
    ["day-night-cycle"] = 86400,
    ["cerys-ambient-radiation"] = 120,
  },

  ["vulcanus"] = {
    temperature = 633,
    ["cerys-ambient-radiation"] = 200,
    ["solar-power"] = 1000,
    ["solar-power-in-space"] = 2000,
  },

  ["fulgora"] = {
    temperature = 245,
    ["cerys-ambient-radiation"] = 180,
    ["solar-power-in-space"] = 80,
  },

  ["gleba"] = {
    temperature = 300,
    ["cerys-ambient-radiation"] = 110,
  },

  ["aquilo"] = {
    temperature = 193,
    ["cerys-ambient-radiation"] = 60,
  },

  -- Mod Planets

  ["froodara"] = {
    temperature = 298,
    ["solar-power"] = 300,
    ["solar-power-in-space"] = 500,
  },

  ["zzhora"] = {
    temperature = 355,
    ["solar-power"] = 500,
    ["solar-power-in-space"] = 800,
  },

  ["tapatrion"] = {
    temperature = 193,
    ["solar-power-in-space"] = 50,
  },

  ["ithurice"] = {
    temperature = 128,
    ["solar-power-in-space"] = 40,
  },

  ["frozeta"] = {
    temperature = 143,
  },

  ["igrys"] = {
    temperature = 320,
    ["solar-power"] = 60,
    ["solar-power-in-space"] = 65,
  },

  ["shchierbin"] = {
    temperature = 305,
    ["solar-power"] = 55,
    ["solar-power-in-space"] = 60,
  },

  ["omnia"] = {
    temperature = 305,
    ["solar-power"] = 40,
    ["solar-power-in-space"] = 60,
  },

  ["castra"] = {
    temperature = 295,
    ["solar-power-in-space"] = 90,
  },

  ["rubia"] = {
    ["solar-power-in-space"] = 75,
  },

  ["maraxsis"] = {
    temperature = 312,
    ["cerys-ambient-radiation"] = 90,
  },

  ["moshine"] = {
    ["solar-power"] = 800,
    ["solar-power-in-space"] = 1000,
  },

  ["linox-planet_linox"] = {
    temperature = 825,
    ["solar-power-in-space"] = 4000,
  },

  ["panglia"] = {
    ["solar-power-in-space"] = 50,
  },

  ["arig"] = {
    ["solar-power-in-space"] = 348,
  },

  ["cubium"] = {
    temperature = 223,
    ["solar-power"] = 30,
    ["solar-power-in-space"] = 65,
    ["cerys-ambient-radiation"] = 90,
  },

  ["vesta"] = {
    temperature = 225,
    gravity=100,
    ["solar-power"] = 60,
    ["solar-power-in-space"] = 55,
  },

  ["mickora"] = {
    temperature = 275,
    ["solar-power"] = 1,
    ["solar-power-in-space"] = 5,
  },

  ["corruption"] = {
    temperature = 268,
    ["solar-power"] = 0.1,
    ["solar-power-in-space"] = 1,
  },

  ["hexalith"] = {
    temperature = 282,
    ["solar-power"] = 10,
    ["solar-power-in-space"] = 60,
  },

  ["quadromire"] = {
    temperature = 292,
    ["solar-power"] = 25,
    ["solar-power-in-space"] = 40,
  },

  ["nekohaven"] = {
    temperature = 280,
    ["solar-power-in-space"] = 55,
  },

  ["planet-dea-dia"] = {
    gravity=80,
    gasous_atmosphere=100,
  },
}

-- ===================================================================
-- APPLY PROPERTIES
-- ===================================================================

-- Apply all properties from the configuration
for planet_name, properties in pairs(PLANET_PROPERTIES) do
  for property_name, value in pairs(properties) do
    set_property(planet_name, property_name, value)
  end
end