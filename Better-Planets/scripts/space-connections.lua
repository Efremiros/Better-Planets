-- === Deleting connection: prefer gate -> dea-dia-system-edge; only remove Fulgora link ===
do
  local function proto_exists(name)
    return (data.raw.planet and data.raw.planet[name])
        or (data.raw["space-location"] and data.raw["space-location"][name])
  end

  local function resolve_endpoint(name)
    return proto_exists(name) and name or nil
  end

  local function remove_connection_between(a, b)
    local t = data.raw["space-connection"]
    if not t then return end
    for cname, conn in pairs(table.deepcopy(t)) do
      if conn and type(conn.from)=="string" and type(conn.to)=="string" then
        local is_pair = (conn.from == a and conn.to == b) or (conn.from == b and conn.to == a)
        if is_pair then
          t[cname] = nil
        end
      end
    end
  end

  local function ensure_connection(from_name, to_name)
    if not (from_name and to_name) then return end
    local cname = "bp-conn-"..from_name.."__"..to_name
    if not data.raw["space-connection"] or not data.raw["space-connection"][cname] then
      data:extend({
        {
          type = "space-connection",
          name = cname,
          icon = "__core__/graphics/empty.png",
          icon_size = 1,
          from = from_name,
          to   = to_name,
          length = 500,
          order  = "zzz["..cname.."]",
        }
      })
    end
  end

  local DEST      = resolve_endpoint("dea-dia-system-edge")
  local GATE      = resolve_endpoint("calidus-senestella-gate-calidus")
  local FULGORA   = resolve_endpoint("fulgora")
  local GLEBA   = resolve_endpoint("gleba")

  local COPRULU   = resolve_endpoint("sye-nexuz-sw")
  local SOLAR   = resolve_endpoint("solar-system-edge")


  if COPRULU then
    remove_connection_between(COPRULU, SOLAR)
  end
  if DEST then
    if GATE then
      if FULGORA then
        remove_connection_between(FULGORA, DEST)
      end
      if GLEBA then
        remove_connection_between(GLEBA, GATE)
      end
      ensure_connection(GATE, DEST)
      ensure_connection(GLEBA, FULGORA)
      log("[Better-Planets] edge-routing: using gate '"..GATE.."' -> '"..DEST.."' (removed only Fulgora link)")
    else
      log("[Better-Planets] edge-routing: gate not found; keep default Fulgora link to '"..DEST.."'")
    end
  else
    log("[Better-Planets] edge-routing: DEST 'dea-dia-system-edge' not found; skip")
  end
end