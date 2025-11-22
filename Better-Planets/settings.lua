local function provider_ok(name, mod_spec)
  if mod_spec == true then return true end
  if mod_spec == nil then
    return heuristic_has_provider(name) or false
  elseif type(mod_spec) == "string" then
    return mods[mod_spec] ~= nil
  else -- table of possible mods
    for _, m in ipairs(mod_spec) do if mods[m] then return true end end
    return false
  end
end

-- Load shared configuration
local DEFAULTS = require("__Better-Planets__/config")

-- Generate lookup tables from DEFAULTS for settings creation
-- These are minimal arrays needed for add_entry() function and DEFAULT_ENABLE calculation
local ORDER = {}
local DEFAULT_R = {}
local DEFAULT_ANGLE = {}
local DEFAULT_SCALE = {}
local MOON_LIST = {}
local MOON_DEFAULT_LEN = {}
local DEFAULTS_LOOKUP = {}  -- Fast lookup by name

for _, entry in ipairs(DEFAULTS) do
  table.insert(ORDER, entry.name)
  -- Use 0 as fallback for nil values for settings (settings need a default value)
  DEFAULT_R[entry.name] = entry.radius or 0
  DEFAULT_ANGLE[entry.name] = entry.angle or 0
  DEFAULTS_LOOKUP[entry.name] = entry

  if entry.scale then
    DEFAULT_SCALE[entry.name] = entry.scale
  end

  if entry.is_moon then
    table.insert(MOON_LIST, entry.name)
    MOON_DEFAULT_LEN[entry.name] = entry.moon_length
  end
end

local STAR_OVERRIDES = {
  ["star-dea-dia"]     = { icon_from = "dea-dia-system-edge" },
  ["nexuz-background"] = { icon_from = "sye-nexuz-sw" },
  ["redstar"]          = { icon_from = "calidus-senestella-gate-senestella" }
}

local function display_label(name)
  local ov = STAR_OVERRIDES[name]
  local iconName = (ov and ov.icon_from) or name
  -- Read planet names from the mod's locale under [space-location-name]
  return {"", {"space-location-name."..name}, " [img=tr-picon-"..iconName.."]"}
end

-- ordered output
local function add_entry(name, idx)
  local ord_prefix = string.format("%03d-", idx)

-- Enabled by default, if NOT (r==0 && angle==0)
local DEFAULT_ENABLE = {}
for name, _ in pairs(DEFAULT_R) do
  local r = DEFAULT_R[name] or 0
  local a = DEFAULT_ANGLE[name] or 0
  DEFAULT_ENABLE[name] = not (r == 0 or r == 0.0) or not (a == 0 or a == 0.0)
end

  -- header-switch: enable recalculation for this location
  data:extend({
    {
      type = "bool-setting",
      name = "tr-enable-"..name,
      setting_type = "startup",
      default_value = DEFAULT_ENABLE[name] or false,
      localised_name = display_label(name),
      localised_description = {"bp.desc-enable"},
      order = ord_prefix .. "a"
    },
    {
      type = "double-setting",
      name = "tr-radius-"..name,
      setting_type = "startup",
      default_value = DEFAULT_R[name] or 0,
      minimum_value = 0,
      maximum_value = 5000,
      localised_name = {"bp.setting-radius-child"},
      localised_description = {"bp.desc-radius"},
      order = ord_prefix .. "b"
    },
    {
      type = "double-setting",
      name = "tr-angle-"..name,
      setting_type = "startup",
      default_value = DEFAULT_ANGLE[name] or 0,
      minimum_value = 0,
      maximum_value = 360,
      localised_name = {"bp.setting-angle-child"},
      localised_description = {"bp.desc-angle"},
      order = ord_prefix .. "c"
    },
    {
      type = "string-setting",
      name = "tr-scale-" .. name,
      setting_type = "startup",
      default_value = DEFAULT_SCALE[name] or "",
      allow_blank = true, -- blank = don't change
      localised_name = {"bp.setting-scale-child"},
      localised_description = {"bp.desc-scale"},
      order = ord_prefix.."d"
    }
  })

  -- route length — only for our moons
  for i, child in ipairs(MOON_LIST) do
    if child == name then
      data:extend({
        {
          type = "int-setting",
          name = "tr-conn-length-" .. child,
          setting_type = "startup",
          default_value = MOON_DEFAULT_LEN[child] or 3000,
          minimum_value = 1000,
          maximum_value = 20000,
          localised_name = {"bp.setting-connlen-child"},
          localised_description = {"bp.desc-connlen"},
          order = ord_prefix.."e"
        }
      })
      break
    end
  end
end

-- Master toggle and script toggles - add at the very beginning
data:extend({
  {
    type = "bool-setting",
    name = "tr-use-custom-parameters",
    setting_type = "startup",
    default_value = false,
    localised_name = {"bp.master-toggle"},
    localised_description = {"bp.desc-master-toggle"},
    order = "000-a-master"
  },
  -- Script toggles
  {
    type = "bool-setting",
    name = "tr-enable-tech-reparent",
    setting_type = "startup",
    default_value = true,
    localised_name = {"bp.enable-tech-reparent"},
    localised_description = {"bp.desc-enable-tech-reparent"},
    order = "000-b-tech-reparent"
  },
  {
    type = "bool-setting",
    name = "tr-enable-space-connections",
    setting_type = "startup",
    default_value = true,
    localised_name = {"bp.enable-space-connections"},
    localised_description = {"bp.desc-enable-space-connections"},
    order = "000-c-space-connections"
  },
  {
    type = "bool-setting",
    name = "tr-enable-connection-normalizer",
    setting_type = "startup",
    default_value = true,
    localised_name = {"bp.enable-connection-normalizer"},
    localised_description = {"bp.desc-enable-connection-normalizer"},
    order = "000-d-connection-normalizer"
  }
})

-- add only existing ones, and carefully re-sort order
do
  local idx = 0
  for _, name in ipairs(ORDER) do
    local entry = DEFAULTS_LOOKUP[name]
    if entry and provider_ok(name, entry.mod) then
      idx = idx + 1
      add_entry(name, idx)
    end
  end
end
