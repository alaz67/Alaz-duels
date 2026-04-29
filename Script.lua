-- S7 Shub - Black & Purple Edition with Lock Toggle (Bat Aimbot) & Taunt Feature
-- With Discord Tag Above Head & Taunt Button (Draggable, sends /lol S7 Shub😂😂 twice)
-- Lock/Bat Aimbot: NO auto swing, purple line, smooth movement (60 speed)
-- Lagger: When holding Brainrot + Lagger ON = 10.5 walkspeed | Lagger ON + NO Brainrot = 35 walkspeed

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

local antiLagActive = false
local removeAccessoriesActive = false
local descendantConnection = nil
local accessoryConnection = nil

-- Black & Purple color scheme
local AL_BG = Color3.fromRGB(10, 10, 15)
local AL_CARD = Color3.fromRGB(20, 20, 30)
local AL_GREEN = Color3.fromRGB(180, 180, 200)
local AL_WHITE = Color3.fromRGB(230, 230, 240)
local AL_RED = Color3.fromRGB(170, 70, 70)
local AL_SW_OFF = Color3.fromRGB(45, 45, 55)
local AL_HOVER = Color3.fromRGB(35, 35, 45)
local PURPLE = Color3.fromRGB(156, 50, 255)
local DARK_PURPLE = Color3.fromRGB(100, 30, 170)

-- ==================== DESYNC GUI VARIABLES ====================
local desyncGUIActive = false
local desyncPanel = nil
local desyncStatusBox = nil
local desyncActive = false
local noAnimActive = false
local noAnimConnection = nil
local desyncMinimized = false

-- ==================== LAGGER VARIABLES ====================
local laggerActive = false
local laggerPanel = nil
local laggerMinimized = false
local LAGGER_SLOW_SPEED = 10.5
local LAGGER_NORMAL_SPEED = 35

-- Store original speed values
local originalNormalSpeed = 60
local originalCarrySpeed = 29
local originalAimbotSpeed = 60

-- Desync speeds
local DESYNC_NORMAL_SPEED = 40
local DESYNC_CARRY_SPEED = 20
local DESYNC_AIMBOT_SPEED = 35

-- ==================== DESYNC SPEED OVERRIDE FUNCTION ====================
local function updateDesyncSettings()
    if desyncActive then
        NORMAL_SPEED = DESYNC_NORMAL_SPEED
        SLOW_SPEED = DESYNC_CARRY_SPEED
        AIMBOT_SPEED = DESYNC_AIMBOT_SPEED
        if normalSpeedBox then
            normalSpeedBox.Text = tostring(DESYNC_NORMAL_SPEED)
            normalSpeedBox.TextColor3 = PURPLE
        end
        if carrySpeedBox then
            carrySpeedBox.Text = tostring(DESYNC_CARRY_SPEED)
            carrySpeedBox.TextColor3 = PURPLE
        end
    else
        NORMAL_SPEED = originalNormalSpeed
        SLOW_SPEED = originalCarrySpeed
        AIMBOT_SPEED = originalAimbotSpeed
        if normalSpeedBox then
            normalSpeedBox.Text = tostring(originalNormalSpeed)
            normalSpeedBox.TextColor3 = Color3.fromRGB(200, 200, 210)
        end
        if carrySpeedBox then
            carrySpeedBox.Text = tostring(originalCarrySpeed)
            carrySpeedBox.TextColor3 = Color3.fromRGB(200, 200, 210)
        end
    end
end

-- ==================== LAGGER FUNCTION ====================
local laggerMonitorConns = {}

local function updateLaggerSpeed()
    if not laggerActive then
        return
    end
    
    local char = player.Character
    if not char then return end
    
    local hasBrainrot = char:FindFirstChild("Brainrot") ~= nil
    local isStealing = player:GetAttribute("Stealing") == true
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if not hum then return end
    
    if hasBrainrot or isStealing then
        hum.WalkSpeed = LAGGER_SLOW_SPEED
    else
        if hum.WalkSpeed ~= LAGGER_NORMAL_SPEED then
            hum.WalkSpeed = LAGGER_NORMAL_SPEED
        end
    end
end

local function setupLaggerMonitor()
    local char = player.Character
    if not char then return end
    
    local function checkAndApply()
        if not laggerActive then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hasBrainrot = char:FindFirstChild("Brainrot") ~= nil
        local isStealing = player:GetAttribute("Stealing") == true
        
        if hum then
            if hasBrainrot or isStealing then
                hum.WalkSpeed = LAGGER_SLOW_SPEED
            else
                hum.WalkSpeed = LAGGER_NORMAL_SPEED
            end
        end
    end
    
    local addedConn = char.ChildAdded:Connect(function(child)
        if child.Name == "Brainrot" then
            checkAndApply()
        end
    end)
    
    local removedConn = char.ChildRemoved:Connect(function(child)
        if child.Name == "Brainrot" then
            checkAndApply()
        end
    end)
    
    table.insert(laggerMonitorConns, addedConn)
    table.insert(laggerMonitorConns, removedConn)
    
    checkAndApply()
end

local function cleanupLaggerMonitor()
    for _, conn in ipairs(laggerMonitorConns) do
        pcall(function() conn:Disconnect() end)
    end
    laggerMonitorConns = {}
end

-- ==================== BAT AIMBOT VARIABLES ====================
local batAimbotEnabled = false
local aimbotConnection = nil
local aimbotTarget = nil
local purpleLine = nil
local AIMBOT_SPEED = 60
local MELEE_OFFSET = 3
local lockedTarget = nil

-- Function to find Bat tool
local function findBatTool()
    local c = player.Character
    if not c then return nil end
    local bp = player:FindFirstChildOfClass("Backpack")
    local SlapList = {"Bat", "Slap", "Iron Slap", "Gold Slap", "Diamond Slap", "Emerald Slap", "Ruby Slap", "Dark Matter Slap", "Flame Slap", "Nuclear Slap", "Galaxy Slap", "Glitched Slap"}
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then
            return ch
        end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then
                return ch
            end
        end
    end
    for _, name in ipairs(SlapList) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    return nil
end

local function isTargetValid(targetChar)
    if not targetChar then return false end
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    local ff  = targetChar:FindFirstChildOfClass("ForceField")
    return hum and hrp and hum.Health > 0 and not ff
end

local function getBestTarget(myHRP)
    if lockedTarget and isTargetValid(lockedTarget) then
        return lockedTarget:FindFirstChild("HumanoidRootPart"), lockedTarget
    end
    local shortestDist = math.huge
    local newTargetChar, newTargetHRP = nil, nil
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player and isTargetValid(p.Character) then
            local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                local d = (tHRP.Position - myHRP.Position).Magnitude
                if d < shortestDist then
                    shortestDist = d
                    newTargetHRP  = tHRP
                    newTargetChar = p.Character
                end
            end
        end
    end
    lockedTarget = newTargetChar
    return newTargetHRP, newTargetChar
end

-- Start Bat Aimbot (NO auto swing, purple line, smooth movement)
local function startBatAimbot()
    if aimbotConnection then return end
    
    -- Create purple selection box for target
    if not purpleLine then
        purpleLine = Instance.new("SelectionBox")
        purpleLine.Name = "AimbotLine"
        purpleLine.Color3 = PURPLE
        purpleLine.LineThickness = 0.1
        purpleLine.Transparency = 0.3
    end
    
    -- Stop other movement scripts
    if aplOn then stopAutoPlayLeft() end
    if aprOn then stopAutoPlayRight() end
    if autoLOn then stopAutoL() end
    if autoROn then stopAutoR() end
    
    local r   = getHRP()
    local hum = getHum()
    
    aimbotConnection = RunService.Heartbeat:Connect(function(dt)
        if not batAimbotEnabled then return end
        
        local c = player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local humChar = c:FindFirstChildOfClass("Humanoid")
        if not h or not humChar then return end
        
        -- Auto-equip bat
        local bat = findBatTool()
        if bat and bat.Parent ~= c then
            humChar:EquipTool(bat)
        end
        
        -- Get best target
        local targetHRP, targetChar = getBestTarget(h)
        aimbotTarget = targetHRP
        
        -- Update purple line
        if aimbotTarget and purpleLine then
            purpleLine.Adornee = aimbotTarget
            if not purpleLine.Parent then
                purpleLine.Parent = aimbotTarget
            end
        elseif purpleLine then
            purpleLine.Adornee = nil
        end
        
        if targetHRP and targetChar then
            -- Prediction for smoother aim
            local targetVel = targetHRP.AssemblyLinearVelocity
            local speed = targetVel.Magnitude
            local predictTime = math.clamp(speed / 150, 0.05, 0.2)
            local predictedPos = targetHRP.Position + (targetVel * predictTime)
            local dirToTarget = predictedPos - h.Position
            local dist3D = dirToTarget.Magnitude
            local targetStandPos = dist3D > 0 and (predictedPos - dirToTarget.Unit * MELEE_OFFSET) or predictedPos
            
            -- Movement towards target
            local moveDir = targetStandPos - h.Position
            local distToStand = moveDir.Magnitude
            if distToStand > 1.5 then
                h.AssemblyLinearVelocity = moveDir.Unit * AIMBOT_SPEED
            else
                h.AssemblyLinearVelocity = targetVel
            end
            
            -- Face target
            humChar.AutoRotate = false
            h.CFrame = CFrame.lookAt(h.Position, Vector3.new(predictedPos.X, h.Position.Y, predictedPos.Z))
        else
            lockedTarget = nil
            if h then
                h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
            end
            if purpleLine then
                purpleLine.Adornee = nil
            end
            local humCurrent = getHum()
            if humCurrent then
                humCurrent.AutoRotate = true
            end
        end
    end)
end

local function stopBatAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    aimbotTarget = nil
    lockedTarget = nil
    if purpleLine then
        purpleLine.Adornee = nil
    end
    local humCurrent = getHum()
    if humCurrent then
        humCurrent.AutoRotate = true
    end
end

-- ==================== OTHER FUNCTIONS ====================
local function processDescendant(obj)
    if not antiLagActive then return end
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") then
        obj.Enabled = false
    end
    if obj:IsA("Decal") or obj:IsA("Texture") then
        obj.Transparency = 1
    end
    if obj:IsA("BasePart") then
        obj.Material = Enum.Material.Plastic
        obj.Reflectance = 0
        obj.CastShadow = false
    end
    if removeAccessoriesActive and (obj:IsA("Accessory") or obj:IsA("Hat")) then
        obj:Destroy()
    end
end

local function optimizeLighting()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9000000488
    Lighting.Brightness = 1
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("BloomEffect") or effect:IsA("DepthOfFieldEffect") then
            effect.Enabled = false
        end
    end
    task.spawn(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            processDescendant(obj)
        end
    end)
end

local function enableAntiLag()
    if antiLagActive then return end
    antiLagActive = true
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    optimizeLighting()
    if descendantConnection then descendantConnection:Disconnect() end
    descendantConnection = Workspace.DescendantAdded:Connect(processDescendant)
end

local function disableAntiLag()
    antiLagActive = false
    if descendantConnection then
        descendantConnection:Disconnect()
        descendantConnection = nil
    end
end

local function removeAllAccessories()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            for _, obj in ipairs(player.Character:GetDescendants()) do
                if obj:IsA("Accessory") or obj:IsA("Hat") then
                    obj:Destroy()
                end
            end
        end
    end
end

local function enableRemoveAccessories()
    removeAccessoriesActive = true
    removeAllAccessories()
    if not accessoryConnection then
        accessoryConnection = Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                if removeAccessoriesActive then
                    for _, obj in ipairs(char:GetDescendants()) do
                        if obj:IsA("Accessory") or obj:IsA("Hat") then
                            obj:Destroy()
                        end
                    end
                end
            end)
        end)
    end
    if descendantConnection then descendantConnection:Disconnect() end
    descendantConnection = Workspace.DescendantAdded:Connect(processDescendant)
end

local function disableRemoveAccessories()
    removeAccessoriesActive = false
    if accessoryConnection then
        accessoryConnection:Disconnect()
        accessoryConnection = nil
    end
end

local function createDiscordTag()
    local function addTag()
        local char = player.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        
        local existing = char:FindFirstChild("S7DiscordTag")
        if existing then existing:Destroy() end
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "S7DiscordTag"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 160, 0, 28)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = char
        
        local frame = Instance.new("Frame", billboard)
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        frame.BackgroundTransparency = 0.15
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
        
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = PURPLE
        stroke.Thickness = 1
        
        local text = Instance.new("TextLabel", frame)
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = "discord.gg/qMtvNQg68s"
        text.TextColor3 = Color3.fromRGB(200, 200, 210)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 11
        text.TextScaled = true
    end
    
    if player.Character then addTag() end
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        addTag()
    end)
end

-- ==================== TAUNT BUTTON (DRAGGABLE, SENDS /lol S7 Shub😂😂 TWICE) ====================
local tauntGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
tauntGui.Name = "S7TauntButton"
tauntGui.ResetOnSpawn = false
tauntGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local tauntBtn = Instance.new("TextButton", tauntGui)
tauntBtn.Size = UDim2.new(0, 80, 0, 38)
tauntBtn.Position = UDim2.new(1, -90, 0.5, -50)
tauntBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
tauntBtn.Text = "TAUNT"
tauntBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
tauntBtn.Font = Enum.Font.GothamBlack
tauntBtn.TextSize = 12
tauntBtn.ZIndex = 20
Instance.new("UICorner", tauntBtn).CornerRadius = UDim.new(0, 10)

local tauntStroke = Instance.new("UIStroke", tauntBtn)
tauntStroke.Color = PURPLE
tauntStroke.Thickness = 1.5

-- Make taunt button draggable
local tauntDragging = false
local tauntDragStart = nil
local tauntStartPos = nil

tauntBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tauntDragging = true
        tauntDragStart = input.Position
        tauntStartPos = tauntBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if tauntDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - tauntDragStart
        tauntBtn.Position = UDim2.new(tauntStartPos.X.Scale, tauntStartPos.X.Offset + delta.X, tauntStartPos.Y.Scale, tauntStartPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tauntDragging = false
    end
end)

local tauntCooldown = false

