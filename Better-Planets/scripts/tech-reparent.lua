-- scripts/tech-reparent.lua
-- Better Planets — перенос технологий и веток между узлами дерева исследований.
-- Выполняется на стадии data-final-fixes, когда уже загружены все моды.
--
-- Возможности:
--  * Перенос одиночной технологии под другой узел ("под ветку").
--  * Перенос целой ветки (все потомки остаются висеть на корневой технологии).
--  * Аккуратная «вырезка»: если переносим ТОЛЬКО один узел, то все технологии,
--    которые зависели от него, вместо него начинают зависеть от его прежних
--    родителей — так не рвутся пути.
--  * Мягкий фоллбек: если какой‑то технологии нет — ничего не делаем.
--  * Настройка стоимости: можно скопировать рецептуру пакетов из другой
--    технологии и/или задать новое число (count).
--
-- Как подключить: добавьте в data-final-fixes.lua строку:
--   require("__Better-Planets__/scripts/tech-reparent")
--
-- Если хотите вызывать из другого файла, экспорт доступен через таблицу
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

-- Собираем потомков (ветку), идущих после корневой технологии root.
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
  return vis -- множество имён (true)
end

-- Все непосредственные «дети» (те, кто прямо зависит от узла)
local function direct_successors(name)
  local set = {}
  for n, proto in pairs(data.raw.technology or {}) do
    if has_prereq(proto, name) then set[n] = true end
  end
  return set
end

-- Копия unit с возможной заменой счётчика
local function copy_unit_from(source_name, new_count)
  local src = tech(source_name)
  if not (src and src.unit) then return nil end
  local unit = util.table.deepcopy(src.unit)
  if new_count then
    unit.count = tonumber(new_count)
    unit.count_formula = nil -- принудительно переходим на фиксированное число
  end
  return unit
end

-- Главная функция
-- opts:
--   move_branch (bool, default true) — переносить всю ветку (потомков не трогаем, они остаются на корне)
--   splice_gap  (bool, default true) — если переносим ТОЛЬКО одиночный узел (move_branch=false),
--                                       то заменить зависимости его «детей» на прежних «родителей» узла
--   copy_cost_from (string|nil)       — имя технологии-донора для рецептуры пакетов
--   new_count (int|nil)               — новое число исследования (unit.count)
-- Возвращает true/false: были ли изменения.
function T.move(tech_name, new_parent_name, opts)
  opts = opts or {}
  local move_branch = (opts.move_branch ~= false) -- по умолчанию true
  local splice_gap  = (opts.splice_gap ~= false)  -- по умолчанию true
  local donor       = opts.copy_cost_from
  local new_count   = opts.new_count

  if not (exists(tech_name) and exists(new_parent_name)) then return false end
  local node = tech(tech_name)
  local parent = tech(new_parent_name)

  node.prerequisites = dedup(node.prerequisites or {})
  local old_parents = util.table.deepcopy(node.prerequisites)

  -- Защита от циклов: нельзя вешать на собственного потомка
  local branch = collect_branch(tech_name)
  if branch[new_parent_name] then return false end

  -- 1) Если переносим одиночный узел, аккуратно «вырезаем» его из старого места
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

  -- 2) Перевешиваем сам узел под нового родителя
  node.prerequisites = { new_parent_name }

  -- 3) Настройка стоимости, если требуется
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

-- Экспорт для потенциального переиспользования в других скриптах мода
BetterPlanetsTech = rawget(_G, "BetterPlanetsTech") or {}
BetterPlanetsTech.move = T.move

-- Moons

T.move("planet-discovery-quadromire",  "planet-discovery-gleba", { move_branch=true, splice_gap=false })
T.move("planet-discovery-gerkizia",  "planet-discovery-gleba", { move_branch=true, splice_gap=false })

T.move("planet-discovery-tchekor",  "planet-discovery-fulgora", { move_branch=true, splice_gap=false })

T.move("planet-discovery-ithurice",  "planet-discovery-secretas", { move_branch=true, splice_gap=false, copy_cost_from="planet-discovery-secretas", new_count=5000 })
T.move("planet-discovery-tapatrion", "planet-discovery-secretas", { move_branch=true, splice_gap=false, copy_cost_from="planet-discovery-secretas", new_count=5000 })

T.move("planet-discovery-froodara", "planet-discovery-vulcanus", { move_branch=true, splice_gap=false, new_count=2000 })
T.move("planet-discovery-zhora", "planet-discovery-vulcanus", { move_branch=true, splice_gap=false, new_count=2000 })

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