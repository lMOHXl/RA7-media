-- ra7-media client: DUI textures, world overlays, object removal, picker, NUI bridge
local QBCore = exports['qb-core']:GetCoreObject()
local RES = GetCurrentResourceName()

local Lang = Config.DefaultLang
local Items = {}        -- [id] = item
local Duis = {}         -- [key] = { dui, txd, txn, refs, overlay = bool }
local nearList = {}     -- overlays drawn this frame set
local seq = 0
local activeOverlayDui = 0
local panelOpen, picking = false, false
local preview = nil     -- draft quad drawn while the editor is open
local VS = {}           -- [id] = shared video state from the server { playing, speed, pos, t, vol, muted }
local CanCtl = false    -- may this player control videos (server decides)
local Zones = {}        -- [id] = qb-target zone name

local function T(key) return (Config.Text[Lang] or Config.Text.en)[key] or key end
local function Notify(key, kind) QBCore.Functions.Notify(T(key), kind or 'primary') end

-- ---------------------------------------------------------------- math helpers
local function vcross(a, b)
    return vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end
local function vnorm(v)
    local l = #v
    if l < 1e-6 then return vector3(0.0, 0.0, 1.0) end
    return v / l
end

-- four corners (tl, tr, br, bl) of a rectangle lying on a surface with normal n
local function buildQuad(x, y, z, nx, ny, nz, w, h, roll, off)
    local n = vnorm(vector3(nx, ny, nz))
    local c = vector3(x, y, z) + n * (off or 0.0)
    local up = math.abs(n.z) > 0.95 and vector3(0.0, 1.0, 0.0) or vector3(0.0, 0.0, 1.0)
    local r = vnorm(vcross(up, n))
    local u = vcross(n, r)
    local a = math.rad(roll or 0.0)
    local ca, sa = math.cos(a), math.sin(a)
    local r2 = r * ca + u * sa
    local u2 = u * ca - r * sa
    local hw, hh = (w or 1.0) * 0.5, (h or 1.0) * 0.5
    return {
        c - r2 * hw + u2 * hh,   -- tl
        c + r2 * hw + u2 * hh,   -- tr
        c + r2 * hw - u2 * hh,   -- br
        c - r2 * hw - u2 * hh,   -- bl
    }
end

-- unit basis (right, up) of a surface quad
local function quadBasis(n, roll)
    local up = math.abs(n.z) > 0.95 and vector3(0.0, 1.0, 0.0) or vector3(0.0, 0.0, 1.0)
    local r = vnorm(vcross(up, n))
    local u = vcross(n, r)
    local a = math.rad(roll or 0.0)
    local ca, sa = math.cos(a), math.sin(a)
    return r * ca + u * sa, u * ca - r * sa
end

-- corners of an overlay pushed `off` metres off the surface (called per frame: the push grows with distance)
local function quadFor(it, off)
    local c = it._c0 + it._n * off
    local rw, uh = it._r2 * it._hw, it._u2 * it._hh
    return { c - rw + uh, c + rw + uh, c + rw - uh, c - rw - uh }
end

local function isSolid(mode) return mode == 'black' or mode == 'white' or mode == 'clear' end

-- ---------------------------------------------------------------- item prep
local function prep(it)
    if it.kind == 'overlay' then
        local a = it.w / it.h
        local W, H
        if a >= 1 then W, H = 1024, math.max(64, math.floor(1024 / a)) else H, W = 1024, math.max(64, math.floor(1024 * a)) end
        it._rw, it._rh = W, H
        it._n = vnorm(vector3(it.nx, it.ny, it.nz))
        it._c0 = vector3(it.x, it.y, it.z)
        it._r2, it._u2 = quadBasis(it._n, it.roll)
        it._hw, it._hh = it.w * 0.5, it.h * 0.5
        it._dd = math.max(it.dist or 0.0, Config.MinDrawDistance or 0.0)
        it._pos = vector3(it.x, it.y, it.z)
    elseif it.kind == 'hide' then
        it._pos = vector3(it.x, it.y, it.z)
    end
    if isSolid(it.mode) then it._rw, it._rh = 8, 8 end
    return it
end

local function publicItem(it)
    local o = {}
    for k, v in pairs(it) do
        if type(k) == 'string' and k:sub(1, 1) ~= '_' then o[k] = v end
    end
    return o
end

