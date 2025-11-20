-- scripts/space-connections.lua
-- Better Planets — управление space-connection связями между планетами/локациями.
-- Выполняется на стадии data-final-fixes, когда уже загружены все моды.
--
-- Возможности:
--  * Удаление связей между двумя точками (remove).
--  * Создание новых связей (ensure).
--  * Мягкий фоллбек: если какой-то локации нет — ничего не делаем.
--
-- Как подключить: добавьте в data-final-fixes.lua строку:
--   require("__Better-Planets__/scripts/space-connections")
--
-- Если хотите вызывать из другого файла, экспорт доступен через таблицу
--   BetterPlanetsConnections.remove(from, to)
--   BetterPlanetsConnections.ensure(from, to, length)

local C = {}

-- Проверка существования прототипа планеты/локации
local function proto_exists(name)
  return (data.raw.planet and data.raw.planet[name])
      or (data.raw["space-location"] and data.raw["space-location"][name])
end

-- Резолвинг точки (возвращает имя, если существует)
local function resolve_endpoint(name)
  return proto_exists(name) and name or nil
end

-- Удаление связи между двумя точками (в любом направлении)
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

-- Создание новой связи между двумя точками
-- opts:
--   length (number, default 500) — длина связи
--   order  (string, optional)    — порядок сортировки
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

-- Экспорт для потенциального переиспользования в других скриптах мода
BetterPlanetsConnections = rawget(_G, "BetterPlanetsConnections") or {}
BetterPlanetsConnections.remove = C.remove
BetterPlanetsConnections.ensure = C.ensure

-- ===================================================================
-- ШАБЛОНЫ: можно вручную добавлять или удалять связи
-- ===================================================================

-- Удаление связей
C.remove("sye-nexuz-sw", "solar-system-edge")
C.remove("fulgora", "dea-dia-system-edge")
C.remove("gleba", "calidus-senestella-gate-calidus")
C.remove("calidus-senestella-gate-calidus", "calidus-senestella-gate-senestella")

-- Создание новых связей
C.ensure("calidus-senestella-gate-calidus", "dea-dia-system-edge", { length = 1000 })
C.ensure("calidus-senestella-gate-calidus", "calidus-senestella-gate-senestella", { length = 1000 })
C.ensure("gleba", "fulgora", { length = 30000 })
