-- settings.lua
-- Для каждого тела создаём: галочку (включить), затем ↳ радиус, ↳ угол (в градусах, 0..360 CCW от севера).
-- Пустое поле оставляет значение как есть.

local function add(def) data:extend({def}) end

-- ===== ДЕФОЛТЫ =====
-- Радиусы (твои значения)
local DEFAULT_RADIUS = {
  aiur=204.3,
  aquilo=35.0,
  arig=11.9,
  arrakis=187.6,
  ["calidus-senestella-gate-calidus"]=20.0,
  ["calidus-senestella-gate-senestella"]=111.7,
  castra=21.0,
  cerys=26.4,
  char=205.7,
  corrundum=186.6,
  corruption=20.0,
  cubium=15.0,
  ["dea-dia-system-edge"]=68.6,
  earth=15.0,
  froodara=12.7,
  frozeta=44.2,
  fulgora=25.1,
  gerkizia=17.4,
  gleba=20.0,
  hexalith=17.1,
  hyarion=22.5,
  igrys=14.2,
  ithurice=32.0,
  lemures=61.9,
  lignumis=14.4,
  ["maraxsis-trench"]=15.6,
  maraxsis=184.7,
  mickora=20.0,
  ["mirandus-a"]=130.6,
  moshine=6.0,
  muluna=16.3,
  nauvis=15.0,
  nekohaven=21.9,
  nix=114.5,
  omnia=12.0,
  panglia=22.0,
  paracelsin=42.0,
  pelagos=20.0,
  ["planet-dea-dia"]=62.2,
  prosephina=68.2,
  quadromire=21.4,
  ringworld=139.0,
  rubia=15.0,
  secretas=45.0,
  ["shattered-planet"]=80.0,
  shchierbin=21.0,
  shipyard=119.7,
  skewer_lost_beyond=92.3,
  skewer_shattered_planet=82.3,
  ["slp-solar-system-sun2"]=4.0,
  ["slp-solar-system-sun"]=8.0,
  ["solar-system-edge"]=50.0,
  ["sye-nexuz-sw"]=150.0,
  tapatrion=32.0,
  tchekor=14.3,
  tenebris=220.1,
  terrapalus=18.8,
  tiber=226.1,
  vesta=30.0,
  vulcanus=8.3,
  zzhora=16.6
}

-- Углы: tiers -> градусы (1 tier = 54.000054°, т.к. fallback_tier=3.33333 -> 180°)
local DEFAULT_ANGLE_DEG = {
  nauvis = 54,
  vulcanus = 97.2,
  fulgora = 129.6,
  gleba = 189,
  aquilo = 270,
  gerkizia = 27,
  quadromire = 27,
  mickora = 54,
  pelagos = 81,
  froodara = 97.2,
  tchekor = 108,
  nekohaven = 135,
  zzhora = 135,
  igrys = 140.4,
  arig = 151.2,
  shchierbin = 162,
  ithurice = 178.2,
  moshine = 194.4,
  castra = 216,
  tapatrion = 216,
  cubium = 221.4,
  rubia = 243,
  paracelsin = 259.2,
  hexalith = 275.4,
  vesta = 280.8,
  frozeta = 297,
  panglia = 307.8,
  omnia = 324,
  secretas = 302.4,

  ["shattered-planet"] = 270,
  ["solar-system-edge"] = 270,
  ["slp-solar-system-sun"] = 10.8,
  ["slp-solar-system-sun2"] = 10.8,
}

-- Собираем имена как объединение ключей обеих карт
local NAMES = {}
for k,_ in pairs(DEFAULT_RADIUS) do NAMES[k]=true end
for k,_ in pairs(DEFAULT_ANGLE_DEG) do NAMES[k]=true end

local angle_desc = {"",
  {"", "Абсолютный градус 0..360 от севера (12:00), против часовой стрелки."}, "\n",
  {"", "Поддерживаются относительные значения: +Δ, -Δ, *k, пусто — не менять."}
}
local radius_desc = {"",
  {"", "Абсолютный радиус x, в расстояние x * 1000 км."}, "\n",
  {"", "Поддерживаются относительные значения: +Δ, -Δ, *k, пусто — не менять."}
}

local function mk(idx, name)
  local base = string.format("g%04d", idx) -- порядок
  local disp = {"?", {"planet-name."..name}, {"space-location-name."..name}, name}
  local sprite = "tr-picon-"..name

  add{
    type="bool-setting", setting_type="startup",
    name=("tr-enable-planet-%s"):format(name),
    default_value=true,
    order=base.."-00",
    localised_name={"tr.ui.header_with_icon", disp, sprite},
    localised_description={"", "Включить переопределение для этого тела."}
  }
  add{
    type="string-setting", setting_type="startup",
    name=("tr-radius-planet-%s"):format(name),
    default_value=(DEFAULT_RADIUS[name] and tostring(DEFAULT_RADIUS[name]) or ""),
    allow_blank=true,
    order=base.."-10",
    localised_name={"", "  ↳ ", "Радиус"},
    localised_description=radius_desc
  }
  add{
    type="string-setting", setting_type="startup",
    name=("tr-angle-planet-%s"):format(name),
    default_value=(DEFAULT_ANGLE_DEG[name] and tostring(DEFAULT_ANGLE_DEG[name]) or ""),
    allow_blank=true,
    order=base.."-20",
    localised_name={"", "  ↳ ", "Угол (°)"},
    localised_description=angle_desc
  }
end

local i = 0
for name,_ in pairs(NAMES) do i=i+1; mk(i, name) end
