-- Universal Hub Beta
-- Modernized Version with Fly, Visible, and ESP Fixes (Updated March 16, 2025)

-- Kontroller
if not game then error("Game object is not available") end
local success, Players = pcall(game.GetService, game, "Players")
if not success or not Players then error("Players service is not available") end
local success, UserInputService = pcall(game.GetService, game, "UserInputService")
if not success or not UserInputService then error("UserInputService is not available") end
local success, RunService = pcall(game.GetService, game, "RunService")
if not success or not RunService then error("RunService is not available") end
local success, StarterGui = pcall(game.GetService, game, "StarterGui")
if not success or not StarterGui then error("StarterGui is not available") end
local success, TweenService = pcall(game.GetService, game, "TweenService")
if not success or not TweenService then error("TweenService is not available") end
local success, Lighting = pcall(game.GetService, game, "Lighting")
if not success or not Lighting then error("Lighting service is not available") end

local player = Players.LocalPlayer
local character = player.Character
if not character then
    character = player.CharacterAdded:Wait()
end
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local mouse = player:GetMouse()

-- Device detection (Mobil mi PC mi?)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local deviceType = nil

-- Mobil/PC seçim ekranı
local function askDeviceType()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DeviceSelectionGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    frame.Parent = screenGui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Select Device Type"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = frame

    local pcButton = Instance.new("TextButton")
    pcButton.Size = UDim2.new(0, 120, 0, 40)
    pcButton.Position = UDim2.new(0, 30, 0, 60)
    pcButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    pcButton.Text = "PC"
    pcButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    pcButton.TextSize = 16
    pcButton.Font = Enum.Font.Gotham
    local pcCorner = Instance.new("UICorner")
    pcCorner.CornerRadius = UDim.new(0, 5)
    pcCorner.Parent = pcButton
    pcButton.Parent = frame

    local mobileButton = Instance.new("TextButton")
    mobileButton.Size = UDim2.new(0, 120, 0, 40)
    mobileButton.Position = UDim2.new(0, 150, 0, 60)
    mobileButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    mobileButton.Text = "Mobile"
    mobileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    mobileButton.TextSize = 16
    mobileButton.Font = Enum.Font.Gotham
    local mobileCorner = Instance.new("UICorner")
    mobileCorner.CornerRadius = UDim.new(0, 5)
    mobileCorner.Parent = mobileButton
    mobileButton.Parent = frame

    local event = Instance.new("BindableEvent")
    pcButton.MouseButton1Click:Connect(function()
        deviceType = "PC"
        event:Fire()
    end)
    mobileButton.MouseButton1Click:Connect(function()
        deviceType = "Mobile"
        event:Fire()
    end)

    event.Event:Wait()
    screenGui:Destroy()
end

-- Cihaz türünü sor
askDeviceType()
if not deviceType then error("Device type not selected") end

-- Initial physical state reset
if rootPart then
    rootPart.Velocity = Vector3.new(0, 0, 0)
    rootPart.RotVelocity = Vector3.new(0, 0, 0)
end

-- Fly and teleport variables (all disabled by default)
local flyEnabled = false
local flyLocked = true
local isFlying = false
local teleportActive = false
local flySpeed = 50
local bodyVelocity = Instance.new("BodyVelocity")
local bodyGyro = Instance.new("BodyGyro")

if rootPart then
    bodyVelocity.Name = "FlyVelocity"
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart

    bodyGyro.Name = "FlyGyro"
    bodyGyro.MaxTorque = Vector3.new(0, 0, 0)
    bodyGyro.D = 500
    bodyGyro.P = 5000
    bodyGyro.Parent = rootPart
end

local moveForward = 0
local moveRight = 0
local moveUp = 0 -- Yukarı/aşağı hareket için

-- Invisible Variables (Test Phase)
local isInvis = false

-- Viewer variables
local isViewing = false
local viewedPlayer = nil

-- Noclip variables
local isNoclipEnabled = false
local noclipConnection = nil
local noclipBodyVelocity = nil

-- Fling Variables
local flingEnabled = false
local flingBambam = nil
local flingDied = nil

-- Fling Player Variables
local flingPlayerEnabled = false
local flingTarget = nil
local flingPlayerBambam = nil
local flingPlayerDied = nil

-- ESP Variables (Test Phase)
local ESPenabled = false
local showHealth = false
local showDistance = false
local showTracer = false
local espColor = Color3.fromRGB(255, 255, 255)

-- Collision protection
local protectDuringFling = false
local protectDuringFlingPlayer = false

-- Can Touch Variable
local canTouchEnabled = false

-- Background color
local backgroundColor = Color3.fromRGB(30, 30, 30)

-- Fullbright Variables
local fullbrightActive = false
local origSettings = {
    abt = Lighting.Ambient,
    oabt = Lighting.OutdoorAmbient,
    brt = Lighting.Brightness,
    time = Lighting.ClockTime,
    fe = Lighting.FogEnd,
    fs = Lighting.FogStart,
    gs = Lighting.GlobalShadows
}

-- Helper Functions
local function getRoot(char)
    if not char then return nil end
    local rootPart = char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
    return rootPart
end

local function toggleCollisionProtection(state, isPlayerFling)
    if not character or not rootPart then return end
    if state then
        if isPlayerFling then
            protectDuringFlingPlayer = true
        else
            protectDuringFling = true
        end
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    else
        if isPlayerFling then
            protectDuringFlingPlayer = false
        else
            protectDuringFling = false
        end
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local function teleportToPlayer(targetPosition)
    if not character or not humanoid or not rootPart or not targetPosition then return end
    local targetChar = targetPosition.Parent
    local targetRoot = getRoot(targetChar)
    if targetRoot then
        local currentOrientation = rootPart.CFrame - rootPart.CFrame.Position
        rootPart.CFrame = currentOrientation + targetRoot.CFrame.Position + Vector3.new(0, 5, 0)
    else
        warn("Failed to find HumanoidRootPart for target player!")
    end
end

local function toggleNoclip(state)
    if not _G.noclipToggleButton or not character or not rootPart then
        warn("noclipToggleButton or character is nil in toggleNoclip!")
        return
    end
    if state then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipBodyVelocity = Instance.new("BodyVelocity")
        noclipBodyVelocity.Name = "NoclipGravity"
        noclipBodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
        noclipBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        noclipBodyVelocity.Parent = rootPart
        noclipConnection = RunService.Stepped:Connect(function()
            if not character or not rootPart or not isNoclipEnabled then
                if noclipConnection then noclipConnection:Disconnect() end
                if noclipBodyVelocity then noclipBodyVelocity:Destroy() noclipBodyVelocity = nil end
                return
            end
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            if noclipBodyVelocity then
                noclipBodyVelocity.Velocity = Vector3.new(0, -50, 0)
            end
        end)
        _G.noclipToggleButton.Text = "Noclip: Enabled"
    else
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
        if noclipBodyVelocity then noclipBodyVelocity:Destroy() noclipBodyVelocity = nil end
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
        _G.noclipToggleButton.Text = "Noclip: Disabled"
    end
    isNoclipEnabled = state
end

