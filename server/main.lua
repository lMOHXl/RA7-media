-- ra7-media server: storage, validation, admin gate, sync
local QB = exports['qb-core']:GetCoreObject()
local Items = {}   -- [id] = item table (includes id, kind)

local function isAdmin(src)
    if src == 0 then return true end
    return QB.Functions.HasPermission(src, Config.AdminPermissions) or IsPlayerAceAllowed(src, 'command')
end

local function adminName(src)
    local P = QB.Functions.GetPlayer(src)
    local ci = P and P.PlayerData.charinfo
    local n = ci and (('%s %s'):format(ci.firstname or '', ci.lastname or '')) or GetPlayerName(src) or tostring(src)
    return n:sub(1, 60)
end

local function notify(src, key, kind)
    TriggerClientEvent('ra7-media:client:notify', src, key, kind or 'primary')
end

-- ---------------------------------------------------------------- validation
local MODES = { black = true, white = true, clear = true, image = true, video = true }

local function num(v, lo, hi, def)
    v = tonumber(v)
    if not v or v ~= v or v == math.huge or v == -math.huge then return def end
    return math.min(hi, math.max(lo, v))
end

local function str(v, max)
    if type(v) ~= 'string' then return '' end
    return v:sub(1, max)
end

-- returns ok, errKey
local function checkUrl(u)
    if not u:match('^https?://[^%s"\'<>\\]+$') then return false, 'badurl' end
    if Config.AllowedHosts then
        local host = u:match('^https?://([^/:%?#]+)')
        for _, h in ipairs(Config.AllowedHosts) do
            if host and host:lower() == h:lower() then return true end
        end
        return false, 'badhost'
    end
    return true
end

local function clean(kind, d)
    if type(d) ~= 'table' then return nil, 'invalid' end
    if kind == 'hide' then
        local o = { label = str(d.label, 60), enabled = d.enabled ~= false, mode = 'hide' }
        o.model = num(d.model, -2147483648, 4294967295)
        o.x, o.y, o.z = num(d.x, -10000, 10000), num(d.y, -10000, 10000), num(d.z, -2000, 5000)
        if not (o.model and o.x and o.y and o.z) then return nil, 'invalid' end
        o.model = math.floor(o.model)
        o.radius = num(d.radius, 0.1, 99999, 1.0)
        if o.label == '' then o.label = 'hide' end
        return o
    end
    local o = {
        label   = str(d.label, 60),
        enabled = d.enabled ~= false,
        mode    = d.mode,
        url     = str(d.url, 600),
        loop    = d.loop ~= false,
        muted   = d.muted == true,
        volume  = num(d.volume, 0, 100, 50),
        fit     = (d.fit == 'cover' or d.fit == 'contain') and d.fit or 'fill',
    }
    if not MODES[o.mode] then return nil, 'invalid' end
    if o.mode == 'image' or o.mode == 'video' then
        local ok, err = checkUrl(o.url)
        if not ok then return nil, err end
    else
        o.url = ''
    end
    if o.label == '' then o.label = kind end

    if kind == 'overlay' then
        o.x, o.y, o.z = num(d.x, -10000, 10000), num(d.y, -10000, 10000), num(d.z, -2000, 5000)
        local nx, ny, nz = num(d.nx, -1, 1), num(d.ny, -1, 1), num(d.nz, -1, 1)
        if not (o.x and o.y and o.z and nx and ny and nz) then return nil, 'invalid' end
        local len = math.sqrt(nx * nx + ny * ny + nz * nz)
        if len < 0.01 then return nil, 'invalid' end
        o.nx, o.ny, o.nz = nx / len, ny / len, nz / len
        o.w    = num(d.w, 0.05, 80, 2.0)
        o.h    = num(d.h, 0.05, 80, 1.2)
        o.roll = num(d.roll, -360, 360, 0.0)
        o.off  = num(d.off, 0.0, 1.0, Config.SurfaceOffset)
        o.dist = num(d.dist, 5, Config.MaxDrawDistance, Config.DefaultDrawDistance)
    end
    return o
end

-- ---------------------------------------------------------------- storage
local function count()
    local n = 0
    for _ in pairs(Items) do n = n + 1 end
    return n
end