-- ---------------------------------------------------------------- DUI pool
local function urlenc(s)
    return (tostring(s):gsub('[^%w%-_%.~]', function(c) return ('%%%02X'):format(c:byte()) end))
end

local function dKey(it)
    if isSolid(it.mode) then return it.mode end
    return table.concat({ it.mode, it.url, it._rw, it._rh, it.loop and 1 or 0, it.muted and 1 or 0, it.fit or 'fill' }, '|')
end

local function playerUrl(it)
    local url = it.url or ''
    return ('https://cfx-nui-%s/html/player.html?mode=%s&url=%s&loop=%d&muted=%d&fit=%s'):format(
        RES, it.mode, urlenc(url), it.loop and 1 or 0, it.muted and 1 or 0, it.fit or 'fill')
end

local function acquire(it, overlay)
    local key = dKey(it)
    local d = Duis[key]
    if not d then
        local dui = CreateDui(playerUrl(it), it._rw, it._rh)
        local handle = GetDuiHandle(dui)
        seq = seq + 1
        local txd, txn = 'ra7m_' .. seq, 'tex'
        local rt = CreateRuntimeTxd(txd)
        CreateRuntimeTextureFromDuiHandle(rt, txn, handle)
        d = { dui = dui, txd = txd, txn = txn, refs = 0, overlay = overlay, video = it.mode == 'video', vol = -1 }
        Duis[key] = d
        if overlay then activeOverlayDui = activeOverlayDui + 1 end
    end
    d.refs = d.refs + 1
    return key, d
end

local function release(key)
    local d = Duis[key]
    if not d then return end
    d.refs = d.refs - 1
    if d.refs <= 0 then
        DestroyDui(d.dui)
        if d.overlay then activeOverlayDui = activeOverlayDui - 1 end
        Duis[key] = nil
    end
end

-- ---------------------------------------------------------------- overlay lifecycle
local function dropOverlay(it)
    if it._dkey then
        release(it._dkey)
        it._dkey = nil
    end
end

-- ---------------------------------------------------------------- object removal (model hide)
local HideApplied = {}  -- [id] = { x, y, z, radius, model }