local function toggleFling(state)
    if not _G.flingToggleButton or not character or not rootPart then
        warn("flingToggleButton or character is nil in toggleFling!")
        return
    end
    if state then
        if not character or not rootPart then return end
        flingEnabled = true
        toggleNoclip(true)
        for _, child in pairs(character:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CustomPhysicalProperties = PhysicalProperties.new(math.huge, 0.3, 0.5)
            end
        end
        wait(0.1)
        flingBambam = Instance.new("BodyAngularVelocity")
        flingBambam.Name = "BamBam"
        flingBambam.Parent = rootPart
        flingBambam.AngularVelocity = Vector3.new(0, 99999, 0)
        flingBambam.MaxTorque = Vector3.new(0, math.huge, 0)
        flingBambam.P = math.huge
        for _, v in pairs(character:GetChildren()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
                v.Massless = true
                v.Velocity = Vector3.new(0, 0, 0)
            end
        end
        local function flingDiedF()
            flingEnabled = false
            if flingBambam then flingBambam:Destroy() end
            if flingDied then flingDied:Disconnect() end
            delay(1.5, function()
                toggleNoclip(false)
                if _G.flingToggleButton then _G.flingToggleButton.Text = "Fling: Disabled" end
                toggleCollisionProtection(false)
            end)
        end
        flingDied = humanoid and humanoid.Died:Connect(flingDiedF)
        spawn(function()
            while flingEnabled do
                if flingBambam then
                    flingBambam.AngularVelocity = Vector3.new(0, 99999, 0)
                end
                wait(0.2)
                if flingBambam then
                    flingBambam.AngularVelocity = Vector3.new(0, 0, 0)
                end
                wait(0.1)
            end
        end)
        toggleCollisionProtection(true)
        _G.flingToggleButton.Text = "Fling: Enabled"
    else
        flingEnabled = false
        if flingDied then flingDied:Disconnect() end
        if flingBambam then
            local tween = TweenService:Create(flingBambam, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {AngularVelocity = Vector3.new(0, 0, 0)})
            tween:Play()
            tween.Completed:Connect(function()
                flingBambam:Destroy()
                local stabilizer = Instance.new("BodyVelocity")
                stabilizer.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                stabilizer.Velocity = Vector3.new(0, -10, 0)
                stabilizer.Parent = rootPart
                wait(2)
                stabilizer:Destroy()
                if rootPart then
                    rootPart.Velocity = Vector3.new(0, 0, 0)
                    rootPart.RotVelocity = Vector3.new(0, 0, 0)
                end
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
                toggleNoclip(false)
            end)
        end
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("BasePart") then
                child.CanCollide = true
                child.Massless = false
                child.CustomPhysicalProperties = nil
            end
        end
        toggleCollisionProtection(false)
        if _G.flingToggleButton then _G.flingToggleButton.Text = "Fling: Disabled" end
    end
end

local function toggleFlingPlayer(state, target)
    if not startFlingButton or not character or not rootPart or not target or not target.Character or not getRoot(target.Character) then
        warn("startFlingButton, character, or target is nil in toggleFlingPlayer!")
        return
    end
    if state then
        flingTarget = target
        flingPlayerEnabled = true
        toggleNoclip(true)
        for _, child in pairs(character:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CustomPhysicalProperties = PhysicalProperties.new(math.huge, 0.3, 0.5)
            end
        end
        wait(0.1)
        flingPlayerBambam = Instance.new("BodyAngularVelocity")
        flingPlayerBambam.Name = "PlayerBamBam"
        flingPlayerBambam.Parent = rootPart
        flingPlayerBambam.AngularVelocity = Vector3.new(0, 99999, 0)
        flingPlayerBambam.MaxTorque = Vector3.new(0, math.huge, 0)
        flingPlayerBambam.P = math.huge
        for _, v in pairs(character:GetChildren()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
                v.Massless = false
                v.Velocity = Vector3.new(0, 0, 0)
            end
        end
        local targetRoot = getRoot(target.Character)
        local function flingPlayerDiedF()
            flingPlayerEnabled = false
            if flingPlayerBambam then flingPlayerBambam:Destroy() end
            if flingPlayerDied then flingPlayerDied:Disconnect() end
            delay(2, function()
                toggleNoclip(false)
                startFlingButton.Text = "Start Fling"
                toggleCollisionProtection(false, true)
            end)
        end
        flingPlayerDied = humanoid and humanoid.Died:Connect(flingPlayerDiedF)
        spawn(function()
            while flingPlayerEnabled and target.Character and targetRoot do
                local direction = (targetRoot.Position - rootPart.Position).Unit
                rootPart.CFrame = CFrame.new(rootPart.Position + direction * 5)
                if flingPlayerBambam then
                    flingPlayerBambam.AngularVelocity = Vector3.new(0, 99999, 0)
                end
                wait(0.2)
                if flingPlayerBambam then
                    flingPlayerBambam.AngularVelocity = Vector3.new(0, 0, 0)
                end
                wait(0.1)
                if targetRoot and not targetRoot.Anchored then
                    targetRoot.CanCollide = true
                    local flingForce = Instance.new("BodyVelocity")
                    flingForce.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    flingForce.Velocity = direction * 5000
                    flingForce.Parent = targetRoot
                    wait(0.2)
                    flingForce:Destroy()
                end
            end
        end)
        toggleCollisionProtection(true, true)
        startFlingButton.Text = "Stop Fling"
    else
        flingPlayerEnabled = false
        if flingPlayerDied then flingPlayerDied:Disconnect() end
        if flingPlayerBambam then
            local tween = TweenService:Create(flingPlayerBambam, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {AngularVelocity = Vector3.new(0, 0, 0)})
            tween:Play()
            tween.Completed:Connect(function()
                flingPlayerBambam:Destroy()
                local stabilizer = Instance.new("BodyVelocity")
                stabilizer.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                stabilizer.Velocity = Vector3.new(0, -10, 0)
                stabilizer.Parent = rootPart
                wait(2)
                stabilizer:Destroy()
                if rootPart then
                    rootPart.Velocity = Vector3.new(0, 0, 0)
                    rootPart.RotVelocity = Vector3.new(0, 0, 0)
                end
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
                toggleNoclip(false)
            end)
        end
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("BasePart") then
                child.CanCollide = true
                child.Massless = false
                child.CustomPhysicalProperties = nil
            end
        end
        toggleCollisionProtection(false, true)
        startFlingButton.Text = "Start Fling"
    end
end

-- ESP Fonksiyonu (Test Phase)
local function updateESP()
    if not ESPenabled then return end
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "ESPBox" or v.Name == "ESPHealth" or v.Name == "ESPDistance" or v.Name == "ESPTracer" then
            v:Destroy()
        end
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and getRoot(plr.Character) then
            local humanoid = plr.Character:FindFirstChildWhichIsA("Humanoid")
            if humanoid then
                ESP(plr)
            end
        end
    end
end

local function ESP(plr)
    if not ESPenabled or not plr.Character or not getRoot(plr.Character) then return end
    local humanoid = plr.Character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    local root = getRoot(plr.Character)
    local head = plr.Character:FindFirstChild("Head")
    if not root or not head then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESPBox"
    box.Parent = root
    box.Adornee = root
    box.AlwaysOnTop = true
    box.Size = root.Size + Vector3.new(0.2, 0.2, 0.2)
    box.Transparency = 0.3
    box.Color3 = espColor
    box.ZIndex = 10

    if showHealth then
        local healthLabel = Instance.new("BillboardGui")
        healthLabel.Name = "ESPHealth"
        healthLabel.Parent = root
        healthLabel.Adornee = head
        healthLabel.Size = UDim2.new(0, 100, 0, 50)
        healthLabel.StudsOffset = Vector3.new(0, 3, 0)
        healthLabel.AlwaysOnTop = true
        local healthText = Instance.new("TextLabel")
        healthText.Parent = healthLabel
        healthText.Size = UDim2.new(1, 0, 1, 0)
        healthText.Text = "Health: " .. math.floor(humanoid.Health) .. "/" .. humanoid.MaxHealth
        healthText.TextColor3 = Color3.new(1, 1, 1)
        healthText.BackgroundTransparency = 1
        healthText.ZIndex = 10
    end

    if showDistance then
        local distanceLabel = Instance.new("BillboardGui")
        distanceLabel.Name = "ESPDistance"
        distanceLabel.Parent = root
        distanceLabel.Adornee = head
        distanceLabel.Size = UDim2.new(0, 100, 0, 50)
        distanceLabel.StudsOffset = Vector3.new(0, 1, 0)
        distanceLabel.AlwaysOnTop = true
        local distanceText = Instance.new("TextLabel")
        distanceText.Parent = distanceLabel
        distanceText.Size = UDim2.new(1, 0, 1, 0)
        distanceText.Text = "Distance: " .. math.floor((getRoot(player.Character).Position - root.Position).Magnitude) .. " studs"
        distanceText.TextColor3 = Color3.new(1, 1, 1)
        distanceText.BackgroundTransparency = 1
        distanceText.ZIndex = 10
    end

    if showTracer then
        local tracer = Instance.new("Beam")
        tracer.Name = "ESPTracer"
        tracer.Parent = workspace.CurrentCamera
        tracer.Color = ColorSequence.new(espColor)
        tracer.Transparency = NumberSequence.new(0)
        tracer.LightInfluence = 0
        tracer.Width0 = 0.2
        tracer.Width1 = 0.2
        local attachment0 = Instance.new("Attachment")
        attachment0.Parent = workspace.CurrentCamera
        attachment0.Position = Vector3.new(0, 0, 0)
        local attachment1 = Instance.new("Attachment")
        attachment1.Parent = root
        attachment1.Position = Vector3.new(0, -root.Size.Y/2, 0)
        tracer.Attachment0 = attachment0
        tracer.Attachment1 = attachment1
    end

    local espConnection
    espConnection = RunService.RenderStepped:Connect(function()
        if not ESPenabled or not plr.Character or not getRoot(plr.Character) or not plr.Character:FindFirstChildWhichIsA("Humanoid") then
            if box then box:Destroy() end
            for _, v in pairs(root:GetChildren()) do
                if v.Name == "ESPHealth" or v.Name == "ESPDistance" then
                    v:Destroy()
                end
            end
            for _, v in pairs(workspace.CurrentCamera:GetChildren()) do
                if v.Name == "ESPTracer" then
                    v:Destroy()
                end
            end
            if espConnection then espConnection:Disconnect() end
        end
    end)

    if humanoid then
        humanoid.Died:Connect(function()
            wait(1)
            updateESP()
        end)
    end

    plr.CharacterAdded:Connect(function()
        wait(1)
        updateESP()
    end)
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if ESPenabled then
            repeat wait(1) until plr.Character and getRoot(plr.Character)
            ESP(plr)
        end
    end)
end)

Players.PlayerRemoving:Connect(function()
    wait(1)
    updateESP()
end)

local function toggleCanTouch(state)
    if not character then return end
    canTouchEnabled = state
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanTouch = canTouchEnabled
        end
    end
end

-- Fly Function (Test Phase)
local function toggleFly()
    if flyLocked or not character or not rootPart or not humanoid then
        return
    end
    if not flyEnabled then
        return
    end
    isFlying = not isFlying
    if isFlying then
        humanoid.PlatformStand = true
        humanoid.Sit = false
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
    else
        bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyGyro.MaxTorque = Vector3.new(0, 0, 0)
        humanoid.PlatformStand = false
        if rootPart then
            rootPart.Velocity = Vector3.new(0, rootPart.Velocity.Y, 0)
            rootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Landing)
        end
        moveForward = 0
        moveRight = 0
        moveUp = 0
    end
end

-- Invisible Function (Test Phase)
function toggleInvisible()
    if not character then return end
    if isInvis then
        for i, v in pairs(workspace:GetChildren()) do
            if v.Name == player.Name .. "_InvisibleClone" then
                v:Destroy()
            end
        end
        local ch = character
        if ch and rootPart then
            rootPart.CFrame = ch:FindFirstChild("HumanoidRootPart").CFrame
            for i, v in pairs(ch:GetChildren()) do
                if v:IsA("BasePart") then
                    v.Transparency = 0
                elseif v:IsA("Accessory") then
                    local part = v:FindFirstChildOfClass("Part")
                    if part then part.Transparency = 0 end
                end
            end
            ch.Parent = workspace
            player.Character = ch
            isInvis = false
            if invisibleButton then invisibleButton.Text = "Invisible: Disabled (Test Phase)" end
        end
    else
        local ch = character
        local clone = ch:Clone()
        clone.Name = player.Name .. "_InvisibleClone"
        for i, v in pairs(ch:GetChildren()) do
            if v:IsA("BasePart") then
                v.Transparency = 1
            elseif v:IsA("Accessory") then
                local part = v:FindFirstChildOfClass("Part")
                if part then part.Transparency = 1 end
            end
        end
        clone.Parent = workspace
        ch.Parent = game.Lighting
        player.Character = clone
        isInvis = true
        if invisibleButton then invisibleButton.Text = "Invisible: Enabled (Test Phase)" end
    end
end

-- GUI Creation (Modernized Design)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Universal Hub (beta)"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = deviceType == "Mobile" and UDim2.new(0, 300, 0, 450) or UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
mainFrame.BackgroundColor3 = backgroundColor
mainFrame.BorderSizePixel = 0
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame
mainFrame.Parent = screenGui

-- Minimize ikonu (minimize edildiğinde görünecek)
local minimizedIcon = Instance.new("TextButton")
minimizedIcon.Size = UDim2.new(0, 50, 0, 50)
minimizedIcon.Position = UDim2.new(0, 10, 0, 10)
minimizedIcon.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
minimizedIcon.Text = "???"
minimizedIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizedIcon.TextSize = 24
minimizedIcon.Visible = false
local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 10)
iconCorner.Parent = minimizedIcon
minimizedIcon.Parent = screenGui

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.BorderSizePixel = 0
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Universal Hub(beta)"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 25, 0, 25)
minimizeButton.Position = UDim2.new(1, -60, 0, 7)
minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
minimizeButton.Text = ""
local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 5)
minimizeCorner.Parent = minimizeButton
local minimizeIcon = Instance.new("ImageLabel")
minimizeIcon.Size = UDim2.new(0, 15, 0, 15)
minimizeIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
minimizeIcon.BackgroundTransparency = 1
minimizeIcon.Image = "rbxassetid://7072725342"
minimizeIcon.Parent = minimizeButton
minimizeButton.Parent = titleBar

