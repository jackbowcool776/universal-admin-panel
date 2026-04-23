-- Universal Script by Claude
-- Fixed version with working tabs, drag and open/close

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

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = 2,
        })
    end)
end

-- =====================
-- FEATURES
-- =====================
local function toggleSpeed()
    States.Speed = not States.Speed
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = States.Speed and SpeedValue or OriginalWalkSpeed end
    notify("Speed", States.Speed and "ON" or "OFF")
end

local function toggleFly()
    States.Fly = not States.Fly
    local root = getRootPart()
    local hum = getHumanoid()
    if not root or not hum then return end
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
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
            bv.Velocity = dir * FlySpeed
            bg.CFrame = cam.CFrame
        end)
    else
        hum.PlatformStand = false
        if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
        for _, v in pairs(root:GetChildren()) do
            if v.Name == "FlyVelocity" or v.Name == "FlyGyro" then pcall(function() v:Destroy() end) end
        end
    end
    notify("Fly", States.Fly and "ON" or "OFF")
end

UserInputService.JumpRequest:Connect(function()
    if States.InfiniteJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
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

-- Chat commands
LocalPlayer.Chatted:Connect(function(msg)
    local args = string.lower(msg):split(" ")
    local cmd = args[1]
    if cmd == "!fly" then toggleFly()
    elseif cmd == "!speed" then toggleSpeed()
    elseif cmd == "!jump" then toggleInfiniteJump()
    elseif cmd == "!afk" then toggleAntiAFK()
    elseif cmd == "!bright" then toggleFullbright()
    elseif cmd == "!esp" then toggleESP()
    elseif cmd == "!noclip" then toggleNoclip()
    elseif cmd == "!rejoin" then rejoin()
    elseif cmd == "!tp" and args[2] then teleportToPlayer(args[2])
    elseif cmd == "!spec" and args[2] then spectatePlayer(args[2])
    end
end)

-- =====================
-- GUI
-- =====================
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalScript"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = game:GetService("CoreGui") end)

local COLORS = {
    bg = Color3.fromRGB(22,22,32),
    titlebar = Color3.fromRGB(14,14,22),
    tabbar = Color3.fromRGB(18,18,28),
    row = Color3.fromRGB(32,32,46),
    input = Color3.fromRGB(45,45,62),
    switchOff = Color3.fromRGB(55,55,72),
    switchOn = Color3.fromRGB(45,140,75),
    accent = Color3.fromRGB(70,110,210),
    text = Color3.fromRGB(220,220,220),
    subtext = Color3.fromRGB(140,140,170),
    cmdColor = Color3.fromRGB(100,180,255),
}

local OPEN_HEIGHT = 440
local CLOSED_HEIGHT = 42
local WIDTH = 260
local isOpen = true

-- Main frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, WIDTH, 0, OPEN_HEIGHT)
Main.Position = UDim2.new(0, 20, 0.3, 0)
Main.BackgroundColor3 = COLORS.bg
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Shadow effect
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5554236805"
shadow.ImageColor3 = Color3.fromRGB(0,0,0)
shadow.ImageTransparency = 0.6
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(23,23,277,277)
shadow.ZIndex = 0
shadow.Parent = Main

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, CLOSED_HEIGHT)
TitleBar.BackgroundColor3 = COLORS.titlebar
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 5
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -50, 1, 0)
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.TextColor3 = COLORS.text
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Text = "⚡ Universal Script"
TitleText.ZIndex = 6
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
OpenBtn.ZIndex = 6
OpenBtn.Parent = TitleBar
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 6)

-- Tab bar
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, 0, 0, 34)
TabBar.Position = UDim2.new(0, 0, 0, CLOSED_HEIGHT)
TabBar.BackgroundColor3 = COLORS.tabbar
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 4
TabBar.Parent = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Parent = TabBar

local TabPad = Instance.new("UIPadding")
TabPad.PaddingLeft = UDim.new(0, 6)
TabPad.Parent = TabBar

-- Content area (scrolling)
local ContentArea = Instance.new("ScrollingFrame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, 0, 1, -(CLOSED_HEIGHT + 34))
ContentArea.Position = UDim2.new(0, 0, 0, CLOSED_HEIGHT + 34)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.ScrollBarThickness = 3
ContentArea.ScrollBarImageColor3 = Color3.fromRGB(80,80,110)
ContentArea.CanvasSize = UDim2.new(0,0,0,0)
ContentArea.ZIndex = 3
ContentArea.Parent = Main

-- =====================
-- OPEN / CLOSE
-- =====================
OpenBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        {Size = UDim2.new(0, WIDTH, 0, isOpen and OPEN_HEIGHT or CLOSED_HEIGHT)}
    ):Play()
    OpenBtn.Text = isOpen and "▼" or "▲"
end)

-- =====================
-- DRAGGING (on title bar)
-- =====================
local dragging = false
local dragStart = nil
local frameStart = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        frameStart = Main.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                     input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            frameStart.X.Scale,
            frameStart.X.Offset + delta.X,
            frameStart.Y.Scale,
            frameStart.Y.Offset + delta.Y
        )
    end
