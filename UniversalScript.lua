-- Universal Script by Claude
-- Main hub + separate Fly System window

if not game:IsLoaded() then game.Loaded:Wait() end

local success, err = pcall(function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function getCharacter() return LocalPlayer.Character end
local function getHumanoid()
    local c = getCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRootPart()
    local c = getCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

repeat task.wait(0.1) until getCharacter() and getHumanoid() and getRootPart()

local States = {
    Speed = false, Fly = false, InfiniteJump = false,
    AntiAFK = false, Fullbright = false, ESP = false, Noclip = false,
}

local SpeedValue = 50
local FlySpeed = 50
local JumpPowerValue = 50
local OriginalWalkSpeed = getHumanoid().WalkSpeed
local OriginalAmbient = Lighting.Ambient
local OriginalBrightness = Lighting.Brightness
local FlyConnection, NoclipConnection, AntiAFKConnection = nil, nil, nil

local ESPFolder
pcall(function()
    ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "ESP_Folder"
    ESPFolder.Parent = game:GetService("CoreGui")
end)

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=2})
    end)
end

-- forward declare fly UI updater
local updateFlyWindow = nil

-- =====================
-- FEATURES
-- =====================
local function toggleSpeed()
    States.Speed = not States.Speed
    local h = getHumanoid()
    if h then h.WalkSpeed = States.Speed and SpeedValue or OriginalWalkSpeed end
    notify("Speed", States.Speed and "ON" or "OFF")
end

local function disableFly()
    if not States.Fly then return end
    States.Fly = false
    local root = getRootPart()
    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
    if root then
        for _, v in pairs(root:GetChildren()) do
            if v.Name == "FlyVelocity" or v.Name == "FlyGyro" then
                pcall(function() v:Destroy() end)
            end
        end
    end
    if updateFlyWindow then updateFlyWindow(false) end
end

local function enableFly()
    if States.Fly then return end
    States.Fly = true
    local root = getRootPart()
    local hum = getHumanoid()
    if not root or not hum then return end
    hum.PlatformStand = true
    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyVelocity"
    bv.Velocity = Vector3.new(0,0,0)
    bv.MaxForce = Vector3.new(1e9,1e9,1e9)
    bv.Parent = root
    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyGyro"
    bg.MaxTorque = Vector3.new(1e9,1e9,1e9)
    bg.P = 1e4
    bg.Parent = root
    FlyConnection = RunService.Heartbeat:Connect(function()
        if not States.Fly then
            pcall(function() bv:Destroy() end)
            pcall(function() bg:Destroy() end)
            FlyConnection:Disconnect() FlyConnection = nil
            return
        end
        local cam = workspace.CurrentCamera
        local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
        bv.Velocity = dir * FlySpeed
        bg.CFrame = cam.CFrame
    end)
    if updateFlyWindow then updateFlyWindow(true) end
end

local function toggleFly()
    if States.Fly then disableFly() else enableFly() end
    notify("Fly", States.Fly and "ON" or "OFF")
end

-- Disable fly on death
local function setupDeath(char)
    local hum = char:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        if States.Fly then
            disableFly()
            notify("Fly", "Disabled on death")
        end
    end)
end
setupDeath(getCharacter())
LocalPlayer.CharacterAdded:Connect(function(char)
    setupDeath(char)
    task.wait(0.5)
    if States.Speed then
        local h = getHumanoid()
        if h then h.WalkSpeed = SpeedValue end
    end
    if JumpPowerValue and JumpPowerValue ~= 50 then
        local h = getHumanoid()
        if h then
            pcall(function() h.JumpHeight = JumpPowerValue end)
            pcall(function() h.JumpPower = JumpPowerValue end)
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if States.InfiniteJump then
        local h = getHumanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
local function toggleInfiniteJump()
    States.InfiniteJump = not States.InfiniteJump
    notify("Infinite Jump", States.InfiniteJump and "ON" or "OFF")
end

local function toggleAntiAFK()
    States.AntiAFK = not States.AntiAFK
    if States.AntiAFK then
        AntiAFKConnection = RunService.Heartbeat:Connect(function()
            if States.AntiAFK then pcall(function() LocalPlayer:Move(Vector3.new(0,0,0)) end) end
        end)
    else
        if AntiAFKConnection then AntiAFKConnection:Disconnect() AntiAFKConnection = nil end
    end
    notify("Anti-AFK", States.AntiAFK and "ON" or "OFF")
end

local function toggleFullbright()
    States.Fullbright = not States.Fullbright
    if States.Fullbright then
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e9
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then v.Enabled = false end
        end
    else
        Lighting.Ambient = OriginalAmbient
        Lighting.Brightness = OriginalBrightness
        Lighting.GlobalShadows = true
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then v.Enabled = true end
        end
    end
    notify("Fullbright", States.Fullbright and "ON" or "OFF")
end

local function createESP(player)
    if player == LocalPlayer then return end
    pcall(function()
        local bb = Instance.new("BillboardGui")
        bb.Name = "ESP_"..player.Name
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0,100,0,40)
        bb.StudsOffset = Vector3.new(0,3,0)
        bb.Parent = ESPFolder
        local nl = Instance.new("TextLabel", bb)
        nl.Size = UDim2.new(1,0,0.5,0)
        nl.BackgroundTransparency = 1
        nl.TextColor3 = Color3.fromRGB(255,50,50)
        nl.TextStrokeTransparency = 0
        nl.Font = Enum.Font.GothamBold
        nl.TextScaled = true
        nl.Text = player.Name
        local dl = Instance.new("TextLabel", bb)
        dl.Size = UDim2.new(1,0,0.5,0)
        dl.Position = UDim2.new(0,0,0.5,0)
        dl.BackgroundTransparency = 1
        dl.TextColor3 = Color3.fromRGB(255,255,255)
        dl.TextStrokeTransparency = 0
        dl.Font = Enum.Font.Gotham
        dl.TextScaled = true
        dl.Text = "0 studs"
        RunService.Heartbeat:Connect(function()
            if not States.ESP then pcall(function() bb:Destroy() end) return end
            local char = player.Character
            local root = getRootPart()
            if char and char:FindFirstChild("HumanoidRootPart") and root then
                bb.Adornee = char.HumanoidRootPart
                dl.Text = math.floor((root.Position - char.HumanoidRootPart.Position).Magnitude).." studs"
            end
        end)
    end)
