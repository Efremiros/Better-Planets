-- Shared configuration for Better Planets mod
-- This file contains the complete default configuration for all planets and locations

-- Complete default configuration: mod provider, order, radius, angle, scale, moon properties
-- mod can be: true (ALWAYS present), string (single mod), table (multiple mods), or nil (use heuristic)
-- scale: optional icon scaling (string or nil)
-- is_moon: true if this is a moon (has special connection handling)
-- moon_length: connection length in km (only for moons)
local DEFAULTS = {
  {name="nauvis", mod=true, radius=18, angle=20},
  {name="lignumis", mod="lignumis", radius=2, angle=300},
  {name="muluna", mod="planet-muluna", radius=1.5, angle=60},

  {name="Gaia", mod={"exotic-space-industries","exotic-space-industries-remembrance"}, radius=22.5, angle=55},

  {name="vulcanus", mod=true, radius=8, angle=50},
  {name="froodara", mod="planet-froodara", radius=2.5, angle=330, scale="0.6", is_moon=true, moon_length=3500},
  {name="zzhora", mod="planet-zzhora", radius=2, angle=180, scale="0.7", is_moon=true, moon_length=3000},

  {name="gleba", mod=true, radius=16, angle=60},
  {name="rabbasca", mod="planet-rabbasca", radius=1.5, angle=15, scale="0.7"},
  {name="terrapalus", mod="terrapalus", radius=2, angle=140},
  {name="gerkizia", mod="planet-gerkizia", radius=2.5, angle=50, scale="0.8", is_moon=true, moon_length=5000},

  {name="pelagos", mod="pelagos", radius=14, angle=90, scale="1.3"},

  {name="fulgora", mod=true, radius=24, angle=130},
  {name="cerys", mod="Cerys-Moon-of-Fulgora", radius=1.5, angle=160},
  {name="tchekor", mod="planet-tchekor", radius=3, angle=80, scale="0.6", is_moon=true, moon_length=4400},

  {name="moshine", mod="Moshine", radius=10, angle=200},
  {name="linox-planet_linox", mod="linox", radius=7, angle=280},

  {name="arig", mod={"planetaris-arig","planetaris-unbounded"}, radius=12, angle=150},
  {name="hyarion", mod={"planetaris-hyarion","planetaris-unbounded"}, radius=26, angle=180},

  {name="rubia", mod="rubia", radius=30, angle=295},
  {name="castra", mod="castra", radius=20, angle=245},

  {name="panglia", mod="panglia_planet", radius=46, angle=330, scale="2.5"},

  {name="omnia", mod="omnia", radius=39, angle=10},
  {name="igrys", mod="Igrys", radius=41, angle=80},
  {name="shchierbin", mod="shchierbin", radius=44, angle=100},

  {name="vicrox", mod="planet-vicrox-reworked", radius=29, angle=320},
  {name="akularis", mod="planet-akularis-reworked", radius=26, angle=340},

  {name="akularis", mod="planet-akularis-reworked", radius=26, angle=340},

  --Additional support (in the first asteroid layer):
  {name="arboria", mod="arboria", radius=0, angle=0},
  {name="alchemy-planet", mod="alchemy-khemia", radius=0, angle=0},
  {name="arcanyx", mod="Arcanyx", radius=0, angle=0},
  {name="nexus", mod="Nexus", radius=0, angle=0},
  {name="oort-cloud", mod="Nexus", radius=0, angle=0},
  {name="sol", mod="Nexus", radius=0, angle=0},
  {name="crymora", mod="lunar_legacy", radius=0, angle=0},
  {name="solune", mod="lunar_legacy", radius=0, angle=0},
  {name="lunaris", mod="lunar_legacy", radius=0, angle=0},
  {name="OMNI", mod="omni", radius=0, angle=0},

  --{name="asteroid-belt-inner-edge", mod="AsteroidBelts"},
  --{name="asteroid-belt-outer-edge", mod="AsteroidBelts"},

  {name="aquilo", mod=true, radius=44, angle=280},
  {name="cubium", mod="cubium", radius=42, angle=230},
  {name="paracelsin", mod="Paracelsin", radius=50, angle=195},

  {name="secretas", mod="secretas", radius=53, angle=320},
  {name="frozeta", mod="secretas", radius=5, angle=250},
  {name="tapatrion", mod="planet-tapatrion", radius=4, angle=160, scale="0.7", is_moon=true, moon_length=9000},
  {name="ithurice", mod="planet-ithurice", radius=6, angle=330, scale="0.9", is_moon=true, moon_length=12000},

  {name="vesta", mod="skewer_planet_vesta", radius=48, angle=160},
  {name="quadromire", mod="planet-quadromire", radius=5, angle=70, scale="0.6", is_moon=true, moon_length=6000},
  {name="hexalith", mod="planet-hexalith", radius=7, angle=350, scale="0.6", is_moon=true, moon_length=10000},
  {name="nekohaven", mod="planet-nekohaven", radius=6, angle=275, scale="0.8", is_moon=true, moon_length=8000},
  {name="mickora", mod="planet-mickora", radius=8, angle=140, scale="0.8", is_moon=true, moon_length=12000},
  {name="corruption", mod="terraria", radius=9, angle=190, scale="1.2", is_moon=true, moon_length=20000},

  {name="slp-solar-system-sun", mod="slp-dyson-sphere-reworked", radius=6, angle=1, scale="0.7"},
  {name="slp-solar-system-sun2", mod="slp-dyson-sphere-reworked", radius=4, angle=1, scale="0.7"},
  {name="solar-system-edge", mod=true, radius=70, angle=270},

  {name="shattered-planet", mod=true, radius=500, angle=270},
  {name="skewer_shattered_planet", mod="skewer_shattered_planet", radius=515, angle=271},
  {name="skewer_lost_beyond", mod="skewer_shattered_planet", radius=560, angle=272},

  {name="sye-nauvis-ne", mod="Starmap_Nexuz", radius=70, angle=330},
  {name="sye-nexuz-sw", mod="Starmap_Nexuz", radius=56, angle=150},
  {name="nexuz-background", mod="Starmap_Nexuz"},
  {name="arrakis", mod="planet-arrakis", radius=18, angle=140, scale="1.5"},
  {name="maraxsis", mod="maraxsis", radius=25, angle=100, scale="1.8"},
  {name="aiur", mod="erm_toss", radius=39, angle=290},
  {name="char", mod="erm_zerg", radius=14, angle=10, scale="1.5"},
  {name="earth", mod="erm_redarmy", radius=30, angle=35},
  {name="corrundum", mod="corrundum", radius=35, angle=195},
  {name="tiber", mod="Factorio-Tiberium", radius=22, angle=240},
  {name="tenebris", mod={"tenebris-prime","tenebris"}, radius=56, angle=340},

  {name="star-dea-dia", mod="dea-dia-system", radius=200, angle=65},
  {name="dea-dia-system-edge", mod="dea-dia-system", radius=20, angle=220},
  {name="planet-dea-dia", mod="dea-dia-system", radius=20, angle=270},
  {name="prosephina", mod="dea-dia-system", radius=10, angle=190},
  {name="lemures", mod="dea-dia-system", radius=7, angle=70},

  {name="calidus-senestella-gate-calidus", mod="metal-and-stars", radius=70, angle=110},
  {name="calidus-senestella-gate-senestella", mod="metal-and-stars"},
  {name="redstar", mod="metal-and-stars", radius=300, angle=230},
  {name="shipyard", mod="metal-and-stars"},
  {name="mirandus-a", mod="metal-and-stars"},
  {name="nix", mod="metal-and-stars"},
  {name="ringworld", mod="metal-and-stars", radius=9, angle=35}
}

return DEFAULTS