local function sendTaunt()
    if tauntCooldown then return end
    tauntCooldown = true
    
    -- Send the message twice with emojis
    local chatEvent = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
    for i = 1, 2 do
        chatEvent:FireServer("/lol S7 Shub😂😂", "All")
        task.wait(0.2)
    end
    
    tauntBtn.BackgroundColor3 = DARK_PURPLE
    task.wait(3)
    tauntBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    tauntCooldown = false
end

tauntBtn.MouseButton1Click:Connect(sendTaunt)

tauntBtn.MouseEnter:Connect(function()
    TweenService:Create(tauntBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}):Play()
end)
tauntBtn.MouseLeave:Connect(function()
    TweenService:Create(tauntBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25, 25, 35)}):Play()
end)

-- ==================== VARIABLES ====================
NORMAL_SPEED = 60
SLOW_SPEED = 29

POS_L1 = Vector3.new(-476.48,-6.28,92.73)
POS_L2 = Vector3.new(-483.12,-4.95,94.80)
POS_R1 = Vector3.new(-476.16,-6.52,25.62)
POS_R2 = Vector3.new(-483.04,-5.09,23.14)

FAP_L1 = Vector3.new(-476.48,-6.28,92.73)
FAP_L2 = Vector3.new(-482.85,-5.03,93.13)
FAP_L3 = Vector3.new(-475.68,-6.89,92.76)
FAP_L4 = Vector3.new(-476.50,-6.46,27.58)
FAP_L5 = Vector3.new(-482.42,-5.03,27.84)
FAP_R1 = Vector3.new(-476.16,-6.52,25.62)
FAP_R2 = Vector3.new(-483.06,-5.03,27.51)
FAP_R3 = Vector3.new(-476.21,-6.63,27.46)
FAP_R4 = Vector3.new(-476.66,-6.39,92.44)
FAP_R5 = Vector3.new(-481.94,-5.03,92.42)

aplOn = false
aprOn = false
aplPhase = 1
aprPhase = 1
aplConn = nil
aprConn = nil
autoLOn = false
autoROn = false
autoLConn = nil
autoRConn = nil
autoLPhase = 1
autoRPhase = 1
autoStealEnabled = false
isStealing = false
stealStartTime = nil
autoStealConn = nil
progressConn = nil
STEAL_RADIUS = 20
STEAL_DURATION = 0.35
antiRagdollEnabled = false
unwalkEnabled = false
unwalkConn = nil
galaxyEnabled = false
hopsEnabled = false
galaxyVF = nil
galaxyAtt = nil
DEFAULT_GRAVITY = 196.2
GALAXY_GRAVITY = 42
GALAXY_HOP = 35
HOP_COOLDOWN = 0.08
lastHop = 0
spaceHeld = false
spinBotEnabled = false
spinBAV = nil
SPIN_SPEED = 19
espEnabled = true
espConns = {}
optimizerEnabled = false
xrayOrig = {}
fovValue = 70
fovConn = nil
slowDownEnabled = true
infJumpEnabled = true
INF_JUMP_FORCE = 54
CLAMP_FALL = 80
gChar = nil
gHum = nil
gHrp = nil
ProgressBarFill = nil
ProgressLabel = nil
ProgressPctLabel = nil
animalCache = {}
promptCache = {}
stealCache = {}
toggleSetters = {}
mobBtnRefs = {}
AntiRagdollConns = {}
CONFIG_KEY = "S7_Hub_Config"
autoSaveEnabled = false
medusaCounterEnabled = false
goodAnimEnabled = false
goodAnimConn = nil

local function getHRP() local c = player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = player.Character; return c and c:FindFirstChildOfClass("Humanoid") end

local Anims = {idle1="rbxassetid://133806214992291",idle2="rbxassetid://94970088341563",walk="rbxassetid://707897309",run="rbxassetid://707861613",jump="rbxassetid://116936326516985",fall="rbxassetid://116936326516985",climb="rbxassetid://116936326516985",swim="rbxassetid://116936326516985",swimidle="rbxassetid://116936326516985"}
local origAnims = nil
local function saveOrigAnims(char) local a = char:FindFirstChild("Animate"); if not a then return end; local function g(o) return o and o.AnimationId or nil end; origAnims = {idle1=g(a.idle and a.idle.Animation1),idle2=g(a.idle and a.idle.Animation2),walk=g(a.walk and a.walk.WalkAnim),run=g(a.run and a.run.RunAnim),jump=g(a.jump and a.jump.JumpAnim),fall=g(a.fall and a.fall.FallAnim),climb=g(a.climb and a.climb.ClimbAnim),swim=g(a.swim and a.swim.Swim),swimidle=g(a.swimidle and a.swimidle.SwimIdle)} end
local function applyGoodAnims(char) local a = char:FindFirstChild("Animate"); if not a then return end; local function s(o,id) if o then o.AnimationId = id end end; s(a.idle and a.idle.Animation1,Anims.idle1); s(a.idle and a.idle.Animation2,Anims.idle2); s(a.walk and a.walk.WalkAnim,Anims.walk); s(a.run and a.run.RunAnim,Anims.run); s(a.jump and a.jump.JumpAnim,Anims.jump); s(a.fall and a.fall.FallAnim,Anims.fall); s(a.climb and a.climb.ClimbAnim,Anims.climb); s(a.swim and a.swim.Swim,Anims.swim); s(a.swimidle and a.swimidle.SwimIdle,Anims.swimidle) end
local function restoreOrigAnims(char) if not origAnims then return end; local a = char:FindFirstChild("Animate"); if not a then return end; local function s(o,id) if o and id then o.AnimationId = id end end; s(a.idle and a.idle.Animation1,origAnims.idle1); s(a.idle and a.idle.Animation2,origAnims.idle2); s(a.walk and a.walk.WalkAnim,origAnims.walk); s(a.run and a.run.RunAnim,origAnims.run); s(a.jump and a.jump.JumpAnim,origAnims.jump); s(a.fall and a.fall.FallAnim,origAnims.fall); s(a.climb and a.climb.ClimbAnim,origAnims.climb); s(a.swim and a.swim.Swim,origAnims.swim); s(a.swimidle and a.swimidle.SwimIdle,origAnims.swimidle); local hum = char:FindFirstChildOfClass("Humanoid"); if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop(0) end end end
local function startGoodAnim() local char = player.Character; if not char then return end; saveOrigAnims(char); applyGoodAnims(char); local hum = char:FindFirstChildOfClass("Humanoid"); if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop(0) end end; if goodAnimConn then goodAnimConn:Disconnect() end; goodAnimConn = RunService.Heartbeat:Connect(function() if not goodAnimEnabled then return end; local c = player.Character; if c then applyGoodAnims(c) end end) end
local function stopGoodAnim() if goodAnimConn then goodAnimConn:Disconnect(); goodAnimConn = nil end; local char = player.Character; if char then restoreOrigAnims(char) end end

local MEDUSA_COOLDOWN = 25
local medusaLastUsed = 0
local medusaDebounce = false
local medusaAnchorConns = {}
local function findMedusaTool() local char = player.Character; if not char then return nil end; for _,tool in ipairs(char:GetChildren()) do if tool:IsA("Tool") then local tn = tool.Name:lower(); if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end end end; local bp = player:FindFirstChild("Backpack"); if bp then for _,tool in ipairs(bp:GetChildren()) do if tool:IsA("Tool") then local tn = tool.Name:lower(); if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end end end end; return nil end
local function useMedusaCounter() if medusaDebounce then return end; if tick()-medusaLastUsed < MEDUSA_COOLDOWN then return end; local char = player.Character; if not char then return end; medusaDebounce = true; local med = findMedusaTool(); if not med then medusaDebounce = false; return end; if med.Parent ~= char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum:EquipTool(med) end end; pcall(function() med:Activate() end); medusaLastUsed = tick(); medusaDebounce = false end
local function stopMedusaCounter() for _,c in pairs(medusaAnchorConns) do pcall(function() c:Disconnect() end) end; medusaAnchorConns = {} end
local function setupMedusaCounter(char) stopMedusaCounter(); if not char then return end; local function onAnchorChanged(part) return part:GetPropertyChangedSignal("Anchored"):Connect(function() if medusaCounterEnabled and part.Anchored and part.Transparency == 1 then useMedusaCounter() end end) end; for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(medusaAnchorConns,onAnchorChanged(part)) end end; table.insert(medusaAnchorConns,char.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then table.insert(medusaAnchorConns,onAnchorChanged(part)) end end)) end

Keybinds = {
    AutoLeft = Enum.KeyCode.Z, AutoRight = Enum.KeyCode.C,
    AutoSteal = Enum.KeyCode.Unknown, BatAimbot = Enum.KeyCode.X,
    AntiRagdoll = Enum.KeyCode.Unknown, Unwalk = Enum.KeyCode.N,
    CarrySpd = Enum.KeyCode.F, Drop = Enum.KeyCode.B, TPDown = Enum.KeyCode.G,
    Lagger = Enum.KeyCode.L,
    MobAutoL = Enum.KeyCode.Unknown, MobAutoR = Enum.KeyCode.Unknown
}

local function saveConfig()
    pcall(function()
        if not writefile then return end
        local data = {NORMAL_SPEED=NORMAL_SPEED,SLOW_SPEED=SLOW_SPEED,STEAL_RADIUS=STEAL_RADIUS,STEAL_DURATION=STEAL_DURATION,GALAXY_GRAVITY=GALAXY_GRAVITY,GALAXY_HOP=GALAXY_HOP,SPIN_SPEED=SPIN_SPEED,fovValue=fovValue,AIMBOT_SPEED=AIMBOT_SPEED,infJumpEnabled=infJumpEnabled,espEnabled=espEnabled,antiRagdollEnabled=antiRagdollEnabled,unwalkEnabled=unwalkEnabled,spinBotEnabled=spinBotEnabled,slowDownEnabled=slowDownEnabled,galaxyEnabled=galaxyEnabled,optimizerEnabled=optimizerEnabled,autoStealEnabled=autoStealEnabled,batAimbotEnabled=batAimbotEnabled,autoSaveEnabled=autoSaveEnabled,medusaCounterEnabled=medusaCounterEnabled,goodAnimEnabled=goodAnimEnabled,laggerActive=laggerActive}
        for k in pairs(Keybinds) do
            local ok,name = pcall(function() return Keybinds[k].Name end)
            if ok and Keybinds[k] ~= Enum.KeyCode.Unknown then data["KEY_"..k] = name end
        end
        writefile(CONFIG_KEY..".json", game:GetService("HttpService"):JSONEncode(data))
    end)
end

local savedData = {}
local function loadConfig()
    pcall(function()
        if not (readfile and isfile and isfile(CONFIG_KEY..".json")) then return end
        local ok,data = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(CONFIG_KEY..".json")) end)
        if not ok or not data then return end
        savedData = data
        if data.NORMAL_SPEED then NORMAL_SPEED = data.NORMAL_SPEED; originalNormalSpeed = data.NORMAL_SPEED end
        if data.SLOW_SPEED then SLOW_SPEED = data.SLOW_SPEED; originalCarrySpeed = data.SLOW_SPEED end
        if data.AIMBOT_SPEED then AIMBOT_SPEED = data.AIMBOT_SPEED; originalAimbotSpeed = data.AIMBOT_SPEED end
        if data.STEAL_RADIUS then STEAL_RADIUS = data.STEAL_RADIUS end
        if data.STEAL_DURATION then STEAL_DURATION = data.STEAL_DURATION end
        if data.GALAXY_GRAVITY then GALAXY_GRAVITY = data.GALAXY_GRAVITY end
        if data.GALAXY_HOP then GALAXY_HOP = data.GALAXY_HOP end
        if data.SPIN_SPEED then SPIN_SPEED = data.SPIN_SPEED end
        if data.fovValue then fovValue = data.fovValue end
        if data.infJumpEnabled ~= nil then infJumpEnabled = data.infJumpEnabled end
        if data.espEnabled ~= nil then espEnabled = data.espEnabled end
        if data.antiRagdollEnabled ~= nil then antiRagdollEnabled = data.antiRagdollEnabled end
        if data.unwalkEnabled ~= nil then unwalkEnabled = data.unwalkEnabled end
        if data.spinBotEnabled ~= nil then spinBotEnabled = data.spinBotEnabled end
        if data.slowDownEnabled ~= nil then slowDownEnabled = data.slowDownEnabled end
        if data.galaxyEnabled ~= nil then galaxyEnabled = data.galaxyEnabled end
        if data.optimizerEnabled ~= nil then optimizerEnabled = data.optimizerEnabled end
        if data.autoStealEnabled ~= nil then autoStealEnabled = data.autoStealEnabled end
        if data.batAimbotEnabled ~= nil then batAimbotEnabled = data.batAimbotEnabled end
        if data.autoSaveEnabled ~= nil then autoSaveEnabled = data.autoSaveEnabled end
        if data.medusaCounterEnabled ~= nil then medusaCounterEnabled = data.medusaCounterEnabled end
        if data.goodAnimEnabled ~= nil then goodAnimEnabled = data.goodAnimEnabled end
        if data.laggerActive ~= nil then laggerActive = data.laggerActive end
        for k in pairs(Keybinds) do
            if data["KEY_"..k] then
                local kc = Enum.KeyCode[data["KEY_"..k]]
                if kc and kc ~= Enum.KeyCode.Unknown then pcall(function() Keybinds[k] = kc end) end
            end
        end
    end)
end
loadConfig()
player.AncestryChanged:Connect(function() if not player.Parent and autoSaveEnabled then saveConfig() end end)
game:GetService("Players").PlayerRemoving:Connect(function(p) if p == player and autoSaveEnabled then saveConfig() end end)

local function doTPDown()
    task.spawn(function()
        pcall(function()
            local c = player.Character; if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
            local rp = RaycastParams.new(); rp.FilterDescendantsInstances = {c}; rp.FilterType = Enum.RaycastFilterType.Exclude
            local hit = workspace:Raycast(hrp.Position, Vector3.new(0,-600,0), rp)
            if hit then hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero; local hh = hum.HipHeight or 2; local hy = hrp.Size.Y/2; hrp.CFrame = CFrame.new(hit.Position.X, hit.Position.Y+hh+hy+0.1, hit.Position.Z); hrp.AssemblyLinearVelocity = Vector3.zero end
        end)
    end)