end
local function toggleESP()
    States.ESP = not States.ESP
    if States.ESP then
        for _, p in pairs(Players:GetPlayers()) do createESP(p) end
        Players.PlayerAdded:Connect(function(p) if States.ESP then createESP(p) end end)
    else
        if ESPFolder then ESPFolder:ClearAllChildren() end
    end
    notify("ESP", States.ESP and "ON" or "OFF")
end

local function toggleNoclip()
    States.Noclip = not States.Noclip
    if States.Noclip then
        NoclipConnection = RunService.Stepped:Connect(function()
            if not States.Noclip then
                NoclipConnection:Disconnect() NoclipConnection = nil
                local char = getCharacter()
                if char then for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
                return
            end
            local char = getCharacter()
            if char then for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
    end
    notify("Noclip", States.Noclip and "ON" or "OFF")
end

local function teleportToPlayer(name)
    local target = Players:FindFirstChild(name)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local root = getRootPart()
        if root then root.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0) end
        notify("Teleport", "Teleported to "..name)
    else notify("Teleport", "Player not found!") end
end

local spectateConn = nil
local function spectatePlayer(name)
    if spectateConn then
        spectateConn:Disconnect() spectateConn = nil
        Camera.CameraType = Enum.CameraType.Custom
        notify("Spectate", "Stopped spectating") return
    end
    local target = Players:FindFirstChild(name)
    if target then
        spectateConn = RunService.Heartbeat:Connect(function()
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                Camera.CameraType = Enum.CameraType.Custom
                Camera.CFrame = CFrame.lookAt(
                    target.Character.HumanoidRootPart.CFrame.Position + Vector3.new(0,5,10),
                    target.Character.HumanoidRootPart.Position
                )
            end
        end)
        notify("Spectate", "Spectating "..name)
    else notify("Spectate", "Player not found!") end
end

local function rejoin()
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- =====================
-- GUI
-- =====================
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalScript"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
pcall(function() gui.Parent = game:GetService("CoreGui") end)

local COLORS = {
    bg        = Color3.fromRGB(22,22,32),
    titlebar  = Color3.fromRGB(14,14,22),
    tabbar    = Color3.fromRGB(18,18,28),
    row       = Color3.fromRGB(32,32,46),
    input     = Color3.fromRGB(45,45,62),
    switchOff = Color3.fromRGB(55,55,72),
    switchOn  = Color3.fromRGB(45,140,75),
    accent    = Color3.fromRGB(70,110,210),
    text      = Color3.fromRGB(220,220,220),
    subtext   = Color3.fromRGB(140,140,170),
    cmdColor  = Color3.fromRGB(100,180,255),
    drop      = Color3.fromRGB(38,38,58),
    dropItem  = Color3.fromRGB(50,50,72),
    dropHover = Color3.fromRGB(62,62,88),
}

-- =====================
-- FLY SYSTEM WINDOW
-- =====================
local FlyWin = Instance.new("Frame")
FlyWin.Name = "FlyWindow"
FlyWin.Size = UDim2.new(0, 320, 0, 270)
FlyWin.Position = UDim2.new(0, 300, 0.3, 0)
FlyWin.BackgroundColor3 = Color3.fromRGB(15,15,22)
FlyWin.BorderSizePixel = 0
FlyWin.Visible = false
FlyWin.ZIndex = 100
FlyWin.Parent = gui
Instance.new("UICorner", FlyWin).CornerRadius = UDim.new(0,16)

