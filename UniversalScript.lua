-- Universal Script by Claude
-- Main hub + separate Fly System window

-- Wait for game to fully load
task.wait(1)
pcall(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
end)
task.wait(0.5)

-- =====================
-- OWNER ONLY ACCESS
-- Only your UserId can use this script
-- =====================
local OWNER_ID = 5680334775  -- jackbowcool776

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local function isWhitelisted(userId)
    return userId == OWNER_ID
end

local function showAccessDenied()
    local gui = Instance.new("ScreenGui")
    gui.Name = "AccessDenied"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    pcall(function() gui.Parent = game:GetService("CoreGui") end)

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1,0,1,0)
    overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0
    overlay.Parent = gui

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0,400,0,240)
    box.Position = UDim2.new(0.5,-200,0.5,-120)
    box.BackgroundColor3 = Color3.fromRGB(18,18,26)
    box.BorderSizePixel = 0
    box.Parent = gui
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,12)

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1,0,0,6)
    topBar.BackgroundColor3 = Color3.fromRGB(200,40,40)
    topBar.BorderSizePixel = 0
    topBar.Parent = box
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0,12)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1,0,0,55)
    icon.Position = UDim2.new(0,0,0,16)
    icon.BackgroundTransparency = 1
    icon.TextColor3 = Color3.fromRGB(200,40,40)
    icon.Font = Enum.Font.GothamBlack
    icon.TextSize = 38
    icon.Text = "⛔"
    icon.Parent = box

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,28)
    title.Position = UDim2.new(0,0,0,72)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 22
    title.Text = "Access Denied"
    title.Parent = box

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1,-40,0,36)
    sub.Position = UDim2.new(0,20,0,104)
    sub.BackgroundTransparency = 1
    sub.TextColor3 = Color3.fromRGB(160,160,180)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 13
    sub.TextWrapped = true
    sub.Text = "You are not whitelisted. Contact the script owner for access."
    sub.Parent = box

    local idLbl = Instance.new("TextLabel")
    idLbl.Size = UDim2.new(1,-40,0,18)
    idLbl.Position = UDim2.new(0,20,0,144)
    idLbl.BackgroundTransparency = 1
    idLbl.TextColor3 = Color3.fromRGB(100,100,130)
    idLbl.Font = Enum.Font.GothamBold
    idLbl.TextSize = 12
    idLbl.Text = "Your UserId: "..tostring(LocalPlayer.UserId)
    idLbl.Parent = box

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,120,0,32)
    closeBtn.Position = UDim2.new(0.5,-60,0,192)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200,40,40)
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.Text = "Close"
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = box
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
end

-- Only the owner can use this script
-- Others can open it but see a permission denied screen
local isOwner = isWhitelisted(LocalPlayer.UserId)

-- Access granted
local success, err = pcall(function()


local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

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

-- Declared early so fly enable/disable functions can update the UI
local switchRefs = {}

local SpeedValue = 50
local FlySpeed = 50
-- Default Roblox JumpHeight is 7.2 — store the actual current value
local OriginalWalkSpeed = getHumanoid().WalkSpeed
local OriginalJumpHeight = getHumanoid().JumpHeight
local OriginalJumpPower = getHumanoid().JumpPower
local JumpPowerValue = OriginalJumpHeight -- use actual default, not hardcoded 50
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

-- forward declare fly UI updater and move tab fly box for syncing
local updateFlyWindow = nil
local moveTabFlyBox = nil

-- =====================
-- GOD MODE
-- Blocks damage remotes so server never receives damage signal
-- Only works on games that use client-side damage remotes
-- =====================
local godModeOn = false
local godModeConn = nil
local originalNamecall = nil
local blockedCount = 0

local function detectDamageRemotes()
    -- Scan for any remotes that look like damage remotes
    local found = {}
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("damage") or name:find("hurt") or name:find("kill")
            or name:find("hit") or name:find("dead") or name:find("death") then
                table.insert(found, obj:GetFullName())
            end
        end
    end
    return found
end

local function enableGodMode()
    godModeOn = true
    blockedCount = 0

    -- Check if any damage remotes exist first
    local remotes = detectDamageRemotes()
    if #remotes > 0 then
        notify("God Mode", "ON — found "..#remotes.." damage remote(s)!")
        for _, r in ipairs(remotes) do print("[GOD MODE] Blocking: "..r) end
    else
        notify("God Mode", "ON — no damage remotes found, may not work in this game")
        print("[GOD MODE] Warning: No damage remotes found — this game likely uses server-side damage")
    end

    -- Hook metatable to block damage remotes
    pcall(function()
        local mt = getrawmetatable(game)
        originalNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (method == "FireServer" or method == "InvokeServer") and godModeOn then
                local name = self.Name:lower()
                if name:find("damage") or name:find("hurt") or name:find("kill")
                or name:find("hit") or name:find("dead") or name:find("death") then
                    blockedCount = blockedCount + 1
                    print("[GOD MODE] Blocked: "..self:GetFullName())
                    return -- block it
                end
            end
            return originalNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

local function disableGodMode()
    godModeOn = false

    pcall(function()
        if originalNamecall then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__namecall = originalNamecall
            setreadonly(mt, true)
            originalNamecall = nil
        end
    end)

    if blockedCount > 0 then
        notify("God Mode", "OFF — blocked "..blockedCount.." damage signals!")
    else
        notify("God Mode", "OFF — no signals were blocked (game uses server-side damage)")
    end
    blockedCount = 0
end

-- =====================
-- FEATURES
-- =====================

-- Camera perspective functions
local function setThirdPerson()
    LocalPlayer.CameraMode = Enum.CameraMode.Classic
    -- Allow zooming by setting min/max zoom
    pcall(function()
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 128
    end)
    notify("Camera", "Third Person — scroll to zoom")
end

local function setFirstPerson()
    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    notify("Camera", "First Person locked")
end

local speedConn = nil
local function toggleSpeed()
    States.Speed = not States.Speed
    local h = getHumanoid()
    if States.Speed then
        if h then h.WalkSpeed = SpeedValue end
        -- Keep applying speed every frame since some games reset it
        if not speedConn then
            speedConn = RunService.Heartbeat:Connect(function()
                if not States.Speed then
                    speedConn:Disconnect()
                    speedConn = nil
                    return
                end
                local hum = getHumanoid()
                if hum and hum.WalkSpeed ~= SpeedValue then
                    hum.WalkSpeed = SpeedValue
                end
            end)
        end
    else
        if speedConn then speedConn:Disconnect() speedConn = nil end
        if h then h.WalkSpeed = OriginalWalkSpeed end
    end
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
    if switchRefs and switchRefs["Fly"] then switchRefs["Fly"](false) end
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
    if switchRefs and switchRefs["Fly"] then switchRefs["Fly"](true) end
end

local function toggleFly()
    if States.Fly then disableFly() else enableFly() end
    notify("Fly", States.Fly and "ON" or "OFF")
end

-- Fly keybind storage - single key only
local flyKeybind = nil -- e.g. "Q"

-- Listen for fly keybind globally - single key press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not flyKeybind then return end
    if input.KeyCode.Name == flyKeybind then
        toggleFly()
    end
end)

local function disableFlyUI()
    States.Fly = false
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
    if switchRefs and switchRefs["Fly"] then switchRefs["Fly"](false) end
    if updateFlyWindow then updateFlyWindow(false) end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    char:WaitForChild("Humanoid")

    -- Disable fly on respawn and update UI
    if States.Fly then
        disableFlyUI()
        notify("Fly", "Disabled on respawn")
    end

    -- Also hook death to turn off fly immediately when dying
    local hum = char:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        if States.Fly then
            disableFlyUI()
            notify("Fly", "Disabled on death")
        end
    end)

    task.wait(0.5)
    if States.Speed then
        local h = getHumanoid()
        if h then h.WalkSpeed = SpeedValue end
        if speedConn then speedConn:Disconnect() speedConn = nil end
        speedConn = RunService.Heartbeat:Connect(function()
            if not States.Speed then
                speedConn:Disconnect()
                speedConn = nil
                return
            end
            local hum = getHumanoid()
            if hum and hum.WalkSpeed ~= SpeedValue then
                hum.WalkSpeed = SpeedValue
            end
        end)
    end
    -- Always restore jump to correct value on respawn
    local h = getHumanoid()
    if h then
        if States.InfiniteJump or JumpPowerValue ~= OriginalJumpHeight then
            pcall(function() h.JumpHeight = JumpPowerValue end)
            pcall(function() h.JumpPower = JumpPowerValue end)
        else
            -- Restore to original defaults
            pcall(function() h.JumpHeight = OriginalJumpHeight end)
            pcall(function() h.JumpPower = OriginalJumpPower end)
        end
    end
end)

