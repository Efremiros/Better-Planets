-- scripts/tech-reparent.lua
-- Better Planets — moving technologies and branches between nodes of the research tree.
-- Executed at data-final-fixes stage, when all mods are already loaded.
--
-- Capabilities:
--  * Moving a single technology under another node ('under a branch').
--  * Moving an entire branch (all descendants remain attached to the root technology).
--  * Careful 'cutting': if moving ONLY one node, then all technologies,
--    that depended on it, instead of it start depending on its former
--    parents — this way paths are not broken.
--  * Soft fallback: if some technology doesn't exist — we do nothing.
--  * Cost adjustment: you can copy the pack recipe from another
--    technology and/or set a new number (count).
--
-- How to connect: add to data-final-fixes.lua the line:
--   require("__Better-Planets__/scripts/tech-reparent")
--
-- If you want to call from another file, export is available through table
--   BetterPlanetsTech.move(tech_name, new_parent_name, opts)

local util = require("util")

local T = {}

local function tech(name)
  return (data.raw.technology or {})[name]
end

local function exists(name)
  return tech(name) ~= nil
end

local function dedup(list)
  local out, seen = {}, {}
  for _,v in ipairs(list or {}) do
    if type(v) == "string" and not seen[v] then
      seen[v] = true
      table.insert(out, v)
    end
  end
  return out
end

local function has_prereq(proto, name)
  if not (proto and proto.prerequisites) then return false end
  for _,p in ipairs(proto.prerequisites) do if p == name then return true end end
  return false
end

local function add_prereq(proto, name)
  proto.prerequisites = proto.prerequisites or {}
  if not has_prereq(proto, name) then table.insert(proto.prerequisites, name) end
end

local function remove_prereq(proto, name)
  if not (proto and proto.prerequisites) then return end
  local dst = {}
  for _,p in ipairs(proto.prerequisites) do if p ~= name then table.insert(dst, p) end end
  proto.prerequisites = dst
end

-- Collect descendants (branch) going after root technology root.
local function collect_branch(root_name)
  local vis = {[root_name] = true}
  local queue = {root_name}
  while #queue > 0 do
    local cur = table.remove(queue, 1)
    for name, proto in pairs(data.raw.technology or {}) do
      if not vis[name] and has_prereq(proto, cur) then
        vis[name] = true
        table.insert(queue, name)
      end
    end
  end
  return vis -- set of names (true)
end

-- All direct 'children' (those who directly depend on the node)
local function direct_successors(name)
  local set = {}
  for n, proto in pairs(data.raw.technology or {}) do
    if has_prereq(proto, name) then set[n] = true end
  end
  return set
end

-- Copy of unit with possible counter replacement
local function copy_unit_from(source_name, new_count)
  local src = tech(source_name)
  if not (src and src.unit) then return nil end
  local unit = util.table.deepcopy(src.unit)
  if new_count then
    unit.count = tonumber(new_count)
    unit.count_formula = nil -- forcefully switch to fixed number
  end
  return unit
end

-- Main function
-- opts:
--   move_branch (bool, default true) — move entire branch (don't touch descendants, they remain on root)
--   splice_gap  (bool, default true) — if moving ONLY a single node (move_branch=false),
--                                       then replace dependencies of its 'children' with former 'parents' of the node
--   copy_cost_from (string|nil)       — name of donor technology for pack recipe
--   new_count (int|nil)               — new research number (unit.count)
-- Returns true/false: whether there were changes.
function T.move(tech_name, new_parent_name, opts)
  opts = opts or {}
  local move_branch = (opts.move_branch ~= false) -- default true
  local splice_gap  = (opts.splice_gap ~= false)  -- default true
  local donor       = opts.copy_cost_from
  local new_count   = opts.new_count

  if not (exists(tech_name) and exists(new_parent_name)) then return false end
  local node = tech(tech_name)
  local parent = tech(new_parent_name)

  node.prerequisites = dedup(node.prerequisites or {})
  local old_parents = util.table.deepcopy(node.prerequisites)

  -- Protection against cycles: can't hang on own descendant
  local branch = collect_branch(tech_name)
  if branch[new_parent_name] then return false end

  -- 1) If moving a single node, carefully 'cut' it from old place
  if not move_branch and splice_gap then
    local succ = direct_successors(tech_name)
    for s_name,_ in pairs(succ) do
      local s = tech(s_name)
      if s then
        remove_prereq(s, tech_name)
        for _,p in ipairs(old_parents) do add_prereq(s, p) end
        s.prerequisites = dedup(s.prerequisites)
      end
    end
  end

  -- 2) Rehang the node itself under new parent
  node.prerequisites = { new_parent_name }

  -- 3) Cost adjustment, if required
  if donor or new_count then
    local unit
    if donor and exists(donor) and tech(donor).unit then
      unit = copy_unit_from(donor, new_count)
    else
      unit = util.table.deepcopy(node.unit or {})
      if new_count then
        unit.count = tonumber(new_count)
        unit.count_formula = nil
      end
    end
    if unit and next(unit) then node.unit = unit end
  end

  return true
end

-- Export for potential reuse in other mod scripts
BetterPlanetsTech = rawget(_G, "BetterPlanetsTech") or {}
BetterPlanetsTech.move = T.move

-- Moons

T.move("planet-discovery-quadromire",  "planet-discovery-gleba", { move_branch=true, splice_gap=false })
T.move("planet-discovery-gerkizia",  "planet-discovery-gleba", { move_branch=true, splice_gap=false })