-- Fly title bar
local FlyTitleBar = Instance.new("Frame")
FlyTitleBar.Size = UDim2.new(1,0,0,56)
FlyTitleBar.BackgroundColor3 = Color3.fromRGB(12,12,18)
FlyTitleBar.BorderSizePixel = 0
FlyTitleBar.ZIndex = 101
FlyTitleBar.Parent = FlyWin
Instance.new("UICorner", FlyTitleBar).CornerRadius = UDim.new(0,16)

-- Fix bottom corners of title bar
local FlyTitleFix = Instance.new("Frame")
FlyTitleFix.Size = UDim2.new(1,0,0.5,0)
FlyTitleFix.Position = UDim2.new(0,0,0.5,0)
FlyTitleFix.BackgroundColor3 = Color3.fromRGB(12,12,18)
FlyTitleFix.BorderSizePixel = 0
FlyTitleFix.ZIndex = 101
FlyTitleFix.Parent = FlyTitleBar

local FlyTitleText = Instance.new("TextLabel")
FlyTitleText.Size = UDim2.new(1,-110,1,0)
FlyTitleText.Position = UDim2.new(0,16,0,0)
FlyTitleText.BackgroundTransparency = 1
FlyTitleText.TextColor3 = Color3.fromRGB(0,210,255)
FlyTitleText.Font = Enum.Font.GothamBlack
FlyTitleText.TextSize = 20
FlyTitleText.TextXAlignment = Enum.TextXAlignment.Left
FlyTitleText.Text = "FLY SYSTEM"
FlyTitleText.ZIndex = 102
FlyTitleText.Parent = FlyTitleBar

-- Minimize button
local FlyMinBtn = Instance.new("TextButton")
FlyMinBtn.Size = UDim2.new(0,38,0,38)
FlyMinBtn.Position = UDim2.new(1,-90,0.5,-19)
FlyMinBtn.BackgroundColor3 = Color3.fromRGB(55,55,72)
FlyMinBtn.TextColor3 = Color3.fromRGB(255,255,255)
FlyMinBtn.Font = Enum.Font.GothamBold
FlyMinBtn.TextSize = 20
FlyMinBtn.Text = "−"
FlyMinBtn.BorderSizePixel = 0
FlyMinBtn.ZIndex = 103
FlyMinBtn.Parent = FlyTitleBar
Instance.new("UICorner", FlyMinBtn).CornerRadius = UDim.new(0,8)

-- Close button
local FlyCloseBtn = Instance.new("TextButton")
FlyCloseBtn.Size = UDim2.new(0,38,0,38)
FlyCloseBtn.Position = UDim2.new(1,-46,0.5,-19)
FlyCloseBtn.BackgroundColor3 = Color3.fromRGB(210,50,50)
FlyCloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
FlyCloseBtn.Font = Enum.Font.GothamBlack
FlyCloseBtn.TextSize = 18
FlyCloseBtn.Text = "X"
FlyCloseBtn.BorderSizePixel = 0
FlyCloseBtn.ZIndex = 103
FlyCloseBtn.Parent = FlyTitleBar
Instance.new("UICorner", FlyCloseBtn).CornerRadius = UDim.new(0,8)

-- Fly content
local FlyContent = Instance.new("Frame")
FlyContent.Size = UDim2.new(1,0,1,-56)
FlyContent.Position = UDim2.new(0,0,0,56)
FlyContent.BackgroundTransparency = 1
FlyContent.ZIndex = 100
FlyContent.Parent = FlyWin

-- Speed label
local FlySpeedLabel = Instance.new("TextLabel")
FlySpeedLabel.Size = UDim2.new(1,0,0,22)
FlySpeedLabel.Position = UDim2.new(0,0,0,12)
FlySpeedLabel.BackgroundTransparency = 1
FlySpeedLabel.TextColor3 = Color3.fromRGB(190,190,205)
FlySpeedLabel.Font = Enum.Font.GothamBold
FlySpeedLabel.TextSize = 13
FlySpeedLabel.Text = "SPEED (studs/sec, no limit)"
FlySpeedLabel.ZIndex = 101
FlySpeedLabel.Parent = FlyContent

-- Speed input
local FlySpeedBox = Instance.new("TextBox")
FlySpeedBox.Size = UDim2.new(1,-36,0,54)
FlySpeedBox.Position = UDim2.new(0,18,0,38)
FlySpeedBox.BackgroundColor3 = Color3.fromRGB(20,20,32)
FlySpeedBox.TextColor3 = Color3.fromRGB(50,220,120)
FlySpeedBox.Font = Enum.Font.GothamBold
FlySpeedBox.TextSize = 26
FlySpeedBox.Text = "50"
FlySpeedBox.ClearTextOnFocus = false
FlySpeedBox.BorderSizePixel = 0
FlySpeedBox.ZIndex = 101
FlySpeedBox.Parent = FlyContent
Instance.new("UICorner", FlySpeedBox).CornerRadius = UDim.new(0,10)

