-- scripts/asteroid-streams.lua
-- Better Planets — precise copying of asteroid paths with endpoint influence synchronization.
-- Does:
--  1) Complete replacement of asteroid_spawn_definitions for target space-connection (with rescale and optional reverse).
--  2) Eliminates overlapping: leaves EXACTLY one connection for pair from<->to (other duplicates are removed).
--  3) Copies 'background' from endpoints: asteroid_spawn_influence AND asteroid_spawn_definitions
--     from source locations to corresponding targets (considering reverse).
--  4) Fixes connection from 'redrawers' through redrawn_connections_keep.

local M = {}

-- Eliminate overlapping (remove duplicate connections for pair from<->to)
local EXACT_MODE = true

-- ==== Utilities =============================================================

local function deep_copy(obj)
  if type(obj) ~= "table" then return obj end
  local res = {}
  for k, v in pairs(obj) do res[k] = deep_copy(v) end
  return res
end

local function has_sc()
  return data and data.raw and data.raw["space-connection"] ~= nil
end

-- Find connection between from/to (in any order)
-- Return: proto, is_forward, length_km, proto_name
local function find_connection(from_name, to_name)
  if not has_sc() then return nil, false, nil, nil end
  for name, def in pairs(data.raw["space-connection"]) do
    local a, b = def.from, def.to
    if a == from_name and b == to_name then
      return def, true, tonumber(def.length) or 600, name
    elseif a == to_name and b == from_name then
      return def, false, tonumber(def.length) or 600, name
    end
  end
  return nil, false, nil, nil
end

-- Remove all connections A<->B except keep_name (to exclude probability summation)
local function nuke_other_connections(a, b, keep_name)
  if not (EXACT_MODE and has_sc()) then return end
  local sc = data.raw["space-connection"]
  local to_del = {}
  for name, def in pairs(sc) do
    local f, t = def.from, def.to
    if f and t and ((f == a and t == b) or (f == b and t == a)) then
      if not keep_name or name ~= keep_name then table.insert(to_del, name) end
    end
  end
  for _, n in ipairs(to_del) do sc[n] = nil end
end

local function stamp_keep(def)
  def.redrawn_connections_keep = true
end

-- Remap points by length (with reverse)
local function remap_points(points, src_len, dst_len, reverse)
  local out = {}
  src_len = src_len or 600
  dst_len = dst_len or 600
  for _, sp in ipairs(points or {}) do
    local d = tonumber(sp.distance) or 0
    if d < 0 then d = 0 elseif d > src_len then d = src_len end
    local t = (src_len > 0) and (d / src_len) or 0
    if reverse then t = 1 - t end
    table.insert(out, {
      distance           = t * dst_len,
      probability        = sp.probability,
      speed              = sp.speed,
      angle_when_stopped = sp.angle_when_stopped,
    })
  end
  table.sort(out, function(a, b) return (a.distance or 0) < (b.distance or 0) end)
  return out
end

-- DSL → API (used only in set_route_asteroids)
local function normalize_defs(in_defs, len_km, opts)
  opts = opts or {}
  if type(in_defs) == "table" and in_defs[1] and in_defs[1].spawn_points then
    return deep_copy(in_defs)
  end
  local out = {}
  for asteroid_name, points in pairs(in_defs or {}) do
    if type(points) == "table" then
      local def = { asteroid = asteroid_name, type = "asteroid-chunk", spawn_points = {} }
      for _, p in ipairs(points) do
        local d = (p.distance or p.d or 0)
        local is_rel = (opts.relative ~= nil) and opts.relative or (type(d) == "number" and d >= 0 and d <= 1)
        local dist_km = is_rel and (d * (len_km or 600)) or d
        table.insert(def.spawn_points, {
          distance           = dist_km,
          probability        = p.probability or p.p or 0,
          speed              = p.speed or p.s or 1.0,
          angle_when_stopped = p.angle_when_stopped or p.a,
        })
      end
      table.insert(out, def)
    end
  end
  return out
end

-- ==== Working with location prototypes (endpoint) =======================