end)

-- =====================
-- TAB SYSTEM
-- =====================
local tabData = {}
local activeTabName = nil

local function switchTab(name)
    for tname, tinfo in pairs(tabData) do
        tinfo.content.Visible = tname == name
        if tname == name then
            tinfo.btn.BackgroundColor3 = COLORS.accent
            tinfo.btn.TextColor3 = Color3.fromRGB(255,255,255)
        else
            tinfo.btn.BackgroundColor3 = Color3.fromRGB(35,35,50)
            tinfo.btn.TextColor3 = COLORS.subtext
        end
    end
    activeTabName = name
    ContentArea.CanvasPosition = Vector2.new(0,0)
end

local function newTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 58, 0, 26)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,50)
    btn.TextColor3 = COLORS.subtext
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Text = name
    btn.BorderSizePixel = 0
    btn.ZIndex = 5
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local content = Instance.new("Frame")
    content.Name = name.."Content"
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.Visible = false
    content.Parent = ContentArea

    local cLayout = Instance.new("UIListLayout")
    cLayout.Padding = UDim.new(0, 6)
    cLayout.Parent = content

    local cPad = Instance.new("UIPadding")
    cPad.PaddingTop = UDim.new(0, 8)
    cPad.PaddingLeft = UDim.new(0, 10)
    cPad.PaddingRight = UDim.new(0, 10)
    cPad.PaddingBottom = UDim.new(0, 8)
    cPad.Parent = content

    tabData[name] = {btn = btn, content = content}

    btn.MouseButton1Click:Connect(function()
        switchTab(name)
        -- update canvas size
        task.wait()
        local layout = content:FindFirstChildOfClass("UIListLayout")
        if layout then
            ContentArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end
    end)

    return content
end

-- =====================
-- HELPERS
-- =====================
local switchRefs = {}

local function makeSection(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = COLORS.subtext
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "── "..text:upper().." ──"
    lbl.Parent = parent
end

local function makeInput(parent, label, default, onChange)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 50)
    wrap.BackgroundColor3 = COLORS.row
    wrap.BorderSizePixel = 0
    wrap.Parent = parent
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = COLORS.subtext
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label..": "..tostring(default)
    lbl.Parent = wrap

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 0, 22)
    box.Position = UDim2.new(0, 10, 0, 24)
    box.BackgroundColor3 = COLORS.input
    box.TextColor3 = COLORS.text
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.Text = tostring(default)
    box.PlaceholderText = "Enter value..."
    box.BorderSizePixel = 0
    box.Parent = wrap
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

    box.FocusLost:Connect(function()
        local v = tonumber(box.Text)
        if v then
            lbl.Text = label..": "..v
            onChange(v)
        else
            box.Text = tostring(default)
        end
    end)
    return wrap
end

local function makeToggle(parent, label, toggleFn, stateKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = COLORS.row
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = COLORS.text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 44, 0, 24)
    bg.Position = UDim2.new(1, -52, 0.5, -12)
    bg.BackgroundColor3 = COLORS.switchOff
    bg.BorderSizePixel = 0
    bg.Parent = row
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    knob.BorderSizePixel = 0
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function updateVisual(on)
        TweenService:Create(knob, TweenInfo.new(0.15),
            {Position = on and UDim2.new(0,23,0.5,-9) or UDim2.new(0,3,0.5,-9),
             BackgroundColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)}):Play()
        TweenService:Create(bg, TweenInfo.new(0.15),
            {BackgroundColor3 = on and COLORS.switchOn or COLORS.switchOff}):Play()
    end

    if stateKey then switchRefs[stateKey] = updateVisual end

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = row
    clickBtn.MouseButton1Click:Connect(function()
        toggleFn()
        if stateKey then updateVisual(States[stateKey]) end
    end)
end