-- Actual studs label
local FlyActualLabel = Instance.new("TextLabel")
FlyActualLabel.Size = UDim2.new(1,0,0,18)
FlyActualLabel.Position = UDim2.new(0,0,0,96)
FlyActualLabel.BackgroundTransparency = 1
FlyActualLabel.TextColor3 = Color3.fromRGB(120,120,150)
FlyActualLabel.Font = Enum.Font.Gotham
FlyActualLabel.TextSize = 12
FlyActualLabel.Text = "Actual: 50 studs/sec"
FlyActualLabel.ZIndex = 101
FlyActualLabel.Parent = FlyContent

-- Big fly toggle button
local FlyToggleBtn = Instance.new("TextButton")
FlyToggleBtn.Size = UDim2.new(1,-36,0,56)
FlyToggleBtn.Position = UDim2.new(0,18,0,120)
FlyToggleBtn.BackgroundColor3 = Color3.fromRGB(40,190,90)
FlyToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
FlyToggleBtn.Font = Enum.Font.GothamBlack
FlyToggleBtn.TextSize = 18
FlyToggleBtn.Text = "▶  START FLY"
FlyToggleBtn.BorderSizePixel = 0
FlyToggleBtn.ZIndex = 101
FlyToggleBtn.Parent = FlyContent
Instance.new("UICorner", FlyToggleBtn).CornerRadius = UDim.new(0,12)

-- Button inner shadow
local FlyBtnShadow = Instance.new("Frame")
FlyBtnShadow.Size = UDim2.new(1,0,0,6)
FlyBtnShadow.Position = UDim2.new(0,0,1,-4)
FlyBtnShadow.BackgroundColor3 = Color3.fromRGB(20,100,45)
FlyBtnShadow.BorderSizePixel = 0
FlyBtnShadow.ZIndex = 100
FlyBtnShadow.Parent = FlyToggleBtn
Instance.new("UICorner", FlyBtnShadow).CornerRadius = UDim.new(0,12)

-- Controls hint
local FlyHintLabel = Instance.new("TextLabel")
FlyHintLabel.Size = UDim2.new(1,0,0,16)
FlyHintLabel.Position = UDim2.new(0,0,0,184)
FlyHintLabel.BackgroundTransparency = 1
FlyHintLabel.TextColor3 = Color3.fromRGB(90,90,120)
FlyHintLabel.Font = Enum.Font.Gotham
FlyHintLabel.TextSize = 11
FlyHintLabel.Text = "WASD  |  Space ↑  |  Shift ↓"
FlyHintLabel.ZIndex = 101
FlyHintLabel.Parent = FlyContent

-- Update fly window visual
updateFlyWindow = function(on)
    if on then
        TweenService:Create(FlyToggleBtn, TweenInfo.new(0.2),
            {BackgroundColor3 = Color3.fromRGB(210,55,55)}):Play()
        FlyToggleBtn.Text = "◼  STOP FLY"
        FlyBtnShadow.BackgroundColor3 = Color3.fromRGB(110,20,20)
    else
        TweenService:Create(FlyToggleBtn, TweenInfo.new(0.2),
            {BackgroundColor3 = Color3.fromRGB(40,190,90)}):Play()
        FlyToggleBtn.Text = "▶  START FLY"
        FlyBtnShadow.BackgroundColor3 = Color3.fromRGB(20,100,45)
    end
end

FlyToggleBtn.MouseButton1Click:Connect(function()
    toggleFly()
end)

FlyToggleBtn.MouseEnter:Connect(function()
    if not States.Fly then
        TweenService:Create(FlyToggleBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50,210,100)}):Play()
    end
end)
FlyToggleBtn.MouseLeave:Connect(function()
    if not States.Fly then
        TweenService:Create(FlyToggleBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40,190,90)}):Play()
    end
end)

FlySpeedBox.FocusLost:Connect(function()
    local v = tonumber(FlySpeedBox.Text)
    if v and v > 0 then
        FlySpeed = v
        FlySpeedBox.Text = tostring(v)
        FlyActualLabel.Text = "Actual: "..v.." studs/sec"
    else
        FlySpeedBox.Text = tostring(FlySpeed)
    end
end)

-- Minimize fly window
local flyMinimized = false
FlyMinBtn.MouseButton1Click:Connect(function()
    flyMinimized = not flyMinimized
    FlyContent.Visible = not flyMinimized
    TweenService:Create(FlyWin, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        {Size = flyMinimized and UDim2.new(0,320,0,56) or UDim2.new(0,320,0,270)}):Play()
    FlyMinBtn.Text = flyMinimized and "+" or "−"
end)

-- Close fly window
FlyCloseBtn.MouseButton1Click:Connect(function()
    disableFly()
    FlyWin.Visible = false
end)