T.move("planet-discovery-tchekor",  "planet-discovery-fulgora", { move_branch=true, splice_gap=false })

T.move("planet-discovery-ithurice",  "planet-discovery-secretas", { move_branch=true, splice_gap=false, copy_cost_from="planet-discovery-secretas", new_count=5000 })
T.move("planet-discovery-tapatrion", "planet-discovery-secretas", { move_branch=true, splice_gap=false, copy_cost_from="planet-discovery-secretas", new_count=5000 })

T.move("planet-discovery-froodara", "planet-discovery-vulcanus", { move_branch=true, splice_gap=false, new_count=2000 })
T.move("planet-discovery-zzhora", "planet-discovery-vulcanus", { move_branch=true, splice_gap=false, new_count=2000 })

T.move("planet-discovery-vesta", "fusion-reactor", { move_branch=true, splice_gap=false, copy_cost_from="fusion-reactor", new_count=5000 })
T.move("planet-discovery-nekohaven", "planet-discovery-vesta", { move_branch=true, splice_gap=false, copy_cost_from="planet-discovery-vesta", new_count=5000 })
T.move("planet-discovery-corruption", "planet-discovery-vesta", { move_branch=true, splice_gap=false, copy_cost_from="planet-discovery-vesta", new_count=5000 })
T.move("planet-discovery-hexalith", "planet-discovery-vesta", { move_branch=true, splice_gap=false, copy_cost_from="planet-discovery-vesta", new_count=5000 })
T.move("planet-discovery-mickora", "planet-discovery-vesta", { move_branch=true, splice_gap=false, copy_cost_from="planet-discovery-vesta", new_count=5000 })


-- Planets
T.move("planet-discovery-cubium", "space-discovery-asteroid-belt", { move_branch=true, splice_gap=false, copy_cost_from="planet-discovery-aquilo" })
T.move("planet-discovery-shipyard", "planet-discovery-fulgora", { move_branch=true, splice_gap=false, copy_cost_from="terra-asteroid-processsing", new_count=5000 })
T.move("planet-discovery-omnia", "asteroid-collector", { move_branch=true, splice_gap=false, copy_cost_from="terra-asteroid-processsing", new_count=1000 })


-- Nexuz System
T.move("planet-discovery-tiber", "starsystem-discovery-nexuz", { move_branch=true, splice_gap=false, copy_cost_from="starsystem-discovery-nexuz", new_count=5000 })
T.move("planet-discovery-aquilo", "space-discovery-asteroid-belt", { move_branch=true, splice_gap=false }) -- moving aquilo out of tiber planet discovery tech
T.move("planet-discovery-arrakis", "starsystem-discovery-nexuz", { move_branch=true, splice_gap=false, copy_cost_from="starsystem-discovery-nexuz", new_count=5000 })

T.move("planet-discovery-char", "starsystem-discovery-nexuz", { move_branch=true, splice_gap=false, copy_cost_from="starsystem-discovery-nexuz", new_count=5000 })
T.move("enemy_erm_zerg--larva_egg-processing", "planet-discovery-char", { move_branch=true, splice_gap=false })
T.move("enemy_erm_zerg--controllable-unlock", "enemy_erm_zerg--larva_egg-processing", { move_branch=true, splice_gap=false, new_count=10000 })
T.move("enemy_erm_zerg--controllable-damage", "enemy_erm_zerg--controllable-unlock", { move_branch=true, splice_gap=false })

T.move("planet-discovery-aiur", "starsystem-discovery-nexuz", { move_branch=true, splice_gap=false, copy_cost_from="starsystem-discovery-nexuz", new_count=5000 })
T.move("enemy_erm_toss--crystal-processing", "planet-discovery-aiur", { move_branch=true, splice_gap=false })
T.move("enemy_erm_toss--controllable-unlock", "enemy_erm_toss--crystal-processing", { move_branch=true, splice_gap=false, new_count=10000 })
T.move("enemy_erm_toss--controllable-damage", "enemy_erm_toss--controllable-unlock", { move_branch=true, splice_gap=false })

T.move("planet-discovery-earth", "starsystem-discovery-nexuz", { move_branch=true, splice_gap=false, copy_cost_from="starsystem-discovery-nexuz", new_count=5000 })
T.move("enemy_erm_redarmy--organ-processing", "planet-discovery-earth", { move_branch=true, splice_gap=false })

T.move("planet-discovery-corrundum", "starsystem-discovery-nexuz", { move_branch=true, splice_gap=false, copy_cost_from="starsystem-discovery-nexuz", new_count=5000 })
T.move("planet-discovery-tenebris", "starsystem-discovery-nexuz", { move_branch=true, splice_gap=false, new_count=5000 })
T.move("planet-discovery-maraxsis", "starsystem-discovery-nexuz", { move_branch=true, splice_gap=false, new_count=5000 })

-- Custom Tech Fixes
T.move("heating-tower", "planet-discovery-gleba", { move_branch=true, splice_gap=false })
T.move("agriculture", "planet-discovery-gleba", { move_branch=true, splice_gap=false })

T.move("tungsten-carbide", "planet-discovery-vulcanus", { move_branch=true, splice_gap=false })
T.move("calcite-processing", "planet-discovery-vulcanus", { move_branch=true, splice_gap=false })

T.move("holmium-processing", "planet-discovery-fulgora", { move_branch=true, splice_gap=false })

T.move("lithium-processing", "planet-discovery-aquilo", { move_branch=true, splice_gap=false })