-- Also hook initial character death
local initHum = getHumanoid()
if initHum then
    initHum.Died:Connect(function()
        if States.Fly then
            disableFlyUI()
            notify("Fly", "Disabled on death")
        end
    end)
end

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

local FullbrightLevel = 2 -- default brightness level

local function toggleFullbright()
    States.Fullbright = not States.Fullbright
    if States.Fullbright then
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.Brightness = FullbrightLevel
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

local function teleportToPlayer(query)
    local queryLower = string.lower(query)
    local matches = {}

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local displayLower = string.lower(p.DisplayName)
            local userLower = string.lower(p.Name)
            if string.sub(displayLower, 1, #queryLower) == queryLower
            or string.sub(userLower, 1, #queryLower) == queryLower then
                local already = false
                for _, m in ipairs(matches) do
                    if m == p then already = true break end
                end
                if not already then
                    table.insert(matches, p)
                end
            end
        end
    end

    if #matches == 0 then
        notify("Teleport", "No player found matching '"..query.."'")
    elseif #matches > 1 then
        notify("Teleport", "Be more specific! ("..#matches.." players match)")
    else
        local target = matches[1]
        -- If character isn't loaded yet, wait up to 3 seconds for it
        if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
            notify("Teleport", "Waiting for "..target.DisplayName.."'s character...")
            task.spawn(function()
                local waited = 0
                while waited < 3 do
                    task.wait(0.2)
                    waited = waited + 0.2
                    if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        local root = getRootPart()
                        if root then
                            root.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
                            notify("Teleport", "Teleported to "..target.DisplayName)
                        end
                        return
                    end
                end
                notify("Teleport", target.DisplayName.." has no character — are they respawning?")
            end)
        else
            local root = getRootPart()
            if root then
                root.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
                notify("Teleport", "Teleported to "..target.DisplayName)
            end
        end
    end
end

local spectateConn = nil
local spectateTarget = nil
local originalCameraSubject = nil
local resetPickerCallback = nil -- set after player picker is created

local function stopSpectate()
    if spectateConn then
        spectateConn:Disconnect()
        spectateConn = nil
    end
    spectateTarget = nil
    originalCameraSubject = nil

    -- Retry restoring camera a few times to make sure it sticks
    task.spawn(function()
        for i = 1, 10 do
            task.wait(0.1)
            local char = getCharacter()
            local hum = getHumanoid()
            if char and hum then
                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = hum
                -- Double check it actually changed
                task.wait(0.05)
                if Camera.CameraSubject == hum then
                    break -- success
                end
            end
        end
    end)
    notify("Spectate", "Stopped spectating")
end

-- Instantly stop spectating when target leaves
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if spectateTarget and spectateTarget == leavingPlayer then
        notify("Spectate", leavingPlayer.DisplayName.." left — returning to your character")
        stopSpectate()
    end
    if resetPickerCallback then
        resetPickerCallback(leavingPlayer.Name)
    end
end)

local function spectatePlayer(name)
    -- If already spectating, stop
    if spectateConn then
        stopSpectate()
        return
    end

    local target = Players:FindFirstChild(name)
    if not target then
        notify("Spectate", "Player not found!")
        return
    end

    spectateTarget = target

    local function attachCamera()
        if not target or not target.Character then return end
        local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
        if not targetHum then return end
        originalCameraSubject = Camera.CameraSubject
        Camera.CameraType = Enum.CameraType.Custom
        Camera.CameraSubject = targetHum
    end

    -- Re-attach camera if subject gets lost (e.g. target respawns)
    spectateConn = RunService.Heartbeat:Connect(function()
        if not spectateTarget then return end
        if Camera.CameraSubject == nil or
           (Camera.CameraSubject and not Camera.CameraSubject.Parent) then
            attachCamera()
        end
    end)

    -- Re-attach when target respawns
    target.CharacterAdded:Connect(function()
        if spectateTarget == target then
            task.wait(0.5)
            attachCamera()
        end
    end)

    -- If character isn't ready, wait for it
    if not target.Character or not target.Character:FindFirstChildOfClass("Humanoid") then
        notify("Spectate", "Waiting for "..target.DisplayName.."'s character...")
        task.spawn(function()
            local waited = 0
            while waited < 5 do
                task.wait(0.2)
                waited = waited + 0.2
                if target.Character and target.Character:FindFirstChildOfClass("Humanoid") then
                    attachCamera()
                    notify("Spectate", "Spectating "..target.DisplayName)
                    return
                end
            end
            notify("Spectate", target.DisplayName.." still not loaded — try again")
            stopSpectate()
        end)
    else
        attachCamera()
        notify("Spectate", "Spectating "..target.DisplayName)
    end

end

local function rejoin()
    pcall(function()
        local TeleportService = game:GetService("TeleportService")
        -- Rejoin the exact same server using JobId
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end

local function resetCharacter()
    local hum = getHumanoid()
    if hum then
        hum.Health = 0
        notify("Reset", "Character reset!")
    end
end

local function serverHop()
    notify("Server Hop", "Finding a new server...")
    pcall(function()
        local TeleportService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        local placeId = game.PlaceId
        local currentJobId = game.JobId

        -- Fetch server list via Roblox API
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
        local response = HttpService:JSONDecode(game:HttpGet(url))

        if response and response.data then
            local servers = response.data
            -- shuffle so we don't always pick first
            for i = #servers, 2, -1 do
                local j = math.random(i)
                servers[i], servers[j] = servers[j], servers[i]
            end
            for _, server in ipairs(servers) do
                -- skip current server and full servers
                if server.id ~= currentJobId and server.playing < server.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                    return
                end
            end
            notify("Server Hop", "No open servers found!")
        else
            notify("Server Hop", "Failed to fetch servers!")
        end
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

-- Keybind row in fly window (syncs with move tab)
-- Built after makeKeybindRow is defined, using a placeholder for now
local FlyWinKeybindPlaceholder = Instance.new("Frame")
FlyWinKeybindPlaceholder.Size = UDim2.new(1,-36,0,52)
FlyWinKeybindPlaceholder.Position = UDim2.new(0,18,0,205)
FlyWinKeybindPlaceholder.BackgroundTransparency = 1
FlyWinKeybindPlaceholder.ZIndex = 101
FlyWinKeybindPlaceholder.Parent = FlyContent

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
        local displayStr = v == math.floor(v) and string.format("%.0f", v) or tostring(v)
        FlySpeedBox.Text = displayStr
        FlyActualLabel.Text = "Actual: "..displayStr.." studs/sec"
        if moveTabFlyBox then
            moveTabFlyBox.Text = displayStr
        end
    else
        FlySpeedBox.Text = tostring(FlySpeed)
    end
end)

-- Minimize fly window
FlyMinBtn.MouseButton1Click:Connect(function()
    flyMinimized = not flyMinimized
    FlyContent.Visible = not flyMinimized
    TweenService:Create(FlyWin, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        {Size = flyMinimized and UDim2.new(0,320,0,56) or UDim2.new(0,320,0,330)}):Play()
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


local TabBar = Instance.new("ScrollingFrame")
TabBar.Size = UDim2.new(1, 0, 0, 34)
TabBar.Position = UDim2.new(0, 0, 0, CLOSED_HEIGHT)
TabBar.BackgroundColor3 = COLORS.tabbar
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 9
TabBar.ScrollBarThickness = 0
TabBar.ScrollingDirection = Enum.ScrollingDirection.X
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
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

local function makeInput(parent, label, default, onChange, minVal, maxVal)
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

    local currentVal = default
    box.FocusLost:Connect(function()
        local v = tonumber(box.Text)
        if v then
            -- clamp to min/max if provided
            if minVal and v < minVal then v = minVal end
            if maxVal and v > maxVal then v = maxVal end
            currentVal = v
            -- Format as integer if it's a whole number to avoid 1e+28 style display
            local displayStr = v == math.floor(v) and string.format("%.0f", v) or tostring(v)
            box.Text = displayStr
            lbl.Text = label..": "..displayStr
            onChange(v)
        else
            -- not a number, reset to last valid value
            box.Text = tostring(currentVal)
        end
    end)
    return box
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
        if chosenName then
            local p = Players:FindFirstChild(chosenName)
            selBtn.Text = (p and p.DisplayName or chosenName).." ▾"
        else
            selBtn.Text = "Click to pick player ▾"
        end
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
            if p ~= LocalPlayer then table.insert(playerList, p) end
        end

        local PAD = 8
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
            for i, p in ipairs(playerList) do
                -- show display name, with username below if different
                local displayText = p.DisplayName
                if p.DisplayName ~= p.Name then
                    displayText = p.DisplayName.." (@"..p.Name..")"
                end

                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1,0,0,ITEM_H)
                item.BackgroundColor3 = COLORS.dropItem
                item.TextColor3 = COLORS.text
                item.Font = Enum.Font.Gotham
                item.TextSize = 12
                item.Text = displayText
                item.TextTruncate = Enum.TextTruncate.AtEnd
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
                    chosenName = p.Name -- store username for teleport/spectate functions
                    selBtn.Text = p.DisplayName.." ▾"
                    dropScroll.Visible = false
                    TweenService:Create(dropScroll, TweenInfo.new(0.15), {Size = UDim2.new(1,-20,0,0)}):Play()
                    TweenService:Create(outer, TweenInfo.new(0.15), {Size = UDim2.new(1,0,0,50)}):Play()
                    dropOpen = false
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

    -- Reset picker if a specific player left
    local function resetIfLeft(leavingUsername)
        if chosenName == leavingUsername then
            chosenName = nil
            selBtn.Text = "Click to pick player ▾"
            -- close dropdown if open
            if dropOpen then
                dropOpen = false
                dropScroll.Visible = false
                dropScroll.Size = UDim2.new(1,-20,0,0)
                outer.Size = UDim2.new(1,0,0,50)
            end
        end
    end

    return outer, function() return chosenName end, resetIfLeft
end

-- =====================
-- BUILD TABS
-- =====================

-- MOVE TAB
local moveContent = newTab("🏃 Move")
makeSection(moveContent, "Walk Speed")
local walkSpeedBox = makeInput(moveContent, "Walk Speed", 50, function(v)
    SpeedValue = v
    if States.Speed then local h = getHumanoid() if h then h.WalkSpeed = v end end
end, 1)
makeToggle(moveContent, "Speed", toggleSpeed, "Speed")
makeSection(moveContent, "Fly")
moveTabFlyBox = makeInput(moveContent, "Fly Speed", 50, function(v)
    FlySpeed = v
    if FlySpeedBox then
        FlySpeedBox.Text = tostring(v)
        FlyActualLabel.Text = "Actual: "..v.." studs/sec"
    end
end, 1)
makeToggle(moveContent, "Fly", toggleFly, "Fly")

-- Fly keybind row (shared logic, two instances)
local keybindDisplays = {}

local function makeKeybindRow(parent)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,50)
    row.BackgroundColor3 = COLORS.row
    row.BorderSizePixel = 0
    if parent then row.Parent = parent end
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1,-10,0,18)
    titleLbl.Position = UDim2.new(0,10,0,4)
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextColor3 = COLORS.subtext
    titleLbl.Font = Enum.Font.Gotham
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = "Fly Keybind — click box then press a key:"
    titleLbl.Parent = row

    local display = Instance.new("TextButton")
    display.Size = UDim2.new(1,-20,0,24)
    display.Position = UDim2.new(0,10,0,22)
    display.BackgroundColor3 = COLORS.input
    display.TextColor3 = COLORS.text
    display.Font = Enum.Font.GothamBold
    display.TextSize = 13
    display.Text = flyKeybind or "None"
    display.BorderSizePixel = 0
    display.Parent = row
    Instance.new("UICorner", display).CornerRadius = UDim.new(0,5)

    table.insert(keybindDisplays, display)

    local function syncDisplays()
        local txt = flyKeybind or "None"
        for _, d in ipairs(keybindDisplays) do
            d.Text = txt
            d.TextColor3 = COLORS.text
        end
    end

    local waiting = false

    display.MouseButton1Click:Connect(function()
        if waiting then return end
        waiting = true
        for _, d in ipairs(keybindDisplays) do
            d.Text = "Press a key..."
            d.TextColor3 = Color3.fromRGB(255,200,50)
        end

        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local keyName = input.KeyCode.Name
            if keyName == "Unknown" or keyName == "Return" or keyName == "Escape" then
                -- Escape = clear keybind
                if keyName == "Escape" then
                    flyKeybind = nil
                    notify("Fly Keybind", "Cleared")
                end
                waiting = false
                conn:Disconnect()
                syncDisplays()
                return
            end
            flyKeybind = keyName
            waiting = false
            conn:Disconnect()
            notify("Fly Keybind", "Set to: "..keyName)
            syncDisplays()
        end)
    end)

    return row
