-- settings.lua
-- Блок на каждое тело: галочка (имя+иконка), под ней ↳ радиус, ↳ угол.
-- Показываем только тела из реально установленных модов (ваниль — всегда).

local function src(ids, title) return { id = ids, title = title } end
local function mod_installed_any(id)
  if not id then return true end
  if type(id)=="string" then return mods[id]~=nil end
  for _,m in ipairs(id) do if m and mods[m] then return true end end
  return false
end
local function should_expose(e) return mod_installed_any(e.src and e.src.id) end
local function display_name(e) return {"?", {"planet-name."..e.name}, {"space-location-name."..e.name}, e.name} end
local function add(def) data:extend({def}) end

-- ===== Список тел (имена прототипов) =====
local BODIES = {
  -- VANILLA planets
  {kind="planet", name="nauvis",   src=src(nil,"Vanilla / Space Age")},
  {kind="planet", name="vulcanus", src=src(nil,"Vanilla / Space Age")},
  {kind="planet", name="fulgora",  src=src(nil,"Vanilla / Space Age")},
  {kind="planet", name="gleba",    src=src(nil,"Vanilla / Space Age")},
  {kind="planet", name="aquilo",   src=src(nil,"Vanilla / Space Age")},

  -- moons (моды планет часто объявляют их как planet — так и оставляем)
  {kind="planet", name="muluna",   src=src({"planet-muluna"},"Muluna (moon)")},
  {kind="planet", name="lignumis", src=src({"planet-lignumis"},"Lignumis (moon)")},
  {kind="planet", name="ceris",    src=src({"planet-ceris"},"Ceris (moon)")},

  -- Metal and Stars (systems)
  {kind="space-location", name="neumann-v", src=src("metal-and-stars","Metal and Stars / Neumann V")},
  {kind="space-location", name="nix",       src=src("metal-and-stars","Metal and Stars / Nix")},
  {kind="space-location", name="circa",     src=src("metal-and-stars","Metal and Stars / Circa")},
  {kind="space-location", name="mirandus",  src=src("metal-and-stars","Metal and Stars / Mirandus")},

  -- Dyson Sphere
  {kind="space-location", name="sun-orbit",       src=src("dyson-sphere","Dyson Sphere / Sun Orbit")},
  {kind="space-location", name="sun-orbit-close", src=src("dyson-sphere","Dyson Sphere / Close Sun Orbit")},

  -- Shattered planet & co
  {kind="space-location", name="shattered-planet",           src=src({"skewer_shattered_planet"},"Shattered Planet")},
  {kind="space-location", name="shattered-planet-approach",  src=src({"skewer_shattered_planet"},"Approach to Shattered Planet")},
  {kind="space-location", name="lost-beyond",                src=src({"skewer_shattered_planet"},"Lost Beyond")},
  {kind="space-location", name="solar-system-edge",          src=src({"skewer_shattered_planet"},"Solar System Edge")},

  -- Dea Dia system
  {kind="space-location", name="dea-dia",  src=src("dea-dia-system","Dea Dia System")},
  {kind="planet",         name="prosephina", src=src("dea-dia-system","Dea Dia / Prosephina")},
  {kind="planet",         name="lemures",    src=src("dea-dia-system","Dea Dia / Lemures")},

  -- Nexuz / compat pack
  {kind="planet", name="tenebris",          src=src({"Starmap_Nexuz","tenebris"},"Tenebris")},
  {kind="planet", name="maraxsis",          src=src({"Starmap_Nexuz","maraxsis"},"Maraxsis")},
  {kind="planet", name="arrakis",           src=src({"Starmap_Nexuz","planet-arrakis"},"Arrakis")},
  {kind="planet", name="tiber",             src=src({"Starmap_Nexuz","Factorio-Tiberium"},"Tiber")},
  {kind="planet", name="janus",             src=src("janus","Janus")},
  {kind="planet", name="corrundum",         src=src("corrundum","Corrundum")},
  {kind="planet", name="naufulglebunusilo", src=src("naufulglebunusilo","Naufulglebunusilo")},
  {kind="planet", name="aiur",              src=src("erm_toss","Aiur (ERM)")},
  {kind="planet", name="char",              src=src("erm_zerg","Char (ERM)")},

  -- singles (твоё доп. семейство)
  {kind="planet", name="moshine",    src=src({"planet-moshine"},"Moshine")},
  {kind="planet", name="paracelsin", src=src({"planet-paracelsin","paracelsin"},"Paracelsin")},
  {kind="planet", name="vesta",      src=src({"skewer_planet_vesta","planet-vesta"},"Vesta")},
  {kind="planet", name="secretas",   src=src({"secretas","planet-secretas"},"Secretas")},
  {kind="planet", name="frozeta",    src=src({"planet-frozeta","frozeta"},"Frozeta")},
  {kind="planet", name="froodara",   src=src({"planet-froodara"},"Froodara")},
  {kind="planet", name="gerkizia",   src=src({"planet-gerkizia"},"Gerkizia")},
  {kind="planet", name="hexalith",   src=src({"planet-hexalith"},"Hexalith")},
  {kind="planet", name="ithurice",   src=src({"planet-ithurice"},"Ithurice")},
  {kind="planet", name="mickora",    src=src({"planet-mickora"},"Mickora")},
  {kind="planet", name="nekohaven",  src=src({"planet-nekohaven"},"Nekohaven")},
  {kind="planet", name="quadromire", src=src({"planet-quadromire"},"Quadromire")},
}

-- Подсказки (с подсветкой)
local angle_desc  = {"", {"tr.ui.angle_l1"},  "\n", {"tr.ui.angle_l2"}, "\n", {"tr.ui.angle_l3"}, "\n", {"tr.ui.angle_l4"}}
local radius_desc = {"", {"tr.ui.radius_l1"}, "\n", {"tr.ui.radius_l2"}, "\n", {"tr.ui.radius_l3"}, "\n", {"tr.ui.radius_l4"}, "\n", {"tr.ui.radius_l5"}}

local function mk(idx, e)
  if not should_expose(e) then return end
  local disp   = display_name(e)
  local sprite = "tr-picon-"..e.name
  local src_ln = (e.src and e.src.title) and {"", "\n", {"tr.ui.source", e.src.title}} or ""
  local base   = string.format("g%04d", idx) -- шапка -> радиус -> угол

  add{
    type="bool-setting", setting_type="startup",
    name=("tr-enable-%s-%s"):format(e.kind, e.name),
    default_value=false,
    order=base.."-00",
    localised_name={"tr.ui.header_with_icon", disp, sprite},
    localised_description={"tr.ui.header_hint"}
  }
  add{
    type="string-setting", setting_type="startup",
    name=("tr-radius-%s-%s"):format(e.kind, e.name),
    default_value="", allow_blank=true,
    order=base.."-10",
    localised_name={"", "  ↳ ", {"tr.ui.radius_label"}},
    localised_description={"", radius_desc, "\n", {"tr.ui.applies_to", disp}, src_ln}
  }
  add{
    type="string-setting", setting_type="startup",
    name=("tr-angle-%s-%s"):format(e.kind, e.name),
    default_value="", allow_blank=true,
    order=base.."-20",
    localised_name={"", "  ↳ ", {"tr.ui.angle_label"}},
    localised_description={"", angle_desc, "\n", {"tr.ui.applies_to", disp}, src_ln}
  }
end

for i,e in ipairs(BODIES) do mk(i,e) end
