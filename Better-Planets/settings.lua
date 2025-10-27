local DEFAULT_R = {
  aiur=204.3, aquilo=35.0, arig=11.9, arrakis=187.6,
  ["calidus-senestella-gate-calidus"]=20.0,
  ["calidus-senestella-gate-senestella"]=111.7,
  castra=21.0, cerys=26.4, char=205.7, corrundum=186.6,
  corruption=20.0, cube1=1000.0, cube2=1035.0, cubium=15.0,
  ["dea-dia-system-edge"]=68.6, earth=15.0, froodara=12.7, frozeta=44.2,
  fulgora=25.1, gerkizia=17.4, gleba=20.0, hexalith=17.1, hyarion=22.5,
  igrys=14.2, ithurice=32.0, lemures=61.9, lignumis=14.4,
  ["maraxsis-trench"]=15.6, maraxsis=184.7, mickora=20.0, ["mirandus-a"]=130.6,
  moshine=6.0, muluna=16.3, nauvis=15.0, nekohaven=21.9, nix=114.5,
  omnia=12.0, panglia=22.0, paracelsin=42.0, pelagos=20.0,
  ["planet-dea-dia"]=62.2, prosephina=68.2, quadromire=21.4, ringworld=139.0,
  rubia=15.0, secretas=45.0, ["shattered-planet"]=80.0, shchierbin=21.0,
  shipyard=119.7, skewer_lost_beyond=92.3, skewer_shattered_planet=82.3,
  ["slp-solar-system-sun2"]=4.0, ["slp-solar-system-sun"]=8.0,
  ["solar-system-edge"]=50.0, ["sye-nexuz-sw"]=150.0, tapatrion=32.0,
  tchekor=14.3, tenebris=220.1, terrapalus=18.8, tiber=226.1,
  vesta=30.0, vulcanus=8.3, zzhora=16.6,
  ["sye-nauvis-ne"]=0.0, ["nexuz-background"]=0.0, ["star-dea-dia"]=0.0, redstar=0.0
}

local DEFAULT_ANGLE = {
  nauvis=54,  vulcanus=97.2, fulgora=129.6, gleba=189, aquilo=270,
  gerkizia=27, quadromire=27, mickora=54, pelagos=81, froodara=97.2,
  tchekor=108, nekohaven=135, zzhora=135, igrys=140.4, arig=151.2,
  shchierbin=162, ithurice=178.2, moshine=194.4, castra=216, tapatrion=216,
  cubium=221.4, rubia=243, paracelsin=259.2, hexalith=275.4, vesta=280.8,
  frozeta=297, panglia=307.8, omnia=324, secretas=302.4,
  ["shattered-planet"]=270, ["solar-system-edge"]=270,
  ["slp-solar-system-sun"]=10.8, ["slp-solar-system-sun2"]=10.8,
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