end

makeKeybindRow(moveContent)

-- Add keybind row to fly window
FlyWin.Size = UDim2.new(0, 320, 0, 330)
local flyMinimized = false

local flyWinKeybindRow = makeKeybindRow(FlyContent)
flyWinKeybindRow.Size = UDim2.new(1,-36,0,50)
flyWinKeybindRow.Position = UDim2.new(0,18,0,205)
flyWinKeybindRow.BackgroundColor3 = Color3.fromRGB(22,22,35)
flyWinKeybindRow.ZIndex = 101
for _, c in pairs(flyWinKeybindRow:GetDescendants()) do
    if c:IsA("GuiObject") then c.ZIndex = 101 end
end
makeSection(moveContent, "Jump")
makeInput(moveContent, "Jump Power", 50, function(v)
    JumpPowerValue = v
    local h = getHumanoid()
    if h then
        pcall(function() h.JumpHeight = v end)
        pcall(function() h.JumpPower = v end)
    end
end, 1)
makeToggle(moveContent, "Infinite Jump", toggleInfiniteJump, "InfiniteJump")
makeSection(moveContent, "Other")
makeToggle(moveContent, "Noclip", toggleNoclip, "Noclip")
makeToggle(moveContent, "Anti-AFK", toggleAntiAFK, "AntiAFK")

