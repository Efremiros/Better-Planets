-- 1) Create sprites [img=tr-picon-<name>] for ALL planets/locations + aliases for stars.
-- 2) Don't touch geometry (position/orbit) — important for PlanetsLib.
-- 3) At the very end — a light sanitizer for orientations (1.0 -> 0.0), to avoid catching errors at the boundary.

local function pick_from_table(t, depth)
  depth = (depth or 0) + 1
  if depth > 4 or type(t) ~= "table" then return nil end
  if t.filename then
    local sz = t.size or t.icon_size or t.width or t.height
    local mm = t.mipmap_count or t.icon_mipmaps or 0
    return t.filename, sz, mm
  end
  if t.layers and t.layers[1] then
    local f,s,m = pick_from_table(t.layers[1], depth); if f then return f,s,m end
  end
  if t.hr_version then
    local f,s,m = pick_from_table(t.hr_version, depth); if f then return f,s,m end
  end
  for _,v in pairs(t) do
    local f,s,m = pick_from_table(v, depth); if f then return f,s,m end
  end
  return nil
end

local function first_proto(name)
  for _,k in ipairs({"planet","space-location"}) do
    local p = data.raw[k] and data.raw[k][name]
    if p then return p end
  end
end

local function best_icon_for(proto)
  if not proto then return nil end
  if proto.starmap_icon then
    if type(proto.starmap_icon) == "string" then
      return proto.starmap_icon, (proto.starmap_icon_size or proto.icon_size or 64), (proto.icon_mipmaps or 0)
    else
      local f,s,m = pick_from_table(proto.starmap_icon)
      return f, (s or proto.starmap_icon_size or proto.icon_size or 64), m
    end
  end
  if proto.icon then
    if type(proto.icon) == "string" then
      return proto.icon, (proto.icon_size or 64), (proto.icon_mipmaps or 0)
    else
      local f,s,m = pick_from_table(proto.icon)
      return f, (s or proto.icon_size or 64), m
    end
  end
  if proto.icons and proto.icons[1] then
    local ic = proto.icons[1]
    if type(ic.icon) == "string" then
      return ic.icon, (ic.icon_size or proto.icon_size or 64), (ic.icon_mipmaps or proto.icon_mipmaps or 0)
    else
      local f,s,m = pick_from_table(ic)
      return f, (s or ic.icon_size or proto.icon_size or 64), m
    end
  end
  local f,s,m = pick_from_table(proto)
  return f, (s or proto.icon_size or 64), m
end

local function ensure_sprite_from_proto(target_sprite_name, source_proto_name)
  if data.raw.sprite and data.raw.sprite[target_sprite_name] then return true end
  local src = first_proto(source_proto_name)
  if not src then return false end
  local filename, size, mm = best_icon_for(src)
  if not filename then return false end
  data:extend{{
    type = "sprite",
    name = target_sprite_name,
    filename = filename,
    size = tonumber(size) or 64,
    mipmap_count = tonumber(mm) or 0,
    flags = {"gui-icon"}
  }}
  return true
end

-- 1) Base sprites: for EVERY prototype [img=tr-picon-<its_name>]
for _, kind in ipairs({"planet","space-location"}) do
  for name,_ in pairs(data.raw[kind] or {}) do
    ensure_sprite_from_proto("tr-picon-"..name, name)
  end
end

-- 2) Aliases for stars:
--    star-dea-dia -> icon from dea-dia-system-edge
--    nexuz-background -> icon from sye-nexuz-sw
--    redstar -> icon from calidus-senestella-gate-senestella
local STAR_ALIAS = {
  ["star-dea-dia"]     = "dea-dia-system-edge",
  ["nexuz-background"] = "sye-nexuz-sw",
  ["redstar"]          = "calidus-senestella-gate-senestella",
}
for star, src in pairs(STAR_ALIAS) do
  ensure_sprite_from_proto("tr-picon-"..star, src)
end

-- === sanity [0,1) ===
local function norm01(x)
  if type(x) ~= "number" then return x end
  x = x - math.floor(x)
  if x < 0 then x = x + 1 end
  if x >= 1 then x = 0 end  -- 1.0 -> 0.0
  return x
end

for _, kind in ipairs({"planet","space-location"}) do
  for _, proto in pairs(data.raw[kind] or {}) do
    if proto.orientation ~= nil then
      proto.orientation = norm01(proto.orientation)
    end
    if proto.orbit and proto.orbit.orientation ~= nil then
      proto.orbit.orientation = norm01(proto.orbit.orientation)
    end
  end
end

-- Conditionally load scripts based on settings
if settings.startup["tr-enable-tech-reparent"] and settings.startup["tr-enable-tech-reparent"].value then
  require("__Better-Planets__/scripts/tech-reparent")
end

if settings.startup["tr-enable-space-connections"] and settings.startup["tr-enable-space-connections"].value then
  require("__Better-Planets__/scripts/space-connections")
end

if settings.startup["tr-enable-connection-normalizer"] and settings.startup["tr-enable-connection-normalizer"].value then
  require("__Better-Planets__/scripts/space-connection-normalizer")
end

-- Always load asteroid streams (no toggle for this yet)
require("__Better-Planets__/scripts/asteroid-streams")