local isMinimized = false
minimizeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

minimizedIcon.MouseButton1Click:Connect(function()
    isMinimized = false
    mainFrame.Visible = true
    minimizedIcon.Visible = false
    minimizeIcon.Image = "rbxassetid://7072725342"
end)

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 25, 0, 25)
closeButton.Position = UDim2.new(1, -30, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
closeButton.Text = ""
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeButton
local closeIcon = Instance.new("ImageLabel")
closeIcon.Size = UDim2.new(0, 15, 0, 15)
closeIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
closeIcon.BackgroundTransparency = 1
closeIcon.Image = "rbxassetid://7072719338"
closeIcon.Parent = closeButton
closeButton.Parent = titleBar
closeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    mainFrame.Visible = not isMinimized
    minimizedIcon.Visible = isMinimized
    closeIcon.Image = isMinimized and "rbxassetid://7072706620" or "rbxassetid://7072719338"
end)

-- Boyutlandırma için sağ alt köşe (PC için)
if deviceType == "PC" then
    local resizeHandle = Instance.new("TextButton")
    resizeHandle.Size = UDim2.new(0, 20, 0, 20)
    resizeHandle.Position = UDim2.new(1, -20, 1, -20)
    resizeHandle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    resizeHandle.Text = "-"
    resizeHandle.TextColor3 = Color3.fromRGB(255, 255, 255)
    resizeHandle.TextSize = 14
    local resizeCorner = Instance.new("UICorner")
    resizeCorner.CornerRadius = UDim.new(0, 5)
    resizeCorner.Parent = resizeHandle
    resizeHandle.Parent = mainFrame

    local resizing, resizeStart, startSize
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            startSize = mainFrame.Size
        end
    end)

    resizeHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local newWidth = math.max(300, startSize.X.Offset + delta.X)
            local newHeight = math.max(300, startSize.Y.Offset + delta.Y)
            mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
            contentScroll.Size = UDim2.new(0, newWidth - 120, 1, -40)
            playerTPList.Size = UDim2.new(0, newWidth - 160, 0, 200)
            playerViewerList.Size = UDim2.new(0, newWidth - 160, 0, 200)
            flingPlayerList.Size = UDim2.new(0, newWidth - 160, 0, 200)
            playerESPFrame.Size = UDim2.new(1, 0, 1, -40)
        end
    end)
end

local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(0, 120, 1, -40)
tabFrame.Position = UDim2.new(0, 0, 0, 40)
tabFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tabFrame.BorderSizePixel = 0
local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 10)
tabCorner.Parent = tabFrame
tabFrame.Parent = mainFrame

local basicHackTabButton = Instance.new("TextButton")
basicHackTabButton.Size = UDim2.new(1, -10, 0, 40)
basicHackTabButton.Position = UDim2.new(0, 5, 0, 5)
basicHackTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
basicHackTabButton.Text = "Basic Hacks"
basicHackTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
basicHackTabButton.TextSize = 16
basicHackTabButton.Font = Enum.Font.Gotham
local basicTabCorner = Instance.new("UICorner")
basicTabCorner.CornerRadius = UDim.new(0, 5)
basicTabCorner.Parent = basicHackTabButton
basicHackTabButton.Parent = tabFrame