local function proto_of_planet_or_loc(name)
  return (data.raw.planet and data.raw.planet[name])
      or (data.raw["space-location"] and data.raw["space-location"][name])
end

-- Completely copy asteroid_spawn_definitions AND asteroid_spawn_influence
-- from one location (src_loc) to another (dst_loc). If source has nil — set nil.
local function copy_endpoint_all(src_loc, dst_loc)
  local src = proto_of_planet_or_loc(src_loc)
  local dst = proto_of_planet_or_loc(dst_loc)
  if not (src and dst) then
    log(("[BP] copy_endpoint_all: src=%s dst=%s not found"):format(src_loc or "?", dst_loc or "?"))
    return false
  end

  -- copy exact definitions and influence (background)
  if src.asteroid_spawn_definitions ~= nil then
    dst.asteroid_spawn_definitions = deep_copy(src.asteroid_spawn_definitions)
  else
    dst.asteroid_spawn_definitions = nil
  end

  if src.asteroid_spawn_influence ~= nil then
    dst.asteroid_spawn_influence = deep_copy(src.asteroid_spawn_influence)
  else
    dst.asteroid_spawn_influence = nil
  end

  return true
end

-- ==== Main operations ====================================================

-- Complete replacement of asteroid set on route (custom points)
function M.set_route_asteroids(from_name, to_name, defs, opts)
  opts = opts or {}
  local conn, _, L, conn_name = find_connection(from_name, to_name)
  if not conn then
    log(("[BP] set_route_asteroids: route %s → %s not found"):format(from_name, to_name))
    return false
  end
  local norm = normalize_defs(defs, L or 600, opts)
  for _, def in ipairs(norm) do
    table.sort(def.spawn_points, function(a, b) return (a.distance or 0) < (b.distance or 0) end)
  end
  conn.asteroid_spawn_definitions = norm
  stamp_keep(conn)
  nuke_other_connections(from_name, to_name, conn_name)
  return true
end

-- Copying asteroid set (with rescale/reverse) AND endpoint influence synchronization.
-- opts.reverse=true – reverse curve by length and 'swap' endpoint influence copying.
function M.copy_route_and_endpoints(src_from, src_to, dst_from, dst_to, opts)
  opts = opts or {}
  local src, _, src_len = find_connection(src_from, src_to)
  if not src then
    log(("[BP] copy_route_and_endpoints: source %s → %s not found"):format(src_from, src_to))
    return false
  end
  local dst, _, dst_len, dst_name = find_connection(dst_from, dst_to)
  if not dst then
    log(("[BP] copy_route_and_endpoints: destination %s → %s not found"):format(dst_from, dst_to))
    return false
  end

  local defs = src.asteroid_spawn_definitions
  if not (defs and defs[1]) then
    log(("[BP] copy_route_and_endpoints: source %s → %s has no asteroid_spawn_definitions; skipping"):format(src_from, src_to))
    return false
  end

  -- 1) Copy asteroid curves
  local out_defs = {}
  for _, def in ipairs(defs) do
    table.insert(out_defs, {
      asteroid     = def.asteroid,
      type         = def.type,
      spawn_points = remap_points(def.spawn_points, src_len or 600, dst_len or 600, opts.reverse),
    })
  end
  for _, d in ipairs(out_defs) do
    table.sort(d.spawn_points, function(a, b) return (a.distance or 0) < (b.distance or 0) end)
  end
  dst.asteroid_spawn_definitions = out_defs
  stamp_keep(dst)
  nuke_other_connections(dst_from, dst_to, dst_name)

  -- 2) Synchronize endpoint influence and local endpoint definitions
  --    Normal case: copy A→B → C→D:
  --      influence(A) → influence(C), influence(B) → influence(D)
  --    With reverse=true: copy A→B → (reverse) C→D:
  --      influence(A) → influence(D), influence(B) → influence(C)
  if opts.reverse then
    copy_endpoint_all(src_from, dst_to)
    copy_endpoint_all(src_to,   dst_from)
  else
    copy_endpoint_all(src_from, dst_from)
    copy_endpoint_all(src_to,   dst_to)
  end

  return true