-- Drag fly window
local flyDragging, flyDragStart, flyFrameStart = false, nil, nil
FlyTitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        flyDragging = true
        flyDragStart = input.Position
        flyFrameStart = FlyWin.Position
    end
end)
FlyTitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        flyDragging = false
    end
end)

-- =====================
-- MAIN HUB
-- =====================
local OPEN_HEIGHT = 440
local CLOSED_HEIGHT = 42
local WIDTH = 260
local isOpen = true

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, WIDTH, 0, OPEN_HEIGHT)
Main.Position = UDim2.new(0, 20, 0.3, 0)
Main.BackgroundColor3 = COLORS.bg
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, CLOSED_HEIGHT)
TitleBar.BackgroundColor3 = COLORS.titlebar
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 10
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -50, 1, 0)
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.TextColor3 = COLORS.text
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 13
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Text = "⚡ Universal Script"
TitleText.ZIndex = 11
TitleText.Parent = TitleBar

local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 28, 0, 28)
OpenBtn.Position = UDim2.new(1, -34, 0.5, -14)
OpenBtn.BackgroundColor3 = COLORS.accent
OpenBtn.TextColor3 = Color3.fromRGB(255,255,255)
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 14
OpenBtn.Text = "▼"
OpenBtn.BorderSizePixel = 0
OpenBtn.ZIndex = 12
OpenBtn.Parent = TitleBar
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 6)


local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 34)
TabBar.Position = UDim2.new(0, 0, 0, CLOSED_HEIGHT)
TabBar.BackgroundColor3 = COLORS.tabbar
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 9
TabBar.Parent = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Parent = TabBar

local TabPad = Instance.new("UIPadding")
TabPad.PaddingLeft = UDim.new(0, 6)
TabPad.Parent = TabBar

local ScrollArea = Instance.new("ScrollingFrame")
ScrollArea.Size = UDim2.new(1, 0, 1, -(CLOSED_HEIGHT + 34))
ScrollArea.Position = UDim2.new(0, 0, 0, CLOSED_HEIGHT + 34)
ScrollArea.BackgroundTransparency = 1
ScrollArea.BorderSizePixel = 0
ScrollArea.ScrollBarThickness = 3
ScrollArea.ScrollBarImageColor3 = Color3.fromRGB(80,80,110)
ScrollArea.CanvasSize = UDim2.new(0,0,0,0)
ScrollArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollArea.ZIndex = 8
ScrollArea.Parent = Main

OpenBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        {Size = UDim2.new(0, WIDTH, 0, isOpen and OPEN_HEIGHT or CLOSED_HEIGHT)}):Play()
    OpenBtn.Text = isOpen and "▼" or "▲"
end)

-- Shared drag handler for both windows
local mainDragging, mainDragStart, mainFrameStart = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        mainDragging = true
        mainDragStart = input.Position
        mainFrameStart = Main.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        mainDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        if mainDragging then
            local delta = input.Position - mainDragStart
            Main.Position = UDim2.new(
                mainFrameStart.X.Scale, mainFrameStart.X.Offset + delta.X,
                mainFrameStart.Y.Scale, mainFrameStart.Y.Offset + delta.Y
            )
        end
        if flyDragging then
            local delta = input.Position - flyDragStart
            FlyWin.Position = UDim2.new(
                flyFrameStart.X.Scale, flyFrameStart.X.Offset + delta.X,
                flyFrameStart.Y.Scale, flyFrameStart.Y.Offset + delta.Y
            )
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        mainDragging = false
        flyDragging = false
    end
end)

-- =====================
-- TAB SYSTEM
-- =====================
local tabData = {}
local function switchTab(name)
    for tname, tinfo in pairs(tabData) do
        tinfo.content.Visible = tname == name
        tinfo.btn.BackgroundColor3 = tname == name and COLORS.accent or Color3.fromRGB(35,35,50)
        tinfo.btn.TextColor3 = tname == name and Color3.fromRGB(255,255,255) or COLORS.subtext
    end
    ScrollArea.CanvasPosition = Vector2.new(0,0)
end

local function newTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 58, 0, 26)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,50)
    btn.TextColor3 = COLORS.subtext
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.Text = name
    btn.BorderSizePixel = 0
    btn.ZIndex = 10
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,0,0,0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.Visible = false
    content.Parent = ScrollArea

    local cl = Instance.new("UIListLayout")
    cl.Padding = UDim.new(0,6)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    cl.Parent = content

    local cp = Instance.new("UIPadding")
    cp.PaddingTop = UDim.new(0,8)
    cp.PaddingLeft = UDim.new(0,10)
    cp.PaddingRight = UDim.new(0,10)
    cp.PaddingBottom = UDim.new(0,8)
    cp.Parent = content

    tabData[name] = {btn=btn, content=content}
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    return content
end

-- =====================
-- HELPERS
-- =====================
local switchRefs = {}