local function makeButton(parent, label, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = COLORS.accent
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = label
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

local function makePlayerPicker(parent)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 50)
    wrap.BackgroundColor3 = COLORS.row
    wrap.BorderSizePixel = 0
    wrap.Parent = parent
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = COLORS.subtext
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "Select Player:"
    lbl.Parent = wrap

    local selected = Instance.new("TextButton")
    selected.Size = UDim2.new(1, -20, 0, 22)
    selected.Position = UDim2.new(0, 10, 0, 24)
    selected.BackgroundColor3 = COLORS.input
    selected.TextColor3 = COLORS.text
    selected.Font = Enum.Font.Gotham
    selected.TextSize = 12
    selected.Text = "Click to pick player..."
    selected.BorderSizePixel = 0
    selected.Parent = wrap
    Instance.new("UICorner", selected).CornerRadius = UDim.new(0, 5)

    local chosenName = nil
    local dropFrame = nil
    local dropOpen = false

    selected.MouseButton1Click:Connect(function()
        if dropOpen and dropFrame then
            dropFrame:Destroy()
            dropFrame = nil
            dropOpen = false
            return
        end
        dropOpen = true

        local playerList = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(playerList, p.Name) end
        end

        dropFrame = Instance.new("Frame")
        dropFrame.Size = UDim2.new(1, -20, 0, math.min(#playerList, 5) * 28 + 8)
        dropFrame.Position = UDim2.new(0, 10, 1, 2)
        dropFrame.BackgroundColor3 = Color3.fromRGB(38,38,55)
        dropFrame.BorderSizePixel = 0
        dropFrame.ZIndex = 20
        dropFrame.Parent = wrap
        Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)

        local dl = Instance.new("UIListLayout")
        dl.Padding = UDim.new(0, 2)
        dl.Parent = dropFrame
        local dp = Instance.new("UIPadding")
        dp.PaddingTop = UDim.new(0,4)
        dp.PaddingLeft = UDim.new(0,4)
        dp.PaddingRight = UDim.new(0,4)
        dp.Parent = dropFrame

        if #playerList == 0 then
            local none = Instance.new("TextLabel")
            none.Size = UDim2.new(1,0,0,24)
            none.BackgroundTransparency = 1
            none.TextColor3 = COLORS.subtext
            none.Font = Enum.Font.Gotham
            none.TextSize = 12
            none.Text = "No other players"
            none.ZIndex = 21
            none.Parent = dropFrame
        end

        for _, name in pairs(playerList) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, 26)
            item.BackgroundColor3 = Color3.fromRGB(50,50,70)
            item.TextColor3 = COLORS.text
            item.Font = Enum.Font.Gotham
            item.TextSize = 12
            item.Text = name
            item.BorderSizePixel = 0
            item.ZIndex = 21
            item.Parent = dropFrame
            Instance.new("UICorner", item).CornerRadius = UDim.new(0,4)
            item.MouseButton1Click:Connect(function()
                chosenName = name
                selected.Text = name
                dropFrame:Destroy()
                dropFrame = nil
                dropOpen = false
            end)
        end
    end)

    return wrap, function() return chosenName end
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

makeSection(moveContent, "Fly")
makeInput(moveContent, "Fly Speed", 50, function(v) FlySpeed = v end)
makeToggle(moveContent, "Fly", toggleFly, "Fly")

makeSection(moveContent, "Jump")
makeInput(moveContent, "Jump Power", 50, function(v)
    local h = getHumanoid() if h then h.JumpPower = v end
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
makeSection(playerContent, "Teleport")
local _, getTpTarget = makePlayerPicker(playerContent)
makeButton(playerContent, "Teleport to Player", function()
    local t = getTpTarget()
    if t then teleportToPlayer(t) else notify("Teleport","Pick a player first!") end
end)

makeSection(playerContent, "Spectate")
local _, getSpecTarget = makePlayerPicker(playerContent)
makeButton(playerContent, "Spectate / Stop", function()
    local t = getSpecTarget()
    if t then spectatePlayer(t) else notify("Spectate","Pick a player first!") end
end)

makeSection(playerContent, "Server")
makeButton(playerContent, "🔄 Rejoin Server", function() rejoin() end)

-- COMMANDS TAB
local cmdsContent = newTab("💬 Cmds")
makeSection(cmdsContent, "Chat Commands")

local cmdList = {
    {"!fly", "Toggle fly mode"},
    {"!speed", "Toggle speed hack"},
    {"!jump", "Toggle infinite jump"},
    {"!afk", "Toggle anti-AFK"},
    {"!bright", "Toggle fullbright"},
    {"!esp", "Toggle ESP"},
    {"!noclip", "Toggle noclip"},
    {"!rejoin", "Rejoin the server"},
    {"!tp [name]", "Teleport to player"},
    {"!spec [name]", "Spectate a player"},
}

for _, c in pairs(cmdList) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = COLORS.row
    row.BorderSizePixel = 0
    row.Parent = cmdsContent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local cmd = Instance.new("TextLabel")
    cmd.Size = UDim2.new(1,-10,0,20)
    cmd.Position = UDim2.new(0,10,0,4)
    cmd.BackgroundTransparency = 1
    cmd.TextColor3 = COLORS.cmdColor
    cmd.Font = Enum.Font.GothamBold
    cmd.TextSize = 13
    cmd.TextXAlignment = Enum.TextXAlignment.Left
    cmd.Text = c[1]
    cmd.Parent = row

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1,-10,0,16)
    desc.Position = UDim2.new(0,10,0,24)
    desc.BackgroundTransparency = 1
    desc.TextColor3 = COLORS.subtext
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 11
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Text = c[2]
    desc.Parent = row
end

-- Start on Move tab
switchTab("🏃 Move")
task.wait()
local ml = tabData["🏃 Move"].content:FindFirstChildOfClass("UIListLayout")
if ml then ContentArea.CanvasSize = UDim2.new(0,0,0,ml.AbsoluteContentSize.Y+20) end

print("[Universal Script] Loaded! Use !fly, !speed etc in chat.")

end)

if not success then
    warn("[Universal Script] Error: "..tostring(err))
end