-- Click to Teleport
local clickTpKeybind = nil
local clickTpKeybindDisplays = {}

local function makeClickTpRow(parent)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,50)
    row.BackgroundColor3 = COLORS.row
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1,-10,0,18)
    titleLbl.Position = UDim2.new(0,10,0,4)
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextColor3 = COLORS.subtext
    titleLbl.Font = Enum.Font.Gotham
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = "Click-to-TP Keybind — click box then press a key:"
    titleLbl.Parent = row

    local display = Instance.new("TextButton")
    display.Size = UDim2.new(1,-20,0,24)
    display.Position = UDim2.new(0,10,0,22)
    display.BackgroundColor3 = COLORS.input
    display.TextColor3 = COLORS.text
    display.Font = Enum.Font.GothamBold
    display.TextSize = 13
    display.Text = clickTpKeybind or "None"
    display.BorderSizePixel = 0
    display.Parent = row
    Instance.new("UICorner", display).CornerRadius = UDim.new(0,5)

    table.insert(clickTpKeybindDisplays, display)

    local function syncDisplays()
        local txt = clickTpKeybind or "None"
        for _, d in ipairs(clickTpKeybindDisplays) do
            d.Text = txt
            d.TextColor3 = COLORS.text
        end
    end

    local waiting = false
    display.MouseButton1Click:Connect(function()
        if waiting then return end
        waiting = true
        for _, d in ipairs(clickTpKeybindDisplays) do
            d.Text = "Press a key..."
            d.TextColor3 = Color3.fromRGB(255,200,50)
        end
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local keyName = input.KeyCode.Name
            if keyName == "Unknown" or keyName == "Return" then return end
            if keyName == "Escape" then
                clickTpKeybind = nil
                notify("Click-TP Keybind", "Cleared")
            else
                clickTpKeybind = keyName
                notify("Click-TP Keybind", "Set to: "..keyName.." — aim and press to teleport!")
            end
            waiting = false
            conn:Disconnect()
            syncDisplays()
        end)
    end)

    return row
end

makeSection(moveContent, "Click to Teleport")
makeClickTpRow(moveContent)

-- Freeze on teleport toggle and duration
local freezeOnTp = false
local freezeDuration = 2

States.FreezeOnTp = false
makeToggle(moveContent, "Freeze on Teleport", function()
    States.FreezeOnTp = not States.FreezeOnTp
    freezeOnTp = States.FreezeOnTp
    notify("Freeze on TP", freezeOnTp and "ON" or "OFF")
end, "FreezeOnTp")

makeInput(moveContent, "Freeze Duration (1-5 sec)", 2, function(v)
    freezeDuration = v
end, 1, 5)

makeSection(moveContent, "Protection")
States.GodMode = false
makeToggle(moveContent, "🛡️ God Mode", function()
    States.GodMode = not States.GodMode
    if States.GodMode then enableGodMode() else disableGodMode() end
end, "GodMode")