local function makeSection(parent, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,16)
    l.BackgroundTransparency = 1
    l.TextColor3 = COLORS.subtext
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = "── "..text:upper().." ──"
    l.Parent = parent
end

local function makeInput(parent, label, default, onChange)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1,0,0,50)
    wrap.BackgroundColor3 = COLORS.row
    wrap.BorderSizePixel = 0
    wrap.Parent = parent
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0,8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-10,0,20)
    lbl.Position = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = COLORS.subtext
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label..": "..tostring(default)
    lbl.Parent = wrap

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1,-20,0,22)
    box.Position = UDim2.new(0,10,0,24)
    box.BackgroundColor3 = COLORS.input
    box.TextColor3 = COLORS.text
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.Text = tostring(default)
    box.PlaceholderText = "Enter value..."
    box.BorderSizePixel = 0
    box.Parent = wrap
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,5)

    box.FocusLost:Connect(function()
        local v = tonumber(box.Text)
        if v then lbl.Text = label..": "..v onChange(v)
        else box.Text = tostring(default) end
    end)
end

local function makeToggle(parent, label, toggleFn, stateKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,36)
    row.BackgroundColor3 = COLORS.row
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-60,1,0)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = COLORS.text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0,44,0,24)
    bg.Position = UDim2.new(1,-52,0.5,-12)
    bg.BackgroundColor3 = COLORS.switchOff
    bg.BorderSizePixel = 0
    bg.Parent = row
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,18,0,18)
    knob.Position = UDim2.new(0,3,0.5,-9)
    knob.BackgroundColor3 = Color3.fromRGB(200,200,200)
    knob.BorderSizePixel = 0
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local function updateVisual(on)
        TweenService:Create(knob, TweenInfo.new(0.15),
            {Position = on and UDim2.new(0,23,0.5,-9) or UDim2.new(0,3,0.5,-9),
             BackgroundColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)}):Play()
        TweenService:Create(bg, TweenInfo.new(0.15),
            {BackgroundColor3 = on and COLORS.switchOn or COLORS.switchOff}):Play()
    end
    if stateKey then switchRefs[stateKey] = updateVisual end

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1,0,1,0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = row
    clickBtn.MouseButton1Click:Connect(function()
        toggleFn()
        if stateKey then updateVisual(States[stateKey]) end
    end)
end

local function makeButton(parent, label, onClick, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,34)
    btn.BackgroundColor3 = color or COLORS.accent
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = label
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

