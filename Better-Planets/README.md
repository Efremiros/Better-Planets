# **WILL WORK PERFECTLY SAFE IN THE EXISTING GAME**
However, please backup your save file before.

### If you see that a planet is positioned oddly on the galactic map or it has no space routes, you need to disable it in the mod settings (or play around with the angle and radius). Since Better Planets was developed alongside the listed mods, if some of them are missing, planets may be positioned **NOT AS INTENDED.**

Better Planets lets you precisely set the orbital **angle (tier)** and **distance (radius)** of planets and space locations, creates new moons, adds asteroid belt exits with Kuiper Belt zones, manages planet properties (temperature, gravity, solar power), smooths space routes lengths, and reparents tech - all with safe, late-stage updates that respect other planet mods.

Changes are made for progression-focused playthroughs with the listed mods. It supports rjdunlap's planets (nearly all of them), plus **Rabbasca** and **Linox**. However, it can also be installed without some mods or no other mods and played standalone. Orbit rendering is implemented for any celestial bodies that are modified.

Recommended settings for planets distance and angle already included as defaults.
Also, I personally recommend to play with **Better StarMap Background** mod with **Enable Outer Asteroid Belt** option.
Redrawn Space Connections should have route length multiplier set to 1.3 for better starmap routes.

---

## What it changes

- **Master Configuration Switches**

    - **Use Custom Parameters** - Toggle between mod defaults and custom settings. When disabled, the mod uses recommended presets for all planets without needing manual configuration.
    - **Enable Technology Reparenting** - Control whether the mod adjusts technology prerequisites.
    - **Enable Space Connections** - Manage space connections between locations (especially for moons).
    - **Enable Connection Normalizer** - Rounds connection lengths to nearest 10000 km for cleaner display.
    - **Enable Asteroid Belt Clones** - Creates additional asteroid belt exits and Kuiper Belt locations.

- **Per-object orbital control**

    - Toggle any supported planet/location on, then set its **angle (0-360°)** and **distance (0-5000)** from the parent. Updates are applied late so positions cascade safely to children without fighting other mods.

    - Optional **visual scale** per body (clamped), plus a final magnitude pass to keep results sane.

- **New moons**
        - **Tchekor** new moon of **Fulgora** 
        - **Froodara** and **ZZhora** new moons of **Vulcanus**
        - **Gerkizia** and **Quadromire** new moons of **Gleba**
        - **Tapatrion** and **Ithurice** new moons of **Secretas**
        - **Nekohaven, Hexalith, Mickora, Corruption** are new moons of **Vesta**

    - **Panglia** is restored as a normal planet (from **Gleba** moon).

- **Nexuz system**

    - Relocated planet Earth to Nexuz system. Planets **Arrakis, Aiur, Char, Corrundum, Maraxsis, Tiber, Tenebris** slightly changed their locations.

- **Dea-Dia / Calidus gate routing**

    - Re-route a **Calidus gate** (Metal and Stars mod)  to **Dea-Dia system edge**, removing the old **Fulgora↔Dea-Dia system Edge** link if present.

- **Asteroid Belt Exits & Kuiper Belt**

    - **9 additional asteroid belt locations** (requires AsteroidBelt mod):
        - **3 inner belt exits** - North, West, and South
        - **3 outer belt exits** - North, West, and South
        - **3 Kuiper Belt exits** - East, West, and North (with custom Kuiper Belt icon)

    - Each exit has its own technology to discover it
    - Kuiper Belt locations positioned at radius 56 in outer solar system
    - Connects to Shattered Planet, Dea Dia/Redstar systems, and Nexuz

- **Planet Properties System**

    - Automatically configures surface properties for planets/locations:
        - **Temperature** (Kelvin) - Affects habitability and resource processing
        - **Gravity** - Impacts movement and logistics
        - **Pressure** - Environmental factor for processing
        - **Magnetic Field** - Affects electromagnetic systems
        - **Solar Power** - Surface and space solar panel efficiency
        - **Day-Night Cycle** - Length of planetary day
        - **Radiation** (if Cerys mod present) - Ambient radiation levels

    - Properties set for **vanilla planets**: Nauvis, Vulcanus, Fulgora, Gleba, Aquilo
    - Properties set for **50+ mod planets/moons**: Froodara, Zzhora, Tapatrion, Ithurice, Frozeta, Igrys, Shchierbin, Omnia, Castra, Rubia, Maraxsis, Moshine, Linox, Panglia, Arig, Cubium, Vesta, Mickora, Corruption, Hexalith, Quadromire, Nekohaven, and more

- **New Supported Planets**

    - **Rabbasca** - Added to configuration with default position (radius 1.5, angle 15°, scale 0.7)
    - **Linox** - Hot planet near Moshine (radius 7, angle 280°, temperature 825K, high solar power)

---

## Technology re-parenting

> If the target tech is missing (mod not installed), tech reparent is simply skipped. When specified, research **unit** is copied from the new parent and **count** is adjusted.