local playersTabButton = Instance.new("TextButton")
playersTabButton.Size = UDim2.new(1, -10, 0, 40)
playersTabButton.Position = UDim2.new(0, 5, 0, 50)
playersTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playersTabButton.Text = "Players"
playersTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playersTabButton.TextSize = 16
playersTabButton.Font = Enum.Font.Gotham
local playersTabCorner = Instance.new("UICorner")
playersTabCorner.CornerRadius = UDim.new(0, 5)
playersTabCorner.Parent = playersTabButton
playersTabButton.Parent = tabFrame

local settingsTabButton = Instance.new("TextButton")
settingsTabButton.Size = UDim2.new(1, -10, 0, 40)
settingsTabButton.Position = UDim2.new(0, 5, 0, 95)
settingsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
settingsTabButton.Text = "Settings"
settingsTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsTabButton.TextSize = 16
settingsTabButton.Font = Enum.Font.Gotham
local settingsTabCorner = Instance.new("UICorner")
settingsTabCorner.CornerRadius = UDim.new(0, 5)
settingsTabCorner.Parent = settingsTabButton
settingsTabButton.Parent = tabFrame

local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Size = deviceType == "Mobile" and UDim2.new(0, 180, 1, -40) or UDim2.new(0, 380, 1, -40)
contentScroll.Position = UDim2.new(0, 120, 0, 40)
contentScroll.BackgroundColor3 = backgroundColor
contentScroll.BorderSizePixel = 0
contentScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
contentScroll.ScrollBarThickness = 6
local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 10)
contentCorner.Parent = contentScroll
contentScroll.Parent = mainFrame

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 2, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = contentScroll

local basicHackFrame = Instance.new("Frame")
basicHackFrame.Size = UDim2.new(1, 0, 0, 400)
basicHackFrame.BackgroundColor3 = backgroundColor
basicHackFrame.BorderSizePixel = 0
basicHackFrame.Parent = contentFrame
basicHackFrame.Visible = true

local playersFrame = Instance.new("Frame")
playersFrame.Size = UDim2.new(1, 0, 0, 500)
playersFrame.BackgroundColor3 = backgroundColor
playersFrame.BorderSizePixel = 0
playersFrame.Visible = false
playersFrame.Parent = contentFrame

local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(1, 0, 0, 500)
settingsFrame.BackgroundColor3 = backgroundColor
settingsFrame.BorderSizePixel = 0
settingsFrame.Visible = false
settingsFrame.Parent = contentFrame

local playersTabFrame = Instance.new("Frame")
playersTabFrame.Size = UDim2.new(1, 0, 0, 40)
playersTabFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playersTabFrame.BorderSizePixel = 0
local playersTabCorner = Instance.new("UICorner")
playersTabCorner.CornerRadius = UDim.new(0, 5)
playersTabCorner.Parent = playersTabFrame
playersTabFrame.Parent = playersFrame

local playerTPTabButton = Instance.new("TextButton")
playerTPTabButton.Size = UDim2.new(0.25, 0, 1, -10)
playerTPTabButton.Position = UDim2.new(0, 5, 0, 5)
playerTPTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
playerTPTabButton.Text = "Teleport"
playerTPTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playerTPTabButton.TextSize = 14
playerTPTabButton.Font = Enum.Font.Gotham
local tpTabCorner = Instance.new("UICorner")
tpTabCorner.CornerRadius = UDim.new(0, 5)
tpTabCorner.Parent = playerTPTabButton
playerTPTabButton.Parent = playersTabFrame

local playerViewerTabButton = Instance.new("TextButton")
playerViewerTabButton.Size = UDim2.new(0.25, 0, 1, -10)
playerViewerTabButton.Position = UDim2.new(0.25, 0, 0, 5)
playerViewerTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playerViewerTabButton.Text = "Viewer"
playerViewerTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playerViewerTabButton.TextSize = 14
playerViewerTabButton.Font = Enum.Font.Gotham
local viewerTabCorner = Instance.new("UICorner")
viewerTabCorner.CornerRadius = UDim.new(0, 5)
viewerTabCorner.Parent = playerViewerTabButton
playerViewerTabButton.Parent = playersTabFrame

local flingPlayerTabButton = Instance.new("TextButton")
flingPlayerTabButton.Size = UDim2.new(0.25, 0, 1, -10)
flingPlayerTabButton.Position = UDim2.new(0.5, 0, 0, 5)
flingPlayerTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
flingPlayerTabButton.Text = "Fling"
flingPlayerTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flingPlayerTabButton.TextSize = 14
flingPlayerTabButton.Font = Enum.Font.Gotham
local flingTabCorner = Instance.new("UICorner")
flingTabCorner.CornerRadius = UDim.new(0, 5)
flingTabCorner.Parent = flingPlayerTabButton
flingPlayerTabButton.Parent = playersTabFrame

local playerESPTabButton = Instance.new("TextButton")
playerESPTabButton.Size = UDim2.new(0.25, 0, 1, -10)
playerESPTabButton.Position = UDim2.new(0.75, 0, 0, 5)
playerESPTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playerESPTabButton.Text = "ESP (Test Phase)"
playerESPTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playerESPTabButton.TextSize = 14
playerESPTabButton.Font = Enum.Font.Gotham
local espTabCorner = Instance.new("UICorner")
espTabCorner.CornerRadius = UDim.new(0, 5)
espTabCorner.Parent = playerESPTabButton
playerESPTabButton.Parent = playersTabFrame

local playerTPFrame = Instance.new("Frame")
playerTPFrame.Size = UDim2.new(1, 0, 1, -40)
playerTPFrame.Position = UDim2.new(0, 0, 0, 40)
playerTPFrame.BackgroundColor3 = backgroundColor
playerTPFrame.BorderSizePixel = 0
playerTPFrame.Parent = playersFrame

local playerViewerFrame = Instance.new("Frame")
playerViewerFrame.Size = UDim2.new(1, 0, 1, -40)
playerViewerFrame.Position = UDim2.new(0, 0, 0, 40)
playerViewerFrame.BackgroundColor3 = backgroundColor
playerViewerFrame.BorderSizePixel = 0
playerViewerFrame.Visible = false
playerViewerFrame.Parent = playersFrame

local flingPlayerFrame = Instance.new("Frame")
flingPlayerFrame.Size = UDim2.new(1, 0, 1, -40)
flingPlayerFrame.Position = UDim2.new(0, 0, 0, 40)
flingPlayerFrame.BackgroundColor3 = backgroundColor
flingPlayerFrame.BorderSizePixel = 0
flingPlayerFrame.Visible = false
flingPlayerFrame.Parent = playersFrame

local playerESPFrame = Instance.new("Frame")
playerESPFrame.Size = UDim2.new(1, 0, 1, -40)
playerESPFrame.Position = UDim2.new(0, 0, 0, 40)
playerESPFrame.BackgroundColor3 = backgroundColor
playerESPFrame.BorderSizePixel = 0
playerESPFrame.Visible = false
playerESPFrame.Parent = playersFrame

local playerTPList = Instance.new("ScrollingFrame")
playerTPList.Size = deviceType == "Mobile" and UDim2.new(0, 140, 0, 200) or UDim2.new(0, 340, 0, 200)
playerTPList.Position = UDim2.new(0.5, -170, 0, 20)
playerTPList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playerTPList.CanvasSize = UDim2.new(0, 0, 0, 0)
playerTPList.ScrollBarThickness = 6
local tpListCorner = Instance.new("UICorner")
tpListCorner.CornerRadius = UDim.new(0, 5)
tpListCorner.Parent = playerTPList
playerTPList.Parent = playerTPFrame

local function updatePlayerTPList()
    if not playerTPList then return end
    for _, child in pairs(playerTPList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    local yOffset = 0
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local playerButton = Instance.new("TextButton")
            playerButton.Size = UDim2.new(1, -10, 0, 30)
            playerButton.Position = UDim2.new(0, 5, 0, yOffset)
            playerButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            playerButton.Text = otherPlayer.Name
            playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerButton.TextSize = 14
            playerButton.Font = Enum.Font.Gotham
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 5)
            buttonCorner.Parent = playerButton
            playerButton.Parent = playerTPList
            playerButton.MouseButton1Click:Connect(function()
                local targetRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot and character and rootPart then
                    teleportToPlayer(targetRoot)
                else
                    warn("Teleport failed!")
                end
            end)
            yOffset = yOffset + 35
        end
    end
    playerTPList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

