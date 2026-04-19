-- Universal Script by Claude
-- Toggle switch version with speed inputs

if not game:IsLoaded() then game.Loaded:Wait() end

local success, err = pcall(function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local function getCharacter()
    return LocalPlayer.Character
end
local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function getRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

repeat task.wait(0.1) until getCharacter() and getHumanoid() and getRootPart()

local States = {
    Speed = false,
    Fly = false,
    InfiniteJump = false,
    AntiAFK = false,
    Fullbright = false,
    ESP = false,
    Noclip = false,
}

local SpeedValue = 50
local FlySpeed = 50
local OriginalWalkSpeed = getHumanoid().WalkSpeed
local OriginalAmbient = Lighting.Ambient
local OriginalBrightness = Lighting.Brightness
local FlyConnection = nil
local NoclipConnection = nil
local AntiAFKConnection = nil

local ESPFolder
pcall(function()
    ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "ESP_Folder"
    ESPFolder.Parent = game:GetService("CoreGui")
end)

-- =====================
-- SPEED
-- =====================
local function toggleSpeed()
    States.Speed = not States.Speed
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = States.Speed and SpeedValue or OriginalWalkSpeed
    end
end

-- =====================
-- FLY
-- =====================
local function toggleFly()
    States.Fly = not States.Fly
    local char = getCharacter()
    local root = getRootPart()
    local hum = getHumanoid()
    if not char or not root or not hum then return end

    if States.Fly then
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
                FlyConnection:Disconnect()
                FlyConnection = nil
                return
            end
            local cam = workspace.CurrentCamera
            local dir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
            bv.Velocity = dir * FlySpeed
            bg.CFrame = cam.CFrame
        end)
    else
        if hum then hum.PlatformStand = false end
        if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
        if root then
            for _, v in pairs(root:GetChildren()) do
                if v.Name == "FlyVelocity" or v.Name == "FlyGyro" then
                    pcall(function() v:Destroy() end)
                end
            end
        end
    end
end

-- =====================
-- INFINITE JUMP
-- =====================
UserInputService.JumpRequest:Connect(function()
    if States.InfiniteJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
local function toggleInfiniteJump()
    States.InfiniteJump = not States.InfiniteJump
end

-- =====================
-- ANTI-AFK
-- =====================
local function toggleAntiAFK()
    States.AntiAFK = not States.AntiAFK
    if States.AntiAFK then
        AntiAFKConnection = RunService.Heartbeat:Connect(function()
            if States.AntiAFK then
                pcall(function() LocalPlayer:Move(Vector3.new(0,0,0)) end)
            end
        end)
    else
        if AntiAFKConnection then AntiAFKConnection:Disconnect() AntiAFKConnection = nil end
    end
end

-- =====================
-- FULLBRIGHT
-- =====================
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
end

-- =====================
-- ESP
-- =====================
local function createESP(player)
    if player == LocalPlayer then return end
    pcall(function()
        local bb = Instance.new("BillboardGui")
        bb.Name = "ESP_" .. player.Name
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0,100,0,40)
        bb.StudsOffset = Vector3.new(0,3,0)
        bb.Parent = ESPFolder

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1,0,0.5,0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255,50,50)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextScaled = true
        nameLabel.Text = player.Name
        nameLabel.Parent = bb

        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1,0,0.5,0)
        distLabel.Position = UDim2.new(0,0,0.5,0)
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = Color3.fromRGB(255,255,255)
        distLabel.TextStrokeTransparency = 0
        distLabel.Font = Enum.Font.Gotham
        distLabel.TextScaled = true
        distLabel.Text = "0 studs"
        distLabel.Parent = bb

        RunService.Heartbeat:Connect(function()
            if not States.ESP then pcall(function() bb:Destroy() end) return end
            local char = player.Character
            local root = getRootPart()
            if char and char:FindFirstChild("HumanoidRootPart") and root then
                bb.Adornee = char.HumanoidRootPart
                local dist = math.floor((root.Position - char.HumanoidRootPart.Position).Magnitude)
                distLabel.Text = dist .. " studs"
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
end

-- =====================
-- NOCLIP
-- =====================
local function toggleNoclip()
    States.Noclip = not States.Noclip
    if States.Noclip then
        NoclipConnection = RunService.Stepped:Connect(function()
            if not States.Noclip then
                NoclipConnection:Disconnect()
                NoclipConnection = nil
                local char = getCharacter()
                if char then
                    for _, p in pairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = true end
                    end
                end
                return
            end
            local char = getCharacter()
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end

-- =====================
-- GUI
-- =====================
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalScript"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = game:GetService("CoreGui") end)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0,240,0,530)
MainFrame.Position = UDim2.new(0,20,0.5,-265)
MainFrame.BackgroundColor3 = Color3.fromRGB(25,25,35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = gui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,10)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,40)
TitleBar.BackgroundColor3 = Color3.fromRGB(15,15,25)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1,-40,1,0)
TitleLabel.Position = UDim2.new(0,10,0,0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Text = "Universal Script"
TitleLabel.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0,30,0,30)
MinBtn.Position = UDim2.new(1,-35,0,5)
MinBtn.BackgroundColor3 = Color3.fromRGB(60,60,80)
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.Text = "-"
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,6)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,0,1,-40)
Content.Position = UDim2.new(0,0,0,40)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,6)
layout.Parent = Content

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0,8)
padding.PaddingLeft = UDim.new(0,10)
padding.PaddingRight = UDim.new(0,10)
padding.Parent = Content