- **Moons**

    - **Gleba moons**  
        - *Planet Discovery - Quadromire* moved under **Planet Discovery - Gleba**  
        - *Planet Discovery - Gerkizia* moved under **Planet Discovery - Gleba**

    - **Fulgora moon**  
        - *Planet Discovery - Tchekor* moved under **Planet Discovery - Fulgora**

    - **Secretas moons**  
        - *Planet Discovery - Ithurice* moved under **Planet Discovery - Secretas**
        - *Planet Discovery - Tapatrion* moved under **Planet Discovery - Secretas**

    - **Vulcanus moons**  
        - *Planet Discovery - Froodara* moved under **Planet Discovery - Vulcanus**
        - *Planet Discovery - ZZhora* moved under **Planet Discovery - Vulcanus**

    - **Vesta moons**  
        - *Planet Discovery - Nekohaven* moved under **Planet Discovery - Vesta**
        - *Planet Discovery - Corruption* moved under **Planet Discovery - Vesta**
        - *Planet Discovery - Hexalith* moved under **Planet Discovery - Vesta**
        - *Planet Discovery - Mickora* moved under **Planet Discovery - Vesta**

- **Planets / locations**

    - *Planet Discovery - Cubium* moved under **Asteroid Belt** (if exists)
    - *Planet Discovery - Shipyard* moved under **Planet Discovery - Fulgora**
    - *Planet Discovery - Omnia* moved under **Asteroid Collector**
    - *Planet Discovery - Linox* moved under **Moshine Neural Computer** tech
    - *Planet Discovery - Castra* moved under **Moshine Neural Computer** tech
    - *Planet Discovery - Rubia* moved under **Moshine Neural Computer** tech

- **Asteroid Belt Technologies**

    - Multiple new technologies for discovering asteroid belt exits:
        - *Discover North Asteroid Belt border*
        - *Discover West Asteroid Belt border*
        - *Discover South Asteroid Belt border*
        - *Discover East Kuiper Belt border*
        - *Discover West Kuiper Belt border*
        - *Discover North Kuiper Belt border*

    - Tech tree reorganized around asteroid belt progression
    - *Planet Discovery - Panglia* moved under **North Asteroid Belt** exit
    - *Planet Discovery - Igrys* and *Shchierbin* moved under **West Asteroid Belt** exit
    - *System Discovery - Dea Dia* moved under **West Kuiper Belt** exit

- **Nexuz System**

    - Moves the following discovery techs under **Star System Discovery - Nexuz** (if mod is installed). Each gets a fresh cost suitable for a system-level unlock (5000, unless otherwise noted):

        - *Planet Discovery - Tiber* (and moves **Aquilo** out; see below)  
        - *Planet Discovery - Arrakis*  
        - *Planet Discovery - Char*  
        - *Planet Discovery - Aiur*  
        - *Planet Discovery - Earth*  
        - *Planet Discovery - Corrundum*  
        - *Planet Discovery - Tenebris*  
        - *Planet Discovery - Maraxsis*

    - *Planet Discovery - Aquilo* moved under **Asteroid Belt** (if exists, this decouples Aquilo from Tiber).

---

## Mod Settings

### Master Switches

- **Use Custom Parameters** - When enabled, reads custom angle/radius/scale from mod settings. When disabled, uses only mod defaults (ignores all custom settings). **Default: OFF** - mod uses recommended presets automatically.

- **Enable Technology Reparenting** - When enabled, adjusts technology prerequisites based on planet assignments. Disable if you want to manage tech tree yourself. **Default: ON**

- **Enable Space Connections** - When enabled, manages space connections between locations (especially for moons). Disable if changing planet locations or want other mods to handle connections. **Default: ON**

- **Enable Connection Normalizer** - When enabled, rounds connection lengths to nearest 10000 km for cleaner display. Disable to keep exact values. **Default: ON**

- **Enable Asteroid Belt Clones** - When enabled, creates 9 additional asteroid belt locations (3 inner, 3 outer, 3 Kuiper Belt). Requires AsteroidBelt mod. **Default: ON**

### Per-Planet Settings

- **Enable recalculation** per object
- **Radius (distance)** and **Angle (degrees)**
- **Scale** (visual magnitude; blank = unchanged)
- **Moon lane length** (only for bodies managed as moons)

Entries only appear when the source mod is present. **Defaults are provided for many bodies** so you can start from a sensible map without manual configuration.
Labels show the object name with its icon right in the settings list.

---

## Compatibility & scope

- Built for **Factorio 2.0 / Space Age** and with usage of **PlanetsLib**. Integrates with **PlanetsLibTiers**, **Tiered-Solar-System** and overwrites their values. Designed to be played with **Redrawn Space Connections**.
- Supports (optionally, when installed): Nexuz, Dea-Dia, Metal & Stars, Asteroid Belts, Skewer (Vesta/Shattered), StarCraft worlds, Maraxsis, Arrakis, Tiberium, Rabbasca, Linox, and more. If a planet isn't present, it's simply skipped.
- **Conflicting mods** (marked as incompatible):
    - Orbit patch mods (secretas-orbit-patch, terrapalus-orbit-patch, rabbasca-orbit-patch, panglia-orbit-patch) - Better Planets draws orbits itself
    - Cosmic Social Distancing - Not needed and causes strange behavior