local function makePlayerPicker(parent)
    local chosenName = nil
    local dropOpen = false
    local MAX_VISIBLE = 5
    local ITEM_H = 28
    local DROP_MAX_H = MAX_VISIBLE * (ITEM_H + 3) + 8

    local outer = Instance.new("Frame")
    outer.Size = UDim2.new(1,0,0,50)
    outer.BackgroundColor3 = COLORS.row
    outer.BorderSizePixel = 0
    outer.ClipsDescendants = false
    outer.Parent = parent
    Instance.new("UICorner", outer).CornerRadius = UDim.new(0,8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-10,0,20)
    lbl.Position = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = COLORS.subtext
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "Select Player:"
    lbl.Parent = outer

    local selBtn = Instance.new("TextButton")
    selBtn.Size = UDim2.new(1,-20,0,22)
    selBtn.Position = UDim2.new(0,10,0,24)
    selBtn.BackgroundColor3 = COLORS.input
    selBtn.TextColor3 = COLORS.text
    selBtn.Font = Enum.Font.Gotham
    selBtn.TextSize = 12
    selBtn.Text = "Click to pick player ▾"
    selBtn.BorderSizePixel = 0
    selBtn.Parent = outer
    Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0,5)

    local dropScroll = Instance.new("ScrollingFrame")
    dropScroll.Size = UDim2.new(1,-20,0,0)
    dropScroll.Position = UDim2.new(0,10,0,50)
    dropScroll.BackgroundColor3 = COLORS.drop
    dropScroll.BorderSizePixel = 0
    dropScroll.ScrollBarThickness = 6
    dropScroll.ScrollBarImageColor3 = Color3.fromRGB(120,120,160)
    dropScroll.CanvasSize = UDim2.new(0,0,0,0)
    dropScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
    dropScroll.ClipsDescendants = true
    dropScroll.ScrollingEnabled = true
    dropScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    dropScroll.ElasticBehavior = Enum.ElasticBehavior.Never
    dropScroll.Visible = false
    dropScroll.ZIndex = 20
    dropScroll.Parent = outer
    Instance.new("UICorner", dropScroll).CornerRadius = UDim.new(0,6)

    -- Allow mouse wheel scrolling by forwarding input
    dropScroll.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local newPos = dropScroll.CanvasPosition.Y - (input.Position.Z * 40)
            newPos = math.clamp(newPos, 0, dropScroll.CanvasSize.Y.Offset - dropScroll.AbsoluteSize.Y)
            dropScroll.CanvasPosition = Vector2.new(0, newPos)
        end
    end)

    local dl = Instance.new("UIListLayout")
    dl.Padding = UDim.new(0,3)
    dl.SortOrder = Enum.SortOrder.LayoutOrder
    dl.Parent = dropScroll

    local function closeDropdown()
        dropOpen = false
        selBtn.Text = (chosenName or "Click to pick player").." ▾"
        TweenService:Create(dropScroll, TweenInfo.new(0.15), {Size = UDim2.new(1,-20,0,0)}):Play()
        TweenService:Create(outer, TweenInfo.new(0.15), {Size = UDim2.new(1,0,0,50)}):Play()
        task.wait(0.15)
        dropScroll.Visible = false
    end

    local function openDropdown()
        dropOpen = true

        -- clear old items
        for _, child in pairs(dropScroll:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
        end

        local playerList = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(playerList, p.Name) end
        end

        local PAD = 8 -- top + bottom padding
        local SPACING = 3

        if #playerList == 0 then
            local none = Instance.new("TextLabel")
            none.Size = UDim2.new(1,0,0,28)
            none.BackgroundTransparency = 1
            none.TextColor3 = COLORS.subtext
            none.Font = Enum.Font.Gotham
            none.TextSize = 12
            none.Text = "No other players"
            none.ZIndex = 22
            none.Parent = dropScroll
            dropScroll.CanvasSize = UDim2.new(0,0,0,36)
        else
            for i, name in ipairs(playerList) do
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1,0,0,ITEM_H)
                item.BackgroundColor3 = COLORS.dropItem
                item.TextColor3 = COLORS.text
                item.Font = Enum.Font.Gotham
                item.TextSize = 13
                item.Text = name
                item.BorderSizePixel = 0
                item.LayoutOrder = i
                item.ZIndex = 22
                item.Parent = dropScroll
                Instance.new("UICorner", item).CornerRadius = UDim.new(0,5)

                item.MouseEnter:Connect(function()
                    TweenService:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.dropHover}):Play()
                end)
                item.MouseLeave:Connect(function()
                    TweenService:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.dropItem}):Play()
                end)
                item.MouseButton1Click:Connect(function()
                    chosenName = name
                    closeDropdown()
                end)
            end

            local totalCanvas = #playerList * (ITEM_H + SPACING) + PAD
            dropScroll.CanvasSize = UDim2.new(0, 0, 0, totalCanvas)
        end

        -- Visible height = capped at MAX_VISIBLE items
        local visibleH = math.min(#playerList, MAX_VISIBLE) * (ITEM_H + SPACING) + PAD
        if #playerList == 0 then visibleH = 36 end

        dropScroll.CanvasPosition = Vector2.new(0, 0)
        dropScroll.Visible = true
        TweenService:Create(dropScroll, TweenInfo.new(0.15), {Size = UDim2.new(1,-20,0,visibleH)}):Play()
        TweenService:Create(outer, TweenInfo.new(0.15), {Size = UDim2.new(1,0,0,50+visibleH+6)}):Play()
    end

    selBtn.MouseButton1Click:Connect(function()
        if dropOpen then closeDropdown() else openDropdown() end
    end)
    return outer, function() return chosenName end
end

-- =====================
-- BUILD TABS
-- =====================

-- MOVE TAB
local moveContent = newTab("🏃 Move")
makeSection(moveContent, "Walk Speed")
makeInput(moveContent, "Walk Speed", 50, function(v)
    SpeedValue = v
    if States.Speed then local h = getHumanoid() if h then h.WalkSpeed = v end end
end)
makeToggle(moveContent, "Speed", toggleSpeed, "Speed")
makeSection(moveContent, "Jump")
makeInput(moveContent, "Jump Power", 50, function(v)
    JumpPowerValue = v
    local h = getHumanoid()
    if h then
        pcall(function() h.JumpHeight = v end)
        pcall(function() h.JumpPower = v end)
    end
end)
makeToggle(moveContent, "Infinite Jump", toggleInfiniteJump, "InfiniteJump")
makeSection(moveContent, "Other")
makeToggle(moveContent, "Noclip", toggleNoclip, "Noclip")
makeToggle(moveContent, "Anti-AFK", toggleAntiAFK, "AntiAFK")

-- WORLD TAB
local worldContent = newTab("🌍 World")
makeSection(worldContent, "Visuals")
makeToggle(worldContent, "Fullbright", toggleFullbright, "Fullbright")
makeToggle(worldContent, "ESP", toggleESP, "ESP")
makeSection(worldContent, "Gravity")
makeInput(worldContent, "Gravity", 196, function(v) workspace.Gravity = v end)
makeSection(worldContent, "Time of Day")
makeInput(worldContent, "Clock Time (0-24)", 14, function(v) Lighting.ClockTime = v end)
makeSection(worldContent, "Camera")
makeInput(worldContent, "FOV", 70, function(v) Camera.FieldOfView = v end)
makeSection(worldContent, "FPS")
makeInput(worldContent, "FPS Cap", 144, function(v) pcall(function() setfpscap(v) end) end)

-- PLAYER TAB
local playerContent = newTab("👤 Player")
makeSection(playerContent, "Select a Player")
local _, getTarget = makePlayerPicker(playerContent)
makeSection(playerContent, "Actions")
makeButton(playerContent, "🚀 Teleport to Player", function()
    local t = getTarget()
    if t then teleportToPlayer(t) else notify("Teleport","Pick a player first!") end
end)
makeButton(playerContent, "👁 Spectate / Stop", function()
    local t = getTarget()
    if t then spectatePlayer(t) else notify("Spectate","Pick a player first!") end
end)
makeSection(playerContent, "Server")
makeButton(playerContent, "🔄 Rejoin Server", function() rejoin() end)

-- COMMANDS TAB
local cmdsContent = newTab("💬 Cmds")
makeSection(cmdsContent, "Click to copy")

local cmdList = {
    {"!speed",       "Toggle speed hack"},
    {"!jump",        "Toggle infinite jump"},
    {"!afk",         "Toggle anti-AFK"},
    {"!bright",      "Toggle fullbright"},
    {"!esp",         "Toggle ESP"},
    {"!noclip",      "Turn noclip ON"},
    {"!unnoclip",    "Turn noclip OFF"},
    {"!rejoin",      "Rejoin the server"},
    {"!tp [name]",   "Teleport to player"},
    {"!spec [name]", "Spectate a player"},
}

for _, c in pairs(cmdList) do
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1,0,0,44)
    row.BackgroundColor3 = COLORS.row
    row.BorderSizePixel = 0
    row.Text = ""
    row.Parent = cmdsContent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local cmdLbl = Instance.new("TextLabel")
    cmdLbl.Size = UDim2.new(1,-60,0,20)
    cmdLbl.Position = UDim2.new(0,10,0,4)
    cmdLbl.BackgroundTransparency = 1
    cmdLbl.TextColor3 = COLORS.cmdColor
    cmdLbl.Font = Enum.Font.GothamBold
    cmdLbl.TextSize = 13
    cmdLbl.TextXAlignment = Enum.TextXAlignment.Left
    cmdLbl.Text = c[1]
    cmdLbl.Parent = row

    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1,-60,0,16)
    descLbl.Position = UDim2.new(0,10,0,24)
    descLbl.BackgroundTransparency = 1
    descLbl.TextColor3 = COLORS.subtext
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextSize = 11
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.Text = c[2]
    descLbl.Parent = row

    local copyLbl = Instance.new("TextLabel")
    copyLbl.Size = UDim2.new(0,48,1,0)
    copyLbl.Position = UDim2.new(1,-52,0,0)
    copyLbl.BackgroundTransparency = 1
    copyLbl.TextColor3 = COLORS.subtext
    copyLbl.Font = Enum.Font.Gotham
    copyLbl.TextSize = 10
    copyLbl.Text = "📋 copy"
    copyLbl.Parent = row

    local cmdText = c[1]
    row.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(cmdText) end)
        local orig = cmdLbl.TextColor3
        cmdLbl.TextColor3 = COLORS.switchOn
        copyLbl.Text = "✓ copied!"
        task.wait(1.2)
        cmdLbl.TextColor3 = orig
        copyLbl.Text = "📋 copy"
    end)
    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(42,42,60)}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.row}):Play()
    end)