local playerViewerList = Instance.new("ScrollingFrame")
playerViewerList.Size = deviceType == "Mobile" and UDim2.new(0, 140, 0, 200) or UDim2.new(0, 340, 0, 200)
playerViewerList.Position = UDim2.new(0.5, -170, 0, 20)
playerViewerList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
playerViewerList.CanvasSize = UDim2.new(0, 0, 0, 0)
playerViewerList.ScrollBarThickness = 6
local viewerListCorner = Instance.new("UICorner")
viewerListCorner.CornerRadius = UDim.new(0, 5)
viewerListCorner.Parent = playerViewerList
playerViewerList.Parent = playerViewerFrame

local stopViewingButton = Instance.new("TextButton")
stopViewingButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
stopViewingButton.Position = UDim2.new(0.5, -100, 0, 230)
stopViewingButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
stopViewingButton.Text = "Stop Viewing"
stopViewingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopViewingButton.TextSize = 16
stopViewingButton.Font = Enum.Font.Gotham
local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 5)
stopCorner.Parent = stopViewingButton
stopViewingButton.Parent = playerViewerFrame

local function updatePlayerViewerList()
    if not playerViewerList then return end
    for _, child in pairs(playerViewerList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    local yOffset = 0
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local playerButton = Instance.new("TextButton")
            playerButton.Size = UDim2.new(1, -10, 0, 30)
            playerButton.Position = UDim2.new(0, 5, 0, yOffset)
            playerButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            playerButton.Text = otherPlayer.Name
            playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerButton.TextSize = 14
            playerButton.Font = Enum.Font.Gotham
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 5)
            buttonCorner.Parent = playerButton
            playerButton.Parent = playerViewerList
            playerButton.MouseButton1Click:Connect(function()
                if otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    isViewing = true
                    viewedPlayer = otherPlayer
                end
            end)
            yOffset = yOffset + 35
        end
    end
    playerViewerList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

local flingPlayerList = Instance.new("ScrollingFrame")
flingPlayerList.Size = deviceType == "Mobile" and UDim2.new(0, 140, 0, 200) or UDim2.new(0, 340, 0, 200)
flingPlayerList.Position = UDim2.new(0.5, -170, 0, 20)
flingPlayerList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
flingPlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
flingPlayerList.ScrollBarThickness = 6
local flingListCorner = Instance.new("UICorner")
flingListCorner.CornerRadius = UDim.new(0, 5)
flingListCorner.Parent = flingPlayerList
flingPlayerList.Parent = flingPlayerFrame

local startFlingButton = Instance.new("TextButton")
startFlingButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
startFlingButton.Position = UDim2.new(0.5, -100, 0, 230)
startFlingButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
startFlingButton.Text = "Start Fling"
startFlingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startFlingButton.TextSize = 16
startFlingButton.Font = Enum.Font.Gotham
local startFlingCorner = Instance.new("UICorner")
startFlingCorner.CornerRadius = UDim.new(0, 5)
startFlingCorner.Parent = startFlingButton
startFlingButton.Parent = flingPlayerFrame

local stopFlingButton = Instance.new("TextButton")
stopFlingButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
stopFlingButton.Position = UDim2.new(0.5, -100, 0, 280)
stopFlingButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
stopFlingButton.Text = "Stop Fling"
stopFlingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopFlingButton.TextSize = 16
stopFlingButton.Font = Enum.Font.Gotham
local stopFlingCorner = Instance.new("UICorner")
stopFlingCorner.CornerRadius = UDim.new(0, 5)
stopFlingCorner.Parent = stopFlingButton
stopFlingButton.Parent = flingPlayerFrame

local function updateFlingPlayerList()
    if not flingPlayerList then return end
    for _, child in pairs(flingPlayerList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    local yOffset = 0
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local playerButton = Instance.new("TextButton")
            playerButton.Size = UDim2.new(1, -10, 0, 30)
            playerButton.Position = UDim2.new(0, 5, 0, yOffset)
            playerButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            playerButton.Text = otherPlayer.Name
            playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerButton.TextSize = 14
            playerButton.Font = Enum.Font.Gotham
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 5)
            buttonCorner.Parent = playerButton
            playerButton.Parent = flingPlayerList
            playerButton.MouseButton1Click:Connect(function()
                for _, btn in pairs(flingPlayerList:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    end
                end
                playerButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                flingTarget = otherPlayer
            end)
            yOffset = yOffset + 35
        end
    end
    flingPlayerList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

local espToggleButton = Instance.new("TextButton")
espToggleButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
espToggleButton.Position = UDim2.new(0.5, -100, 0, 20)
espToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
espToggleButton.Text = "ESP: Disabled (Test Phase)"
espToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
espToggleButton.TextSize = 16
espToggleButton.Font = Enum.Font.Gotham
local espToggleCorner = Instance.new("UICorner")
espToggleCorner.CornerRadius = UDim.new(0, 5)
espToggleCorner.Parent = espToggleButton
espToggleButton.Parent = playerESPFrame

local showHealthButton = Instance.new("TextButton")
showHealthButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
showHealthButton.Position = UDim2.new(0.5, -100, 0, 70)
showHealthButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
showHealthButton.Text = "Show Health: Disabled (Test Phase)"
showHealthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
showHealthButton.TextSize = 16
showHealthButton.Font = Enum.Font.Gotham
local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, 5)
healthCorner.Parent = showHealthButton
showHealthButton.Parent = playerESPFrame

local showDistanceButton = Instance.new("TextButton")
showDistanceButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
showDistanceButton.Position = UDim2.new(0.5, -100, 0, 120)
showDistanceButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
showDistanceButton.Text = "Show Distance: Disabled (Test Phase)"
showDistanceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
showDistanceButton.TextSize = 16
showDistanceButton.Font = Enum.Font.Gotham
local distanceCorner = Instance.new("UICorner")
distanceCorner.CornerRadius = UDim.new(0, 5)
distanceCorner.Parent = showDistanceButton
showDistanceButton.Parent = playerESPFrame

local showTracerButton = Instance.new("TextButton")
showTracerButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
showTracerButton.Position = UDim2.new(0.5, -100, 0, 170)
showTracerButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
showTracerButton.Text = "Show Tracer: Disabled (Test Phase)"
showTracerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
showTracerButton.TextSize = 16
showTracerButton.Font = Enum.Font.Gotham
local tracerCorner = Instance.new("UICorner")
tracerCorner.CornerRadius = UDim.new(0, 5)
tracerCorner.Parent = showTracerButton
showTracerButton.Parent = playerESPFrame

local changeColorButton = Instance.new("TextButton")
changeColorButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
changeColorButton.Position = UDim2.new(0.5, -100, 0, 220)
changeColorButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
changeColorButton.Text = "Change ESP Color"
changeColorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
changeColorButton.TextSize = 16
changeColorButton.Font = Enum.Font.Gotham
local colorCorner = Instance.new("UICorner")
colorCorner.CornerRadius = UDim.new(0, 5)
colorCorner.Parent = changeColorButton
changeColorButton.Parent = playerESPFrame

local infJumpToggleButton = Instance.new("TextButton")
infJumpToggleButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
infJumpToggleButton.Position = UDim2.new(0.5, -100, 0, 10)
infJumpToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
infJumpToggleButton.Text = "Infinite Jump: Disabled"
infJumpToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
infJumpToggleButton.TextSize = 16
infJumpToggleButton.Font = Enum.Font.Gotham
local infJumpCorner = Instance.new("UICorner")
infJumpCorner.CornerRadius = UDim.new(0, 5)
infJumpCorner.Parent = infJumpToggleButton
infJumpToggleButton.Parent = basicHackFrame

local flyToggleButton = Instance.new("TextButton")
flyToggleButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
flyToggleButton.Position = UDim2.new(0.5, -100, 0, 60)
flyToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flyToggleButton.Text = "Fly: Disabled (Test Phase)"
flyToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyToggleButton.TextSize = 16
flyToggleButton.Font = Enum.Font.Gotham
local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 5)
flyCorner.Parent = flyToggleButton
flyToggleButton.Parent = basicHackFrame