local function unhide(id)
    local h = HideApplied[id]
    if not h then return end
    RemoveModelHide(h.x, h.y, h.z, h.radius, h.model, false)
    HideApplied[id] = nil
    -- objects the pool sweep made invisible come back at once
    local m = h.model & 0xFFFFFFFF
    local c = vector3(h.x, h.y, h.z)
    for _, e in ipairs(GetGamePool('CObject')) do
        if (GetEntityModel(e) & 0xFFFFFFFF) == m and (h.radius >= 5000.0 or #(GetEntityCoords(e) - c) <= h.radius) then
            SetEntityVisible(e, true, false)
            SetEntityCollision(e, true, true)
        end
    end
end

local function applyHide(it)
    unhide(it.id)
    if not it.enabled then return end
    CreateModelHide(it.x, it.y, it.z, it.radius + 0.0, it.model, true)
    HideApplied[it.id] = { x = it.x, y = it.y, z = it.z, radius = it.radius + 0.0, model = it.model }
end

local function nh(h) return h & 0xFFFFFFFF end

local ModelNames = {}   -- normalised hash -> readable name (for the scan list)
for _, n in ipairs(Config.KnownModelNames or {}) do ModelNames[nh(GetHashKey(n))] = n end
for _, n in ipairs(Config.AutoHide or {}) do ModelNames[nh(GetHashKey(n))] = n end

-- CreateModelHide misses some already-streamed / interior objects: sweep the pool too
CreateThread(function()
    while true do
        Wait(600)
        if next(HideApplied) then
            local byModel = {}
            for _, h in pairs(HideApplied) do
                local m = nh(h.model)
                local l = byModel[m]
                if not l then l = {} byModel[m] = l end
                l[#l + 1] = { c = vector3(h.x, h.y, h.z), r = h.radius }
            end
            for _, e in ipairs(GetGamePool('CObject')) do
                local list = byModel[nh(GetEntityModel(e))]
                if list and IsEntityVisible(e) then
                    for i = 1, #list do
                        local h = list[i]
                        if h.r >= 5000.0 or #(GetEntityCoords(e) - h.c) <= h.r then
                            SetEntityVisible(e, false, false)
                            SetEntityCollision(e, false, false)
                            break
                        end
                    end
                end
            end
        end
    end
end)

-- ---------------------------------------------------------------- video remote (qb-target)
local function vctl(id, action, value)
    TriggerServerEvent('ra7-media:server:vctl', id, action, value)
end

local function removeZone(id)
    local name = Zones[id]
    if name then
        pcall(function() exports['qb-target']:RemoveZone(name) end)
        Zones[id] = nil
    end
end

local openRemote   -- assigned below (needs the NUI helpers)

local function addZone(it)
    removeZone(it.id)
    if it.kind ~= 'overlay' or it.mode ~= 'video' or not it.enabled then return end
    if GetResourceState('qb-target') ~= 'started' then return end
    local id = it.id
    local radius = math.min(14.0, math.max(1.5, math.max(it.w, it.h) * 0.5 + 0.6))
    local center = it._c0 + it._n * 0.4
    local name = 'ra7media_' .. id
    local ok = pcall(function()
        exports['qb-target']:AddCircleZone(name, center, radius, { name = name, debugPoly = false, useZ = true }, {
            options = {
                {
                    icon = 'fas fa-sliders', label = T('t_remote'),
                    canInteract = function() return CanCtl end,
                    action = function() openRemote(id) end,
                },
            },
            distance = 4.0,
        })
    end)
    if ok then Zones[id] = name end
end

local function clearItem(old)
    if old.kind == 'overlay' then removeZone(old.id) dropOverlay(old)
    elseif old.kind == 'hide' then unhide(old.id) end
end

local function setItem(it)
    local old = Items[it.id]
    if old then clearItem(old) end
    Items[it.id] = prep(it)
    if it.kind == 'hide' then applyHide(it)
    elseif it.kind == 'overlay' then addZone(it) end
end

local function delItem(id)
    local old = Items[id]
    if not old then return end
    clearItem(old)
    Items[id] = nil
end

-- 2 draws per triangle (both windings) so the quad shows whichever way the engine culls
local function tri(a, b, c, r, g, bl, al, txd, txn, ua, ub, uc)
    if txd then
        DrawSpritePoly(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, r, g, bl, al, txd, txn,
            ua[1], ua[2], 1.0, ub[1], ub[2], 1.0, uc[1], uc[2], 1.0)
    else
        DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, r, g, bl, al)
    end
end

local UV = { { 0.0, 0.0 }, { 1.0, 0.0 }, { 1.0, 1.0 }, { 0.0, 1.0 } } -- tl tr br bl

local function drawQuad(q, r, g, b, a, txd, txn)
    tri(q[1], q[4], q[3], r, g, b, a, txd, txn, UV[1], UV[4], UV[3])
    tri(q[1], q[3], q[2], r, g, b, a, txd, txn, UV[1], UV[3], UV[2])
    tri(q[1], q[3], q[4], r, g, b, a, txd, txn, UV[1], UV[3], UV[4])
    tri(q[1], q[2], q[3], r, g, b, a, txd, txn, UV[1], UV[2], UV[3])
end

local function drawOutline(q, r, g, b, a)
    for i = 1, 4 do
        local p, n = q[i], q[i % 4 + 1]
        DrawLine(p.x, p.y, p.z, n.x, n.y, n.z, r, g, b, a)
    end
end

local loopTick = 0

-- shared video state -> the DUI page
-- st.pos is the position at the moment the state arrived (st.rv = local timer then); advance it with the local timer
local function curPos(st)
    return st.pos + (st.playing and ((GetGameTimer() - (st.rv or GetGameTimer())) / 1000.0) * st.speed or 0.0)
end

local function pushCtl(id, key)
    local d = Duis[key]
    local st = VS[id]
    if not (d and st) then return end
    SendDuiMessage(d.dui, json.encode({ type = 'ctl', playing = st.playing, speed = st.speed, pos = curPos(st) }))
end

-- slow loop: choose what is near, create / free DUIs, set video volume
CreateThread(function()
    while true do
        local me = GetEntityCoords(PlayerPedId())
        local list = {}
        local vols = {}
        local ctlKeys = {}   -- DUI key -> item id whose shared state drives it
        for _, it in pairs(Items) do
            if it.kind == 'overlay' and it.enabled then
                local dist = #(me - it._pos)
                if dist <= it._dd then
                    if not isSolid(it.mode) and not it._dkey and activeOverlayDui < Config.MaxActiveDui then
                        it._dkey = acquire(it, true)
                    end
                    if isSolid(it.mode) or it._dkey then list[#list + 1] = it end
                    if it._dkey and it.mode == 'video' then
                        local st = VS[it.id]
                        local base = (st and st.vol and st.vol >= 0) and st.vol or it.volume
                        local v = (st and st.muted) and 0.0 or (base / 100.0) * math.max(0.0, 1.0 - dist / it._dd)
                        vols[it._dkey] = math.max(vols[it._dkey] or 0.0, v)
                        ctlKeys[it._dkey] = it.id
                    end
                elseif it._dkey and dist > it._dd + 30.0 then
                    dropOverlay(it)
                end
            end
        end
        nearList = list
        loopTick = loopTick + 1
        if loopTick % 2 == 0 then                 -- re-send the shared state about every second (page seeks only on drift)
            for key, id in pairs(ctlKeys) do pushCtl(id, key) end
        end
        for key, v in pairs(vols) do
            local d = Duis[key]
            if d and math.abs(d.vol - v) > 0.02 then
                d.vol = v
                SendDuiMessage(d.dui, json.encode({ type = 'vol', v = v }))
            end
        end
        Wait(500)
    end
end)

-- render loop
CreateThread(function()
    while true do
        if #nearList == 0 and not preview then
            Wait(300)
        else
            Wait(0)
            local cam = GetFinalRenderedCamCoord()
            for i = 1, #nearList do
                local it = nearList[i]
                local m = it.mode
                if m ~= 'clear' then
                    -- depth precision drops with distance: push the quad further off the wall the further away it is,
                    -- otherwise the wall (or its LOD model) wins and shows through
                    local dist = #(cam - it._c0)
                    local q = quadFor(it, it.off + math.min(1.2, dist * 0.004))
                    if m == 'black' then
                        drawQuad(q, 0, 0, 0, 255)
                    elseif m == 'white' then
                        drawQuad(q, 255, 255, 255, 255)
                    else
                        local d = Duis[it._dkey]
                        if d then drawQuad(q, 255, 255, 255, 255, d.txd, d.txn) end
                    end
                end
            end
            if preview and preview.q then
                drawQuad(preview.q, 70, 200, 255, 70)
                drawOutline(preview.q, 120, 230, 255, 255)
            end
        end
    end
end)

-- ---------------------------------------------------------------- picker
local function vdot(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end

local function castRay(cp, dir, range)
    local to = cp + dir * range
    local h = StartExpensiveSynchronousShapeTestLosProbe(cp.x, cp.y, cp.z, to.x, to.y, to.z, 1 | 16, PlayerPedId(), 7)
    local _, hit, pos, normal, ent = GetShapeTestResult(h)
    if hit ~= 1 then return nil end
    if #(normal) < 0.01 then return nil end
    if vdot(normal, cp - pos) < 0.0 then normal = -normal end
    return pos, vnorm(normal), ent
end

-- ray from the middle of the screen (the crosshair)
local function camRay(range)
    local cp = GetFinalRenderedCamCoord()
    local rot = GetFinalRenderedCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local dir = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    return castRay(cp, dir, range)
end

local function finishPick(result, action)
    picking = false
    preview = nil
    SendNUIMessage({ action = 'pick', on = false })
    SetNuiFocus(true, true)
    SendNUIMessage({ action = action or 'picked', data = result })
end

local function archName(ent)
    local ok, n = pcall(GetEntityArchetypeName, ent)
    if ok and type(n) == 'string' and n ~= '' then return n end
    return nil
end

-- map shells / buildings are huge: never offer them (hiding one would delete a whole interior)
local function bigEnt(e)
    local mn, mx = GetModelDimensions(GetEntityModel(e))
    return math.max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z) > 10.0
end

local function drawEntityBox(e)
    local mn, mx = GetModelDimensions(GetEntityModel(e))
    local cs = {}
    for _, x in ipairs({ mn.x, mx.x }) do
        for _, y in ipairs({ mn.y, mx.y }) do
            for _, z in ipairs({ mn.z, mx.z }) do
                cs[#cs + 1] = GetOffsetFromEntityInWorldCoords(e, x, y, z)
            end
        end
    end
    for i = 0, 7 do
        for b = 0, 2 do
            local j = i ~ (1 << b)
            if j > i then
                local a, c = cs[i + 1], cs[j + 1]
                DrawLine(a.x, a.y, a.z, c.x, c.y, c.z, 255, 60, 60, 255)
            end
        end
    end
end

local function drawLabel(text)
    SetTextFont(4)
    SetTextScale(0.0, 0.45)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5, 0.88)
end

-- the ray often returns no handle for interior props: find the object whose box contains the hit point
local function objectAt(pos)
    local best, bestVol
    for _, e in ipairs(GetGamePool('CObject')) do
        if IsEntityVisible(e) and #(GetEntityCoords(e) - pos) < 6.0 then
            local mn, mx = GetModelDimensions(GetEntityModel(e))
            local off = GetOffsetFromEntityGivenWorldCoords(e, pos.x, pos.y, pos.z)
            local pad = 0.25
            if off.x >= mn.x - pad and off.x <= mx.x + pad and off.y >= mn.y - pad and off.y <= mx.y + pad
                and off.z >= mn.z - pad and off.z <= mx.z + pad then
                local vol = (mx.x - mn.x + 0.1) * (mx.y - mn.y + 0.1) * (mx.z - mn.z + 0.1)
                if not bestVol or vol < bestVol then best, bestVol = e, vol end
            end
        end
    end
    return best
end

-- object picker: aim at a prop (outlined), E = take it
local function startObjectPick()
    if picking then return end
    picking = true
    preview = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'pick', on = true, mode = 'object' })
    CreateThread(function()
        local cur
        local function setOutline(e)
            if cur == e then return end
            if cur and DoesEntityExist(cur) then SetEntityDrawOutline(cur, false) end
            cur = e
            if cur then
                SetEntityDrawOutlineColor(255, 60, 60, 255)
                SetEntityDrawOutline(cur, true)
            end
        end
        local result
        while picking do
            Wait(0)
            local pos, _, ent = camRay(Config.PickRange)
            local function okEnt(e)
                if not (e and e ~= 0 and DoesEntityExist(e)) then return false end
                local ty = GetEntityType(e)
                return ty ~= 1 and ty ~= 2 and not bigEnt(e)   -- not ped / vehicle / building shell; map props (type 0) allowed
            end
            if not okEnt(ent) then ent = pos and objectAt(pos) or nil end
            if ent then setOutline(ent) else setOutline(nil) end
            if cur then
                drawEntityBox(cur)
                drawLabel(('%s  [%d]'):format(archName(cur) or '?', GetEntityModel(cur)))
            end
            if cur and (IsControlJustPressed(0, 38) or IsControlJustPressed(0, 191)) then
                local c = GetEntityCoords(cur)
                result = { model = GetEntityModel(cur), name = archName(cur), x = c.x, y = c.y, z = c.z }
                print(('[ra7-media] picked %s hash=%d'):format(archName(cur) or '?', GetEntityModel(cur)))
                break
            end
            if IsControlJustPressed(0, 177) then break end
        end
        setOutline(nil)
        finishPick(result, 'pickedObj')
    end)
