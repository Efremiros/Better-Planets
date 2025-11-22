-- Shared configuration for Better Planets mod
-- This file contains the complete default configuration for all planets and locations

-- Complete default configuration: mod provider, order, radius, angle, scale, moon properties
-- mod can be: true (ALWAYS present), string (single mod), table (multiple mods), or nil (use heuristic)
-- scale: optional icon scaling (string or nil)
-- is_moon: true if this is a moon (has special connection handling)
-- moon_length: connection length in km (only for moons)
local DEFAULTS = {
  {name="nauvis", mod=true, radius=15, angle=40},
  {name="lignumis", mod="lignumis", radius=2, angle=300},
  {name="muluna", mod="planet-muluna", radius=1.5, angle=60},

  {name="Gaia", mod={"exotic-space-industries","exotic-space-industries-remembrance"}, radius=22.5, angle=55},

  {name="vulcanus", mod=true, radius=8, angle=90},
  {name="froodara", mod="planet-froodara", radius=2, angle=175, scale="0.6", is_moon=true, moon_length=3000},
  {name="zzhora", mod="planet-zzhora", radius=3, angle=355, scale="0.7", is_moon=true, moon_length=3500},

  {name="fulgora", mod=true, radius=28, angle=110},
  {name="cerys", mod="Cerys-Moon-of-Fulgora", radius=1.5, angle=160},
  {name="tchekor", mod="planet-tchekor", radius=3, angle=50, scale="0.6", is_moon=true, moon_length=4400},

  {name="gleba", mod=true, radius=20, angle=75},
  {name="rabbasca", mod="planet-rabbasca", radius=1.5, angle=160, scale="0.7"},
  {name="terrapalus", mod="terrapalus", radius=2.5, angle=50},
  {name="gerkizia", mod="planet-gerkizia", radius=4.5, angle=15, scale="0.8", is_moon=true, moon_length=5000},

  {name="moshine", mod="Moshine", radius=6.5, angle=200},
  {name="linox-planet_linox", mod="linox", radius=7.5, angle=285},

  {name="igrys", mod="Igrys", radius=18, angle=100},
  {name="shchierbin", mod="shchierbin", radius=18, angle=130},

  {name="vicrox", mod="planet-vicrox-reworked"},
  {name="akularis", mod="planet-akularis-reworked"},

  {name="arig", mod={"planetaris-arig","planetaris-unbounded"}, radius=15, angle=170},
  {name="hyarion", mod={"planetaris-hyarion","planetaris-unbounded"}, radius=31, angle=180},

  {name="rubia", mod="rubia", radius=29.5, angle=140},
  {name="castra", mod="castra", radius=22.5, angle=220},
  {name="omnia", mod="omnia", radius=16.5, angle=297},

  {name="pelagos", mod="pelagos", radius=13.5, angle=260, scale="1.2"},
  {name="panglia", mod="panglia_planet", radius=25.3, angle=292, scale="2.5"},

  {name="asteroid-belt-inner-edge", mod="AsteroidBelts"},
  {name="asteroid-belt-outer-edge", mod="AsteroidBelts"},
  {name="aquilo", mod=true},
  {name="cubium", mod="cubium"},
  {name="paracelsin", mod="Paracelsin", radius=50, angle=240},

  {name="secretas", mod="secretas", radius=53, angle=300},
  {name="frozeta", mod="secretas", radius=5, angle=200},
  {name="tapatrion", mod="planet-tapatrion", radius=4, angle=265, scale="0.7", is_moon=true, moon_length=9000},
  {name="ithurice", mod="planet-ithurice", radius=6, angle=20, scale="0.9", is_moon=true, moon_length=12000},

  {name="vesta", mod="skewer_planet_vesta", radius=47.5, angle=168},
  {name="quadromire", mod="planet-quadromire", radius=5, angle=75, scale="0.6", is_moon=true, moon_length=6000},
  {name="hexalith", mod="planet-hexalith", radius=7, angle=10, scale="0.6", is_moon=true, moon_length=10000},
  {name="nekohaven", mod="planet-nekohaven", radius=6, angle=275, scale="0.8", is_moon=true, moon_length=8000},
  {name="mickora", mod="planet-mickora", radius=8, angle=140, scale="0.8", is_moon=true, moon_length=12000},
  {name="corruption", mod="terraria", radius=9, angle=220, scale="1.2", is_moon=true, moon_length=20000},

  {name="slp-solar-system-sun", mod="slp-dyson-sphere-reworked", radius=5.5, angle=0, scale="0.7"},
  {name="slp-solar-system-sun2", mod="slp-dyson-sphere-reworked", radius=4, angle=0, scale="0.7"},
  {name="solar-system-edge", mod=true, radius=70, angle=270},

  {name="shattered-planet", mod=true, radius=500, angle=270},
  {name="skewer_shattered_planet", mod="skewer_shattered_planet", radius=515, angle=271},
  {name="skewer_lost_beyond", mod="skewer_shattered_planet", radius=560, angle=272},

  {name="sye-nauvis-ne", mod="Starmap_Nexuz", radius=70, angle=310},
  {name="sye-nexuz-sw", mod="Starmap_Nexuz"},
  {name="nexuz-background", mod="Starmap_Nexuz"},
  {name="arrakis", mod="planet-arrakis", radius=18, angle=140, scale="1.5"},
  {name="aiur", mod="erm_toss", radius=39, angle=240},
  {name="char", mod="erm_zerg", radius=14, angle=10, scale="1.5"},
  {name="earth", mod="erm_redarmy", radius=29, angle=35},
  {name="corrundum", mod="corrundum", radius=35, angle=200},
  {name="maraxsis", mod="maraxsis", radius=25, angle=95, scale="1.8"},
  {name="tiber", mod="Factorio-Tiberium"},
  {name="tenebris", mod="tenebris-prime", radius=50, angle=336},

  {name="star-dea-dia", mod="dea-dia-system", radius=200, angle=65},
  {name="dea-dia-system-edge", mod="dea-dia-system", radius=20, angle=220},
  {name="planet-dea-dia", mod="dea-dia-system", radius=20, angle=270},
  {name="prosephina", mod="dea-dia-system", radius=10, angle=190},
  {name="lemures", mod="dea-dia-system", radius=7, angle=70},

  {name="calidus-senestella-gate-calidus", mod="metal-and-stars", radius=70, angle=100},
  {name="calidus-senestella-gate-senestella", mod="metal-and-stars"},
  {name="redstar", mod="metal-and-stars", radius=300, angle=230},
  {name="shipyard", mod="metal-and-stars"},
  {name="mirandus-a", mod="metal-and-stars"},
  {name="nix", mod="metal-and-stars"},
  {name="ringworld", mod="metal-and-stars", radius=9, angle=35}
}

return DEFAULTS
