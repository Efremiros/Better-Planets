-- control.lua
-- ✅ Храним и отдаём только tiers. Никаких углов/расстояний здесь больше нет.
global = global or {}

local defaults = {
  vanilla = {
    planet = { nauvis=1, vulcanus=1.8, fulgora=2.4, gleba=3.5, aquilo=5 },
    ["space-location"] = { ["shattered-planet"]=5, ["solar-system-edge"]=5 }
  },
  modded = {
    planet = {
      akularis=0.5, gerkizia=0.5, quadromire=0.5, foliax=0.5, mickora=1,
      ["erimos-prime"]=1.22, vicrox=1.4, pelagos=1.5, froodara=1.8, tchekor=2,
      jahtra=2.2, nekohaven=2.5, zzhora=2.5, igrys=2.6, arig=2.8, janus=3, shchierbin=3,
      ithurice=3.3, corrundum=3.3, moshine=3.6, castra=4, tapatrion=4, tenebris=4,
      cubium=4.1, rubia=4.5, paracelsin=4.8, hexalith=5.1, vesta=5.2, maraxsis=5.3,
      frozeta=5.5, panglia=5.7, omnia=6, naufulglebunusilo=6, arrakis=6, tiber=6.5
    },
    ["space-location"] = {
      ["slp-solar-system-sun"]=0.2,
      ["slp-solar-system-sun2"]=0.2,
      ["calidus-senestella-gate-calidus"]=4.0,
      secretas=5.6
    }
  }
}

local function sanitize(id)
  id = string.lower(id)
  id = id:gsub("[^%w%-_]", "-")
  return id
end

local function deepcopy(orig, seen)
  if type(orig) ~= "table" then return orig end
  if seen and seen[orig] then return seen[orig] end
  local s = seen or {}
  local copy = {}
  s[orig] = copy
  for k, v in pairs(orig) do copy[deepcopy(k, s)] = deepcopy(v, s) end
  return setmetatable(copy, getmetatable(orig))
end

local function collect_tiers(prefix, map)
  local out = {}
  for name, def in pairs(map) do
    local sid = sanitize(name)
    local st = settings.startup[prefix .. "tier-" .. sid]
    out[name] = st and tonumber(st.value) or def
  end
  return out
end

local function build_state()
  global.tiers = {
    vanilla = { planet = {}, ["space-location"] = {} },
    modded  = { planet = {}, ["space-location"] = {} }
  }
  global.tiers.vanilla.planet = collect_tiers("pto-planet-", defaults.vanilla.planet)
  global.tiers.vanilla["space-location"] = collect_tiers("pto-location-", defaults.vanilla["space-location"])
  global.tiers.modded.planet = collect_tiers("pto-planet-", defaults.modded.planet)
  global.tiers.modded["space-location"] = collect_tiers("pto-location-", defaults.modded["space-location"])
end

-- Отдаём только tiers для совместимости
remote.add_interface("planets_overrides", {
  get_vanilla_tiers = function() return deepcopy(global.tiers.vanilla) end,
  get_modded_tiers  = function() return deepcopy(global.tiers.modded)  end,
  get_all           = function() return deepcopy(global.tiers)         end
})

local function maybe_push_to_thirdparty()
  local function safe_push(intf, fn)
    if remote.interfaces[intf] and remote.interfaces[intf][fn] then
      pcall(remote.call, intf, fn, global.tiers.vanilla, global.tiers.modded)
      return true
    end
    return false
  end
  return
    safe_push("planetslib_tiers", "set_tiers") or
    safe_push("PlanetsLib_Tiers", "set_tiers") or
    safe_push("PlanetsLib-Tiers", "set_tiers")
end

script.on_init(function()
  build_state()
  maybe_push_to_thirdparty()
end)

script.on_configuration_changed(function()
  build_state()
  maybe_push_to_thirdparty()
end)
