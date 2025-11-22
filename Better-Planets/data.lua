-- data.lua
-- WARNING: We do NOT call PlanetsLib:update here.
-- We do NOT make any orbit/position edits here.
-- Reparenting/movements are performed ONLY in data-updates.lua (late stage),
-- otherwise the cascade of other mods breaks and orbits start drawing from (0,0).

------------------------------
-- ### Tiers (optional) ###
------------------------------
-- If PlanetsLib: Tiers is installed, we can (carefully) write tier by angle,
-- so that other mods tied to tiers see actual values.
-- Safe: tiers itself doesn't move objects, it's just a 'tag'.

do
  local TL = data.raw["mod-data"] and data.raw["mod-data"]["PlanetsLib-tierlist"]
  if TL and TL.data then
    local TIER_CYCLE   = 20/3                -- 6.666666...
    local DEG_PER_TIER = 360 / TIER_CYCLE    -- ~54.000054

    local function norm_tier(t)
      local c = TIER_CYCLE
      return ((t % c) + c) % c
    end

    local function tier_from_degrees(deg)
      return norm_tier((deg % 360) / DEG_PER_TIER)
    end

    local function enabled(name)
      local st = settings.startup["tr-enable-"..name]
      return st and st.value or false
    end

    local function angle_deg(name)
      local st = settings.startup["tr-angle-"..name]
      return st and st.value or nil
    end

    -- Collect all names from our settings to write tier only for enabled objects
    local names = {}
    for key, st in pairs(settings.startup) do
      if type(key)=="string" and key:sub(1,3)=="tr-" and st then
        local _, n = key:match("^tr%-(enable|angle|radius)%-(.+)$")
        if n and n~="" then names[n] = true end
      end
    end

    for name,_ in pairs(names) do
      if enabled(name) then
        local deg = angle_deg(name)
        if deg ~= nil then
          local t = tier_from_degrees(deg)
          -- Записываем в правильный раздел, если такой прототип существует
          if data.raw.planet and data.raw.planet[name] then
            TL.data.planet = TL.data.planet or {}
            TL.data.planet[name] = t
          end
          if data.raw["space-location"] and data.raw["space-location"][name] then
            TL.data["space-location"] = TL.data["space-location"] or {}
            TL.data["space-location"][name] = t
          end
        end
      end
    end
  end
end