-- =====================
-- INPUT BOX CREATOR
-- =====================
local function createInputBox(labelText, defaultVal, onChanged)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,52)
    container.BackgroundColor3 = Color3.fromRGB(35,35,48)
    container.BorderSizePixel = 0
    container.Parent = Content
    Instance.new("UICorner", container).CornerRadius = UDim.new(0,8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-10,0,22)
    lbl.Position = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(180,180,180)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelText .. ": " .. defaultVal
    lbl.Parent = container

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1,-20,0,22)
    input.Position = UDim2.new(0,10,0,26)
    input.BackgroundColor3 = Color3.fromRGB(50,50,68)
    input.TextColor3 = Color3.fromRGB(255,255,255)
    input.Font = Enum.Font.Gotham
    input.TextSize = 13
    input.Text = tostring(defaultVal)
    input.PlaceholderText = "Enter value..."
    input.BorderSizePixel = 0
    input.Parent = container
    Instance.new("UICorner", input).CornerRadius = UDim.new(0,5)

    input.FocusLost:Connect(function()
        local val = tonumber(input.Text)
        if val then
            lbl.Text = labelText .. ": " .. val
            onChanged(val)
        else
            input.Text = tostring(defaultVal)
        end
    end)
end

-- =====================
-- TOGGLE SWITCH CREATOR
-- =====================
local function createToggleRow(labelText, toggleFunc, stateKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,36)
    row.BackgroundColor3 = Color3.fromRGB(35,35,48)
    row.BorderSizePixel = 0
    row.Parent = Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-60,1,0)
    label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.Parent = row

    local switchBG = Instance.new("Frame")
    switchBG.Size = UDim2.new(0,44,0,24)
    switchBG.Position = UDim2.new(1,-52,0.5,-12)
    switchBG.BackgroundColor3 = Color3.fromRGB(60,60,75)
    switchBG.BorderSizePixel = 0
    switchBG.Parent = row
    Instance.new("UICorner", switchBG).CornerRadius = UDim.new(1,0)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0,18,0,18)
    circle.Position = UDim2.new(0,3,0.5,-9)
    circle.BackgroundColor3 = Color3.fromRGB(180,180,180)
    circle.BorderSizePixel = 0
    circle.Parent = switchBG
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    local tweenOn = TweenService:Create(circle,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad),
        {Position = UDim2.new(0,23,0.5,-9), BackgroundColor3 = Color3.fromRGB(255,255,255)}
    )
    local tweenOff = TweenService:Create(circle,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad),
        {Position = UDim2.new(0,3,0.5,-9), BackgroundColor3 = Color3.fromRGB(180,180,180)}
    )
    local tweenBGOn = TweenService:Create(switchBG,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad),
        {BackgroundColor3 = Color3.fromRGB(50,150,80)}
    )
    local tweenBGOff = TweenService:Create(switchBG,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad),
        {BackgroundColor3 = Color3.fromRGB(60,60,75)}
    )

    btn.MouseButton1Click:Connect(function()
        toggleFunc()
        if States[stateKey] then
            tweenOn:Play()
            tweenBGOn:Play()
        else
            tweenOff:Play()
            tweenBGOff:Play()
        end
    end)
end

-- =====================
-- BUILD GUI ITEMS IN ORDER
-- =====================

-- Speed input THEN speed toggle
createInputBox("Walk Speed", 50, function(val)
    SpeedValue = val
    if States.Speed then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = val end
    end
end)
createToggleRow("Speed", toggleSpeed, "Speed")

-- Fly speed input THEN fly toggle
createInputBox("Fly Speed", 50, function(val)
    FlySpeed = val
end)
createToggleRow("Fly", toggleFly, "Fly")

-- Rest of toggles
createToggleRow("Infinite Jump", toggleInfiniteJump, "InfiniteJump")
createToggleRow("Anti-AFK", toggleAntiAFK, "AntiAFK")
createToggleRow("Fullbright", toggleFullbright, "Fullbright")
createToggleRow("ESP", toggleESP, "ESP")
createToggleRow("Noclip", toggleNoclip, "Noclip")

-- =====================
-- MINIMIZE
-- =====================
local minimized = false
local fullHeight = 530
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0,240,0,40) or UDim2.new(0,240,0,fullHeight)
    MinBtn.Text = minimized and "+" or "-"
end)

-- =====================
-- DRAGGING
-- =====================
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

print("[Universal Script] Loaded successfully!")

end)

if not success then
    warn("[Universal Script] Error: " .. tostring(err))
end
