-- Invisibility by DuaKNo
-- discord.gg/empgqd5qpq

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local HOTKEY = Enum.KeyCode.M -- PC key to toggle invisibility (change if a game already uses M)

-- UI parent
local ParentUI = LocalPlayer:WaitForChild("PlayerGui")
pcall(function()
	local core = game:GetService("CoreGui")
	local test = Instance.new("ScreenGui")
	test.Parent = core
	test:Destroy()
	ParentUI = core
end)

pcall(function()
	local old = ParentUI:FindFirstChild("InvisToggle")
	if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InvisToggle"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = ParentUI

-- Palette
local BG = Color3.fromRGB(17, 17, 21)
local EDGE = Color3.fromRGB(52, 52, 60)
local RED = Color3.fromRGB(205, 52, 52)
local RED_DARK = Color3.fromRGB(34, 20, 22)
local MUTED = Color3.fromRGB(120, 120, 130)
local LIGHT = Color3.fromRGB(255, 240, 240)

local FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Core invis logic
local IsInvisible = false
local VisibleParts = {}
local Character, Humanoid, HumanoidRootPart

local function SetupInvis()
	Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	Humanoid = Character:WaitForChild("Humanoid")
	HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	VisibleParts = {}
	for _, d in pairs(Character:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency == 0 then
			table.insert(VisibleParts, d)
		end
	end
end

-- Panel (original size)
local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = UDim2.fromOffset(100, 30)
Panel.Position = UDim2.new(0.5, -50, 0.18, 0)
Panel.BackgroundColor3 = BG
Panel.BorderSizePixel = 0
Panel.Parent = ScreenGui
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 8)
local PanelStroke = Instance.new("UIStroke", Panel)
PanelStroke.Color = EDGE
PanelStroke.Thickness = 1.5

-- Visual red button (a label, so it never steals or blocks input)
local Btn = Instance.new("TextLabel")
Btn.Size = UDim2.new(1, -30, 1, -6)
Btn.Position = UDim2.fromOffset(3, 3)
Btn.BackgroundColor3 = RED
Btn.Text = "Invisible"
Btn.TextColor3 = LIGHT
Btn.Font = Enum.Font.GothamBold
Btn.TextSize = 12
Btn.Parent = Panel
Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
local BtnStroke = Instance.new("UIStroke", Btn)
BtnStroke.Color = RED
BtnStroke.Thickness = 1
BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Invisible hit area: covers the whole button and extends a little past it on every side
local Hit = Instance.new("TextButton")
Hit.Name = "Hit"
Hit.Size = UDim2.new(1, -18, 1, 12)
Hit.Position = UDim2.fromOffset(-6, -6)
Hit.BackgroundTransparency = 1
Hit.Text = ""
Hit.AutoButtonColor = false
Hit.ZIndex = 5
Hit.Parent = Panel

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 1, 0)
MinBtn.Position = UDim2.new(1, -24, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "–"
MinBtn.TextColor3 = MUTED
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.ZIndex = 6
MinBtn.Parent = Panel

-- Minimized square (original size)
local Mini = Instance.new("TextButton")
Mini.Name = "Mini"
Mini.Size = UDim2.fromOffset(26, 26)
Mini.BackgroundColor3 = BG
Mini.AutoButtonColor = false
Mini.Text = ""
Mini.Visible = false
Mini.Parent = ScreenGui
Instance.new("UICorner", Mini).CornerRadius = UDim.new(0, 7)
local MiniStroke = Instance.new("UIStroke", Mini)
MiniStroke.Color = RED
MiniStroke.Thickness = 1.5

local MiniDot = Instance.new("Frame")
MiniDot.Size = UDim2.fromOffset(8, 8)
MiniDot.Position = UDim2.new(0.5, -4, 0.5, -4)
MiniDot.BackgroundColor3 = RED
MiniDot.BorderSizePixel = 0
MiniDot.Parent = Mini
Instance.new("UICorner", MiniDot).CornerRadius = UDim.new(1, 0)

-- State visuals
local function Refresh()
	if IsInvisible then
		Btn.Text = "Visible"
		TweenService:Create(Btn, FAST, {BackgroundColor3 = RED_DARK, TextColor3 = RED}):Play()
		TweenService:Create(MiniDot, FAST, {BackgroundTransparency = 1}):Play()
	else
		Btn.Text = "Invisible"
		TweenService:Create(Btn, FAST, {BackgroundColor3 = RED, TextColor3 = LIGHT}):Play()
		TweenService:Create(MiniDot, FAST, {BackgroundTransparency = 0}):Play()
	end
end

local function SetInvisible(state)
	IsInvisible = state
	local trans = IsInvisible and 0.5 or 0
	for _, part in pairs(VisibleParts) do
		if part and part.Parent then
			part.Transparency = trans
		end
	end
	Refresh()
end

-- Dragging + tapping.
-- Only ONE input is tracked at a time and its release is caught globally, so a tap
-- still counts if your finger/mouse slips off the button before letting go.
-- Touch gets a larger movement allowance so a normal tap never turns into a drag.
local function MakeDraggable(target, handle, onTap)
	local activeInput, moved = nil, false
	local dragStart, startPos, threshold = nil, nil, 5

	handle.InputBegan:Connect(function(input)
		if activeInput then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			activeInput, moved = input, false
			threshold = (input.UserInputType == Enum.UserInputType.Touch) and 14 or 5
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if activeInput and (input == activeInput
			or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = input.Position - dragStart
			if d.Magnitude > threshold then moved = true end
			if moved then
				target.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if activeInput and input == activeInput then
			activeInput = nil
			if not moved and onTap then onTap() end
		end
	end)
end

local function Minimize()
	Mini.Position = Panel.Position
	Panel.Visible = false
	Mini.Visible = true
end

local function Restore()
	Panel.Position = Mini.Position
	Mini.Visible = false
	Panel.Visible = true
end

-- Hit area drags the panel; a tap (no movement) toggles invis.
MakeDraggable(Panel, Panel)
MakeDraggable(Panel, Hit, function() SetInvisible(not IsInvisible) end)
MakeDraggable(Mini, Mini, Restore)
MinBtn.Activated:Connect(Minimize)

-- PC hotkey (ignored while typing in chat or any textbox)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == HOTKEY then
		SetInvisible(not IsInvisible)
	end
end)

-- Invis loop: move down on Heartbeat, put back on RenderStepped.
-- No yielding, so threads never pile up (that pile-up caused lag and missed inputs when spamming).
local saved = nil

RunService.Heartbeat:Connect(function()
	if IsInvisible and HumanoidRootPart and Humanoid and HumanoidRootPart.Parent then
		local OriginalCFrame = HumanoidRootPart.CFrame
		local OriginalCameraOffset = Humanoid.CameraOffset
		saved = {OriginalCFrame, OriginalCameraOffset}
		local DownCFrame = OriginalCFrame * CFrame.new(0, -200000, 0)
		HumanoidRootPart.CFrame = DownCFrame
		Humanoid.CameraOffset = DownCFrame:ToObjectSpace(CFrame.new(OriginalCFrame.Position)).Position
	end
end)

RunService.RenderStepped:Connect(function()
	if saved then
		local s = saved
		saved = nil
		if HumanoidRootPart and Humanoid and HumanoidRootPart.Parent then
			HumanoidRootPart.CFrame = s[1]
			Humanoid.CameraOffset = s[2]
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	IsInvisible = false
	saved = nil
	Refresh()
	task.wait(1)
	SetupInvis()
end)

SetupInvis()
Refresh()

-- Startup notifications (Roblox's own notification system)
local function Notify(data)
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCore("SendNotification", data)
		end)
		if ok then return end
		task.wait(0.5)
	end
end

task.spawn(function()
	-- DuaKNo's avatar headshot, so it shows on whoever runs the script
	local icon
	pcall(function()
		local id = Players:GetUserIdFromNameAsync("DuaKNo")
		icon = Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)

	Notify({
		Title = "Invisibility",
		Text = "By DuaKNo",
		Icon = icon,
		Duration = 6,
	})
	task.wait(1.5)

	Notify({
		Title = "Follow on Instagram",
		Text = "@me_duakno",
		Duration = 6,
	})
	task.wait(1.5)

	Notify({
		Title = "Join Discord server for more!",
		Text = "Discord.gg/empgqd5qpq",
		Duration = 8,
	})

	-- PC players: tell them about the hotkey
	if UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled then
		task.wait(1.5)
		Notify({
			Title = "Invisibility",
			Text = "Press " .. HOTKEY.Name .. " to become invisible",
			Duration = 8,
		})
	end
end)