end

UserInputService.JumpRequest:Connect(function() if not infJumpEnabled then return end; local h = getHRP(); if not h then return end; h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, INF_JUMP_FORCE, h.AssemblyLinearVelocity.Z) end)
RunService.Heartbeat:Connect(function() if not infJumpEnabled then return end; local h = getHRP(); if not h then return end; if h.AssemblyLinearVelocity.Y < -CLAMP_FALL then h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, -CLAMP_FALL, h.AssemblyLinearVelocity.Z) end end)

local _wfConns = {}
local _wfActive = false
local function startWalkFling() _wfActive = true; table.insert(_wfConns, RunService.Stepped:Connect(function() if not _wfActive then return end; for _,p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then for _,part in ipairs(p.Character:GetChildren()) do if part:IsA("BasePart") then part.CanCollide = false end end end end end)); local co = coroutine.create(function() while _wfActive do RunService.Heartbeat:Wait(); local c = player.Character; local root = c and c:FindFirstChild("HumanoidRootPart"); if not root then RunService.Heartbeat:Wait(); continue end; local vel = root.Velocity; root.Velocity = vel*10000 + Vector3.new(0,10000,0); RunService.RenderStepped:Wait(); if root and root.Parent then root.Velocity = vel end; RunService.Stepped:Wait(); if root and root.Parent then root.Velocity = vel + Vector3.new(0,0.1,0) end end end); coroutine.resume(co); table.insert(_wfConns, co) end
local function stopWalkFling() _wfActive = false; for _,c in ipairs(_wfConns) do if typeof(c)=="RBXScriptConnection" then c:Disconnect() elseif typeof(c)=="thread" then pcall(task.cancel, c) end end; _wfConns = {} end
local function doDrop() startWalkFling(); task.delay(0.4, stopWalkFling) end

local function startAntiRagdoll()
    if #AntiRagdollConns > 0 then return end
    local c = player.Character or player.CharacterAdded:Wait()
    local humanoid = c:WaitForChild("Humanoid")
    local root = c:WaitForChild("HumanoidRootPart")
    local animator = humanoid:WaitForChild("Animator")
    local maxVelocity = 40
    local clampVelocity = 25
    local maxClamp = 15
    local lastVelocity = Vector3.new(0,0,0)
    local function IsRagdollState() local state = humanoid:GetState(); return state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.GettingUp end
    local function CleanRagdollEffects() for _,obj in pairs(c:GetDescendants()) do if obj:IsA("BallSocketConstraint") or obj:IsA("NoCollisionConstraint") or obj:IsA("HingeConstraint") or (obj:IsA("Attachment") and (obj.Name=="A" or obj.Name=="B")) then obj:Destroy() elseif obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then obj:Destroy() elseif obj:IsA("Motor6D") then obj.Enabled = true end end; for _,track in pairs(animator:GetPlayingAnimationTracks()) do local animName = track.Animation and track.Animation.Name:lower() or ""; if animName:find("rag") or animName:find("fall") or animName:find("hurt") or animName:find("down") then track:Stop(0) end end end
    local function ReEnableControls() pcall(function() require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls():Enable() end) end
    table.insert(AntiRagdollConns, humanoid.StateChanged:Connect(function() if IsRagdollState() then humanoid:ChangeState(Enum.HumanoidStateType.Running); CleanRagdollEffects(); workspace.CurrentCamera.CameraSubject = humanoid; ReEnableControls() end end))
    table.insert(AntiRagdollConns, RunService.Heartbeat:Connect(function() if not antiRagdollEnabled then return end; if IsRagdollState() then CleanRagdollEffects(); local vel = root.AssemblyLinearVelocity; if (vel-lastVelocity).Magnitude > maxVelocity and vel.Magnitude > clampVelocity then root.AssemblyLinearVelocity = vel.Unit * math.min(vel.Magnitude, maxClamp) end; lastVelocity = vel end end))
    table.insert(AntiRagdollConns, c.DescendantAdded:Connect(function() if IsRagdollState() then CleanRagdollEffects() end end))
    table.insert(AntiRagdollConns, player.CharacterAdded:Connect(function(newChar) c = newChar; humanoid = newChar:WaitForChild("Humanoid"); root = newChar:WaitForChild("HumanoidRootPart"); animator = humanoid:WaitForChild("Animator"); lastVelocity = Vector3.new(0,0,0); ReEnableControls(); CleanRagdollEffects() end))
    ReEnableControls(); CleanRagdollEffects()
end
local function stopAntiRagdoll() for _,conn in pairs(AntiRagdollConns) do conn:Disconnect() end; AntiRagdollConns = {} end

local function startUnwalk() if not gChar then return end; local h2 = gChar:FindFirstChildOfClass("Humanoid"); if not h2 then return end; local anim = h2:FindFirstChildOfClass("Animator"); if not anim then return end; for _,t in ipairs(anim:GetPlayingAnimationTracks()) do t:Stop(0) end; if unwalkConn then unwalkConn:Disconnect() end; unwalkConn = RunService.Heartbeat:Connect(function() if not unwalkEnabled then if unwalkConn then unwalkConn:Disconnect(); unwalkConn = nil end; return end; local c = player.Character; if not c then return end; local hh = c:FindFirstChildOfClass("Humanoid"); if not hh then return end; local an = hh:FindFirstChildOfClass("Animator"); if not an then return end; for _,t in ipairs(an:GetPlayingAnimationTracks()) do t:Stop(0) end end) end
local function stopUnwalk() if unwalkConn then unwalkConn:Disconnect(); unwalkConn = nil end end

local function createESP(plr) if plr == player or not plr.Character then return end; local c = plr.Character; local root = c:FindFirstChild("HumanoidRootPart"); if not root then return end; local head = c:FindFirstChild("Head"); if not head then return end; if c:FindFirstChild("S7HubESP") then return end; local box = Instance.new("BoxHandleAdornment"); box.Name = "S7HubESP"; box.Adornee = root; box.Size = Vector3.new(4,6,2); box.Color3 = PURPLE; box.Transparency = 0.45; box.ZIndex = 10; box.AlwaysOnTop = true; box.Parent = c; local bb = Instance.new("BillboardGui"); bb.Name = "S7HubESP_Name"; bb.Adornee = head; bb.Size = UDim2.new(0,200,0,45); bb.StudsOffset = Vector3.new(0,3,0); bb.AlwaysOnTop = true; bb.Parent = c; local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1; lbl.Text = plr.DisplayName; lbl.TextColor3 = Color3.fromRGB(255,255,255); lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true; lbl.TextStrokeTransparency = 0.5; lbl.TextStrokeColor3 = DARK_PURPLE; lbl.Parent = bb end
local function removeESP(plr) if not plr.Character then return end; local b = plr.Character:FindFirstChild("S7HubESP"); local n = plr.Character:FindFirstChild("S7HubESP_Name"); if b then b:Destroy() end; if n then n:Destroy() end end
local function enableESP() for _,plr in ipairs(Players:GetPlayers()) do if plr ~= player then if plr.Character then pcall(function() createESP(plr) end) end; table.insert(espConns, plr.CharacterAdded:Connect(function() task.wait(0.1); if espEnabled then pcall(function() createESP(plr) end) end end)) end end; table.insert(espConns, Players.PlayerAdded:Connect(function(plr) if plr == player then return end; table.insert(espConns, plr.CharacterAdded:Connect(function() task.wait(0.1); if espEnabled then pcall(function() createESP(plr) end) end end)) end)) end
local function disableESP() for _,plr in ipairs(Players:GetPlayers()) do pcall(function() removeESP(plr) end) end; for _,c in ipairs(espConns) do if c and c.Connected then c:Disconnect() end end; espConns = {} end

local function enableOptimizer() pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01; Lighting.GlobalShadows = false; Lighting.Brightness = 2; Lighting.FogEnd = 9e9; for _,fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled = false end end end); pcall(function() for _,obj in ipairs(workspace:GetDescendants()) do pcall(function() if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then obj.Enabled = false; obj:Destroy() elseif obj:IsA("SelectionBox") then obj:Destroy() elseif obj:IsA("BasePart") then obj.CastShadow = false; obj.Material = Enum.Material.Plastic; for _,ch in ipairs(obj:GetChildren()) do if ch:IsA("Decal") or ch:IsA("Texture") or ch:IsA("SurfaceAppearance") then ch:Destroy() end end elseif obj:IsA("Sky") then obj:Destroy() end end) end end); pcall(function() for _,obj in ipairs(workspace:GetDescendants()) do if obj:IsA("BasePart") and obj.Anchored and (obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base"))) then xrayOrig[obj] = obj.LocalTransparencyModifier; obj.LocalTransparencyModifier = 0.88 end end end) end
local function disableOptimizer() pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic; Lighting.GlobalShadows = true end); for part,val in pairs(xrayOrig) do if part and part.Parent then part.LocalTransparencyModifier = val end end; xrayOrig = {} end

local function applyFOV() if fovConn then fovConn:Disconnect() end; fovConn = RunService.RenderStepped:Connect(function() workspace.CurrentCamera.FieldOfView = fovValue end) end

local function setupGalaxyForce() local h = getHRP(); if not h then return end; if galaxyVF then galaxyVF:Destroy() end; if galaxyAtt then galaxyAtt:Destroy() end; galaxyAtt = Instance.new("Attachment"); galaxyAtt.Parent = h; galaxyVF = Instance.new("VectorForce"); galaxyVF.Attachment0 = galaxyAtt; galaxyVF.ApplyAtCenterOfMass = true; galaxyVF.RelativeTo = Enum.ActuatorRelativeTo.World; galaxyVF.Force = Vector3.zero; galaxyVF.Parent = h end
local function updateGalaxyForce() if not galaxyEnabled or not galaxyVF or not gChar then return end; local mass = 0; for _,p in ipairs(gChar:GetDescendants()) do if p:IsA("BasePart") then mass = mass + p:GetMass() end end; local tg = DEFAULT_GRAVITY * (GALAXY_GRAVITY/100); galaxyVF.Force = Vector3.new(0, mass*(DEFAULT_GRAVITY-tg)*0.95, 0) end
local function startGalaxy() galaxyEnabled = true; hopsEnabled = true; pcall(setupGalaxyForce) end
local function stopGalaxy() galaxyEnabled = false; hopsEnabled = false; if galaxyVF then galaxyVF:Destroy(); galaxyVF = nil end; if galaxyAtt then galaxyAtt:Destroy(); galaxyAtt = nil end end
local function doHop() local h = getHRP(); local hh = getHum(); if not h or not hh then return end; if tick()-lastHop < HOP_COOLDOWN then return end; lastHop = tick(); if hh.FloorMaterial == Enum.Material.Air then h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, GALAXY_HOP, h.AssemblyLinearVelocity.Z) end end

local function startSpin() local c = player.Character; if not c then return end; local root = c:FindFirstChild("HumanoidRootPart"); if not root then return end; if spinBAV then spinBAV:Destroy() end; spinBAV = Instance.new("BodyAngularVelocity"); spinBAV.Name = "S7HubSpinBAV"; spinBAV.MaxTorque = Vector3.new(0, math.huge, 0); spinBAV.AngularVelocity = Vector3.new(0, SPIN_SPEED, 0); spinBAV.Parent = root end
local function stopSpin() if spinBAV then spinBAV:Destroy(); spinBAV = nil end end

local function stopAutoL() autoLOn = false; if autoLConn then autoLConn:Disconnect(); autoLConn = nil end; autoLPhase = 1; local hh = getHum(); if hh then hh:Move(Vector3.zero, false) end; local h = getHRP(); if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end end
local function stopAutoR() autoROn = false; if autoRConn then autoRConn:Disconnect(); autoRConn = nil end; autoRPhase = 1; local hh = getHum(); if hh then hh:Move(Vector3.zero, false) end; local h = getHRP(); if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end end
local function startAutoL() if autoLConn then autoLConn:Disconnect() end; autoLPhase = 1; local pts = {FAP_L1,FAP_L2,FAP_L3,FAP_L4,FAP_L5}; autoLConn = RunService.Heartbeat:Connect(function() if not autoLOn or not gHrp or not gHum then return end; local ph = autoLPhase; local tgt = pts[ph]; local spd = ph >= 3 and SLOW_SPEED or NORMAL_SPEED; local flat = Vector3.new(tgt.X - gHrp.Position.X, 0, tgt.Z - gHrp.Position.Z); if flat.Magnitude < 1 then if ph == 5 then gHum:Move(Vector3.zero, false); gHrp.AssemblyLinearVelocity = Vector3.zero; autoLOn = false; stopAutoL(); local info = mobBtnRefs["AUTO L"]; if info then info.btn.BackgroundColor3 = Color3.fromRGB(8,8,8); info.bs.Color = DARK_PURPLE; info.bs.Transparency = 0.2; info.state = false end; if toggleSetters["Auto Left"] then toggleSetters["Auto Left"](false) end; return elseif ph == 2 then gHum:Move(Vector3.zero, false); gHrp.AssemblyLinearVelocity = Vector3.zero; task.wait(0.05); autoLPhase = 3; return else autoLPhase = ph+1; return end end; local md = flat.Unit; gHum:Move(md, false); gHrp.AssemblyLinearVelocity = Vector3.new(md.X*spd, gHrp.AssemblyLinearVelocity.Y, md.Z*spd) end) end
local function startAutoR() if autoRConn then autoRConn:Disconnect() end; autoRPhase = 1; local pts = {FAP_R1,FAP_R2,FAP_R3,FAP_R4,FAP_R5}; autoRConn = RunService.Heartbeat:Connect(function() if not autoROn or not gHrp or not gHum then return end; local ph = autoRPhase; local tgt = pts[ph]; local spd = ph >= 3 and SLOW_SPEED or NORMAL_SPEED; local flat = Vector3.new(tgt.X - gHrp.Position.X, 0, tgt.Z - gHrp.Position.Z); if flat.Magnitude < 1 then if ph == 5 then gHum:Move(Vector3.zero, false); gHrp.AssemblyLinearVelocity = Vector3.zero; autoROn = false; stopAutoR(); local info = mobBtnRefs["AUTO R"]; if info then info.btn.BackgroundColor3 = Color3.fromRGB(8,8,8); info.bs.Color = DARK_PURPLE; info.bs.Transparency = 0.2; info.state = false end; if toggleSetters["Auto Right"] then toggleSetters["Auto Right"](false) end; return elseif ph == 2 then gHum:Move(Vector3.zero, false); gHrp.AssemblyLinearVelocity = Vector3.zero; task.wait(0.05); autoRPhase = 3; return else autoRPhase = ph+1; return end end; local md = flat.Unit; gHum:Move(md, false); gHrp.AssemblyLinearVelocity = Vector3.new(md.X*spd, gHrp.AssemblyLinearVelocity.Y, md.Z*spd) end) end

