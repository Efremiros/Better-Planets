-- Округляет длины космических путей до ближайших 5000 км
-- Условия:
--  • Не трогаем пути, где участвует ЛЮБОЙ из перечисленных спутников.
--  • Не трогаем длины < 5000 (считаем за предопределённые/особые).
--  • Меняем только те пути, где хотя бы один конец — из ORDER.

-- === Конфиг: список спутников (исключения) ===
local MOON_SKIP = {
  tchekor=true,
  froodara=true, zzhora=true,
  gerkizia=true, quadromire=true,
  tapatrion=true, ithurice=true,
  nekohaven=true, hexalith=true, mickora=true, corruption=true,
}

-- === Конфиг: периметр работ (ORDER) ===
local ORDER = {
  "nauvis",
  "vulcanus",
  "fulgora",
  "gleba",
  "igrys","shchierbin",
  "moshine",
  "arig","hyarion",
  "rubia",
  "castra",
  "omnia","pelagos","panglia",
  "asteroid-belt-inner-edge","asteroid-belt-outer-edge",
  "aquilo","cubium","paracelsin",
  "secretas",
  "vesta",
  "slp-solar-system-sun","slp-solar-system-sun2","solar-system-edge",

  "sye-nauvis-ne","sye-nexuz-sw",
  "arrakis","aiur","char","earth","corrundum","maraxsis","tiber","tenebris",

  "calidus-senestella-gate-calidus","calidus-senestella-gate-senestella",
  "shipyard","mirandus-a","nix","ringworld"
}
local ORDER_SET = {}
for _, n in ipairs(ORDER) do ORDER_SET[n] = true end

-- Быстрая проверка: является ли локация спутником по признаку subgroup
local function is_satellite(name)
  local p = (data.raw.planet and data.raw.planet[name]) or (data.raw["space-location"] and data.raw["space-location"][name])
  return p and p.subgroup == "satellites"
end

-- Проверка: пропускаем связь, если в ней участвует спутник (или он в MOON_SKIP)
local function connection_involves_moon(a, b)
  if MOON_SKIP[a] or MOON_SKIP[b] then return true end
  if is_satellite(a) or is_satellite(b) then return true end
  return false
end

-- Критерий применения округления
local function should_round(conn)
  if type(conn) ~= "table" then return false end
  local a, b = conn.from, conn.to
  if type(a) ~= "string" or type(b) ~= "string" then return false end
  if connection_involves_moon(a, b) then return false end
  if not (ORDER_SET[a] or ORDER_SET[b]) then return false end
  local L = tonumber(conn.length)
  if not L or L < 5000 then return false end
  return true
end

-- Округление к ближайшим 5000 км
local function round_to_5000(n)
  -- пример: 21000 -> 20000; 17000 -> 15000; 18000 -> 20000; 33000 -> 35000
  local step = 5000
  return math.floor((n + step/2) / step) * step
end

-- Применить ко всем space-connection
do
  local sc = data.raw["space-connection"]
  if sc then
    local changed = 0
    for name, conn in pairs(sc) do
      if should_round(conn) then
        local old = tonumber(conn.length)
        local newv = round_to_5000(old)
        if newv ~= old then
          conn.length = newv
          changed = changed + 1
          -- Немного логов для отладки, можно закомментировать:
          log(("[Better-Planets] round-conn: %s (%s ↔ %s): %d → %d km")
              :format(name, tostring(conn.from), tostring(conn.to), old, newv))
        end
      end
    end
    if changed > 0 then
      log(("[Better-Planets] round-conn: updated %d connection(s) to neat 5k steps"):format(changed))
    end
  end
end
