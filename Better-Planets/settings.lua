local ORDER = {
  "nauvis","muluna","lignumis",
  "vulcanus","froodara","zzhora",
  "fulgora","cerys","tchekor",
  "gleba","terrapalus","quadromire","gerkizia",
  "igrys","shchierbin",
  "moshine",
  "arig","hyarion",
  "rubia",
  "castra",
  "omnia","pelagos","panglia",
  "aquilo","cubium","paracelsin",
  "secretas","frozeta","tapatrion","ithurice",
  "vesta","hexalith","nekohaven","mickora","corruption",
  "slp-solar-system-sun","slp-solar-system-sun2","solar-system-edge",
  "shattered-planet","skewer_shattered_planet","skewer_lost_beyond",
  "sye-nauvis-ne","sye-nexuz-sw","nexuz-background",
  "arrakis","aiur","char","earth","corrundum","maraxsis","maraxsis-trench","tiber","tenebris",
  "star-dea-dia","dea-dia-system-edge","planet-dea-dia","prosephina","lemures",
  "calidus-senestella-gate-calidus","calidus-senestella-gate-senestella",
  "redstar","shipyard","mirandus-a","nix","ringworld"
}

local DEFAULT_R = {
  aiur=39, aquilo=0, arig=15, arrakis=18,
  ["calidus-senestella-gate-calidus"]=70, ["calidus-senestella-gate-senestella"]=0,
  castra=22.5, cerys=1.5, char=14, corrundum=35,
  corruption=9, cubium=0,
      ["dea-dia-system-edge"]=20, earth=29, froodara=2, frozeta=5,
  fulgora=28, gerkizia=3.5, gleba=20, hexalith=7, hyarion=31,
  igrys=18, ithurice=6, lemures=7, lignumis=2,
  ["maraxsis-trench"]=0, maraxsis=25, mickora=8, ["mirandus-a"]=0,
  moshine=9, muluna=1.5, nauvis=15, nekohaven=6, nix=0,
  omnia=16.5, panglia=25.3, paracelsin=50, pelagos=13.5,
  ["planet-dea-dia"]=20, prosephina=10, quadromire=2.5, ringworld=9,
  rubia=29.5, secretas=53, ["shattered-planet"]=500, shchierbin=18,
  shipyard=0, skewer_lost_beyond=560, skewer_shattered_planet=15,
  ["slp-solar-system-sun2"]=4, ["slp-solar-system-sun"]=6,
  ["solar-system-edge"]=70, ["sye-nexuz-sw"]=0, tapatrion=4,
  tchekor=3, tenebris=50, terrapalus=1.5, tiber=0,
  vesta=47.5, vulcanus=8, zzhora=3,
  ["sye-nauvis-ne"]=70, ["nexuz-background"]=0.0, ["star-dea-dia"]=200, redstar=300
}

local DEFAULT_ANGLE = {
  aiur=240, aquilo=0, arig=170, arrakis=140,
  ["calidus-senestella-gate-calidus"]=100, ["calidus-senestella-gate-senestella"]=0,
  castra=220, cerys=160, char=10, corrundum=200,
  corruption=220, cubium=0,
  ["dea-dia-system-edge"]=220, earth=35, froodara=155, frozeta=220,
  fulgora=110, gerkizia=30, gleba=75, hexalith=20, hyarion=180,
  igrys=100, ithurice=20, lemures=70, lignumis=300,
  ["maraxsis-trench"]=0, maraxsis=95, mickora=140, ["mirandus-a"]=0,
  moshine=200, muluna=60, nauvis=40, nekohaven=275, nix=0,
  omnia=297, panglia=292, paracelsin=240, pelagos=260,
  ["planet-dea-dia"]=270, prosephina=190, quadromire=100, ringworld=35,
  rubia=140, secretas=300, ["shattered-planet"]=270, shchierbin=130,
  shipyard=0, skewer_lost_beyond=275, skewer_shattered_planet=290,
  ["slp-solar-system-sun2"]=0, ["slp-solar-system-sun"]=0,
  ["solar-system-edge"]=270, ["sye-nexuz-sw"]=0, tapatrion=265,
  tchekor=50, tenebris=336, terrapalus=150, tiber=0,
  vesta=168, vulcanus=90, zzhora=5,
  ["sye-nauvis-ne"]=310, ["nexuz-background"]=0.0, ["star-dea-dia"]=65, redstar=230
}

local STAR_OVERRIDES = {
  ["star-dea-dia"]     = { icon_from = "dea-dia-system-edge" },
  ["nexuz-background"] = { icon_from = "sye-nexuz-sw" },
  ["redstar"]          = { icon_from = "calidus-senestella-gate-senestella" }
}

-- Включено по умолчанию, если НЕ (r==0 и angle==0)
local DEFAULT_ENABLE = {}
for name, _ in pairs(DEFAULT_R) do
  local r = DEFAULT_R[name] or 0
  local a = DEFAULT_ANGLE[name] or 0
  DEFAULT_ENABLE[name] = not (r == 0 or r == 0.0) or not (a == 0 or a == 0.0)
end

local DEFAULT_SCALE = {
  tchekor="0.6",
  froodara="0.6", zzhora="0.7",
  gerkizia="0.8", quadromire="0.6",
  ithurice="0.9", tapatrion="0.7",
  nekohaven="0.8", hexalith="0.6",
  mickora="0.8", corruption="1.2",

  panglia="2.5",
  pelagos="1.2",

  maraxsis="1.8",
  char="1.5",
  arrakis="1.5",

  ["slp-solar-system-sun"]="0.8",
  ["slp-solar-system-sun2"]="0.8",
}

-- список наших лун и их дефолтных длин маршрутов
local MOON_LIST = {
  "tchekor","froodara","zzhora","gerkizia","quadromire","nekohaven","hexalith","ithurice","tapatrion","mickora","corruption"
}
local MOON_DEFAULT_LEN = {
  tchekor    = 4400,

  froodara   = 3000,
  zzhora     = 3500,

  gerkizia   = 5000,
  quadromire = 3800,

  tapatrion = 9000,
  ithurice = 12000,

  nekohaven  = 8000,
  hexalith   = 10000,
  mickora   = 12000,
  corruption   = 20000,
}

local function display_label(name)
  local ov = STAR_OVERRIDES[name]
  local iconName = (ov and ov.icon_from) or name
  return {"", {"bp.names."..name}, " [img=tr-picon-"..iconName.."]"}
end

-- упорядоченный вывод
local function add_entry(name, idx)
  local ord_prefix = string.format("%03d-", idx)

  -- заголовок-свитч: включить перерасчёт для этой локации
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
      allow_blank = true, -- пусто = не менять
      localised_name = {"bp.setting-scale-child"},
      localised_description = {"bp.desc-scale"},
      order = ord_prefix.."d"
    }
  })

  -- длина маршрута — только для наших спутников
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

for i, name in ipairs(ORDER) do add_entry(name, i) end