end

-- Mass copy (list: { {src={from,to}, dst={ {from,to,reverse?}, ... }}, ... })
function M.copy_many(list)
  if type(list) ~= "table" then return end
  for _, item in ipairs(list) do
    local s = item.src or {}
    for _, d in ipairs(item.dst or {}) do
      M.copy_route_and_endpoints(s.from, s.to, d.from, d.to, { reverse = d.reverse })
    end
  end
end

-- ======= USER PRESETS ============================================

local USER_PRESETS = {}

-- 1) From task:
--   Secretas→Tapatrion and Secretas→Ithurice = like Secretas→Frozeta
--   Gleba→Gerkizia and Gleba→Quadromire      = like Gleba→Terrapalus
--   Fulgora→Tchekor                         = like Fulgora→Cerys
--   Vulcanus→Zzhora and Vulcanus→Froodara    = like Nauvis→Vulcanus (reverse)
USER_PRESETS[#USER_PRESETS+1] = {
  kind = "copy-many",
  data = {
    {
      src = { from = "secretas", to = "frozeta" },
      dst = {
        { from = "secretas", to = "tapatrion" },
        { from = "secretas", to = "ithurice"  },
      }
    },
    {
      src = { from = "gleba", to = "terrapalus" },
      dst = {
        { from = "gleba", to = "gerkizia"   },
      }
    },
    {
      src = { from = "fulgora", to = "cerys" },
      dst = {
        { from = "fulgora", to = "tchekor" },
      }
    },
    {
      src = { from = "nauvis", to = "vulcanus" },
      dst = {
        { from = "vulcanus", to = "zzhora",   reverse = true },
        { from = "vulcanus", to = "froodara", reverse = true },
      }
    },
    {
      src = { from = "aquilo", to = "secretas" },
      dst = {
        { from = "paracelsin", to = "vesta" },
      }
    },
    {
      src = { from = "asteroid-belt-inner-edge", to = "asteroid-belt-outer-edge" },
      dst = {
        { from = "calidus-senestella-gate-calidus", to = "dea-dia-system-edge" },
        { from = "calidus-senestella-gate-calidus", to = "calidus-senestella-gate-senestella" },
      }
    },
    {
      src = { from = "asteroid-belt-outer-edge", to = "cubium" },
      dst = {
        { from = "asteroid-belt-outer-edge-2", to = "igrys" },
        { from = "asteroid-belt-outer-edge-2", to = "shchierbin" },
        { from = "asteroid-belt-outer-edge-1", to = "omnia" },
        { from = "asteroid-belt-outer-edge-1", to = "panglia" },

        { from = "vesta", to = "hexalith" },
        { from = "vesta", to = "nekohaven" },
        { from = "vesta", to = "mickora" },
        { from = "vesta", to = "corruption" },
        { from = "vesta", to = "quadromire" },
      }
    },
  }
}

-- 2) (Optional) example of custom complete replacement:
-- USER_PRESETS[#USER_PRESETS+1] = {
--   kind = "set",
--   data = {
--     from = "gleba", to = "vesta",
--     defs = {
--       ["metallic-asteroid-chunk"] = {
--         {d=0.00, p=0.003, s=1.0},
--         {d=0.33, p=0.006, s=1.1},
--         {d=0.66, p=0.009, s=1.1},
--         {d=1.00, p=0.004, s=0.9},
--       },
--     },
--     opts = { relative = true },
--   }
-- }

-- Execute presets immediately on require
for _, pr in ipairs(USER_PRESETS) do
  if pr.kind == "copy-many" then
    M.copy_many(pr.data)
  elseif pr.kind == "copy" then
    local d = pr.data or {}
    M.copy_route_and_endpoints(d.src_from, d.src_to, d.dst_from, d.dst_to, { reverse = d.reverse })
  elseif pr.kind == "set" then
    local d = pr.data or {}
    M.set_route_asteroids(d.from, d.to, d.defs, d.opts)
  end
end

return M