local teleportToggleButton = Instance.new("TextButton")
teleportToggleButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
teleportToggleButton.Position = UDim2.new(0.5, -100, 0, 110)
teleportToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
teleportToggleButton.Text = "Teleport: Disabled"
teleportToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportToggleButton.TextSize = 16
teleportToggleButton.Font = Enum.Font.Gotham
local teleportCorner = Instance.new("UICorner")
teleportCorner.CornerRadius = UDim.new(0, 5)
teleportCorner.Parent = teleportToggleButton
teleportToggleButton.Parent = basicHackFrame

_G.noclipToggleButton = Instance.new("TextButton")
_G.noclipToggleButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
_G.noclipToggleButton.Position = UDim2.new(0.5, -100, 0, 160)
_G.noclipToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
_G.noclipToggleButton.Text = "Noclip: Disabled"
_G.noclipToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_G.noclipToggleButton.TextSize = 16
_G.noclipToggleButton.Font = Enum.Font.Gotham
local noclipCorner = Instance.new("UICorner")
noclipCorner.CornerRadius = UDim.new(0, 5)
noclipCorner.Parent = _G.noclipToggleButton
_G.noclipToggleButton.Parent = basicHackFrame

_G.flingToggleButton = Instance.new("TextButton")
_G.flingToggleButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
_G.flingToggleButton.Position = UDim2.new(0.5, -100, 0, 210)
_G.flingToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
_G.flingToggleButton.Text = "Fling: Disabled"
_G.flingToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_G.flingToggleButton.TextSize = 16
_G.flingToggleButton.Font = Enum.Font.Gotham
local flingCorner = Instance.new("UICorner")
flingCorner.CornerRadius = UDim.new(0, 5)
flingCorner.Parent = _G.flingToggleButton
_G.flingToggleButton.Parent = basicHackFrame

local canTouchToggleButton = Instance.new("TextButton")
canTouchToggleButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
canTouchToggleButton.Position = UDim2.new(0.5, -100, 0, 260)
canTouchToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
canTouchToggleButton.Text = "Can Touch: Disabled"
canTouchToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
canTouchToggleButton.TextSize = 16
canTouchToggleButton.Font = Enum.Font.Gotham
local canTouchCorner = Instance.new("UICorner")
canTouchCorner.CornerRadius = UDim.new(0, 5)
canTouchCorner.Parent = canTouchToggleButton
canTouchToggleButton.Parent = basicHackFrame

local invisibleButton = Instance.new("TextButton")
invisibleButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
invisibleButton.Position = UDim2.new(0.5, -100, 0, 310)
invisibleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
invisibleButton.Text = "Invisible: Disabled (Test Phase)"
invisibleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
invisibleButton.TextSize = 16
invisibleButton.Font = Enum.Font.Gotham
local invisibleCorner = Instance.new("UICorner")
invisibleCorner.CornerRadius = UDim.new(0, 5)
invisibleCorner.Parent = invisibleButton
invisibleButton.Parent = basicHackFrame

local fullbrightButton = Instance.new("TextButton")
fullbrightButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
fullbrightButton.Position = UDim2.new(0.5, -100, 0, 360)
fullbrightButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
fullbrightButton.Text = "Fullbright: Disabled"
fullbrightButton.TextColor3 = Color3.fromRGB(255, 255, 255)
fullbrightButton.TextSize = 16
fullbrightButton.Font = Enum.Font.Gotham
local fullbrightCorner = Instance.new("UICorner")
fullbrightCorner.CornerRadius = UDim.new(0, 5)
fullbrightCorner.Parent = fullbrightButton
fullbrightButton.Parent = basicHackFrame

-- Mobil için joystick ve Fly kontrol butonu (devam)
if deviceType == "Mobile" then
    local joystickFrame = Instance.new("Frame")
    joystickFrame.Size = UDim2.new(0, 100, 0, 100)
    joystickFrame.Position = UDim2.new(0, 10, 1, -110)
    joystickFrame.BackgroundTransparency = 0.5
    joystickFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    local joystickCorner = Instance.new("UICorner")
    joystickCorner.CornerRadius = UDim.new(0, 50)
    joystickCorner.Parent = joystickFrame
    joystickFrame.Parent = screenGui

    local joystickKnob = Instance.new("TextButton")
    joystickKnob.Size = UDim2.new(0, 40, 0, 40)
    joystickKnob.Position = UDim2.new(0.5, -20, 0.5, -20)
    joystickKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    joystickKnob.Text = ""
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 20)
    knobCorner.Parent = joystickKnob
    joystickKnob.Parent = joystickFrame

    local flyControlButton = Instance.new("TextButton")
    flyControlButton.Size = UDim2.new(0, 60, 0, 60)
    flyControlButton.Position = UDim2.new(1, -70, 1, -80)
    flyControlButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    flyControlButton.Text = "Fly"
    flyControlButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    flyControlButton.TextSize = 16
    local flyControlCorner = Instance.new("UICorner")
    flyControlCorner.CornerRadius = UDim.new(0, 10)
    flyControlCorner.Parent = flyControlButton
    flyControlButton.Parent = screenGui

    local touchStart, touchVector = nil, Vector2.new(0, 0)
    joystickKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            touchStart = input.Position
        end
    end)

    joystickKnob.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and touchStart then
            local delta = input.Position - touchStart
            local magnitude = delta.Magnitude
            local maxDistance = 30
            if magnitude > maxDistance then
                delta = delta.Unit * maxDistance
            end
            joystickKnob.Position = UDim2.new(0.5, delta.X - 20, 0.5, delta.Y - 20)
            touchVector = delta / maxDistance
            moveForward = -touchVector.Y
            moveRight = touchVector.X
        end
    end)

    joystickKnob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            touchStart = nil
            touchVector = Vector2.new(0, 0)
            joystickKnob.Position = UDim2.new(0.5, -20, 0.5, -20)
            moveForward = 0
            moveRight = 0
        end
    end)

    flyControlButton.MouseButton1Click:Connect(function()
        if flyControlButton then
            flyEnabled = not flyEnabled
            if flyToggleButton then
                flyToggleButton.Text = "Fly: " .. (flyEnabled and "Enabled (Test Phase)" or "Disabled (Test Phase)")
            end
            flyControlButton.Text = flyEnabled and "Fly Off" or "Fly"
            if flyEnabled and character and rootPart and humanoid then
                toggleFly()
            elseif not flyEnabled and isFlying then
                toggleFly()
            end
        end
    end)
end

-- Settings Frame Content
local bgColorButton = Instance.new("TextButton")
bgColorButton.Size = deviceType == "Mobile" and UDim2.new(0, 130, 0, 35) or UDim2.new(0, 200, 0, 40)
bgColorButton.Position = UDim2.new(0.5, -100, 0, 20)
bgColorButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
bgColorButton.Text = "Change BG Color"
bgColorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
bgColorButton.TextSize = 16
bgColorButton.Font = Enum.Font.Gotham
local bgColorCorner = Instance.new("UICorner")
bgColorCorner.CornerRadius = UDim.new(0, 5)
bgColorCorner.Parent = bgColorButton
bgColorButton.Parent = settingsFrame