-- Listen for click-to-tp keybind
local freezeBodyPos = nil

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not isOwner then return end
    if gameProcessed then return end

    -- Right click cancels nothing now (no marker to clear)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if not clickTpKeybind then return end
    if input.KeyCode.Name ~= clickTpKeybind then return end

    local root = getRootPart()
    if not root then return end

    -- Get mouse ray
    local mouse = LocalPlayer:GetMouse()
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {getCharacter()}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local mouseOrigin = mouse.UnitRay.Origin
    local mouseDir = mouse.UnitRay.Direction
    local rayOrigin = mouseOrigin + mouseDir * 10
    local result = workspace:Raycast(rayOrigin, mouseDir * 100000, raycastParams)

    local targetPos
    if result then
        targetPos = result.Position + (result.Normal * 0.1)
    else
        targetPos = mouse.Hit.Position
    end

    -- Offset up by hip height so feet land at target
    local charHeight = 3
    local hum = getHumanoid()
    if hum then
        pcall(function() charHeight = hum.HipHeight + 1.5 end)
    end
    local finalPos = targetPos + Vector3.new(0, charHeight, 0)

    root.CFrame = CFrame.new(finalPos, finalPos + root.CFrame.LookVector)
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    notify("Teleport", "Teleported!")

    if freezeOnTp then
        if hum then
            if freezeBodyPos then pcall(function() freezeBodyPos:Destroy() end) freezeBodyPos = nil end
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            pcall(function() hum.JumpHeight = 0 end)
            task.wait(0.05)
            local r = getRootPart()
            if r then
                local bp = Instance.new("BodyPosition")
                bp.Name = "FreezePos"
                bp.Position = r.Position
                bp.MaxForce = Vector3.new(1e9,1e9,1e9)
                bp.P = 1e4
                bp.D = 1e3
                bp.Parent = r
                freezeBodyPos = bp
                r.AssemblyLinearVelocity = Vector3.zero
            end
            notify("Frozen", "Frozen for "..freezeDuration.."s")
            task.delay(freezeDuration, function()
                if freezeBodyPos then pcall(function() freezeBodyPos:Destroy() end) freezeBodyPos = nil end
                local h = getHumanoid()
                if h then
                    h.WalkSpeed = States.Speed and SpeedValue or OriginalWalkSpeed
                    h.JumpPower = JumpPowerValue or OriginalJumpPower
                    pcall(function() h.JumpHeight = JumpPowerValue or OriginalJumpHeight end)
                end
                notify("Frozen", "Unfrozen!")
            end)
        end
    end
end)

-- WORLD TAB
local worldContent = newTab("🌍 World")
makeSection(worldContent, "Visuals")
makeToggle(worldContent, "Fullbright", toggleFullbright, "Fullbright")
makeInput(worldContent, "Brightness (0.1-10)", 2, function(v)
    FullbrightLevel = v
    if States.Fullbright then
        Lighting.Brightness = FullbrightLevel
    end
end, 0.1, 10)
makeToggle(worldContent, "ESP", toggleESP, "ESP")
makeSection(worldContent, "Gravity")
makeInput(worldContent, "Gravity", 196, function(v) workspace.Gravity = v end, 0)
makeSection(worldContent, "Time of Day")
makeInput(worldContent, "Clock Time (0-24)", 14, function(v)
    Lighting.ClockTime = v
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") then
            pcall(function() obj.Disabled = true end)
        end
    end
    Lighting.Brightness = Lighting.Brightness
end, 0, 24)
makeSection(worldContent, "Camera")
makeInput(worldContent, "FOV", 70, function(v) Camera.FieldOfView = v end, 1, 120)
makeSection(worldContent, "FPS")
makeInput(worldContent, "FPS Cap", 144, function(v) pcall(function() setfpscap(v) end) end, 1)

-- PLAYER TAB
local playerContent = newTab("👤 Player")
makeSection(playerContent, "Select a Player")
local _, getTarget, resetPicker = makePlayerPicker(playerContent)
resetPickerCallback = resetPicker
makeButton(playerContent, "🚀 Teleport to Player", function()
    local t = getTarget()
    if t then teleportToPlayer(t) else notify("Teleport","Pick a player first!") end
end)
-- Spectate button - updates dynamically
local spectateBtn = Instance.new("TextButton")
spectateBtn.Size = UDim2.new(1,0,0,34)
spectateBtn.BackgroundColor3 = COLORS.accent
spectateBtn.TextColor3 = Color3.fromRGB(255,255,255)
spectateBtn.Font = Enum.Font.GothamBold
spectateBtn.TextSize = 13
spectateBtn.Text = "👁 Spectate"
spectateBtn.BorderSizePixel = 0
spectateBtn.Parent = playerContent
Instance.new("UICorner", spectateBtn).CornerRadius = UDim.new(0,8)

local function updateSpectateBtn(isSpectating)
    if isSpectating then
        spectateBtn.Text = "🛑 Stop Spectate"
        spectateBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
    else
        spectateBtn.Text = "👁 Spectate"
        spectateBtn.BackgroundColor3 = COLORS.accent
    end
end

spectateBtn.MouseButton1Click:Connect(function()
    if spectateConn then
        stopSpectate()
        updateSpectateBtn(false)
    else
        local t = getTarget()
        if t then
            spectatePlayer(t)
            updateSpectateBtn(true)
        else
            notify("Spectate", "Pick a player first!")
        end
    end
end)

-- Also reset button when player leaves mid-spectate
local _origStopSpectate = stopSpectate
stopSpectate = function()
    _origStopSpectate()
    updateSpectateBtn(false)
end
makeSection(playerContent, "Server")
makeButton(playerContent, "🔄 Rejoin Same Server", function() rejoin() end)
makeButton(playerContent, "🌐 Server Hop", function() serverHop() end, Color3.fromRGB(120,60,180))
makeButton(playerContent, "💀 Reset Character", function() resetCharacter() end, Color3.fromRGB(180,50,50))

-- COMMANDS TAB
local cmdsContent = newTab("💬 Cmds")
makeSection(cmdsContent, "Click to copy")