end

-- =====================
-- CHAT COMMANDS
-- =====================
LocalPlayer.Chatted:Connect(function(msg)
    local args = string.lower(msg):split(" ")
    local cmd = args[1]
    if cmd == "!fly" then
        FlyWin.Visible = true
        FlyWin.Parent = gui -- re-parent to bring to front
        toggleFly()
    elseif cmd == "!speed" then toggleSpeed()
    elseif cmd == "!jump" then toggleInfiniteJump()
    elseif cmd == "!afk" then toggleAntiAFK()
    elseif cmd == "!bright" then toggleFullbright()
    elseif cmd == "!esp" then toggleESP()
    elseif cmd == "!noclip" then
        if not States.Noclip then
            toggleNoclip()
            if switchRefs["Noclip"] then switchRefs["Noclip"](true) end
        end
    elseif cmd == "!unnoclip" then
        if States.Noclip then
            toggleNoclip()
            if switchRefs["Noclip"] then switchRefs["Noclip"](false) end
        end
    elseif cmd == "!rejoin" then rejoin()
    elseif cmd == "!tp" and args[2] then teleportToPlayer(args[2])
    elseif cmd == "!spec" and args[2] then spectatePlayer(args[2])
    end
end)

switchTab("🏃 Move")

print("[Universal Script] Loaded! Press 🚀 button on the hub to show/hide Fly System.")

end)

if not success then
    warn("[Universal Script] Error: "..tostring(err))
end
