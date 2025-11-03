# **WILL WORK PERFECTLY SAFE IN THE EXISTING GAME**
However, please backup your save file before.

<h3> If you see that a planet is positioned oddly on the galactic map or it has no space routes, you need to disable it in the mod settings (or play around with the angle and radius). Since Better Planets was developed alongside the listed mods, if some of them are missing, planets may be positioned <b>NOT AS INTENDED.</b> </h3>

Better Planets lets you precisely set the orbital **angle (tier)** and **distance (radius)** of planets and space locations, creates new moons, smooths space routes lengths, and reparenting some tech - all with safe, late-stage updates that respect other planet mods. 

Changes are made for progression-focused playthroughs with the listed mods. It supports rjdunlap’s planets (nearly all of them). However, it can also be installed without some mods or no other mods and played standalone. Orbit rendering is implemented for any celestial bodies that are modified.

Recommended settings for planets distance and angle already included.
Also, I personally recommend to play with **Better StarMap Background** mod with **Enable Outer Asteroid Belt** option.
Redrawn Space Connections should have route length multiplier set to 1.3 for better starmap routes.

---

## What it changes

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

- **Enables recalculation** per object  
- **Radius (distance)** and **Angle (degrees)**  
- **Scale** (visual magnitude; blank = unchanged)  
- **Moon lane length** (only for bodies managed as moons)

Entries only appear when the source mod is present. Defaults are provided for many bodies so you can start from a sensible map.
Labels show the object name with its icon right in the settings list.

---

## Compatibility & scope

- Built for **Factorio 2.0 / Space Age** and with usage of **PlanetsLib**. Integrates with **PlanetsLibTiers**, **Tiered-Solar-System** and overwrites their values. Designed to be played with **Redrawn Space Connections**.
- Supports (optionally, when installed): Nexuz, Dea-Dia, Metal & Stars, Asteroid Belts, Skewer (Vesta/Shattered), StarCraft worlds, Maraxsis, Arrakis, Tiberium, and more. If a planet isn’t present, it’s simply skipped.