bgColorButton.MouseButton1Click:Connect(function()
    if not bgColorButton then return end
    local colorPicker = Instance.new("ScreenGui")
    colorPicker.Parent = player:WaitForChild("PlayerGui")
    local colorFrame = Instance.new("Frame")
    colorFrame.Size = UDim2.new(0, 200, 0, 200)
    colorFrame.Position = UDim2.new(0.5, -100, 0.5, -100)
    colorFrame.BackgroundColor3 = backgroundColor
    colorFrame.BorderSizePixel = 0
    local colorCorner = Instance.new("UICorner")
    colorCorner.CornerRadius = UDim.new(0, 10)
    colorCorner.Parent = colorFrame
    colorFrame.Parent = colorPicker

    local rInput = Instance.new("TextBox")
    rInput.Size = UDim2.new(0, 50, 0, 30)
    rInput.Position = UDim2.new(0, 10, 0, 10)
    rInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    rInput.Text = "R: 30"
    rInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    rInput.TextSize = 14
    rInput.Font = Enum.Font.Gotham
    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 5)
    rCorner.Parent = rInput
    rInput.Parent = colorFrame

    local gInput = Instance.new("TextBox")
    gInput.Size = UDim2.new(0, 50, 0, 30)
    gInput.Position = UDim2.new(0, 70, 0, 10)
    gInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    gInput.Text = "G: 30"
    gInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    gInput.TextSize = 14
    gInput.Font = Enum.Font.Gotham
    local gCorner = Instance.new("UICorner")
    gCorner.CornerRadius = UDim.new(0, 5)
    gCorner.Parent = gInput
    gInput.Parent = colorFrame

    local bInput = Instance.new("TextBox")
    bInput.Size = UDim2.new(0, 50, 0, 30)
    bInput.Position = UDim2.new(0, 130, 0, 10)
    bInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    bInput.Text = "B: 30"
    bInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    bInput.TextSize = 14
    bInput.Font = Enum.Font.Gotham
    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 5)
    bCorner.Parent = bInput
    bInput.Parent = colorFrame

    local applyColorButton = Instance.new("TextButton")
    applyColorButton.Size = UDim2.new(0, 100, 0, 40)
    applyColorButton.Position = UDim2.new(0.5, -50, 0, 150)
    applyColorButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    applyColorButton.Text = "Apply Color"
    applyColorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyColorButton.TextSize = 16
    applyColorButton.Font = Enum.Font.Gotham
    local applyCorner = Instance.new("UICorner")
    applyCorner.CornerRadius = UDim.new(0, 5)
    applyCorner.Parent = applyColorButton
    applyColorButton.Parent = colorFrame

    local cancelColorButton = Instance.new("TextButton")
    cancelColorButton.Size = UDim2.new(0, 100, 0, 40)
    cancelColorButton.Position = UDim2.new(0.5, -50, 0, 200)
    cancelColorButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
    cancelColorButton.Text = "Cancel"
    cancelColorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelColorButton.TextSize = 16
    cancelColorButton.Font = Enum.Font.Gotham
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 5)
    cancelCorner.Parent = cancelColorButton
    cancelColorButton.Parent = colorFrame

    applyColorButton.MouseButton1Click:Connect(function()
        local r = tonumber(rInput.Text:match("R: (%d+)")) or 30
        local g = tonumber(gInput.Text:match("G: (%d+)")) or 30
        local b = tonumber(bInput.Text:match("B: (%d+)")) or 30
        r = math.clamp(r, 0, 255)
        g = math.clamp(g, 0, 255)
        b = math.clamp(b, 0, 255)
        backgroundColor = Color3.fromRGB(r, g, b)
        mainFrame.BackgroundColor3 = backgroundColor
        basicHackFrame.BackgroundColor3 = backgroundColor
        playersFrame.BackgroundColor3 = backgroundColor
        settingsFrame.BackgroundColor3 = backgroundColor
        playerTPFrame.BackgroundColor3 = backgroundColor
        playerViewerFrame.BackgroundColor3 = backgroundColor
        flingPlayerFrame.BackgroundColor3 = backgroundColor
        playerESPFrame.BackgroundColor3 = backgroundColor
        colorFrame:Destroy()
    end)

    cancelColorButton.MouseButton1Click:Connect(function()
        colorFrame:Destroy()
    end)
end)

-- Button Events
basicHackTabButton.MouseButton1Click:Connect(function()
    basicHackTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    playersTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    settingsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    basicHackFrame.Visible = true
    playersFrame.Visible = false
    settingsFrame.Visible = false
end)

playersTabButton.MouseButton1Click:Connect(function()
    basicHackTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playersTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    settingsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    basicHackFrame.Visible = false
    playersFrame.Visible = true
    settingsFrame.Visible = false
    updatePlayerTPList()
    updatePlayerViewerList()
    updateFlingPlayerList()
    updateESP()
end)

settingsTabButton.MouseButton1Click:Connect(function()
    basicHackTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playersTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    settingsTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    basicHackFrame.Visible = false
    playersFrame.Visible = false
    settingsFrame.Visible = true
end)

playerTPTabButton.MouseButton1Click:Connect(function()
    playerTPTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    playerViewerTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    flingPlayerTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerESPTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerTPFrame.Visible = true
    playerViewerFrame.Visible = false
    flingPlayerFrame.Visible = false
    playerESPFrame.Visible = false
    updatePlayerTPList()
end)

playerViewerTabButton.MouseButton1Click:Connect(function()
    playerTPTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerViewerTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    flingPlayerTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerESPTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerTPFrame.Visible = false
    playerViewerFrame.Visible = true
    flingPlayerFrame.Visible = false
    playerESPFrame.Visible = false
    updatePlayerViewerList()
end)

flingPlayerTabButton.MouseButton1Click:Connect(function()
    playerTPTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerViewerTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    flingPlayerTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    playerESPTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerTPFrame.Visible = false
    playerViewerFrame.Visible = false
    flingPlayerFrame.Visible = true
    playerESPFrame.Visible = false
    updateFlingPlayerList()
end)

playerESPTabButton.MouseButton1Click:Connect(function()
    playerTPTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerViewerTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    flingPlayerTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerESPTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    playerTPFrame.Visible = false
    playerViewerFrame.Visible = false
    flingPlayerFrame.Visible = false
    playerESPFrame.Visible = true
    updateESP()
end)

