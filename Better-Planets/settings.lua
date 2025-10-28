local DEFAULT_R = {
  aiur=204.3, aquilo=35, arig=15, arrakis=187.6,
  ["calidus-senestella-gate-calidus"]=70,
  ["calidus-senestella-gate-senestella"]=111.7,
  castra=28, cerys=1.5, char=205.7, corrundum=186.6,
  corruption=20.0, cubium=15.0,
  ["dea-dia-system-edge"]=20, earth=15.0, froodara=2, frozeta=44.2,
  fulgora=28, gerkizia=3, gleba=20, hexalith=17.1, hyarion=30,
  igrys=20, ithurice=53, lemures=5, lignumis=2,
  ["maraxsis-trench"]=15.6, maraxsis=184.7, mickora=20.0, ["mirandus-a"]=130.6,
  moshine=10, muluna=1.5, nauvis=15, nekohaven=5, nix=114.5,
  omnia=12.0, panglia=22.0, paracelsin=42.0, pelagos=20.0,
  ["planet-dea-dia"]=62.2, prosephina=6, quadromire=3, ringworld=9,
  rubia=30, secretas=45, ["shattered-planet"]=500, shchierbin=18,
  shipyard=119.7, skewer_lost_beyond=560, skewer_shattered_planet=10,
  ["slp-solar-system-sun2"]=3, ["slp-solar-system-sun"]=5,
  ["solar-system-edge"]=70, ["sye-nexuz-sw"]=150.0, tapatrion=55,
  tchekor=2, tenebris=220.1, terrapalus=1.5, tiber=226.1,
  vesta=50, vulcanus=8, zzhora=3,
  ["sye-nauvis-ne"]=0.0, ["nexuz-background"]=0.0, ["star-dea-dia"]=150, redstar=200
}

local DEFAULT_ANGLE = {
  aiur=204.3, aquilo=270, arig=200, arrakis=187.6,
  ["calidus-senestella-gate-calidus"]=170,
  ["calidus-senestella-gate-senestella"]=111.7,
  castra=230, cerys=160, char=205.7, corrundum=186.6,
  corruption=20.0, cubium=220,
  ["dea-dia-system-edge"]=220, earth=15.0, froodara=140, frozeta=44.2,
  fulgora=110, gerkizia=200, gleba=75, hexalith=17.1, hyarion=180,
  igrys=130, ithurice=130, lemures=120, lignumis=300,
  ["maraxsis-trench"]=15.6, maraxsis=184.7, mickora=20.0, ["mirandus-a"]=130.6,
  moshine=190, muluna=60, nauvis=35, nekohaven=20, nix=114.5,
  omnia=12.0, panglia=22.0, paracelsin=42.0, pelagos=20.0,
  ["planet-dea-dia"]=62.2, prosephina=220, quadromire=30, ringworld=35,
  rubia=140, secretas=300, ["shattered-planet"]=270, shchierbin=155,
  shipyard=119.7, skewer_lost_beyond=275, skewer_shattered_planet=290,
  ["slp-solar-system-sun2"]=0, ["slp-solar-system-sun"]=0,
  ["solar-system-edge"]=270, ["sye-nexuz-sw"]=150.0, tapatrion=75,
  tchekor=30, tenebris=220.1, terrapalus=310, tiber=226.1,
  vesta=160, vulcanus=95, zzhora=50,
  ["sye-nauvis-ne"]=0.0, ["nexuz-background"]=0.0, ["star-dea-dia"]=75, redstar=230
}

local ORDER = {
  "nauvis","muluna","lignumis",
  "vulcanus","froodara","zzhora",
  "fulgora","cerys","tchekor",
  "gleba","terrapalus","gerkizia","quadromire",
  "moshine",
  "igrys","hyarion",
  "rubia",
  "arig","castra","shchierbin",
  "vesta","hexalith","nekohaven",
  "mickora",
  "panglia","omnia","paracelsin","pelagos",
  "cubium","aquilo","tapatrion","ithurice",
  "secretas","frozeta",
  "corruption",
  "slp-solar-system-sun","slp-solar-system-sun2","solar-system-edge",
  "shattered-planet","skewer_shattered_planet","skewer_lost_beyond",
  "sye-nauvis-ne","sye-nexuz-sw","nexuz-background",
  "arrakis","aiur","char","earth","corrundum","maraxsis","maraxsis-trench","tiber","tenebris",
  "star-dea-dia","dea-dia-system-edge","planet-dea-dia","prosephina","lemures",
  "calidus-senestella-gate-calidus","calidus-senestella-gate-senestella",
  "redstar","shipyard","mirandus-a","nix","ringworld"
}

-- добавить «хвост» из DEFAULT_R, если что-то не попало в ORDER
do
  local seen = {}; for _,n in ipairs(ORDER) do seen[n]=true end
  for n,_ in pairs(DEFAULT_R) do if not seen[n] then table.insert(ORDER, n) end end
end

local STAR_OVERRIDES = {
  ["star-dea-dia"]     = { icon_from = "dea-dia-system-edge" },
  ["nexuz-background"] = { icon_from = "sye-nexuz-sw" },
  ["redstar"]          = { icon_from = "calidus-senestella-gate-senestella" }
}

local function display_label(name)
  local ov = STAR_OVERRIDES[name]
  local iconName = (ov and ov.icon_from) or name
  return {"", {"bp.names."..name}, " [img=tr-picon-"..iconName.."]"}
end

local function add_entry(name, idx)
  local ord_prefix = string.format("%03d-%s-", idx, name)
  data:extend{
    {
      type = "bool-setting",
      name = "tr-enable-"..name,
      setting_type = "startup",
      default_value = false,
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
    }
  }
end

for i, name in ipairs(ORDER) do add_entry(name, i) end