end

local function startPick(opts)
    if picking then return end
    picking = true
    preview = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'pick', on = true })
    local w, h, roll = tonumber(opts.w) or 2.0, tonumber(opts.h) or 1.2, tonumber(opts.roll) or 0.0
    local off = tonumber(opts.off) or Config.SurfaceOffset
    CreateThread(function()
        local result
        while picking do
            Wait(0)
            for _, c in ipairs({ 14, 15, 16, 17, 37, 99, 100 }) do DisableControlAction(0, c, true) end
            local pos, n = camRay(Config.PickRange)
            if pos then
                preview = { q = buildQuad(pos.x, pos.y, pos.z, n.x, n.y, n.z, w, h, roll, off) }
            else
                preview = nil
            end

            local up = IsDisabledControlJustPressed(0, 241) or IsControlJustPressed(0, 241)
            local down = IsDisabledControlJustPressed(0, 242) or IsControlJustPressed(0, 242)
            if up or down then
                local k = up and 1.1 or (1 / 1.1)
                if IsControlPressed(0, 21) then w = w * k            -- shift = width only
                elseif IsControlPressed(0, 36) then h = h * k        -- ctrl  = height only
                else w, h = w * k, h * k end
                w, h = math.min(80.0, math.max(0.1, w)), math.min(80.0, math.max(0.1, h))
            end
            if IsControlPressed(0, 174) then roll = roll - 1.2 end
            if IsControlPressed(0, 175) then roll = roll + 1.2 end
            if roll > 180.0 then roll = roll - 360.0 elseif roll < -180.0 then roll = roll + 360.0 end

            if pos and (IsControlJustPressed(0, 191) or IsControlJustPressed(0, 38)) then
                result = {
                    x = pos.x, y = pos.y, z = pos.z, nx = n.x, ny = n.y, nz = n.z,
                    w = math.floor(w * 100 + 0.5) / 100, h = math.floor(h * 100 + 0.5) / 100,
                    roll = math.floor(roll * 10 + 0.5) / 10,
                }
                break
            end
            if IsControlJustPressed(0, 177) then break end
        end
        picking = false
        preview = nil
        SendNUIMessage({ action = 'pick', on = false })
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'picked', data = result })
    end)