local cmdList = {
    {"!god",                "Toggle god mode"},
    {"!speed set [num]",    "Set speed e.g. !speed set 100"},
    {"!jumppower set [num]","Set jump power e.g. !jumppower set 20"},
    {"!infjump",            "Toggle infinite jump"},
    {"!thirdp",             "Force third person"},
    {"!firstp",             "Lock first person"},
    {"!afk",                "Toggle anti-AFK"},
    {"!bright",             "Toggle fullbright"},
    {"!esp",                "Toggle ESP"},
    {"!noclip",             "Turn noclip ON"},
    {"!unnoclip",           "Turn noclip OFF"},
    {"!rejoin",             "Rejoin same server"},
    {"!serverhop",          "Server hop to new server"},
    {"!reset",              "Reset your character"},
    {"!to [name]",          "Teleport by display name"},
    {"!spectate [name]",    "Spectate a player"},
    {"!unspectate",         "Stop spectating"},
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

-- WHITELIST TAB (owner only)
if isOwner then
    -- Create tab button same as others
    local wlBtn = Instance.new("TextButton")
    wlBtn.Size = UDim2.new(0, 58, 0, 26)
    wlBtn.BackgroundColor3 = Color3.fromRGB(35,35,50)
    wlBtn.TextColor3 = COLORS.subtext
    wlBtn.Font = Enum.Font.GothamBold
    wlBtn.TextSize = 9
    wlBtn.Text = "🔒 WL"
    wlBtn.BorderSizePixel = 0
    wlBtn.ZIndex = 10
    wlBtn.Parent = TabBar
    Instance.new("UICorner", wlBtn).CornerRadius = UDim.new(0,6)

    -- Fixed frame directly on Main so it doesn't scroll with ScrollArea
    local wlFrame = Instance.new("Frame")
    wlFrame.Size = UDim2.new(1,0,1,-(CLOSED_HEIGHT+34))
    wlFrame.Position = UDim2.new(0,0,0,CLOSED_HEIGHT+34)
    wlFrame.BackgroundTransparency = 1
    wlFrame.Visible = false
    wlFrame.ZIndex = 8
    wlFrame.Parent = Main

    local wlMainLayout = Instance.new("UIListLayout")
    wlMainLayout.Padding = UDim.new(0,6)
    wlMainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    wlMainLayout.Parent = wlFrame

    local wlMainPad = Instance.new("UIPadding")
    wlMainPad.PaddingTop = UDim.new(0,8)
    wlMainPad.PaddingLeft = UDim.new(0,10)
    wlMainPad.PaddingRight = UDim.new(0,10)
    wlMainPad.PaddingBottom = UDim.new(0,8)
    wlMainPad.Parent = wlFrame

    -- Register in tabData
    tabData["🔒 WL"] = {btn=wlBtn, content=Instance.new("Frame")} -- dummy content
    wlBtn.MouseButton1Click:Connect(function()
        -- Hide all other tabs
        for tname, tinfo in pairs(tabData) do
            tinfo.content.Visible = false
            tinfo.btn.BackgroundColor3 = Color3.fromRGB(35,35,50)
            tinfo.btn.TextColor3 = COLORS.subtext
        end
        ScrollArea.Visible = false
        wlFrame.Visible = true
        wlBtn.BackgroundColor3 = COLORS.accent
        wlBtn.TextColor3 = Color3.fromRGB(255,255,255)
    end)

    -- Also make other tabs hide wlFrame
    local origSwitchTab = switchTab
    switchTab = function(name)
        wlFrame.Visible = false
        ScrollArea.Visible = true
        wlBtn.BackgroundColor3 = Color3.fromRGB(35,35,50)
        wlBtn.TextColor3 = COLORS.subtext
        origSwitchTab(name)
    end

    local function makeWLSection(text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1,0,0,14)
        l.BackgroundTransparency = 1
        l.TextColor3 = COLORS.subtext
        l.Font = Enum.Font.GothamBold
        l.TextSize = 10
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = "── "..text:upper().." ──"
        l.ZIndex = 9
        l.Parent = wlFrame
        return l
    end

    -- Runtime whitelist: stores {id=number, name=string}
    local runtimeWhitelist = {}

    makeWLSection("Whitelisted Players")

    local wlScroll = Instance.new("ScrollingFrame")
    wlScroll.Size = UDim2.new(1,0,0,130)
    wlScroll.BackgroundColor3 = COLORS.row
    wlScroll.BorderSizePixel = 0
    wlScroll.ScrollBarThickness = 3
    wlScroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,110)
    wlScroll.CanvasSize = UDim2.new(0,0,0,0)
    wlScroll.ScrollingEnabled = true
    wlScroll.Parent = wlFrame
    Instance.new("UICorner", wlScroll).CornerRadius = UDim.new(0,8)

    local wlLayout = Instance.new("UIListLayout")
    wlLayout.Padding = UDim.new(0,4)
    wlLayout.Parent = wlScroll
    local wlPad = Instance.new("UIPadding")
    wlPad.PaddingTop = UDim.new(0,6)
    wlPad.PaddingLeft = UDim.new(0,8)
    wlPad.PaddingRight = UDim.new(0,8)
    wlPad.PaddingBottom = UDim.new(0,6)
    wlPad.Parent = wlScroll

    local function rebuildWLList()
        for _, c in pairs(wlScroll:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
        end
        if #runtimeWhitelist == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1,0,0,24)
            empty.BackgroundTransparency = 1
            empty.TextColor3 = COLORS.subtext
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 12
            empty.Text = "No players whitelisted yet"
            empty.Parent = wlScroll
        else
            for i, entry in ipairs(runtimeWhitelist) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1,0,0,28)
                row.BackgroundColor3 = COLORS.input
                row.BorderSizePixel = 0
                row.Parent = wlScroll
                Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)

                local idLbl = Instance.new("TextLabel")
                idLbl.Size = UDim2.new(1,-42,1,0)
                idLbl.Position = UDim2.new(0,8,0,0)
                idLbl.BackgroundTransparency = 1
                idLbl.TextColor3 = COLORS.text
                idLbl.Font = Enum.Font.GothamBold
                idLbl.TextSize = 12
                idLbl.TextXAlignment = Enum.TextXAlignment.Left
                -- Show name if available, otherwise show ID
                idLbl.Text = entry.name ~= "" and entry.name.." ("..entry.id..")" or tostring(entry.id)
                idLbl.Parent = row

                local removeBtn = Instance.new("TextButton")
                removeBtn.Size = UDim2.new(0,32,0,20)
                removeBtn.Position = UDim2.new(1,-36,0.5,-10)
                removeBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
                removeBtn.TextColor3 = Color3.fromRGB(255,255,255)
                removeBtn.Font = Enum.Font.GothamBold
                removeBtn.TextSize = 12
                removeBtn.Text = "X"
                removeBtn.BorderSizePixel = 0
                removeBtn.Parent = row
                Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0,5)

                local idx = i
                removeBtn.MouseButton1Click:Connect(function()
                    local removed = runtimeWhitelist[idx]
                    table.remove(runtimeWhitelist, idx)
                    notify("Whitelist", "Removed "..(removed.name ~= "" and removed.name or tostring(removed.id)))
                    rebuildWLList()
                end)
            end
        end
        task.wait()
        wlScroll.CanvasSize = UDim2.new(0,0,0,wlLayout.AbsoluteContentSize.Y + 12)
    end

    rebuildWLList()

    -- Add by UserId
    makeWLSection("Add by UserId")

    local addRow = Instance.new("Frame")
    addRow.Size = UDim2.new(1,0,0,34)
    addRow.BackgroundColor3 = COLORS.row
    addRow.BorderSizePixel = 0
    addRow.Parent = wlFrame
    Instance.new("UICorner", addRow).CornerRadius = UDim.new(0,8)

    local addBox = Instance.new("TextBox")
    addBox.Size = UDim2.new(1,-82,0,26)
    addBox.Position = UDim2.new(0,4,0.5,-13)
    addBox.BackgroundColor3 = COLORS.input
    addBox.TextColor3 = COLORS.text
    addBox.Font = Enum.Font.GothamBold
    addBox.TextSize = 13
    addBox.Text = ""
    addBox.PlaceholderText = "Enter UserId..."
    addBox.BorderSizePixel = 0
    addBox.ClearTextOnFocus = false
    addBox.Parent = addRow
    Instance.new("UICorner", addBox).CornerRadius = UDim.new(0,6)

    local addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(0,70,0,26)
    addBtn.Position = UDim2.new(1,-74,0.5,-13)
    addBtn.BackgroundColor3 = COLORS.switchOn
    addBtn.TextColor3 = Color3.fromRGB(255,255,255)
    addBtn.Font = Enum.Font.GothamBold
    addBtn.TextSize = 12
    addBtn.Text = "Add"
    addBtn.BorderSizePixel = 0
    addBtn.Parent = addRow
    Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0,6)

    -- Numbers only
    addBox.Changed:Connect(function(prop)
        if prop == "Text" then
            local filtered = addBox.Text:gsub("[^%d]", "")
            if filtered ~= addBox.Text then addBox.Text = filtered end
        end
    end)

    local function tryAddUser(text)
        local id = tonumber(text)
        if not id then notify("Whitelist", "Enter a valid UserId number!") return end
        if id == OWNER_ID then notify("Whitelist", "That's you — you already have access!") return end
        for _, entry in ipairs(runtimeWhitelist) do
            if entry.id == id then notify("Whitelist", id.." already whitelisted!") return end
        end
        -- Try to find their name from players in server
        local name = ""
        for _, p in pairs(Players:GetPlayers()) do
            if p.UserId == id then name = p.DisplayName break end
        end
        table.insert(runtimeWhitelist, {id=id, name=name})
        addBox.Text = ""
        notify("Whitelist", "Added "..(name ~= "" and name or tostring(id)).."!")
        rebuildWLList()
    end

    addBtn.MouseButton1Click:Connect(function() tryAddUser(addBox.Text) end)
    addBox.FocusLost:Connect(function(enter) if enter then tryAddUser(addBox.Text) end end)

    -- Players in server
    makeWLSection("Players in Server")

    local paScroll = Instance.new("ScrollingFrame")
    paScroll.Size = UDim2.new(1,0,0,140)
    paScroll.BackgroundColor3 = COLORS.row
    paScroll.BorderSizePixel = 0
    paScroll.ScrollBarThickness = 3
    paScroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,110)
    paScroll.CanvasSize = UDim2.new(0,0,0,0)
    paScroll.ScrollingEnabled = true
    paScroll.Parent = wlFrame
    Instance.new("UICorner", paScroll).CornerRadius = UDim.new(0,8)

    local paLayout = Instance.new("UIListLayout")
    paLayout.Padding = UDim.new(0,4)
    paLayout.Parent = paScroll
    local paPad = Instance.new("UIPadding")
    paPad.PaddingTop = UDim.new(0,6)
    paPad.PaddingLeft = UDim.new(0,8)
    paPad.PaddingRight = UDim.new(0,8)
    paPad.PaddingBottom = UDim.new(0,6)
    paPad.Parent = paScroll

    local function buildPlayerList()
        for _, c in pairs(paScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local pRow = Instance.new("Frame")
            pRow.Size = UDim2.new(1,0,0,28)
            pRow.BackgroundColor3 = COLORS.input
            pRow.BorderSizePixel = 0
            pRow.Parent = paScroll
            Instance.new("UICorner", pRow).CornerRadius = UDim.new(0,6)

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1,-80,1,0)
            nameLbl.Position = UDim2.new(0,8,0,0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.TextColor3 = COLORS.text
            nameLbl.Font = Enum.Font.Gotham
            nameLbl.TextSize = 11
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Text = p.DisplayName.." ("..p.UserId..")"
            nameLbl.Parent = pRow

            local alreadyIn = false
            for _, entry in ipairs(runtimeWhitelist) do
                if entry.id == p.UserId then alreadyIn = true break end
            end

            local pBtn = Instance.new("TextButton")
            pBtn.Size = UDim2.new(0,72,0,20)
            pBtn.Position = UDim2.new(1,-76,0.5,-10)
            pBtn.BackgroundColor3 = alreadyIn and Color3.fromRGB(180,40,40) or COLORS.switchOn
            pBtn.TextColor3 = Color3.fromRGB(255,255,255)
            pBtn.Font = Enum.Font.GothamBold
            pBtn.TextSize = 11
            pBtn.Text = alreadyIn and "Remove" or "Add"
            pBtn.BorderSizePixel = 0
            pBtn.Parent = pRow
            Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0,5)

            pBtn.MouseButton1Click:Connect(function()
                local found = false
                for i, entry in ipairs(runtimeWhitelist) do
                    if entry.id == p.UserId then
                        table.remove(runtimeWhitelist, i)
                        found = true break
                    end
                end
                if found then
                    pBtn.Text = "Add"
                    pBtn.BackgroundColor3 = COLORS.switchOn
                    notify("Whitelist", p.DisplayName.." removed!")
                else
                    table.insert(runtimeWhitelist, {id=p.UserId, name=p.DisplayName})
                    pBtn.Text = "Remove"
                    pBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
                    notify("Whitelist", p.DisplayName.." added!")
                end
                rebuildWLList()
            end)
        end
        task.wait()
        paScroll.CanvasSize = UDim2.new(0,0,0,paLayout.AbsoluteContentSize.Y + 12)
    end

    buildPlayerList()

    local lastRefresh = 0
    RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastRefresh < 1 then return end
        lastRefresh = now
        buildPlayerList()
    end)

    Players.PlayerAdded:Connect(function() buildPlayerList() end)
    Players.PlayerRemoving:Connect(function() buildPlayerList() end)

    local originalIsWhitelisted = isWhitelisted
    isWhitelisted = function(userId)
        if originalIsWhitelisted(userId) then return true end
        for _, entry in ipairs(runtimeWhitelist) do
            if entry.id == userId then return true end
        end
        return false
    end