local function stopAutoPlayLeft() aplOn = false; if aplConn then aplConn:Disconnect(); aplConn = nil end; aplPhase = 1; local hh = getHum(); if hh then hh:Move(Vector3.zero, false) end; local h = getHRP(); if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end end
local function stopAutoPlayRight() aprOn = false; if aprConn then aprConn:Disconnect(); aprConn = nil end; aprPhase = 1; local hh = getHum(); if hh then hh:Move(Vector3.zero, false) end; local h = getHRP(); if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end end
local function startAutoPlayLeft() if aplConn then aplConn:Disconnect() end; aplPhase = 1; aplConn = RunService.Heartbeat:Connect(function() if not aplOn or not gHrp or not gHum then return end; local targets = {POS_L1,POS_L2}; local tp = targets[aplPhase]; local d = Vector3.new(tp.X - gHrp.Position.X, 0, tp.Z - gHrp.Position.Z); if d.Magnitude < 1 then if aplPhase == #targets then gHum:Move(Vector3.zero, false); gHrp.AssemblyLinearVelocity = Vector3.zero; aplOn = false; stopAutoPlayLeft(); local info = mobBtnRefs["PLAY L"]; if info then info.btn.BackgroundColor3 = Color3.fromRGB(8,8,8); info.bs.Color = DARK_PURPLE; info.bs.Transparency = 0.2; info.state = false end; if toggleSetters["Play Left"] then toggleSetters["Play Left"](false) end; return end; aplPhase = aplPhase+1 else local md = d.Unit; gHum:Move(md, false); local spd = NORMAL_SPEED; gHrp.AssemblyLinearVelocity = Vector3.new(md.X*spd, gHrp.AssemblyLinearVelocity.Y, md.Z*spd) end end) end
local function startAutoPlayRight() if aprConn then aprConn:Disconnect() end; aprPhase = 1; aprConn = RunService.Heartbeat:Connect(function() if not aprOn or not gHrp or not gHum then return end; local targets = {POS_R1,POS_R2}; local tp = targets[aprPhase]; local d = Vector3.new(tp.X - gHrp.Position.X, 0, tp.Z - gHrp.Position.Z); if d.Magnitude < 1 then if aprPhase == #targets then gHum:Move(Vector3.zero, false); gHrp.AssemblyLinearVelocity = Vector3.zero; aprOn = false; stopAutoPlayRight(); local info = mobBtnRefs["PLAY R"]; if info then info.btn.BackgroundColor3 = Color3.fromRGB(8,8,8); info.bs.Color = DARK_PURPLE; info.bs.Transparency = 0.2; info.state = false end; if toggleSetters["Play Right"] then toggleSetters["Play Right"](false) end; return end; aprPhase = aprPhase+1 else local md = d.Unit; gHum:Move(md, false); local spd = NORMAL_SPEED; gHrp.AssemblyLinearVelocity = Vector3.new(md.X*spd, gHrp.AssemblyLinearVelocity.Y, md.Z*spd) end end) end

local function isMyBase(plotName) local plots = workspace:FindFirstChild("Plots"); if not plots then return false end; local plot = plots:FindFirstChild(plotName); if not plot then return false end; local sign = plot:FindFirstChild("PlotSign"); if not sign then return false end; local yb = sign:FindFirstChild("YourBase"); return yb and yb:IsA("BillboardGui") and yb.Enabled == true end
local function scanPlot(plot) if not plot or not plot:IsA("Model") then return end; if isMyBase(plot.Name) then return end; local podiums = plot:FindFirstChild("AnimalPodiums"); if not podiums then return end; for _,pod in ipairs(podiums:GetChildren()) do if pod:IsA("Model") and pod:FindFirstChild("Base") then table.insert(animalCache, {plot=plot.Name, slot=pod.Name, worldPosition=pod:GetPivot().Position, uid=plot.Name.."_"..pod.Name}) end end end
local function findPromptForAnimal(ad) if not ad then return nil end; local cp = promptCache[ad.uid]; if cp and cp.Parent then return cp end; local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end; local plot = plots:FindFirstChild(ad.plot); if not plot then return nil end; local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then return nil end; local pod = pods:FindFirstChild(ad.slot); if not pod then return nil end; local base = pod:FindFirstChild("Base"); if not base then return nil end; local sp = base:FindFirstChild("Spawn"); if not sp then return nil end; local att = sp:FindFirstChild("PromptAttachment"); if not att then return nil end; for _,p in ipairs(att:GetChildren()) do if p:IsA("ProximityPrompt") then promptCache[ad.uid] = p; return p end end end
local function buildCallbacks(prompt) if stealCache[prompt] then return end; local data = {hold={}, trigger={}, ready=true}; pcall(function() if getconnections then for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if type(c.Function)=="function" then table.insert(data.hold, c.Function) end end; for _,c in ipairs(getconnections(prompt.Triggered)) do if type(c.Function)=="function" then table.insert(data.trigger, c.Function) end end end end); if #data.hold>0 or #data.trigger>0 then stealCache[prompt] = data end end
local function execSteal(prompt) local data = stealCache[prompt]; if not data or not data.ready then return false end; data.ready = false; isStealing = true; stealStartTime = tick(); if ProgressLabel then ProgressLabel.Text = "STEALING..." end; if progressConn then progressConn:Disconnect() end; progressConn = RunService.Heartbeat:Connect(function() if not isStealing then if progressConn then progressConn:Disconnect(); progressConn = nil end; return end; local prog = math.clamp((tick()-stealStartTime)/STEAL_DURATION, 0, 1); if ProgressBarFill then ProgressBarFill.Size = UDim2.new(prog, 0, 1, 0) end; if ProgressPctLabel then ProgressPctLabel.Text = math.floor(prog*100).."%" end end); task.spawn(function() for _,f in ipairs(data.hold) do task.spawn(f) end; task.wait(STEAL_DURATION); for _,f in ipairs(data.trigger) do task.spawn(f) end; if progressConn then progressConn:Disconnect(); progressConn = nil end; if ProgressLabel then ProgressLabel.Text = "READY" end; if ProgressPctLabel then ProgressPctLabel.Text = "" end; if ProgressBarFill then ProgressBarFill.Size = UDim2.new(0,0,1,0) end; data.ready = true; isStealing = false end); return true end
local function nearestAnimal() local h = getHRP(); if not h then return nil end; local best,bestD = nil, math.huge; for _,ad in ipairs(animalCache) do if not isMyBase(ad.plot) and ad.worldPosition then local d = (h.Position - ad.worldPosition).Magnitude; if d < bestD then bestD = d; best = ad end end end; return best end
local function startAutoSteal() if autoStealConn then return end; autoStealConn = RunService.Heartbeat:Connect(function() if not autoStealEnabled or isStealing then return end; local target = nearestAnimal(); if not target then return end; local h = getHRP(); if not h then return end; if (h.Position - target.worldPosition).Magnitude > STEAL_RADIUS then return end; local prompt = promptCache[target.uid]; if not prompt or not prompt.Parent then prompt = findPromptForAnimal(target) end; if prompt then buildCallbacks(prompt); execSteal(prompt) end end) end
local function stopAutoSteal() if autoStealConn then autoStealConn:Disconnect(); autoStealConn = nil end; isStealing = false; if progressConn then progressConn:Disconnect(); progressConn = nil end; if ProgressBarFill then ProgressBarFill.Size = UDim2.new(0,0,1,0) end; if ProgressLabel then ProgressLabel.Text = "READY" end; if ProgressPctLabel then ProgressPctLabel.Text = "" end end

task.spawn(function() task.wait(2); local plots = workspace:WaitForChild("Plots",10); if not plots then return end; for _,plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end; plots.ChildAdded:Connect(function(plot) if plot:IsA("Model") then task.wait(0.5); scanPlot(plot) end end); task.spawn(function() while task.wait(5) do animalCache = {}; for _,plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end end end) end)

RunService.Heartbeat:Connect(function()
    if not gChar or not gHum or not gHrp then return end
    if spinBotEnabled and spinBAV then spinBAV.AngularVelocity = Vector3.new(0, SPIN_SPEED, 0) end
    if galaxyEnabled then updateGalaxyForce() end
    if galaxyEnabled and hopsEnabled and spaceHeld then doHop() end
    if not batAimbotEnabled and not aplOn and not aprOn and not autoLOn and not autoROn then
        local md = gHum.MoveDirection
        if md.Magnitude > 0.1 then 
            local spd = slowDownEnabled and SLOW_SPEED or NORMAL_SPEED
            gHrp.AssemblyLinearVelocity = Vector3.new(md.X*spd, gHrp.AssemblyLinearVelocity.Y, md.Z*spd) 
        end
    end
end)

UserInputService.InputBegan:Connect(function(input) if input.KeyCode == Enum.KeyCode.Space then spaceHeld = true end end)
UserInputService.InputEnded:Connect(function(input) if input.KeyCode == Enum.KeyCode.Space then spaceHeld = false end end)

local function setupChar(c)
    if not c then return end
    gChar = c
    gHum = c:FindFirstChildOfClass("Humanoid")
    gHrp = c:FindFirstChild("HumanoidRootPart")
    if not gHum or not gHrp then 
        task.wait(0.5)
        gHum = c:FindFirstChildOfClass("Humanoid")
        gHrp = c:FindFirstChild("HumanoidRootPart")
        if not gHum or not gHrp then return end
    end
    
    task.wait(0.3)
    
    if galaxyEnabled then 
        pcall(stopGalaxy) 
        task.wait(0.1)
        pcall(startGalaxy) 
    end
    if antiRagdollEnabled then 
        pcall(stopAntiRagdoll)
        task.wait(0.1)
        pcall(startAntiRagdoll) 
    end
    if spinBotEnabled then 
        pcall(stopSpin)
        task.wait(0.1)
        pcall(startSpin) 
    end
    if espEnabled then pcall(enableESP) end
    if batAimbotEnabled then 
        pcall(stopBatAimbot)
        task.wait(0.1)
        pcall(startBatAimbot) 
    end
    if unwalkEnabled then pcall(startUnwalk) end
    if goodAnimEnabled then task.wait(0.3); pcall(startGoodAnim) end
    if medusaCounterEnabled then pcall(setupMedusaCounter, c) end
    
    if laggerActive then
        cleanupLaggerMonitor()
        setupLaggerMonitor()
    end
end

if player.Character then 
    task.wait(1)
    setupChar(player.Character) 
end

player.CharacterAdded:Connect(function(c) 
    task.wait(1.5)
    setupChar(c) 
end)

createDiscordTag()

-- ==================== LAGGER GUI FUNCTIONS ====================
local function makeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function createLaggerGUI()
    if laggerPanel then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "S7LaggerGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "LaggerFrame"
    mainFrame.Size = UDim2.new(0, 235, 0, 130)
    mainFrame.Position = UDim2.new(1, -250, 0.45, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 14)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = PURPLE
    mainStroke.Thickness = 1.8
    mainStroke.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "S7 LAGGER PANEL"
    titleLabel.Font = Enum.Font.LuckiestGuy
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Size = UDim2.new(1, -50, 0, 28)
    titleLabel.Position = UDim2.new(0, 14, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = mainFrame
    
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0, 26, 0, 26)
    dropdownBtn.Position = UDim2.new(1, -38, 0, 9)
    dropdownBtn.BackgroundTransparency = 1
    dropdownBtn.Text = "▼"
    dropdownBtn.TextColor3 = PURPLE
    dropdownBtn.Font = Enum.Font.LuckiestGuy
    dropdownBtn.TextSize = 22
    dropdownBtn.Parent = mainFrame
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -16, 1, -48)
    contentFrame.Position = UDim2.new(0, 8, 0, 40)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = contentFrame
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 6)
    contentPadding.PaddingBottom = UDim.new(0, 10)
    contentPadding.Parent = contentFrame
    
    local laggerRow = Instance.new("Frame")
    laggerRow.Size = UDim2.new(1, -10, 0, 32)
    laggerRow.BackgroundTransparency = 1
    laggerRow.LayoutOrder = 1
    laggerRow.Parent = contentFrame
    
    local laggerText = Instance.new("TextLabel")
    laggerText.Text = "LAGGER:"
    laggerText.Font = Enum.Font.LuckiestGuy
    laggerText.TextSize = 14
    laggerText.TextColor3 = Color3.fromRGB(200, 200, 210)
    laggerText.TextXAlignment = Enum.TextXAlignment.Left
    laggerText.Size = UDim2.new(0.45, 0, 1, 0)
    laggerText.BackgroundTransparency = 1
    laggerText.Parent = laggerRow
    
    local laggerStatusBox = Instance.new("TextLabel")
    laggerStatusBox.Size = UDim2.new(0.5, 0, 1, 0)
    laggerStatusBox.Position = UDim2.new(0.48, 0, 0, 0)
    laggerStatusBox.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    laggerStatusBox.BackgroundTransparency = 0.1
    laggerStatusBox.Text = "OFF"
    laggerStatusBox.TextColor3 = Color3.fromRGB(255, 80, 80)
    laggerStatusBox.TextSize = 13
    laggerStatusBox.Font = Enum.Font.LuckiestGuy
    laggerStatusBox.Parent = laggerRow
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = laggerStatusBox
    
    local laggerToggleBtn = Instance.new("TextButton")
    laggerToggleBtn.Size = UDim2.new(1, -10, 0, 38)
    laggerToggleBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    laggerToggleBtn.Text = "TOGGLE LAGGER"
    laggerToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    laggerToggleBtn.TextSize = 13
    laggerToggleBtn.Font = Enum.Font.LuckiestGuy
    laggerToggleBtn.LayoutOrder = 2
    laggerToggleBtn.Parent = contentFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = laggerToggleBtn
    
    local speedRow = Instance.new("Frame")
    speedRow.Size = UDim2.new(1, -10, 0, 32)
    speedRow.BackgroundTransparency = 1
    speedRow.LayoutOrder = 3
    speedRow.Parent = contentFrame
    
    local speedText = Instance.new("TextLabel")
    speedText.Text = "LAGGER SPEED:"
    speedText.Font = Enum.Font.LuckiestGuy
    speedText.TextSize = 12
    speedText.TextColor3 = Color3.fromRGB(180, 180, 190)
    speedText.TextXAlignment = Enum.TextXAlignment.Left
    speedText.Size = UDim2.new(0.7, 0, 1, 0)
    speedText.BackgroundTransparency = 1
    speedText.Parent = speedRow
    
    local speedValue = Instance.new("TextLabel")
    speedValue.Text = "35 / 10.5"
    speedValue.Font = Enum.Font.LuckiestGuy
    speedValue.TextSize = 12
    speedValue.TextColor3 = PURPLE
    speedValue.TextXAlignment = Enum.TextXAlignment.Right
    speedValue.Size = UDim2.new(0.25, 0, 1, 0)
    speedValue.Position = UDim2.new(0.73, 0, 0, 0)
    speedValue.BackgroundTransparency = 1
    speedValue.Parent = speedRow
    
    local function updateLaggerBtnUI()
        if laggerActive then
            laggerToggleBtn.Text = "LAGGER ACTIVE ✓"
            laggerToggleBtn.BackgroundColor3 = DARK_PURPLE
            laggerToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            laggerStatusBox.Text = "ACTIVE"
            laggerStatusBox.TextColor3 = PURPLE
        else
            laggerToggleBtn.Text = "TOGGLE LAGGER"
            laggerToggleBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
            laggerToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
            laggerStatusBox.Text = "OFF"
            laggerStatusBox.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end
    
    laggerToggleBtn.MouseButton1Click:Connect(function()
        laggerActive = not laggerActive
        updateLaggerBtnUI()
        
        if laggerActive then
            cleanupLaggerMonitor()
            setupLaggerMonitor()
        else
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local currentSpeed = desyncActive and DESYNC_NORMAL_SPEED or originalNormalSpeed
                    hum.WalkSpeed = currentSpeed
                end
            end
            cleanupLaggerMonitor()
        end
        saveConfig()
    end)
    
    dropdownBtn.MouseButton1Click:Connect(function()
        laggerMinimized = not laggerMinimized
        if laggerMinimized then
            dropdownBtn.Text = "▲"
            contentFrame.Visible = false
            mainFrame:TweenSize(UDim2.new(0, 235, 0, 44), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
        else
            dropdownBtn.Text = "▼"
            contentFrame.Visible = true
            mainFrame:TweenSize(UDim2.new(0, 235, 0, 130), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
        end
    end)
    
    updateLaggerBtnUI()
    makeDraggable(mainFrame)
    
    laggerPanel = screenGui
end

local function destroyLaggerGUI()
    if laggerPanel then
        laggerPanel:Destroy()
        laggerPanel = nil
    end
end

-- ==================== DESYNC GUI FUNCTIONS ====================
local function toggleNoAnim(state)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end

    if state then
        if noAnimConnection then return end
        noAnimConnection = RunService.RenderStepped:Connect(function()
            for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                track:Stop()
                track:AdjustSpeed(0)
            end
        end)
    else
        if noAnimConnection then
            noAnimConnection:Disconnect()
            noAnimConnection = nil
        end
    end
end

player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if noAnimActive then
        toggleNoAnim(true)
    end
end)

local function makeDesyncDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function createDesyncGUI()
    if desyncPanel then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "S7DesyncGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "DesyncFrame"
    mainFrame.Size = UDim2.new(0, 235, 0, 178)
    mainFrame.Position = UDim2.new(1, -250, 0.32, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 14)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = PURPLE
    mainStroke.Thickness = 1.8
    mainStroke.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "S7 DESYNC PANEL"
    titleLabel.Font = Enum.Font.LuckiestGuy
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Size = UDim2.new(1, -50, 0, 28)
    titleLabel.Position = UDim2.new(0, 14, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = mainFrame
    
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0, 26, 0, 26)
    dropdownBtn.Position = UDim2.new(1, -38, 0, 9)
    dropdownBtn.BackgroundTransparency = 1
    dropdownBtn.Text = "▼"
    dropdownBtn.TextColor3 = PURPLE
    dropdownBtn.Font = Enum.Font.LuckiestGuy
    dropdownBtn.TextSize = 22
    dropdownBtn.Parent = mainFrame
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -16, 1, -48)
    contentFrame.Position = UDim2.new(0, 8, 0, 40)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = contentFrame
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 6)
    contentPadding.PaddingBottom = UDim.new(0, 10)
    contentPadding.Parent = contentFrame
    
    local desyncRow = Instance.new("Frame")
    desyncRow.Size = UDim2.new(1, -10, 0, 32)
    desyncRow.BackgroundTransparency = 1
    desyncRow.LayoutOrder = 1
    desyncRow.Parent = contentFrame
    
    local desyncText = Instance.new("TextLabel")
    desyncText.Text = "DESYNC ACTIVE:"
    desyncText.Font = Enum.Font.LuckiestGuy
    desyncText.TextSize = 13
    desyncText.TextColor3 = Color3.fromRGB(200, 200, 210)
    desyncText.TextXAlignment = Enum.TextXAlignment.Left
    desyncText.Size = UDim2.new(0.55, 0, 1, 0)
    desyncText.BackgroundTransparency = 1
    desyncText.Parent = desyncRow
    
    desyncStatusBox = Instance.new("TextLabel")
    desyncStatusBox.Size = UDim2.new(0.4, 0, 1, 0)
    desyncStatusBox.Position = UDim2.new(0.58, 0, 0, 0)
    desyncStatusBox.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    desyncStatusBox.BackgroundTransparency = 0.1
    desyncStatusBox.Text = "OFF"
    desyncStatusBox.TextColor3 = Color3.fromRGB(255, 80, 80)
    desyncStatusBox.TextSize = 12
    desyncStatusBox.Font = Enum.Font.LuckiestGuy
    desyncStatusBox.Parent = desyncRow
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = desyncStatusBox
    
    local desyncActiveBtn = Instance.new("TextButton")
    desyncActiveBtn.Size = UDim2.new(1, -10, 0, 38)
    desyncActiveBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    desyncActiveBtn.Text = "TOGGLE DESYNC"
    desyncActiveBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    desyncActiveBtn.TextSize = 13
    desyncActiveBtn.Font = Enum.Font.LuckiestGuy
    desyncActiveBtn.LayoutOrder = 2
    desyncActiveBtn.Parent = contentFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = desyncActiveBtn
    
    local noAnimBtn = Instance.new("TextButton")
    noAnimBtn.Size = UDim2.new(1, -10, 0, 38)
    noAnimBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    noAnimBtn.Text = "NO ANIM: OFF"
    noAnimBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    noAnimBtn.TextSize = 13
    noAnimBtn.Font = Enum.Font.LuckiestGuy
    noAnimBtn.LayoutOrder = 3
    noAnimBtn.Parent = contentFrame
    
    local noAnimCorner = Instance.new("UICorner")
    noAnimCorner.CornerRadius = UDim.new(0, 10)
    noAnimCorner.Parent = noAnimBtn
    
    local function updateDesyncBtnUI()
        if desyncActive then
            desyncActiveBtn.Text = "DESYNC ACTIVE ✓"
            desyncActiveBtn.BackgroundColor3 = DARK_PURPLE
            desyncActiveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            desyncStatusBox.Text = "ACTIVE"
            desyncStatusBox.TextColor3 = PURPLE
            updateDesyncSettings()
        else
            desyncActiveBtn.Text = "TOGGLE DESYNC"
            desyncActiveBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
            desyncActiveBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
            desyncStatusBox.Text = "OFF"
            desyncStatusBox.TextColor3 = Color3.fromRGB(255, 80, 80)
            updateDesyncSettings()
        end
    end
    
    local function updateNoAnimBtnUI()
        if noAnimActive then
            noAnimBtn.Text = "NO ANIM: ON ✓"
            noAnimBtn.BackgroundColor3 = DARK_PURPLE
            noAnimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            noAnimBtn.Text = "NO ANIM: OFF"
            noAnimBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
            noAnimBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        end
    end
    
    desyncActiveBtn.MouseButton1Click:Connect(function()
        desyncActive = not desyncActive
        updateDesyncBtnUI()
        saveConfig()
    end)
    
    noAnimBtn.MouseButton1Click:Connect(function()
        noAnimActive = not noAnimActive
        updateNoAnimBtnUI()
        toggleNoAnim(noAnimActive)
        saveConfig()
    end)
    
    dropdownBtn.MouseButton1Click:Connect(function()
        desyncMinimized = not desyncMinimized
        if desyncMinimized then
            dropdownBtn.Text = "▲"
            contentFrame.Visible = false
            mainFrame:TweenSize(UDim2.new(0, 235, 0, 44), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
        else
            dropdownBtn.Text = "▼"
            contentFrame.Visible = true
            mainFrame:TweenSize(UDim2.new(0, 235, 0, 178), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
        end
    end)
    
    updateDesyncBtnUI()
    updateNoAnimBtnUI()
    
    makeDesyncDraggable(mainFrame)
    
    desyncPanel = screenGui
end

local function destroyDesyncGUI()
    if desyncPanel then
        desyncPanel:Destroy()
        desyncPanel = nil
        desyncStatusBox = nil
    end
end

-- ==================== MAIN GUI CREATION ====================
task.spawn(function()
    local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    ScreenGui.Name = "S7Hub_V1"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 10

    local PBGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    PBGui.Name = "S7Hub_ProgressBar"
    PBGui.ResetOnSpawn = false
    PBGui.IgnoreGuiInset = true
    PBGui.DisplayOrder = 5

    local toggleMenuBtn = Instance.new("TextButton", ScreenGui)
    toggleMenuBtn.Size = UDim2.new(0, 34, 0, 34)
    toggleMenuBtn.Position = UDim2.new(1, -142, 0, 10)
    toggleMenuBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    toggleMenuBtn.Text = "S7"
    toggleMenuBtn.TextColor3 = PURPLE
    toggleMenuBtn.Font = Enum.Font.GothamBlack
    toggleMenuBtn.TextSize = 13
    toggleMenuBtn.BackgroundTransparency = 0.1
    toggleMenuBtn.ZIndex = 10
    Instance.new("UICorner", toggleMenuBtn).CornerRadius = UDim.new(0, 9)
    local tStroke = Instance.new("UIStroke", toggleMenuBtn)
    tStroke.Thickness = 1.5
    tStroke.Color = PURPLE

    local lockBtn = Instance.new("TextButton", ScreenGui)
    lockBtn.Size = UDim2.new(0, 34, 0, 34)
    lockBtn.Position = UDim2.new(1, -180, 0, 10)
    lockBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    lockBtn.Text = "🔒"
    lockBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    lockBtn.Font = Enum.Font.GothamBold
    lockBtn.TextSize = 18
    lockBtn.BackgroundTransparency = 0.1
    lockBtn.ZIndex = 10
    Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 9)
    Instance.new("UIStroke", lockBtn).Color = DARK_PURPLE
    local dragLocked = false
    lockBtn.MouseButton1Click:Connect(function()
        dragLocked = not dragLocked
        lockBtn.Text = dragLocked and "🔒" or "🔓"
        lockBtn.TextColor3 = dragLocked and PURPLE or Color3.fromRGB(200, 200, 210)
    end)

    local mainFrame = Instance.new("Frame", ScreenGui)
    mainFrame.Size = UDim2.new(0, 178, 0, 420)
    mainFrame.Position = UDim2.new(0, 10, 0, 55)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    mainFrame.BackgroundTransparency = 0
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
    local mfStroke = Instance.new("UIStroke", mainFrame)
    mfStroke.Thickness = 1.5
    mfStroke.Color = PURPLE

    local guiLogo = Instance.new("ImageLabel", mainFrame)
    guiLogo.Size = UDim2.new(0, 28, 0, 28)
    guiLogo.Position = UDim2.new(0, 5, 0, 5)
    guiLogo.BackgroundTransparency = 1
    guiLogo.Image = "rbxassetid://6031094876"
    guiLogo.ZIndex = 15

    local leftDrag = Instance.new("Frame", mainFrame)
    leftDrag.Size = UDim2.new(0, 6, 1, -28)
    leftDrag.Position = UDim2.new(0, 0, 0, 14)
    leftDrag.BackgroundColor3 = DARK_PURPLE
    leftDrag.BorderSizePixel = 0
    leftDrag.ZIndex = 10
    leftDrag.Active = true
    Instance.new("UICorner", leftDrag).CornerRadius = UDim.new(0, 6)
    local stripPip = Instance.new("Frame", leftDrag)
    stripPip.Size = UDim2.new(0, 2, 0, 18)
    stripPip.Position = UDim2.new(0.5, -1, 0.5, -9)
    stripPip.BackgroundColor3 = PURPLE
    stripPip.BorderSizePixel = 0
    stripPip.ZIndex = 11
    Instance.new("UICorner", stripPip).CornerRadius = UDim.new(1, 0)

    local stripDragging = false
    local stripDragStart = nil
    local stripStartPos = nil
    leftDrag.InputBegan:Connect(function(inp)
        if dragLocked then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            stripDragging = true
            stripDragStart = Vector2.new(inp.Position.X, inp.Position.Y)
            stripStartPos = Vector2.new(mainFrame.Position.X.Offset, mainFrame.Position.Y.Offset)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            stripDragging = false
            stripDragStart = nil
            stripStartPos = nil
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragLocked or not stripDragging or not stripDragStart then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local dx = inp.Position.X - stripDragStart.X
            local dy = inp.Position.Y - stripDragStart.Y
            mainFrame.Position = UDim2.new(0, stripStartPos.X + dx, 0, stripStartPos.Y + dy)
        end
    end)

    local titleBar = Instance.new("Frame", mainFrame)
    titleBar.Size = UDim2.new(1, -6, 0, 20)
    titleBar.Position = UDim2.new(0, 6, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 3
    titleBar.Active = true
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)
    local tbFix = Instance.new("Frame", titleBar)
    tbFix.Size = UDim2.new(0, 14, 0.6, 0)
    tbFix.Position = UDim2.new(0, 0, 0.4, 0)
    tbFix.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    tbFix.BorderSizePixel = 0
    tbFix.ZIndex = 3
    local tbFix2 = Instance.new("Frame", titleBar)
    tbFix2.Size = UDim2.new(1, 0, 0.5, 0)
    tbFix2.Position = UDim2.new(0, 0, 0.5, 0)
    tbFix2.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    tbFix2.BorderSizePixel = 0
    tbFix2.ZIndex = 3

    local tbDragging = false
    local tbDragStart = nil
    local tbStartPos = nil
    titleBar.InputBegan:Connect(function(inp)
        if dragLocked then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            tbDragging = true
            tbDragStart = Vector2.new(inp.Position.X, inp.Position.Y)
            tbStartPos = Vector2.new(mainFrame.Position.X.Offset, mainFrame.Position.Y.Offset)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            tbDragging = false
            tbDragStart = nil
            tbStartPos = nil
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragLocked or not tbDragging or not tbDragStart then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local dx = inp.Position.X - tbDragStart.X
            local dy = inp.Position.Y - tbDragStart.Y
            mainFrame.Position = UDim2.new(0, tbStartPos.X + dx, 0, tbStartPos.Y + dy)
        end
    end)

    local titleLbl = Instance.new("TextLabel", titleBar)
    titleLbl.Size = UDim2.new(0, 80, 1, 0)
    titleLbl.Position = UDim2.new(0, 35, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "S7 SHUB"
    titleLbl.Font = Enum.Font.LuckiestGuy
    titleLbl.TextSize = 11
    titleLbl.TextColor3 = PURPLE
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 4
    
    local FPSLbl = Instance.new("TextLabel", titleBar)
    FPSLbl.Size = UDim2.new(0, 44, 1, 0)
    FPSLbl.Position = UDim2.new(1, -62, 0, 0)
    FPSLbl.BackgroundTransparency = 1
    FPSLbl.Text = "0 FPS"
    FPSLbl.Font = Enum.Font.GothamBold
    FPSLbl.TextSize = 8
    FPSLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
    FPSLbl.TextXAlignment = Enum.TextXAlignment.Right
    FPSLbl.ZIndex = 5
    
    local fc, lft = 0, tick()
    RunService.RenderStepped:Connect(function()
        fc = fc + 1
        local ct = tick()
        if ct - lft >= 1 then
            FPSLbl.Text = fc .. " FPS"
            fc = 0
            lft = ct
        end
    end)
    
    local minBtn = Instance.new("TextButton", titleBar)
    minBtn.Size = UDim2.new(0, 15, 0, 12)
    minBtn.Position = UDim2.new(1, -18, 0.5, -6)
    minBtn.BackgroundColor3 = DARK_PURPLE
    minBtn.Text = "−"
    minBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 10
    minBtn.ZIndex = 5
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 4)
    
    local guiVisible = true
    local function toggleVis()
        guiVisible = not guiVisible
        mainFrame.Visible = guiVisible
    end
    minBtn.MouseButton1Click:Connect(toggleVis)
    toggleMenuBtn.MouseButton1Click:Connect(toggleVis)

    local sep = Instance.new("Frame", mainFrame)
    sep.Size = UDim2.new(1, -6, 0, 1)
    sep.Position = UDim2.new(0, 6, 0, 20)
    sep.BackgroundColor3 = PURPLE
    sep.BorderSizePixel = 0
    sep.ZIndex = 3

    local scroll = Instance.new("ScrollingFrame", mainFrame)
    scroll.Size = UDim2.new(1, -8, 1, -24)
    scroll.Position = UDim2.new(0, 7, 0, 22)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = PURPLE
    scroll.BorderSizePixel = 0
    scroll.ZIndex = 2
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local ll = Instance.new("UIListLayout", scroll)
    ll.Padding = UDim.new(0, 0)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 8)
    end)

    local lo = 0
    local function nlo()
        lo = lo + 1
        return lo
    end

    local function makeSectionHeader(text)
        local h = Instance.new("Frame", scroll)
        h.Size = UDim2.new(1, 0, 0, 16)
        h.BackgroundTransparency = 1
        h.LayoutOrder = nlo()
        local l = Instance.new("TextLabel", h)
        l.Size = UDim2.new(1, -8, 1, 0)
        l.Position = UDim2.new(0, 8, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.Font = Enum.Font.GothamBlack
        l.TextSize = 8
        l.TextColor3 = PURPLE
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.ZIndex = 3
    end

    local function makeToggleRow(label, defaultState, onToggle)
        local row = Instance.new("Frame", scroll)
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
        row.BorderSizePixel = 0
        row.LayoutOrder = nlo()
        row.ZIndex = 2
        local div = Instance.new("Frame", row)
        div.Size = UDim2.new(1, -6, 0, 1)
        div.Position = UDim2.new(0, 3, 1, -1)
        div.BackgroundColor3 = DARK_PURPLE
        div.BorderSizePixel = 0
        div.ZIndex = 3
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.62, 0, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 10
        lbl.TextColor3 = Color3.fromRGB(215, 215, 225)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 3
        local tBg = Instance.new("Frame", row)
        tBg.Size = UDim2.new(0, 28, 0, 15)
        tBg.Position = UDim2.new(1, -32, 0.5, -7)
        tBg.BackgroundColor3 = defaultState and PURPLE or Color3.fromRGB(45, 45, 58)
        tBg.ZIndex = 3
        Instance.new("UICorner", tBg).CornerRadius = UDim.new(1, 0)
        local tCirc = Instance.new("Frame", tBg)
        tCirc.Size = UDim2.new(0, 10, 0, 10)
        tCirc.Position = defaultState and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
        tCirc.BackgroundColor3 = Color3.new(1, 1, 1)
        tCirc.ZIndex = 4
        Instance.new("UICorner", tCirc).CornerRadius = UDim.new(1, 0)
        local click = Instance.new("TextButton", row)
        click.Size = UDim2.new(1, 0, 1, 0)
        click.BackgroundTransparency = 1
        click.Text = ""
        click.ZIndex = 5
        local isOn = defaultState
        local function setVis(state)
            isOn = state
            tBg.BackgroundColor3 = isOn and PURPLE or Color3.fromRGB(45, 45, 58)
            tCirc.Position = isOn and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
        end
        toggleSetters[label] = setVis
        click.MouseButton1Click:Connect(function()
            isOn = not isOn
            setVis(isOn)
            if onToggle then onToggle(isOn) end
        end)
        return setVis
    end

    local function makeValueRow(label, defaultVal, onChanged)
        local row = Instance.new("Frame", scroll)
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
        row.BorderSizePixel = 0
        row.LayoutOrder = nlo()
        row.ZIndex = 2
        local div = Instance.new("Frame", row)
        div.Size = UDim2.new(1, -6, 0, 1)
        div.Position = UDim2.new(0, 3, 1, -1)
        div.BackgroundColor3 = DARK_PURPLE
        div.BorderSizePixel = 0
        div.ZIndex = 3
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 10
        lbl.TextColor3 = Color3.fromRGB(215, 215, 225)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 3
        local vb = Instance.new("TextBox", row)
        vb.Size = UDim2.new(0, 44, 0, 16)
        vb.Position = UDim2.new(1, -48, 0.5, -8)
        vb.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        vb.Text = tostring(defaultVal)
        vb.TextColor3 = PURPLE
        vb.Font = Enum.Font.GothamBold
        vb.TextSize = 10
        vb.ClearTextOnFocus = false
        vb.ZIndex = 4
        Instance.new("UICorner", vb).CornerRadius = UDim.new(0, 5)
        local vbStroke = Instance.new("UIStroke", vb)
        vbStroke.Color = DARK_PURPLE
        vb.FocusLost:Connect(function()
            local n = tonumber(vb.Text)
            if n then
                if onChanged then onChanged(n, vb) end
            else
                vb.Text = tostring(defaultVal)
            end
        end)
        return vb
    end

    local function makeActionBtn(text, cb)
        local row = Instance.new("Frame", scroll)
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
        row.BorderSizePixel = 0
        row.LayoutOrder = nlo()
        row.ZIndex = 2
        local div = Instance.new("Frame", row)
        div.Size = UDim2.new(1, -6, 0, 1)
        div.Position = UDim2.new(0, 3, 1, -1)
        div.BackgroundColor3 = DARK_PURPLE
        div.BorderSizePixel = 0
        div.ZIndex = 3
        local btn = Instance.new("TextButton", row)
        btn.Size = UDim2.new(1, -12, 0, 17)
        btn.Position = UDim2.new(0, 6, 0.5, -8)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(215, 215, 225)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.ZIndex = 3
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = DARK_PURPLE
        btn.MouseButton1Click:Connect(function()
            if cb then cb(btn) end
        end)
        return btn
    end

    local function makeKeybindRow(label, kbKey)
        local row = Instance.new("Frame", scroll)
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
        row.BorderSizePixel = 0
        row.LayoutOrder = nlo()
        row.ZIndex = 2
        local div = Instance.new("Frame", row)
        div.Size = UDim2.new(1, -6, 0, 1)
        div.Position = UDim2.new(0, 3, 1, -1)
        div.BackgroundColor3 = DARK_PURPLE
        div.BorderSizePixel = 0
        div.ZIndex = 3
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.55, 0, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 9
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 3
        local kbBtn = Instance.new("TextButton", row)
        kbBtn.Size = UDim2.new(0, 60, 0, 16)
        kbBtn.Position = UDim2.new(1, -64, 0.5, -8)
        kbBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        kbBtn.Text = (Keybinds[kbKey] and Keybinds[kbKey] ~= Enum.KeyCode.Unknown) and Keybinds[kbKey].Name or "—"
        kbBtn.TextColor3 = PURPLE
        kbBtn.Font = Enum.Font.GothamBold
        kbBtn.TextSize = 8
        kbBtn.ZIndex = 4
        Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 4)
        local kbStroke = Instance.new("UIStroke", kbBtn)
        kbStroke.Color = DARK_PURPLE
        local waiting = false
        kbBtn.MouseButton1Click:Connect(function()
            if waiting then return end
            waiting = true
            kbBtn.Text = "..."
            local con
            con = UserInputService.InputBegan:Connect(function(inp, gpe)
                if gpe then return end
                if inp.KeyCode ~= Enum.KeyCode.Unknown then
                    Keybinds[kbKey] = inp.KeyCode
                    kbBtn.Text = inp.KeyCode.Name
                    waiting = false
                    con:Disconnect()
                    saveConfig()
                end
            end)
        end)
    end

    -- ==================== DESYNC GUI TOGGLE ====================
    makeToggleRow("Desync GUI", false, function(s)
        desyncGUIActive = s
        if s then
            createDesyncGUI()
        else
            destroyDesyncGUI()
            if desyncActive then
                desyncActive = false
                updateDesyncSettings()
            end
            if noAnimActive then
                noAnimActive = false
                toggleNoAnim(false)
            end
        end
    end)

    -- ==================== LAGGER GUI TOGGLE ====================
    makeToggleRow("Lagger GUI", false, function(s)
        if s then
            createLaggerGUI()
        else
            destroyLaggerGUI()
            if laggerActive then
                laggerActive = false
                local char = player.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local currentSpeed = desyncActive and DESYNC_NORMAL_SPEED or originalNormalSpeed
                        hum.WalkSpeed = currentSpeed
                    end
                end
                cleanupLaggerMonitor()
            end
        end
    end)

    makeSectionHeader("MOVEMENT")
    makeToggleRow("Spin Bot", spinBotEnabled, function(s)
        spinBotEnabled = s
        if s then startSpin() else stopSpin() end
        saveConfig()
    end)
    makeValueRow("Spin Speed", SPIN_SPEED, function(v)
        SPIN_SPEED = math.clamp(v, 1, 200)
        if spinBAV then spinBAV.AngularVelocity = Vector3.new(0, SPIN_SPEED, 0) end
        saveConfig()
    end)
    makeToggleRow("Infinite Jump", infJumpEnabled, function(s)
        infJumpEnabled = s
        saveConfig()
    end)
    makeToggleRow("Anti Ragdoll", antiRagdollEnabled, function(s)
        antiRagdollEnabled = s
        if s then startAntiRagdoll() else stopAntiRagdoll() end
        saveConfig()
    end)
    makeToggleRow("Unwalk", unwalkEnabled, function(s)
        unwalkEnabled = s
        if s then startUnwalk() else stopUnwalk() end
        saveConfig()
    end)
    makeToggleRow("Good Animation", goodAnimEnabled, function(s)
        goodAnimEnabled = s
        if s then startGoodAnim() else stopGoodAnim() end
        saveConfig()
    end)
    makeToggleRow("Carry SPD", slowDownEnabled, function(s)
        slowDownEnabled = s
        saveConfig()
    end)
    local normalSpeedBox = makeValueRow("Normal Speed", NORMAL_SPEED, function(v)
        if not desyncActive then
            NORMAL_SPEED = math.clamp(v, 1, 300)
            originalNormalSpeed = NORMAL_SPEED
            saveConfig()
        end
    end)
    local carrySpeedBox = makeValueRow("Carry SPD Value", SLOW_SPEED, function(v)
        if not desyncActive then
            SLOW_SPEED = math.clamp(v, 1, 300)
            originalCarrySpeed = SLOW_SPEED
            saveConfig()
        end
    end)

    makeSectionHeader("AUTOMATION")
    -- Lock button toggles Bat Aimbot
    makeToggleRow("Lock", batAimbotEnabled, function(s)
        batAimbotEnabled = s
        if s then
            if aplOn then stopAutoPlayLeft(); if toggleSetters["Play Left"] then toggleSetters["Play Left"](false) end end
            if aprOn then stopAutoPlayRight(); if toggleSetters["Play Right"] then toggleSetters["Play Right"](false) end end
            if autoLOn then stopAutoL(); if toggleSetters["Auto Left"] then toggleSetters["Auto Left"](false) end end
            if autoROn then stopAutoR(); if toggleSetters["Auto Right"] then toggleSetters["Auto Right"](false) end end
            startBatAimbot()
        else
            stopBatAimbot()
        end
        saveConfig()
    end)
    makeToggleRow("Auto Steal", autoStealEnabled, function(s)
        autoStealEnabled = s
        if s then startAutoSteal() else stopAutoSteal() end
        saveConfig()
    end)
    makeValueRow("Steal Radius", STEAL_RADIUS, function(v)
        STEAL_RADIUS = math.clamp(v, 1, 300)
        saveConfig()
    end)
    makeToggleRow("Auto Left", false, function(s)
        if s then
            if batAimbotEnabled then stopBatAimbot(); if toggleSetters["Lock"] then toggleSetters["Lock"](false) end end
            if aprOn then stopAutoPlayRight(); if toggleSetters["Play Right"] then toggleSetters["Play Right"](false) end end
            if autoROn then stopAutoR(); if toggleSetters["Auto Right"] then toggleSetters["Auto Right"](false) end end
            if aplOn then stopAutoPlayLeft(); if toggleSetters["Play Left"] then toggleSetters["Play Left"](false) end end
            autoLOn = true
            startAutoL()
        else
            autoLOn = false
            stopAutoL()
        end
    end)
    makeToggleRow("Auto Right", false, function(s)
        if s then
            if batAimbotEnabled then stopBatAimbot(); if toggleSetters["Lock"] then toggleSetters["Lock"](false) end end
            if aplOn then stopAutoPlayLeft(); if toggleSetters["Play Left"] then toggleSetters["Play Left"](false) end end
            if autoLOn then stopAutoL(); if toggleSetters["Auto Left"] then toggleSetters["Auto Left"](false) end end
            if aprOn then stopAutoPlayRight(); if toggleSetters["Play Right"] then toggleSetters["Play Right"](false) end end
            autoROn = true
            startAutoR()
        else
            autoROn = false
            stopAutoR()
        end
    end)

    makeSectionHeader("DEFENSE")
    makeToggleRow("Medusa Counter", medusaCounterEnabled, function(s)
        medusaCounterEnabled = s
        if s then setupMedusaCounter(player.Character) else stopMedusaCounter() end
        saveConfig()
    end)

    makeSectionHeader("ACTIONS")
    makeActionBtn("DROP", function() task.spawn(doDrop) end)
    makeActionBtn("TP DOWN", function() task.spawn(doTPDown) end)

    makeSectionHeader("WORLD & VISUALS")
    makeToggleRow("Player ESP", espEnabled, function(s)
        espEnabled = s
        if s then enableESP() else disableESP() end
        saveConfig()
    end)
    makeToggleRow("Galaxy Mode", galaxyEnabled, function(s)
        galaxyEnabled = s
        if s then startGalaxy() else stopGalaxy() end
        saveConfig()
    end)
    makeValueRow("Gravity %", GALAXY_GRAVITY, function(v)
        GALAXY_GRAVITY = math.clamp(v, 1, 300)
        saveConfig()
    end)
    makeValueRow("Hop Power", GALAXY_HOP, function(v)
        GALAXY_HOP = math.clamp(v, 1, 200)
        saveConfig()
    end)
    makeToggleRow("Optimizer+XRay", optimizerEnabled, function(s)
        optimizerEnabled = s
        if s then enableOptimizer() else disableOptimizer() end
        saveConfig()
    end)
    makeValueRow("Field of View", fovValue, function(v)
        fovValue = math.clamp(v, 10, 120)
        applyFOV()
        saveConfig()
    end)

    makeSectionHeader("SETTINGS")
    makeToggleRow("Auto Save Config", autoSaveEnabled, function(s)
        autoSaveEnabled = s
        saveConfig()
    end)
    makeActionBtn("Save Config", function(btn)
        saveConfig()
        btn.Text = "Saved!"
        btn.TextColor3 = PURPLE
        task.delay(1.5, function()
            btn.Text = "Save Config"
            btn.TextColor3 = Color3.fromRGB(215, 215, 225)
        end)
    end)

    makeSectionHeader("KEYBINDS")
    makeKeybindRow("Auto Left", "AutoLeft")
    makeKeybindRow("Auto Right", "AutoRight")
    makeKeybindRow("Lock", "BatAimbot")
    makeKeybindRow("Carry SPD", "CarrySpd")
    makeKeybindRow("Drop", "Drop")
    makeKeybindRow("TP Down", "TPDown")
    makeKeybindRow("Auto Steal", "AutoSteal")
    makeKeybindRow("Anti Ragdoll", "AntiRagdoll")
    makeKeybindRow("Unwalk", "Unwalk")
    makeKeybindRow("Lagger", "Lagger")

    local PBC = Instance.new("Frame", PBGui)
    PBC.Size = UDim2.new(0, 196, 0, 36)
    PBC.Position = UDim2.new(0.5, -98, 1, -110)
    PBC.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    PBC.BackgroundTransparency = 0.1
    PBC.BorderSizePixel = 0
    PBC.Active = true
    Instance.new("UICorner", PBC).CornerRadius = UDim.new(0, 11)
    local pbs = Instance.new("UIStroke", PBC)
    pbs.Color = PURPLE
    pbs.Thickness = 1.5
    local cashHubText = Instance.new("TextLabel", PBC)
    cashHubText.Size = UDim2.new(0.38, 0, 0.55, 0)
    cashHubText.Position = UDim2.new(0.62, 0, 0, 3)
    cashHubText.BackgroundTransparency = 1
    cashHubText.Text = "S7 SHUB"
    cashHubText.TextColor3 = PURPLE
    cashHubText.Font = Enum.Font.GothamBlack
    cashHubText.TextSize = 11
    cashHubText.TextXAlignment = Enum.TextXAlignment.Right
    cashHubText.ZIndex = 3
    ProgressLabel = Instance.new("TextLabel", PBC)
    ProgressLabel.Size = UDim2.new(0.55, 0, 0.55, 0)
    ProgressLabel.Position = UDim2.new(0, 8, 0, 3)
    ProgressLabel.BackgroundTransparency = 1
    ProgressLabel.Text = "READY"
    ProgressLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    ProgressLabel.Font = Enum.Font.GothamBold
    ProgressLabel.TextSize = 10
    ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
    ProgressLabel.ZIndex = 3
    ProgressPctLabel = Instance.new("TextLabel", PBC)
    ProgressPctLabel.Size = UDim2.new(0, 0, 0, 0)
    ProgressPctLabel.Visible = false
    local pt = Instance.new("Frame", PBC)
    pt.Size = UDim2.new(0.9, 0, 0, 5)
    pt.Position = UDim2.new(0.05, 0, 1, -10)
    pt.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
    pt.BorderSizePixel = 0
    pt.ZIndex = 2
    Instance.new("UICorner", pt).CornerRadius = UDim.new(1, 0)
    ProgressBarFill = Instance.new("Frame", pt)
    ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
    ProgressBarFill.BackgroundColor3 = PURPLE
    ProgressBarFill.BorderSizePixel = 0
    ProgressBarFill.ZIndex = 3
    Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(1, 0)

    local PURPLE_ON = PURPLE
    local BLACK_OFF = Color3.fromRGB(8, 8, 8)
    local panelGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    panelGui.Name = "S7Hub_MobilePanel"
    panelGui.ResetOnSpawn = false
    panelGui.IgnoreGuiInset = true
    panelGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    panelGui.DisplayOrder = 8

    local panelFrame = Instance.new("Frame", panelGui)
    panelFrame.Name = "MobilePanel"
    panelFrame.Size = UDim2.new(0, 120, 0, 232)
    panelFrame.Position = UDim2.new(1, -128, 0.5, -116)
    panelFrame.BackgroundColor3 = Color3.fromRGB(4, 4, 6)
    panelFrame.BackgroundTransparency = 0.05
    panelFrame.BorderSizePixel = 0
    panelFrame.Active = true
    panelFrame.ZIndex = 20
    Instance.new("UICorner", panelFrame).CornerRadius = UDim.new(0, 14)
    local psk = Instance.new("UIStroke", panelFrame)
    psk.Color = PURPLE
    psk.Thickness = 1.2
    psk.Transparency = 0.3

    local pDragging = false
    local pDragStart = nil
    local pFrameStart = nil
    local panelDragConn1 = panelFrame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            pDragging = true
            pDragStart = Vector2.new(inp.Position.X, inp.Position.Y)
            pFrameStart = Vector2.new(panelFrame.Position.X.Offset, panelFrame.Position.Y.Offset)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            pDragging = false
            pDragStart = nil
            pFrameStart = nil
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not pDragging or not pDragStart then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local dx = inp.Position.X - pDragStart.X
            local dy = inp.Position.Y - pDragStart.Y
            if math.abs(dx) > 2 or math.abs(dy) > 2 then
                panelFrame.Position = UDim2.new(panelFrame.Position.X.Scale, pFrameStart.X + dx, panelFrame.Position.Y.Scale, pFrameStart.Y + dy)
            end
        end
    end)

    local panelTitle = Instance.new("TextLabel", panelFrame)
    panelTitle.Size = UDim2.new(1, -4, 0, 12)
    panelTitle.Position = UDim2.new(0, 2, 0, 2)
    panelTitle.BackgroundTransparency = 1
    panelTitle.Text = "S7 SHUB"
    panelTitle.Font = Enum.Font.LuckiestGuy
    panelTitle.TextSize = 8
    panelTitle.TextColor3 = PURPLE
    panelTitle.TextXAlignment = Enum.TextXAlignment.Center
    panelTitle.ZIndex = 26
    task.spawn(function()
        local t = 0
        while panelTitle and panelTitle.Parent do
            t = t + 0.05
            local p = (math.sin(t * 2) + 1) / 2
            panelTitle.TextColor3 = Color3.fromRGB(math.floor(156 - p * 56), math.floor(50 + p * 50), 255)
            task.wait(0.05)
        end
    end)

    local btnGrid = Instance.new("Frame", panelFrame)
    btnGrid.Size = UDim2.new(1, -8, 0, 212)
    btnGrid.Position = UDim2.new(0, 4, 0, 15)
    btnGrid.BackgroundTransparency = 1
    btnGrid.ZIndex = 21
    local gl = Instance.new("UIGridLayout", btnGrid)
    gl.CellSize = UDim2.new(0.5, -3, 0, 50)
    gl.CellPadding = UDim2.new(0, 5, 0, 4)
    gl.SortOrder = Enum.SortOrder.LayoutOrder
    gl.FillDirectionMaxCells = 2

    local function makePBtn(l1, l2, order)
        local btn = Instance.new("TextButton", btnGrid)
        btn.LayoutOrder = order
        btn.Size = UDim2.new(0, 1, 0, 1)
        btn.BackgroundColor3 = BLACK_OFF
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.ZIndex = 22
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        local bs = Instance.new("UIStroke", btn)
        bs.Color = DARK_PURPLE
        bs.Thickness = 1
        bs.Transparency = 0.2
        local t1 = Instance.new("TextLabel", btn)
        t1.Size = UDim2.new(1, 0, 0.52, 0)
        t1.Position = UDim2.new(0, 0, 0.06, 0)
        t1.BackgroundTransparency = 1
        t1.Text = l1
        t1.TextColor3 = Color3.fromRGB(255, 255, 255)
        t1.Font = Enum.Font.GothamBlack
        t1.TextSize = 10
        t1.TextXAlignment = Enum.TextXAlignment.Center
        t1.ZIndex = 23
        local t2 = Instance.new("TextLabel", btn)
        t2.Size = UDim2.new(1, 0, 0.44, 0)
        t2.Position = UDim2.new(0, 0, 0.52, 0)
        t2.BackgroundTransparency = 1
        t2.Text = l2
        t2.TextColor3 = Color3.fromRGB(255, 255, 255)
        t2.Font = Enum.Font.GothamBlack
        t2.TextSize = 10
        t2.TextXAlignment = Enum.TextXAlignment.Center
        t2.ZIndex = 23
        btn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                pDragging = false
            end
        end)
        return btn, bs
    end

    local function setPH(btn, bs, isOn)
        btn.BackgroundColor3 = isOn and PURPLE_ON or BLACK_OFF
        bs.Color = isOn and PURPLE or DARK_PURPLE
        bs.Transparency = isOn and 0 or 0.2
    end

    local btnAAL, bsAAL = makePBtn("AUTO", "L", 1)
    local btnAAR, bsAAR = makePBtn("AUTO", "R", 2)
    local btnDR, bsDR = makePBtn("DROP", "", 5)
    local btnTP, bsTP = makePBtn("TP", "DOWN", 6)
    local btnLK, bsLK = makePBtn("LOCK", "", 7)
    local btnCS, bsCS = makePBtn("CARRY", "SPD", 8)

    local pState = {AAL = false, AAR = false, LK = batAimbotEnabled, CS = slowDownEnabled}
    mobBtnRefs["AUTO L"] = {btn = btnAAL, bs = bsAAL, state = false}
    mobBtnRefs["AUTO R"] = {btn = btnAAR, bs = bsAAR, state = false}
    if pState.LK then setPH(btnLK, bsLK, true) end
    if pState.CS then setPH(btnCS, bsCS, true) end

    local function mutualOff(keep)
        local map = {AAL = {btnAAL, bsAAL}, AAR = {btnAAR, bsAAR}, LK = {btnLK, bsLK}}
        for k, v in pairs(map) do
            if k ~= keep and pState[k] then
                pState[k] = false
                setPH(v[1], v[2], false)
                if k == "AAL" then
                    autoLOn = false
                    stopAutoL()
                    if toggleSetters["Auto Left"] then toggleSetters["Auto Left"](false) end
                elseif k == "AAR" then
                    autoROn = false
                    stopAutoR()
                    if toggleSetters["Auto Right"] then toggleSetters["Auto Right"](false) end
                elseif k == "LK" then
                    batAimbotEnabled = false
                    stopBatAimbot()
                    if toggleSetters["Lock"] then toggleSetters["Lock"](false) end
                end
            end
        end
    end

    btnAAL.MouseButton1Click:Connect(function()
        local ns = not pState.AAL
        if ns then mutualOff("AAL") end
        pState.AAL = ns
        setPH(btnAAL, bsAAL, ns)
        mobBtnRefs["AUTO L"].state = ns
        if toggleSetters["Auto Left"] then toggleSetters["Auto Left"](ns) end
        if ns then
            autoLOn = true
            startAutoL()
        else
            autoLOn = false
            stopAutoL()
        end
    end)

    btnAAR.MouseButton1Click:Connect(function()
        local ns = not pState.AAR
        if ns then mutualOff("AAR") end
        pState.AAR = ns
        setPH(btnAAR, bsAAR, ns)
        mobBtnRefs["AUTO R"].state = ns
        if toggleSetters["Auto Right"] then toggleSetters["Auto Right"](ns) end
        if ns then
            autoROn = true
            startAutoR()
        else
            autoROn = false
            stopAutoR()
        end
    end)

    btnDR.MouseButton1Click:Connect(function()
        setPH(btnDR, bsDR, true)
        task.delay(0.35, function() setPH(btnDR, bsDR, false) end)
        task.spawn(doDrop)
    end)

    btnTP.MouseButton1Click:Connect(function()
        setPH(btnTP, bsTP, true)
        task.delay(0.35, function() setPH(btnTP, bsTP, false) end)
        task.spawn(doTPDown)
    end)

    btnLK.MouseButton1Click:Connect(function()
        local ns = not pState.LK
        if ns then mutualOff("LK") end
        pState.LK = ns
        setPH(btnLK, bsLK, ns)
        batAimbotEnabled = ns
        if toggleSetters["Lock"] then toggleSetters["Lock"](ns) end
        if ns then
            startBatAimbot()
        else
            stopBatAimbot()
        end
        saveConfig()
    end)

    btnCS.MouseButton1Click:Connect(function()
        local ns = not pState.CS
        pState.CS = ns
        setPH(btnCS, bsCS, ns)
        slowDownEnabled = ns
        if toggleSetters["Carry SPD"] then toggleSetters["Carry SPD"](ns) end
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        local kc = input.KeyCode
        if kc == Enum.KeyCode.Unknown then return end
        -- LOCK keybind (X by default) toggles Bat Aimbot
        if kc == Keybinds.BatAimbot then
            local ns = not pState.LK
            if ns then mutualOff("LK") end
            pState.LK = ns
            setPH(btnLK, bsLK, ns)
            batAimbotEnabled = ns
            if toggleSetters["Lock"] then toggleSetters["Lock"](ns) end
            if ns then
                startBatAimbot()
            else
                stopBatAimbot()
            end
            saveConfig()
        elseif kc == Keybinds.AutoLeft then
            local ns = not pState.AAL
            if ns then mutualOff("AAL") end
            pState.AAL = ns
            setPH(btnAAL, bsAAL, ns)
            mobBtnRefs["AUTO L"].state = ns
            if toggleSetters["Auto Left"] then toggleSetters["Auto Left"](ns) end
            if ns then
                autoLOn = true
                startAutoL()
            else
                autoLOn = false
                stopAutoL()
            end
        elseif kc == Keybinds.AutoRight then
            local ns = not pState.AAR
            if ns then mutualOff("AAR") end
            pState.AAR = ns
            setPH(btnAAR, bsAAR, ns)
            mobBtnRefs["AUTO R"].state = ns
            if toggleSetters["Auto Right"] then toggleSetters["Auto Right"](ns) end
            if ns then
                autoROn = true
                startAutoR()
            else
                autoROn = false
                stopAutoR()
            end
        elseif kc == Keybinds.CarrySpd then
            local ns = not pState.CS
            pState.CS = ns
            setPH(btnCS, bsCS, ns)
            slowDownEnabled = ns
            if toggleSetters["Carry SPD"] then toggleSetters["Carry SPD"](ns) end
        elseif kc == Keybinds.Drop then
            task.spawn(doDrop)
        elseif kc == Keybinds.TPDown then
            task.spawn(doTPDown)
        elseif kc == Keybinds.AutoSteal then
            autoStealEnabled = not autoStealEnabled
            if autoStealEnabled then startAutoSteal() else stopAutoSteal() end
            if toggleSetters["Auto Steal"] then toggleSetters["Auto Steal"](autoStealEnabled) end
            saveConfig()
        elseif kc == Keybinds.AntiRagdoll then
            antiRagdollEnabled = not antiRagdollEnabled
            if antiRagdollEnabled then startAntiRagdoll() else stopAntiRagdoll() end
            if toggleSetters["Anti Ragdoll"] then toggleSetters["Anti Ragdoll"](antiRagdollEnabled) end
            saveConfig()
        elseif kc == Keybinds.Unwalk then
            unwalkEnabled = not unwalkEnabled
            if unwalkEnabled then startUnwalk() else stopUnwalk() end
            if toggleSetters["Unwalk"] then toggleSetters["Unwalk"](unwalkEnabled) end
            saveConfig()
        elseif kc == Keybinds.Lagger then
            if laggerPanel then
                laggerActive = not laggerActive
                local toggleBtn = laggerPanel:FindFirstChild("LaggerFrame") and laggerPanel.LaggerFrame:FindFirstChild("ContentFrame") and laggerPanel.LaggerFrame.ContentFrame:FindFirstChild("TOGGLE LAGGER")
                if toggleBtn then
                    if laggerActive then
                        toggleBtn.Text = "LAGGER ACTIVE ✓"
                        toggleBtn.BackgroundColor3 = DARK_PURPLE
                        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        if laggerPanel.LaggerFrame.ContentFrame:FindFirstChild("LaggerRow") and laggerPanel.LaggerFrame.ContentFrame.LaggerRow:FindFirstChild("LaggerStatus") then
                            laggerPanel.LaggerFrame.ContentFrame.LaggerRow.LaggerStatus.Text = "ACTIVE"
                            laggerPanel.LaggerFrame.ContentFrame.LaggerRow.LaggerStatus.TextColor3 = PURPLE
                        end
                    else
                        toggleBtn.Text = "TOGGLE LAGGER"
                        toggleBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
                        toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
                        if laggerPanel.LaggerFrame.ContentFrame:FindFirstChild("LaggerRow") and laggerPanel.LaggerFrame.ContentFrame.LaggerRow:FindFirstChild("LaggerStatus") then
                            laggerPanel.LaggerFrame.ContentFrame.LaggerRow.LaggerStatus.Text = "OFF"
                            laggerPanel.LaggerFrame.ContentFrame.LaggerRow.LaggerStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
                        end
                    end
                end
                if laggerActive then
                    cleanupLaggerMonitor()
                    setupLaggerMonitor()
                else
                    local char = player.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            local currentSpeed = desyncActive and DESYNC_NORMAL_SPEED or originalNormalSpeed
                            hum.WalkSpeed = currentSpeed
                        end
                    end
                    cleanupLaggerMonitor()
                end
                saveConfig()
            else
                laggerActive = not laggerActive
                if laggerActive then
                    cleanupLaggerMonitor()
                    setupLaggerMonitor()
                else
                    local char = player.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            local currentSpeed = desyncActive and DESYNC_NORMAL_SPEED or originalNormalSpeed
                            hum.WalkSpeed = currentSpeed
                        end
                    end
                    cleanupLaggerMonitor()
                end
                saveConfig()
            end
        end
    end)

    if espEnabled then enableESP() end
    applyFOV()
    if spinBotEnabled then startSpin() end
    if antiRagdollEnabled then startAntiRagdoll() end
    if unwalkEnabled then startUnwalk() end
    if batAimbotEnabled then startBatAimbot() end
    if autoStealEnabled then startAutoSteal() end
    if galaxyEnabled then startGalaxy() end
    if optimizerEnabled then enableOptimizer() end
    if goodAnimEnabled then task.spawn(startGoodAnim) end
    if medusaCounterEnabled then task.spawn(function() task.wait(1); setupMedusaCounter(player.Character) end) end

    task.spawn(function()
        task.wait(0.5)
        local alGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
        alGui.Name = "S7AntiLagGUI"
        alGui.ResetOnSpawn = false
        alGui.DisplayOrder = 11
        
        local alMain = Instance.new("Frame")
        alMain.Size = UDim2.new(0, 178, 0, 115)
        alMain.Position = UDim2.new(0, 195, 0, 55)
        alMain.BackgroundColor3 = AL_BG
        alMain.BorderSizePixel = 0
        alMain.Active = true
        alMain.ClipsDescendants = true
        alMain.Parent = alGui
        Instance.new("UICorner", alMain).CornerRadius = UDim.new(0, 12)
        
        local alStroke = Instance.new("UIStroke", alMain)
        alStroke.Color = PURPLE
        alStroke.Thickness = 1.5
        
        do
            local drag, ds, sp = false
            alMain.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    drag = true
                    ds = inp.Position
                    sp = alMain.Position
                    inp.Changed:Connect(function()
                        if inp.UserInputState == Enum.UserInputState.End then drag = false end
                    end)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                    local d = inp.Position - ds
                    alMain.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
                end
            end)
        end
        
        local alTitle = Instance.new("TextLabel", alMain)
        alTitle.Size = UDim2.new(1, -50, 0, 22)
        alTitle.Position = UDim2.new(0, 8, 0, 5)
        alTitle.BackgroundTransparency = 1
        alTitle.Text = "⚡ ANTI LAG"
        alTitle.TextColor3 = Color3.fromRGB(200, 200, 210)
        alTitle.Font = Enum.Font.GothamBlack
        alTitle.TextSize = 11
        alTitle.TextXAlignment = Enum.TextXAlignment.Left
        
        local alSub = Instance.new("TextLabel", alMain)
        alSub.Size = UDim2.new(1, -50, 0, 12)
        alSub.Position = UDim2.new(0, 8, 0, 25)
        alSub.BackgroundTransparency = 1
        alSub.Text = "performance booster"
        alSub.TextColor3 = AL_WHITE
        alSub.Font = Enum.Font.Gotham
        alSub.TextSize = 8
        alSub.TextXAlignment = Enum.TextXAlignment.Left
        
        local alClose = Instance.new("TextButton", alMain)
        alClose.Size = UDim2.new(0, 22, 0, 22)
        alClose.Position = UDim2.new(1, -28, 0, 4)
        alClose.BackgroundColor3 = AL_RED
        alClose.BorderSizePixel = 0
        alClose.Text = "×"
        alClose.TextColor3 = AL_WHITE
        alClose.Font = Enum.Font.GothamBold
        alClose.TextSize = 16
        alClose.ZIndex = 5
        Instance.new("UICorner", alClose).CornerRadius = UDim.new(0, 6)
        
        local function createALToggle(yPos, labelText, callback)
            local container = Instance.new("Frame", alMain)
            container.Size = UDim2.new(1, -16, 0, 28)
            container.Position = UDim2.new(0, 8, 0, yPos)
            container.BackgroundColor3 = AL_CARD
            container.BorderSizePixel = 0
            container.ZIndex = 3
            Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
            
            local stroke = Instance.new("UIStroke", container)
            stroke.Color = PURPLE
            stroke.Thickness = 1
            stroke.Transparency = 0.8
            
            local label = Instance.new("TextLabel", container)
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 6, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = labelText
            label.TextColor3 = AL_WHITE
            label.Font = Enum.Font.GothamBold
            label.TextSize = 10
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 4
            
            local switchBg = Instance.new("Frame", container)
            switchBg.Size = UDim2.new(0, 32, 0, 16)
            switchBg.Position = UDim2.new(1, -40, 0.5, -8)
            switchBg.BackgroundColor3 = AL_SW_OFF
            switchBg.BorderSizePixel = 0
            switchBg.ZIndex = 4
            Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
            
            local switchCircle = Instance.new("Frame", switchBg)
            switchCircle.Size = UDim2.new(0, 12, 0, 12)
            switchCircle.Position = UDim2.new(0, 2, 0.5, -6)
            switchCircle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            switchCircle.BorderSizePixel = 0
            switchCircle.ZIndex = 5
            Instance.new("UICorner", switchCircle).CornerRadius = UDim.new(1, 0)
            
            local isOn = false
            local btn = Instance.new("TextButton", container)
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 6
            
            btn.MouseButton1Click:Connect(function()
                isOn = not isOn
                TweenService:Create(switchBg, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = isOn and PURPLE or AL_SW_OFF}):Play()
                TweenService:Create(switchCircle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position = isOn and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
                if callback then callback(isOn) end
            end)
            
            btn.MouseEnter:Connect(function()
                TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.3}):Play()
                TweenService:Create(container, TweenInfo.new(0.15), {BackgroundColor3 = AL_HOVER}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.8}):Play()
                TweenService:Create(container, TweenInfo.new(0.15), {BackgroundColor3 = AL_CARD}):Play()
            end)
        end
        
        createALToggle(45, "Anti Lag", function(on)
            if on then enableAntiLag() else disableAntiLag() end
        end)
        createALToggle(78, "Remove Accessories", function(on)
            if on then enableRemoveAccessories() else disableRemoveAccessories() end
        end)
        
        local alReopenBtn = Instance.new("TextButton", alGui)
        alReopenBtn.Size = UDim2.new(0, 32, 0, 32)
        alReopenBtn.Position = UDim2.new(0, 195, 0, 55)
        alReopenBtn.BackgroundColor3 = DARK_PURPLE
        alReopenBtn.BorderSizePixel = 0
        alReopenBtn.Text = "⚡"
        alReopenBtn.TextColor3 = AL_WHITE
        alReopenBtn.Font = Enum.Font.GothamBlack
        alReopenBtn.TextSize = 14
        alReopenBtn.Visible = false
        alReopenBtn.ZIndex = 20
        Instance.new("UICorner", alReopenBtn).CornerRadius = UDim.new(0, 8)
        
        alClose.MouseButton1Click:Connect(function()
            alMain.Visible = false
            alReopenBtn.Visible = true
        end)
        alReopenBtn.MouseButton1Click:Connect(function()
            alMain.Visible = true
            alReopenBtn.Visible = false
        end)
        
        alClose.MouseEnter:Connect(function()
            TweenService:Create(alClose, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 80, 80)}):Play()
        end)
        alClose.MouseLeave:Connect(function()
            TweenService:Create(alClose, TweenInfo.new(0.15), {BackgroundColor3 = AL_RED}):Play()
        end)
    end)

    print("S7 Shub loaded - Black & Purple Edition with Lock Toggle (Bat Aimbot) & Taunt Feature")
end)