infJumpToggleButton.MouseButton1Click:Connect(function()
    local infJumpEnabled = infJumpToggleButton.Text:match("Enabled") ~= nil
    infJumpEnabled = not infJumpEnabled
    infJumpToggleButton.Text = "Infinite Jump: " .. (infJumpEnabled and "Enabled" or "Disabled")
    if infJumpEnabled then
        UserInputService.JumpRequest:Connect(function()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

flyToggleButton.MouseButton1Click:Connect(function()
    if flyToggleButton then
        flyEnabled = not flyEnabled
        flyToggleButton.Text = "Fly: " .. (flyEnabled and "Enabled (Test Phase)" or "Disabled (Test Phase)")
        if flyEnabled and character and rootPart and humanoid then
            flyLocked = false
            toggleFly()
        elseif not flyEnabled and isFlying then
            flyLocked = true
            toggleFly()
        end
    end
end)

teleportToggleButton.MouseButton1Click:Connect(function()
    local teleportEnabled = teleportToggleButton.Text:match("Enabled") ~= nil
    teleportEnabled = not teleportEnabled
    teleportToggleButton.Text = "Teleport: " .. (teleportEnabled and "Enabled" or "Disabled")
    teleportActive = teleportEnabled
end)

_G.noclipToggleButton.MouseButton1Click:Connect(function()
    toggleNoclip(not isNoclipEnabled)
end)

_G.flingToggleButton.MouseButton1Click:Connect(function()
    toggleFling(not flingEnabled)
end)

canTouchToggleButton.MouseButton1Click:Connect(function()
    local canTouchEnabledState = canTouchToggleButton.Text:match("Enabled") ~= nil
    toggleCanTouch(not canTouchEnabledState)
    canTouchToggleButton.Text = "Can Touch: " .. (not canTouchEnabledState and "Enabled" or "Disabled")
end)

invisibleButton.MouseButton1Click:Connect(function()
    toggleInvisible()
end)

fullbrightButton.MouseButton1Click:Connect(function()
    fullbrightActive = not fullbrightActive
    fullbrightButton.Text = "Fullbright: " .. (fullbrightActive and "Enabled" or "Disabled")
    if fullbrightActive then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000
        Lighting.FogStart = 0
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = origSettings.abt
        Lighting.OutdoorAmbient = origSettings.oabt
        Lighting.Brightness = origSettings.brt
        Lighting.ClockTime = origSettings.time
        Lighting.FogEnd = origSettings.fe
        Lighting.FogStart = origSettings.fs
        Lighting.GlobalShadows = origSettings.gs
    end
end)

espToggleButton.MouseButton1Click:Connect(function()
    ESPenabled = not ESPenabled
    espToggleButton.Text = "ESP: " .. (ESPenabled and "Enabled (Test Phase)" or "Disabled (Test Phase)")
    updateESP()
end)

showHealthButton.MouseButton1Click:Connect(function()
    showHealth = not showHealth
    showHealthButton.Text = "Show Health: " .. (showHealth and "Enabled (Test Phase)" or "Disabled (Test Phase)")
    updateESP()
end)

showDistanceButton.MouseButton1Click:Connect(function()
    showDistance = not showDistance
    showDistanceButton.Text = "Show Distance: " .. (showDistance and "Enabled (Test Phase)" or "Disabled (Test Phase)")
    updateESP()
end)

showTracerButton.MouseButton1Click:Connect(function()
    showTracer = not showTracer
    showTracerButton.Text = "Show Tracer: " .. (showTracer and "Enabled (Test Phase)" or "Disabled (Test Phase)")
    updateESP()
end)

changeColorButton.MouseButton1Click:Connect(function()
    local colorPicker = Instance.new("ScreenGui")
    colorPicker.Parent = player:WaitForChild("PlayerGui")
    local colorFrame = Instance.new("Frame")
    colorFrame.Size = UDim2.new(0, 200, 0, 200)
    colorFrame.Position = UDim2.new(0.5, -100, 0.5, -100)
    colorFrame.BackgroundColor3 = backgroundColor
    colorFrame.BorderSizePixel = 0
    local colorCorner = Instance.new("UICorner")
    colorCorner.CornerRadius = UDim.new(0, 10)
    colorCorner.Parent = colorFrame
    colorFrame.Parent = colorPicker

    local rInput = Instance.new("TextBox")
    rInput.Size = UDim2.new(0, 50, 0, 30)
    rInput.Position = UDim2.new(0, 10, 0, 10)
    rInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    rInput.Text = "R: " .. math.floor(espColor.R * 255)
    rInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    rInput.TextSize = 14
    rInput.Font = Enum.Font.Gotham
    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 5)
    rCorner.Parent = rInput
    rInput.Parent = colorFrame

    local gInput = Instance.new("TextBox")
    gInput.Size = UDim2.new(0, 50, 0, 30)
    gInput.Position = UDim2.new(0, 70, 0, 10)
    gInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    gInput.Text = "G: " .. math.floor(espColor.G * 255)
    gInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    gInput.TextSize = 14
    gInput.Font = Enum.Font.Gotham
    local gCorner = Instance.new("UICorner")
    gCorner.CornerRadius = UDim.new(0, 5)
    gCorner.Parent = gInput
    gInput.Parent = colorFrame

    local bInput = Instance.new("TextBox")
    bInput.Size = UDim2.new(0, 50, 0, 30)
    bInput.Position = UDim2.new(0, 130, 0, 10)
    bInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    bInput.Text = "B: " .. math.floor(espColor.B * 255)
    bInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    bInput.TextSize = 14
    bInput.Font = Enum.Font.Gotham
    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 5)
    bCorner.Parent = bInput
    bInput.Parent = colorFrame

    local applyColorButton = Instance.new("TextButton")
    applyColorButton.Size = UDim2.new(0, 100, 0, 40)
    applyColorButton.Position = UDim2.new(0.5, -50, 0, 150)
    applyColorButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    applyColorButton.Text = "Apply Color"
    applyColorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyColorButton.TextSize = 16
    applyColorButton.Font = Enum.Font.Gotham
    local applyCorner = Instance.new("UICorner")
    applyCorner.CornerRadius = UDim.new(0, 5)
    applyCorner.Parent = applyColorButton
    applyColorButton.Parent = colorFrame

    local cancelColorButton = Instance.new("TextButton")
    cancelColorButton.Size = UDim2.new(0, 100, 0, 40)
    cancelColorButton.Position = UDim2.new(0.5, -50, 0, 200)
    cancelColorButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
    cancelColorButton.Text = "Cancel"
    cancelColorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelColorButton.TextSize = 16
    cancelColorButton.Font = Enum.Font.Gotham
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 5)
    cancelCorner.Parent = cancelColorButton
    cancelColorButton.Parent = colorFrame

    applyColorButton.MouseButton1Click:Connect(function()
        local r = tonumber(rInput.Text:match("R: (%d+)")) or 255
        local g = tonumber(gInput.Text:match("G: (%d+)")) or 255
        local b = tonumber(bInput.Text:match("B: (%d+)")) or 255
        r = math.clamp(r, 0, 255)
        g = math.clamp(g, 0, 255)
        b = math.clamp(b, 0, 255)
        espColor = Color3.fromRGB(r, g, b)
        updateESP()
        colorFrame:Destroy()
    end)

    cancelColorButton.MouseButton1Click:Connect(function()
        colorFrame:Destroy()
    end)
end)

stopViewingButton.MouseButton1Click:Connect(function()
    isViewing = false
    viewedPlayer = nil
end)

startFlingButton.MouseButton1Click:Connect(function()
    if flingTarget and startFlingButton.Text == "Start Fling" then
        toggleFlingPlayer(true, flingTarget)
    elseif startFlingButton.Text == "Stop Fling" then
        toggleFlingPlayer(false)
    end
end)

stopFlingButton.MouseButton1Click:Connect(function()
    if flingPlayerEnabled then
        toggleFlingPlayer(false)
    end
end)

-- Fly ve Teleport Kontrolleri
RunService.RenderStepped:Connect(function()
    if isFlying and character and rootPart and bodyVelocity and bodyGyro then
        local moveDirection = (workspace.CurrentCamera.CFrame.lookVector * moveForward + workspace.CurrentCamera.CFrame.rightVector * moveRight + Vector3.new(0, moveUp, 0)).Unit
        bodyVelocity.Velocity = moveDirection * flySpeed
        bodyGyro.CFrame = workspace.CurrentCamera.CFrame
    end
    if teleportActive and mouse then
        if mouse.Target and mouse.Target.Parent then
            local targetHumanoid = mouse.Target.Parent:FindFirstChildWhichIsA("Humanoid")
            if targetHumanoid and targetHumanoid.Parent:FindFirstChild("HumanoidRootPart") then
                teleportToPlayer(targetHumanoid.Parent:FindFirstChild("HumanoidRootPart"))
            end
        end
    end
    if isViewing and viewedPlayer and viewedPlayer.Character and viewedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, viewedPlayer.Character.HumanoidRootPart.Position)
    else
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if deviceType == "PC" then
        if flyEnabled then
            if input.KeyCode == Enum.KeyCode.W then
                moveForward = 1
            elseif input.KeyCode == Enum.KeyCode.S then
                moveForward = -1
            elseif input.KeyCode == Enum.KeyCode.A then
                moveRight = -1
            elseif input.KeyCode == Enum.KeyCode.D then
                moveRight = 1
            elseif input.KeyCode == Enum.KeyCode.Space then
                moveUp = 1
            elseif input.KeyCode == Enum.KeyCode.LeftControl then
                moveUp = -1
            elseif input.KeyCode == Enum.KeyCode.F and flyEnabled then
                toggleFly()
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if deviceType == "PC" then
        if flyEnabled then
            if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
                moveForward = 0
            elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
                moveRight = 0
            elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.LeftControl then
                moveUp = 0
            end
        end
    end
end)

-- Player List Güncellemeleri
Players.PlayerAdded:Connect(function(player)
    wait(1)
    updatePlayerTPList()
    updatePlayerViewerList()
    updateFlingPlayerList()
end)

Players.PlayerRemoving:Connect(function(player)
    wait(1)
    updatePlayerTPList()
    updatePlayerViewerList()
    updateFlingPlayerList()
end)

-- Karakterin yeniden yüklenmesi durumunda değişkenleri güncelle
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    -- Fly ve Noclip için gerekli BodyVelocity ve BodyGyro'yu yeniden oluştur
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FlyVelocity"
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FlyGyro"
    bodyGyro.MaxTorque = Vector3.new(0, 0, 0)
    bodyGyro.D = 500
    bodyGyro.P = 5000
    bodyGyro.Parent = rootPart

    -- Mevcut durumları sıfırla
    if isFlying then
        toggleFly() -- Fly'ı kapatıp tekrar aç
        flyEnabled = true
        toggleFly()
    end
    if isNoclipEnabled then
        toggleNoclip(false) -- Noclip'i kapatıp tekrar aç
        toggleNoclip(true)
    end
    if isInvis then
        toggleInvisible() -- Görünmezliği kapatıp tekrar aç
        toggleInvisible()
    end
    if flingEnabled then
        toggleFling(false) -- Fling'i kapatıp tekrar aç
        toggleFling(true)
    end
    if flingPlayerEnabled then
        toggleFlingPlayer(false) -- Fling Player'ı kapatıp tekrar aç
        toggleFlingPlayer(true, flingTarget)
    end
    if canTouchEnabled then
        toggleCanTouch(false) -- Can Touch'ı kapatıp tekrar aç
        toggleCanTouch(true)
    end
end)