local SCHEMA = [[
        CREATE TABLE IF NOT EXISTS ra7_media (
            id INT AUTO_INCREMENT PRIMARY KEY,
            kind VARCHAR(16) NOT NULL,
            data LONGTEXT NOT NULL,
            updated_by VARCHAR(64) NULL,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
]]

MySQL.ready(function()
    MySQL.query.await(SCHEMA)
    for _, r in ipairs(MySQL.query.await('SELECT id, kind, data FROM ra7_media') or {}) do
        local ok, d = pcall(json.decode, r.data)
        if ok and type(d) == 'table' and (r.kind == 'overlay' or r.kind == 'hide') then   -- old texture rows are ignored
            d.id, d.kind = r.id, r.kind
            Items[r.id] = d
        end
    end
    print(('[ra7-media] loaded %d items'):format(count()))
end)

local function list()
    local out = {}
    for _, it in pairs(Items) do out[#out + 1] = it end
    return out
end

-- ---------------------------------------------------------------- shared video state
-- position of a video = pos + (now - t) * speed while playing; every client derives the same position from it
local VS = {}   -- [id] = { playing, speed, pos, t, vol (-1 = item default), muted }

local function isVideo(it) return it and it.mode == 'video' end

local function ensureState(id)
    local st = VS[id]
    if not st then
        st = { playing = true, speed = 1.0, pos = 0.0, t = os.time(), vol = -1, muted = false }
        VS[id] = st
    end
    return st
end

local function curPos(st)
    return st.pos + (st.playing and (os.time() - st.t) * st.speed or 0.0)
end

-- what clients receive: the position RIGHT NOW (clients advance it with their own timer, so server clock skew never matters)
local function snap(st)
    return { playing = st.playing, speed = st.speed, pos = curPos(st), vol = st.vol, muted = st.muted }
end

local function allStates()
    local out = {}
    for id, it in pairs(Items) do
        if isVideo(it) then out[id] = snap(ensureState(id)) end
    end
    return out
end

-- per-player cooldown so a modified client cannot flood the server with sync / control / export requests
local Last = {}
local function throttle(src, key, ms)
    local t = Last[src]
    if not t then t = {} Last[src] = t end
    local now = GetGameTimer()
    if t[key] and now - t[key] < ms then return true end
    t[key] = now
    return false
end
AddEventHandler('playerDropped', function() Last[source] = nil end)

local function canControl(src)
    return Config.VideoControl == 'everyone' or isAdmin(src)
end

-- ---------------------------------------------------------------- events
RegisterNetEvent('ra7-media:server:sync', function()
    if throttle(source, 'sync', 1000) then return end
    TriggerClientEvent('ra7-media:client:sync', source, list(), allStates(), canControl(source))
end)

RegisterNetEvent('ra7-media:server:vctl', function(id, action, value)
    local src = source
    if throttle(src, 'vctl', 100) then return end
    if not canControl(src) then return notify(src, 'noperm', 'error') end
    id = tonumber(id)
    local it = Items[id]
    if not (isVideo(it) and it.enabled) then return end
    local st = ensureState(id)
    local cur = curPos(st)
    value = tonumber(value)
    local note, noteVal

    if action == 'toggle' or action == 'play' or action == 'pause' then
        local want = (action == 'toggle') and (not st.playing) or (action == 'play')
        st.pos, st.t, st.playing = cur, os.time(), want
        note = want and 'v_play' or 'v_pause'
    elseif action == 'restart' then
        st.pos, st.t, st.playing = 0.0, os.time(), true
        note = 'v_restart'
    elseif action == 'seek' and value then            -- relative seconds
        st.pos, st.t = math.max(0.0, cur + math.max(-3600, math.min(3600, value))), os.time()
        note, noteVal = 'v_seek', value
    elseif action == 'seekto' and value then          -- absolute seconds
        st.pos, st.t = math.max(0.0, math.min(86400, value)), os.time()
    elseif action == 'speed' and value then           -- absolute
        st.pos, st.t, st.speed = cur, os.time(), math.max(0.25, math.min(4.0, value))
        note, noteVal = 'v_speed', ('%.2fx'):format(st.speed)
    elseif action == 'speedstep' and value then       -- relative
        st.pos, st.t, st.speed = cur, os.time(), math.max(0.25, math.min(4.0, st.speed + value))
        note, noteVal = 'v_speed', ('%.2fx'):format(st.speed)
    elseif action == 'vol' and value then
        st.vol = math.max(0, math.min(100, value))
        note, noteVal = 'v_vol', ('%d%%'):format(st.vol)
    elseif action == 'volstep' and value then
        local base = st.vol >= 0 and st.vol or (it.volume or 50)
        st.vol = math.max(0, math.min(100, base + value))
        note, noteVal = 'v_vol', ('%d%%'):format(st.vol)
    elseif action == 'mute' then
        st.muted = not st.muted
        note = st.muted and 'v_mute' or 'v_unmute'
    else
        return
    end
    TriggerClientEvent('ra7-media:client:vstate', -1, id, snap(st))
    if note then TriggerClientEvent('ra7-media:client:vnote', src, note, noteVal) end
end)

local function open(src)
    if not isAdmin(src) then return notify(src, 'noperm', 'error') end
    TriggerClientEvent('ra7-media:client:open', src)
end

RegisterCommand(Config.Command, function(src)
    if src == 0 then return end
    open(src)
end, false)

RegisterNetEvent('ra7-media:server:requestOpen', function() open(source) end)

RegisterNetEvent('ra7-media:server:save', function(kind, id, data)
    local src = source
    if not isAdmin(src) then return notify(src, 'noperm', 'error') end
    if kind ~= 'overlay' and kind ~= 'hide' then return end
    local o, err = clean(kind, data)
    if not o then return notify(src, err or 'invalid', 'error') end

    id = tonumber(id)
    local name = adminName(src)
    local payload = json.encode(o)
    if id and Items[id] then
        if Items[id].kind ~= kind then return end
        MySQL.update.await('UPDATE ra7_media SET data = ?, updated_by = ? WHERE id = ?', { payload, name, id })
    else
        if count() >= Config.MaxItems then return notify(src, 'limit', 'error') end
        id = MySQL.insert.await('INSERT INTO ra7_media (kind, data, updated_by) VALUES (?, ?, ?)', { kind, payload, name })
        if not id then return notify(src, 'invalid', 'error') end
    end
    o.id, o.kind = id, kind
    Items[id] = o
    VS[id] = nil                                   -- a re-saved video starts from the beginning
    TriggerClientEvent('ra7-media:client:upsert', -1, o)
    if isVideo(o) then TriggerClientEvent('ra7-media:client:vstate', -1, id, snap(ensureState(id))) end
    notify(src, 'saved', 'success')
    print(('[ra7-media] %s saved %s #%d (%s)'):format(name, kind, id, o.mode))
end)

RegisterNetEvent('ra7-media:server:toggle', function(id, state)
    local src = source
    if not isAdmin(src) then return notify(src, 'noperm', 'error') end
    id = tonumber(id)
    local it = Items[id]
    if not it then return end
    it.enabled = state == true
    local copy = {}
    for k, v in pairs(it) do if k ~= 'id' and k ~= 'kind' then copy[k] = v end end
    MySQL.update.await('UPDATE ra7_media SET data = ?, updated_by = ? WHERE id = ?', { json.encode(copy), adminName(src), id })
    TriggerClientEvent('ra7-media:client:upsert', -1, it)
end)

-----------------------------------------------------------------------
-- ra7dev 
CreateThread(function()
    print("^5")
    print("^5╔══════════════════════════════════════════════════╗^0")
    print("^5║                  ^3Ra7-Dev^5                     ║^0")
    print("^5║                                                  ║^0")
    print("^5║              ^7Developer: Ra7eem^5               ║^0")
    print("^5║              ^7© 2026 Ra7-Dev^5                  ║^0")
    print("^5║                                                  ║^0")
    print("^5║              ^7All Rights Reserved^5             ║^0")
    print("^5║                                                  ║^0")
    print("^5║          ^3https://discord.gg/eKVS44JPw          ║^0")
    print("^5║                                                  ║^0")
    print("^5║ ^1Unauthorized copying, modification or resale^5 ║^0")
    print("^5║ ^1of this script is strictly prohibited.^5       ║^0")
    print("^5╚══════════════════════════════════════════════════╝^0")
    print("^0")
end)


-- ---------------------------------------------------------------- SQL export
-- Builds one INSERT per overlay / object-removal so the same covers can be loaded on another server.
local function sqlStr(s)
    s = s:gsub('\\', '\\\\'):gsub("'", "''")
    return "'" .. s .. "'"
end

RegisterNetEvent('ra7-media:server:export', function()
    local src = source
    if not isAdmin(src) then return notify(src, 'noperm', 'error') end
    if throttle(src, 'export', 3000) then return end
    local ids = {}
    for id in pairs(Items) do ids[#ids + 1] = id end
    table.sort(ids)

    local schema = SCHEMA:gsub('^%s+', ''):gsub('%s+$', '')
    local lines = {
        ('-- ra7-media export  %s  (%d items)'):format(os.date('%Y-%m-%d %H:%M'), #ids),
        '-- Run this on the other server database, then: restart ra7-media',
        '',
        schema .. ';',
        '',
    }
    for _, id in ipairs(ids) do
        local it = Items[id]
        local copy = {}
        for k, v in pairs(it) do
            if k ~= 'id' and k ~= 'kind' then copy[k] = v end
        end
        lines[#lines + 1] = ("INSERT INTO ra7_media (kind, data, updated_by) VALUES (%s, %s, 'export');"):format(sqlStr(it.kind), sqlStr(json.encode(copy)))
    end
    local sql = table.concat(lines, '\n') .. '\n'

    print(('[ra7-media] %s exported %d items'):format(adminName(src), #ids))
    TriggerClientEvent('ra7-media:client:export', src, sql)
end)

RegisterNetEvent('ra7-media:server:delete', function(id)
    local src = source
    if not isAdmin(src) then return notify(src, 'noperm', 'error') end
    id = tonumber(id)
    if not (id and Items[id]) then return end
    MySQL.update.await('DELETE FROM ra7_media WHERE id = ?', { id })
    Items[id] = nil
    VS[id] = nil
    TriggerClientEvent('ra7-media:client:remove', -1, id)
    notify(src, 'deleted', 'success')
    print(('[ra7-media] %s deleted #%d'):format(adminName(src), id))
end)