end

-- ---------------------------------------------------------------- NUI
local function openPanel()
    if panelOpen then return end
    panelOpen = true
    local list = {}
    for _, it in pairs(Items) do list[#list + 1] = publicItem(it) end
    SetNuiFocus(true, true)
    local vs = {}
    for id, st in pairs(VS) do
        vs[tostring(id)] = { playing = st.playing, speed = st.speed, vol = st.vol, muted = st.muted, pos = curPos(st) }
    end
    SendNUIMessage({
        action = 'open', items = list, lang = Lang, vs = vs,
        cfg = { maxDist = Config.MaxDrawDistance, defDist = Config.DefaultDrawDistance, off = Config.SurfaceOffset },
    })
end

local function closePanel()
    panelOpen = false
    preview = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- the video remote: same square panel, but only the remote view (for players allowed to control videos)
openRemote = function(id)
    local it = Items[id]
    if not it or panelOpen then return end
    panelOpen = true
    local st = VS[id]
    local vs = {}
    if st then vs[tostring(id)] = { playing = st.playing, speed = st.speed, vol = st.vol, muted = st.muted, pos = curPos(st) } end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'remote', id = id, item = publicItem(it), lang = Lang, vs = vs })
end

local function pushItems()
    if not panelOpen then return end
    local list = {}
    for _, it in pairs(Items) do list[#list + 1] = publicItem(it) end
    SendNUIMessage({ action = 'items', items = list })
end

RegisterNUICallback('close', function(_, cb) closePanel() cb({}) end)

RegisterNUICallback('pick', function(d, cb)
    d = d or {}
    if d.mode == 'object' then startObjectPick() else startPick(d) end
    cb({})
end)

RegisterNUICallback('preview', function(d, cb)
    if type(d) == 'table' and d.x and d.nx then
        preview = { q = buildQuad(d.x, d.y, d.z, d.nx, d.ny, d.nz, tonumber(d.w) or 1.0, tonumber(d.h) or 1.0, tonumber(d.roll) or 0.0, tonumber(d.off) or Config.SurfaceOffset) }
    else
        preview = nil
    end
    cb({})
end)

RegisterNUICallback('export', function(_, cb)
    TriggerServerEvent('ra7-media:server:export')
    cb({})
end)

RegisterNUICallback('vctl', function(d, cb)
    if type(d) == 'table' then vctl(d.id, d.action, d.value) end
    cb({})
end)

RegisterNUICallback('myPos', function(_, cb)
    local p = GetEntityCoords(PlayerPedId())
    cb({ x = p.x, y = p.y, z = p.z })
end)

RegisterNUICallback('goto', function(d, cb)
    local it = Items[tonumber(d and d.id)]
    if it and it._pos then
        local p = it._pos
        if it.kind == 'overlay' then p = p + vector3(it.nx, it.ny, it.nz) * 2.0 end
        SetEntityCoords(PlayerPedId(), p.x, p.y, p.z, false, false, false, false)
    end
    cb({})
end)

RegisterNUICallback('save', function(d, cb)
    if type(d) == 'table' then TriggerServerEvent('ra7-media:server:save', d.kind, d.id, d.data) end
    cb({})
end)

RegisterNUICallback('toggle', function(d, cb)
    if type(d) == 'table' then TriggerServerEvent('ra7-media:server:toggle', d.id, d.state == true) end
    cb({})
end)

RegisterNUICallback('delete', function(d, cb)
    if type(d) == 'table' then TriggerServerEvent('ra7-media:server:delete', d.id) end
    cb({})
end)

-- list every visible object model around the admin (for removing a whole room, e.g. the strip club)
RegisterNUICallback('scan', function(d, cb)
    local r = math.min(80.0, math.max(3.0, tonumber(d and d.r) or 15.0))
    CreateThread(function()
        local ped = PlayerPedId()
        local me = GetEntityCoords(ped)
        local eye = me + vector3(0.0, 0.0, 0.7)
        local groups = {}

        local function add(e)
            local c = GetEntityCoords(e)
            local dist = #(c - me)
            if dist > r + 2.0 or bigEnt(e) then return end
            local m = GetEntityModel(e)
            local k = nh(m)
            local g = groups[k]
            if not g then
                -- thin sheet (poster / magazine / picture): smallest side < 8 cm, middle side > 15 cm
                local mn, mx = GetModelDimensions(m)
                local sz = { mx.x - mn.x, mx.y - mn.y, mx.z - mn.z }
                table.sort(sz)
                g = {
                    model = m, name = archName(e) or ModelNames[k], count = 0, dist = dist, x = c.x, y = c.y, z = c.z,
                    hx = me.x, hy = me.y, hz = me.z,
                    flat = sz[1] < 0.08 and sz[2] > 0.15,
                    size = ('%.2f x %.2f x %.2f'):format(sz[3], sz[2], sz[1]),
                    seen = {},
                }
                groups[k] = g
            end
            if not g.seen[e] then
                g.seen[e] = true
                g.count = g.count + 1
                if dist < g.dist then g.dist, g.x, g.y, g.z = dist, c.x, c.y, c.z end
            end
        end

        for _, e in ipairs(GetGamePool('CObject')) do
            if IsEntityVisible(e) then add(e) end
        end

        -- ray sweep around the player: finds static map / interior entities that are not in the object pool
        local range = math.min(r, 30.0)
        local n = 0
        for pitch = -60, 70, 4 do
            local cp = math.cos(math.rad(pitch))
            local sp = math.sin(math.rad(pitch))
            for yaw = 0, 359, 3 do
                local cy, sy = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
                local to = eye + vector3(cy * cp, sy * cp, sp) * range
                local h = StartExpensiveSynchronousShapeTestLosProbe(eye.x, eye.y, eye.z, to.x, to.y, to.z, 1 | 16, ped, 7)
                local _, hit, _, _, ent = GetShapeTestResult(h)
                if hit == 1 and ent and ent ~= 0 and DoesEntityExist(ent) then
                    local ty = GetEntityType(ent)
                    if ty ~= 1 and ty ~= 2 then add(ent) end
                end
                n = n + 1
                if n % 300 == 0 then Wait(0) end
            end
        end

        local out = {}
        for _, g in pairs(groups) do
            g.seen = nil
            g.dist = math.floor(g.dist * 10 + 0.5) / 10
            out[#out + 1] = g
        end
        table.sort(out, function(x, y) return x.dist < y.dist end)
        for i = #out, 121, -1 do out[i] = nil end
        cb(out)
    end)
end)

RegisterNUICallback('locate', function(d, cb)
    cb({})
    local k = nh(tonumber(d and d.model) or 0)
    local me = GetEntityCoords(PlayerPedId())
    local marked = {}
    SetEntityDrawOutlineColor(255, 60, 60, 255)
    for _, e in ipairs(GetGamePool('CObject')) do
        if nh(GetEntityModel(e)) == k and #(GetEntityCoords(e) - me) <= 90.0 then
            SetEntityDrawOutline(e, true)
            marked[#marked + 1] = e
        end
    end
    SetTimeout(5000, function()
        for _, e in ipairs(marked) do
            if DoesEntityExist(e) then SetEntityDrawOutline(e, false) end
        end
    end)
end)

-- models hidden on every client from config (names that do not exist in this build just do nothing)
local function applyAutoHide()
    for _, n in ipairs(Config.AutoHide or {}) do
        local h = GetHashKey(n)
        if not HideApplied['auto:' .. n] and IsModelInCdimage(h) then
            CreateModelHide(0.0, 0.0, 0.0, 99999.0, h, true)
            HideApplied['auto:' .. n] = { x = 0.0, y = 0.0, z = 0.0, radius = 99999.0, model = h }
        end
    end
end

-- /mediadebug: prints what the script currently holds (paste the F8 output when something does not show)
RegisterCommand('mediadebug', function()
    local cnt = { overlay = 0, hide = 0 }
    local nearest, nearestD
    local me = GetEntityCoords(PlayerPedId())
    for _, it in pairs(Items) do
        cnt[it.kind] = (cnt[it.kind] or 0) + 1
        if it.kind == 'overlay' and it._pos then
            local d = #(me - it._pos)
            if not nearestD or d < nearestD then nearest, nearestD = it, d end
        end
    end
    local hides = 0
    for _ in pairs(HideApplied) do hides = hides + 1 end
    local duis = 0
    for _ in pairs(Duis) do duis = duis + 1 end
    print(('[ra7-media] items overlay=%d hide=%d | drawing now=%d | duis=%d | model-hides applied=%d'):format(
        cnt.overlay, cnt.hide, #nearList, duis, hides))
    if nearest then
        print(('[ra7-media] nearest overlay #%d "%s" mode=%s dist=%.1fm (draw range %.0fm) enabled=%s'):format(
            nearest.id, nearest.label, nearest.mode, nearestD, nearest._dd or 0, tostring(nearest.enabled)))
    end
end, false)

RegisterCommand('mediacheck', function()
    for _, n in ipairs(Config.AutoHide or {}) do
        print(('[ra7-media] %-28s %s'):format(n, IsModelInCdimage(GetHashKey(n)) and 'EXISTS (hidden)' or 'not found'))
    end
end, false)

-- ---------------------------------------------------------------- server events
RegisterNetEvent('ra7-media:client:open', openPanel)

RegisterNetEvent('ra7-media:client:notify', function(key, kind) Notify(key, kind) end)

RegisterNetEvent('ra7-media:client:export', function(sql)
    SendNUIMessage({ action = 'export', sql = sql })
end)

RegisterNetEvent('ra7-media:client:vstate', function(id, st)
    st.rv = GetGameTimer()
    VS[id] = st
    local it = Items[id]
    local key = it and it._dkey
    if key then pushCtl(id, key) end
    if panelOpen then SendNUIMessage({ action = 'vstate', id = id, st = st, pos = curPos(st) }) end
end)

RegisterNetEvent('ra7-media:client:vnote', function(note, val)
    local txt = T(note)
    if val ~= nil then txt = txt .. ': ' .. tostring(val) end
    QBCore.Functions.Notify(txt, 'primary')
end)

RegisterNetEvent('ra7-media:client:sync', function(list, states, canCtl)
    CanCtl = canCtl == true
    VS = {}
    for k, v in pairs(states or {}) do
        v.rv = GetGameTimer()
        VS[tonumber(k)] = v
    end
    for id in pairs(Items) do delItem(id) end
    for _, it in ipairs(list or {}) do setItem(it) end
    pushItems()
end)

RegisterNetEvent('ra7-media:client:upsert', function(it)
    if type(it) ~= 'table' or not it.id then return end
    setItem(it)
    pushItems()
end)

RegisterNetEvent('ra7-media:client:remove', function(id)
    delItem(id)
    pushItems()
end)

----------------------------------------------------------------------
-- ra7 dev 
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

-- ---------------------------------------------------------------- qb_settings (/trk) bridge: accent + language
local function applySettings(s)
    if type(s) ~= 'table' then return end
    if s.lang == 'ar' or s.lang == 'en' then Lang = s.lang end
    SendNUIMessage({ __tc = 'settings', s = s })
end
AddEventHandler('qb_settings:changed', applySettings)

local function init()
    applyAutoHide()
    local ok, s = pcall(function() return exports['qb_settings']:GetAll() end)
    if ok and type(s) == 'table' then applySettings(s) end
    TriggerServerEvent('ra7-media:server:sync')
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() SetTimeout(1500, init) end)
AddEventHandler('onClientResourceStart', function(res)
    if res == RES then
        SetTimeout(1500, init)
    elseif res == 'qb-target' then                 -- qb-target (re)started: its zones are gone, add ours again
        SetTimeout(1000, function()
            for _, it in pairs(Items) do addZone(it) end
        end)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= RES then return end
    if panelOpen or picking then SetNuiFocus(false, false) end
    for id in pairs(Items) do delItem(id) end
    for id in pairs(HideApplied) do unhide(id) end
    for _, d in pairs(Duis) do DestroyDui(d.dui) end
end)