end

-- =====================
-- CHAT COMMANDS
-- =====================
LocalPlayer.Chatted:Connect(function(msg)
    if not isOwner then return end
    local args = string.lower(msg):split(" ")
    local cmd = args[1]
    if cmd == "!fly" then
        FlyWin.Visible = true
        FlyWin.Parent = gui -- re-parent to bring to front
        toggleFly()
    elseif cmd == "!speed" then
        if args[2] == "set" and tonumber(args[3]) then
            local val = tonumber(args[3])
            if val >= 1 then
                SpeedValue = val
                if walkSpeedBox then
                    local displayStr = val == math.floor(val) and string.format("%.0f", val) or tostring(val)
                    walkSpeedBox.Text = displayStr
                end
                if not States.Speed then
                    toggleSpeed()
                    if switchRefs["Speed"] then switchRefs["Speed"](true) end
                else
                    local h = getHumanoid()
                    if h then h.WalkSpeed = val end
                end
                notify("Speed", "Set to "..val.." — ON")
            end
        else
            notify("Speed", "Usage: !speed set [number] e.g. !speed set 100")
        end
    elseif cmd == "!jumppower" then
        if args[2] == "set" and tonumber(args[3]) then
            local val = tonumber(args[3])
            if val >= 1 then
                JumpPowerValue = val
                local h = getHumanoid()
                if h then
                    h.JumpPower = val
                    pcall(function() h.JumpHeight = val end)
                end
                notify("Jump Power", "Set to "..val)
            end
        else
            notify("Jump Power", "Usage: !jumppower set [number] e.g. !jumppower set 20")
        end
    elseif cmd == "!god" then
        States.GodMode = not States.GodMode
        if States.GodMode then enableGodMode() else disableGodMode() end
        if switchRefs["GodMode"] then switchRefs["GodMode"](States.GodMode) end
    elseif cmd == "!infjump" then
        toggleInfiniteJump()
        if switchRefs["InfiniteJump"] then switchRefs["InfiniteJump"](States.InfiniteJump) end
    elseif cmd == "!afk" then
        toggleAntiAFK()
        if switchRefs["AntiAFK"] then switchRefs["AntiAFK"](States.AntiAFK) end
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
    elseif cmd == "!thirdp" then setThirdPerson()
    elseif cmd == "!firstp" then setFirstPerson()
    elseif cmd == "!rejoin" then rejoin()
    elseif cmd == "!reset" then resetCharacter()
    elseif cmd == "!serverhop" then serverHop()
    elseif cmd == "!to" and args[2] then teleportToPlayer(args[2])
    elseif cmd == "!spectate" and args[2] then
        if spectateConn then
            stopSpectate()
            updateSpectateBtn(false)
        else
            -- search by partial display name or username like !to
            local query = string.lower(args[2])
            local matches = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local displayLower = string.lower(p.DisplayName)
                    local userLower = string.lower(p.Name)
                    if string.sub(displayLower, 1, #query) == query
                    or string.sub(userLower, 1, #query) == query then
                        local already = false
                        for _, m in ipairs(matches) do
                            if m == p then already = true break end
                        end
                        if not already then table.insert(matches, p) end
                    end
                end
            end
            if #matches == 0 then
                notify("Spectate", "No player found matching '"..args[2].."'")
            elseif #matches > 1 then
                notify("Spectate", "Be more specific! ("..#matches.." players match)")
            else
                spectatePlayer(matches[1].Name)
                updateSpectateBtn(true)
            end
        end
    elseif cmd == "!unspectate" then
        if spectateConn then
            stopSpectate()
            updateSpectateBtn(false)
        else
            notify("Spectate", "Not currently spectating anyone")
        end
    elseif cmd == "!spec" and args[2] then
        if spectateConn then stopSpectate()
        else spectatePlayer(args[2]) end
    end
end)

switchTab("🏃 Move")

-- Show permission denied overlay if not owner
if not isOwner then
    local denyGui = Instance.new("ScreenGui")
    denyGui.Name = "PermissionDenied"
    denyGui.ResetOnSpawn = false
    denyGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    denyGui.DisplayOrder = 999
    pcall(function() denyGui.Parent = game:GetService("CoreGui") end)

    local denyOverlay = Instance.new("Frame")
    denyOverlay.Size = UDim2.new(0, 380, 0, 220)
    denyOverlay.Position = UDim2.new(0.5, -190, 0.5, -110)
    denyOverlay.BackgroundColor3 = Color3.fromRGB(210, 55, 55)
    denyOverlay.BackgroundTransparency = 0
    denyOverlay.BorderSizePixel = 0
    denyOverlay.ZIndex = 200
    denyOverlay.Parent = denyGui
    Instance.new("UICorner", denyOverlay).CornerRadius = UDim.new(0, 14)

    -- Darker red outline
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(130, 20, 20)
    stroke.Thickness = 3
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = denyOverlay

    local lockIcon = Instance.new("TextLabel")
    lockIcon.Size = UDim2.new(1, 0, 0, 60)
    lockIcon.Position = UDim2.new(0, 0, 0, 12)
    lockIcon.BackgroundTransparency = 1
    lockIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    lockIcon.Font = Enum.Font.GothamBlack
    lockIcon.TextSize = 42
    lockIcon.Text = "🔒"
    lockIcon.ZIndex = 201
    lockIcon.Parent = denyOverlay

    local denyTitle = Instance.new("TextLabel")
    denyTitle.Size = UDim2.new(1, -24, 0, 50)
    denyTitle.Position = UDim2.new(0, 12, 0, 76)
    denyTitle.BackgroundTransparency = 1
    denyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    denyTitle.Font = Enum.Font.GothamBlack
    denyTitle.TextSize = 17
    denyTitle.Text = "You do not have permission\nto use this script"
    denyTitle.TextWrapped = true
    denyTitle.ZIndex = 201
    denyTitle.Parent = denyOverlay

    local denyId = Instance.new("TextLabel")
    denyId.Size = UDim2.new(1, -24, 0, 36)
    denyId.Position = UDim2.new(0, 12, 0, 170)
    denyId.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    denyId.BackgroundTransparency = 0
    denyId.TextColor3 = Color3.fromRGB(255, 255, 255)
    denyId.Font = Enum.Font.GothamBold
    denyId.TextSize = 16
    denyId.Text = "Your UserId: "..tostring(LocalPlayer.UserId)
    denyId.BorderSizePixel = 0
    denyId.ZIndex = 201
    denyId.Parent = denyOverlay
    Instance.new("UICorner", denyId).CornerRadius = UDim.new(0, 6)

    -- Also hide the main script GUI
    gui.Enabled = false
end

print("[Universal Script] Loaded! Press 🚀 button on the hub to show/hide Fly System.")

end)

if not success then
    warn("[Universal Script] Error: "..tostring(err))
end
