-- === Better-Planets: Orbit sprites (moons r1..7 then r20..100; Nexuz r30..100; exclude r8,r9,r10) ===
do
  -- SMALL sprites (actual PNG sizes), correct geometry through pixel compensation.
  local RINGS_SMALL = {
    { r=1, file="__Better-Planets__/graphics/orbits/orbit-unit-ring1.png",  size=262  },
    { r=2, file="__Better-Planets__/graphics/orbits/orbit-unit-ring2.png",  size=518  },
    { r=3, file="__Better-Planets__/graphics/orbits/orbit-unit-ring3.png",  size=774  },
    { r=4, file="__Better-Planets__/graphics/orbits/orbit-unit-ring4.png",  size=1030 },
    { r=5, file="__Better-Planets__/graphics/orbits/orbit-unit-ring5.png",  size=1286 },
    { r=6, file="__Better-Planets__/graphics/orbits/orbit-unit-ring6.png",  size=1542 },
    { r=7, file="__Better-Planets__/graphics/orbits/orbit-unit-ring7.png",  size=1798 },
  }

  -- Sprites (4096 px) WITH RECOMMENDED scale for their base radius (s_base).
  local RINGS_BIG_20_100 = {
    { r=20,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring20.png",  size=4096, s=0.31268310546875  },
    { r=30,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring30.png",  size=4096, s=0.46893310546875  },
    { r=40,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring40.png",  size=4096, s=0.62518310546875  },
    { r=50,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring50.png",  size=4096, s=0.78143310546875  },
    { r=60,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring60.png",  size=4096, s=0.93768310546875  },
    { r=70,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring70.png",  size=4096, s=1.09393310546875  },
    { r=80,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring80.png",  size=4096, s=1.25018310546875  },
    { r=90,  file="__Better-Planets__/graphics/orbits/orbit-unit-ring90.png",  size=4096, s=1.40643310546875  },
    { r=100, file="__Better-Planets__/graphics/orbits/orbit-unit-ring100.png", size=4096, s=1.5626831054687502 },
  }

  -- For Nexuz we use only r>=30 (thicker, but accurate by radius).
  local RINGS_BIG_30_100 = {
    RINGS_BIG_20_100[2], RINGS_BIG_20_100[3], RINGS_BIG_20_100[4],
    RINGS_BIG_20_100[5], RINGS_BIG_20_100[6], RINGS_BIG_20_100[7],
    RINGS_BIG_20_100[8], RINGS_BIG_20_100[9],
  }

  -- Reference PlanetsLib generator for r=100, 4096 px:
  local REF_R, REF_PX, REF_SCALE = 100, 4096, 1.5626831054687502

  -- Complete prohibitions
  local NO_ORBIT_SELF = {
    ["shattered-planet"] = true,
    ["skewer_shattered_planet"] = true,
    ["skewer_lost_beyond"] = true,
    ["mirandus-a"]       = true,
    ["cube1"]       = true,
    ["cube2"]       = true,
  }

  -- basic orbits should be drawn, if changed, drawn by mod (condition)
  local ORBIT_WHITELIST_COND = {
    muluna = true, lignumis = true, terrapalus = true, cerys = true,
    frozeta = true, prosephina = true, lemures = true, rabbasca = true,
  }
  -- always draw orbits for these locations, as they are changed by the mod
  local ORBIT_WHITELIST_FORCE = {
    -- moons/planets for which we always draw:
    tchekor = true, quadromire = true, gerkizia = true, froodara = true, zzhora = true,
    hexalith = true, nekohaven = true, mickora = true, corruption = true, tapatrion = true,
    ithurice = true,
    -- systems:
    arrakis = true, aiur = true, char = true, earth = true, corrundum = true,
    maraxsis = true, tiber = true, tenebris = true, ["planet-dea-dia"] = true,
    shipyard = true, nix = true,
  }

  -- Set of moons
  local MOONS = {
    muluna=true, lignumis=true, terrapalus=true, cerys=true,
    frozeta=true, prosephina=true, lemures=true,
    tchekor=true, quadromire=true, gerkizia=true, froodara=true, zzhora=true,
    hexalith=true, nekohaven=true, mickora=true, corruption=true, tapatrion=true,
    ithurice=true,
  }

  -- Special parent systems
  local PARENT_STYLE = {
    ["nexuz-background"] = "nexuz",
    ["redstar"]          = "system",
    ["star-dea-dia"]     = "system",
  }

  local function is_central_star(par)
    return par and par.type == "space-location" and par.name == "star"
  end

  -- Scale for SMALL PNG through pixel compensation (correct radius for any dist):
  -- scale = REF_SCALE * (dist / 100) * (4096 / base.size)
  local function scale_small(dist, base_px)
    if not (dist and dist > 0 and base_px and base_px > 0) then return nil end
    return REF_SCALE * (dist / REF_R) * (REF_PX / base_px)
  end

  -- Scale for BIG PNG by their recommended s_base for base.r:
  -- scale = s_base * (dist / base.r)
  local function scale_big_by_base(dist, base)
    if not (dist and dist > 0 and base and base.s and base.r and base.r > 0) then return nil end
    return base.s * (dist / base.r)
  end

  -- Choosing 'floor' for small (r1..r7): maximum r_base ≤ dist
  local function pick_small_floor(dist)
    if type(dist) ~= "number" or dist <= 0 then return nil end
    local best = RINGS_SMALL[1]
    for _, t in ipairs(RINGS_SMALL) do
      if t.r <= dist and t.r > best.r then best = t end
    end
    return best
  end

  -- Choosing 'ceiling' for big (r20..r100), with minimum threshold min_r (20 or 30)
  local function pick_big_ceil_with_min(dist, list, min_r)
    if type(dist) ~= "number" or dist <= 0 then return nil end
    local candidate = nil
    for _, t in ipairs(list) do
      if t.r >= math.max(dist, min_r) and (not candidate or t.r < candidate.r) then
        candidate = t
      end
    end
    return candidate or list[#list]
  end

  local function ensure_orbit_fields(proto)
    proto.orbit = proto.orbit or {}
    if proto.distance    and proto.orbit.distance    == nil then proto.orbit.distance    = proto.distance    end
    if proto.orientation and proto.orbit.orientation == nil then proto.orbit.orientation = proto.orientation end
  end

  -- safe access to settings (fallback, if BP_OVERRIDDEN is not set)
  local function get_setting(key)
    local s = settings and settings.startup
    return (s and s[key]) and s[key].value or nil
  end
  local function our_override_from_settings(name)
    local en = get_setting("bp:"..name..":enable")
              or get_setting("bp-"..name.."-enable")
              or get_setting("bp-"..name.."-enabled")
    local r  = get_setting("bp:"..name..":radius")
              or get_setting("bp-"..name.."-radius")
              or get_setting("bp-"..name.."-r")
    local a  = get_setting("bp:"..name..":angle")
              or get_setting("bp-"..name.."-angle")
              or get_setting("bp-"..name.."-deg")
              or get_setting("bp-"..name.."-orientation")
              or get_setting("bp:"..name..":deg")
    local r_changed = (type(r)=="number" and r ~= 0)
    local a_changed = (type(a)=="number" and a ~= 0)
    return (en == true) or r_changed or a_changed
  end
  local function cond_enabled(name)
    if (type(BP_OVERRIDDEN)=="table" and BP_OVERRIDDEN[name]) then return true end
    return our_override_from_settings(name)
  end

  for _, kind in ipairs({"planet","space-location"}) do
    for name, proto in pairs(data.raw[kind] or {}) do
      -- 0) prohibitions and 'children' of shattered-planet
      if NO_ORBIT_SELF[name] then
        proto.draw_orbit   = false
        if proto.orbit then proto.orbit.sprite = nil end
        goto continue
      end

      -- 1) orbit.parent
      if not (proto.orbit and proto.orbit.parent) then goto continue end
      ensure_orbit_fields(proto)

      local par  = proto.orbit.parent
      local dist = proto.orbit.distance

      -- 2) for central sun — vanilla
      if is_central_star(par) then
        proto.draw_orbit   = true
        proto.orbit.sprite = nil
        goto continue
      end

      -- 3) decide by whitelists
      local must_draw = false
      if ORBIT_WHITELIST_FORCE[name] then
        must_draw = true
      elseif ORBIT_WHITELIST_COND[name] and cond_enabled(name) then
        must_draw = true
      end
      if not (must_draw and type(dist)=="number" and dist > 0) then
        proto.orbit.sprite = nil
        goto continue
      end

      -- 4) selection style
      local style = (par and PARENT_STYLE[par.name]) or "system"
      if MOONS[name] then style = "moon" end

      if style == "moon" then
        if dist <= 15 then
          -- nearby moons: small PNG (visible, but neat)
          local base = pick_small_floor(dist)
          local sc = base and scale_small(dist, base.size) or nil
          if base and sc and sc > 0 then
            proto.draw_orbit = true
            proto.orbit.sprite = {
              filename = base.file,
              size     = base.size,   -- 262..1798
              scale    = sc,
              allow_forced_downscale = true
            }
          else
            proto.orbit.sprite = nil
          end
        else
          -- distant moons: big PNG, BUT without r8..r10 → r20..r100 (thin, but not 'invisible')
          local base = pick_big_ceil_with_min(dist, RINGS_BIG_20_100, 20)
          local sc = base and scale_big_by_base(dist, base) or nil
          if base and sc and sc > 0 then
            proto.draw_orbit = true
            proto.orbit.sprite = {
              filename = base.file,
              size     = base.size,   -- 4096
              scale    = sc,
              allow_forced_downscale = true
            }
          else
            proto.orbit.sprite = nil
          end
        end

      elseif style == "nexuz" then
        -- Nexuz: big PNG r30..r100 (thicker than r100), accurate radius.
        local base = pick_big_ceil_with_min(dist, RINGS_BIG_30_100, 30)
        local sc = base and scale_big_by_base(dist, base) or nil
        if base and sc and sc > 0 then
          proto.draw_orbit = true
          proto.orbit.sprite = {
            filename = base.file,
            size     = base.size,   -- 4096
            scale    = sc,
            allow_forced_downscale = true
          }
        else
          proto.orbit.sprite = nil
        end

      else
        -- Other systems: r100
        local base = RINGS_BIG_20_100[#RINGS_BIG_20_100] -- r=100
        local sc = scale_big_by_base(dist, base)
        if sc and sc > 0 then
          proto.draw_orbit = true
          proto.orbit.sprite = {
            filename = base.file,
            size     = base.size,   -- 4096
            scale    = sc,
            allow_forced_downscale = true
          }
        else
          proto.orbit.sprite = nil
        end
      end

      ::continue::
    end
  end
end