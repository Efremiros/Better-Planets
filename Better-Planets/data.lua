-- data.lua
-- Если установлен PlanetsLib-tierlist, обновим tiers (для тех тел, что мы умеем двигать).
local tiers = data.raw["mod-data"] and data.raw["mod-data"]["PlanetsLib-tierlist"]
if tiers then
  tiers.data = tiers.data or { default = 3, planet = {}, ["space-location"] = {} }

  local APPLY = {
    planet = {
      "nauvis","vulcanus","fulgora","gleba","aquilo",
      "muluna","lignumis","ceris",
      "tenebris","maraxsis","arrakis","tiber","janus","corrundum","naufulglebunusilo",
      "aiur","char","moshine","paracelsin","vesta","secretas","frozeta",
      "froodara","gerkizia","hexalith","ithurice","mickora","nekohaven","quadromire",
      "prosephina","lemures"
    },
    ["space-location"] = {
      "neumann-v","nix","circa","mirandus",
      "sun-orbit","sun-orbit-close",
      "shattered-planet","shattered-planet-approach","lost-beyond","solar-system-edge",
      "dea-dia"
    }
  }

  local function push(kind, name)
    local en = settings.startup["tr-enable-"..kind.."-"..name]
    local an = settings.startup["tr-angle-" ..kind.."-"..name]
    if en and en.value and an and an.value ~= "" then
      local t = tonumber(an.value)
      if t then
        tiers.data[kind] = tiers.data[kind] or {}
        tiers.data[kind][name] = t
      end
    end
  end

  for k, list in pairs(APPLY) do for _, n in ipairs(list) do push(k, n) end end
end
