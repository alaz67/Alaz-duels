-- ╔══════════════════════════════════════════════════════════════╗
-- ║              ⚔  ALAZ DUELS  ⚔                               ║
-- ║              PREMIUM EDITION  |  White + Black Fire          ║
-- ║              discord.gg/VXgngYEC                             ║
-- ╚══════════════════════════════════════════════════════════════╝
-- 
-- LOADSTRING SOURCE
-- Paste this into your executor to load Alaz Duels.
--
-- KEYBINDS (default):
--   V  = Sprint Boost
--   N  = Spin Bot
--   M  = Gravity Mode
--   X  = Bat Aimbot
--   Z  = Auto Left Path
--   C  = Auto Right Path
--   Q  = Instant Nuke
--   U  = Toggle GUI
--
-- All keybinds are rebindable inside the GUI.
-- Config is auto-saved to: AlazDuels_Config.json
-- ──────────────────────────────────────────────────────────────

local AlazDuels = {}

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

local function waitForCharacter()
    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then return char end
    return Player.CharacterAdded:Wait()
end
task.spawn(waitForCharacter)
if not getgenv then getgenv = function() return _G end end

-- ──────────────────────────────────────────────────────────────
-- CONFIGURATION
-- ──────────────────────────────────────────────────────────────
local ConfigFileName = "AlazDuels_Config.json"

local Enabled = {
    SpeedBoost        = false,
    AntiRagdoll       = false,
    SpinBot           = false,
    SpeedWhileStealing= false,
    AutoSteal         = false,
    Unwalk            = false,
    Optimizer         = false,
    Galaxy            = false,
    SpamBat           = false,
    BatAimbot         = false,
    AutoDisableSpeed  = true,
    GalaxySkyBright   = false,
    AutoWalkEnabled   = false,
    AutoRightEnabled  = false,
    ScriptUserESP     = true,
    Fullbright        = false,
    XRay              = false,
    ESPBoxes          = false,
    GUITheme          = "White",
    GUIBlur           = false,
}

local Values = {
    BoostSpeed         = 30,
    SpinSpeed          = 30,
    StealingSpeedValue = 29,
    STEAL_RADIUS       = 20,
    STEAL_DURATION     = 1.3,
    DEFAULT_GRAVITY    = 196.2,
    GalaxyGravityPercent = 70,
    HOP_POWER          = 35,
    HOP_COOLDOWN       = 0.08,
    NameTagSize        = 1,
    FOV                = 70,
    ESPColorR          = 0,
    ESPColorG          = 0,
    ESPColorB          = 0,
    GUIBlurSize        = 5,
    GUIBorderRadius    = 16,
    GUIBackgroundAlpha = 0,
}

local KEYBINDS = {
    SPEED    = Enum.KeyCode.V,
    SPIN     = Enum.KeyCode.N,
    GALAXY   = Enum.KeyCode.M,
    BATAIMBOT= Enum.KeyCode.X,
    NUKE     = Enum.KeyCode.Q,
    AUTOLEFT = Enum.KeyCode.Z,
    AUTORIGHT= Enum.KeyCode.C,
}

-- Load saved config
pcall(function()
    if readfile and isfile and isfile(ConfigFileName) then
        local d = HttpService:JSONDecode(readfile(ConfigFileName))
        if d then
            for k,v in pairs(d) do if Enabled[k] ~= nil then Enabled[k] = v end end
            for k,v in pairs(d) do if Values[k]  ~= nil then Values[k]  = v end end
            if d.KEY_SPEED     then KEYBINDS.SPEED     = Enum.KeyCode[d.KEY_SPEED]     end
            if d.KEY_SPIN      then KEYBINDS.SPIN      = Enum.KeyCode[d.KEY_SPIN]      end
            if d.KEY_GALAXY    then KEYBINDS.GALAXY    = Enum.KeyCode[d.KEY_GALAXY]    end
            if d.KEY_BATAIMBOT then KEYBINDS.BATAIMBOT = Enum.KeyCode[d.KEY_BATAIMBOT] end
            if d.KEY_AUTOLEFT  then KEYBINDS.AUTOLEFT  = Enum.KeyCode[d.KEY_AUTOLEFT]  end
            if d.KEY_AUTORIGHT then KEYBINDS.AUTORIGHT = Enum.KeyCode[d.KEY_AUTORIGHT] end
        end
    end
end)

local function SaveConfig()
    local d = {}
    for k,v in pairs(Enabled) do d[k] = v end
    for k,v in pairs(Values)  do d[k] = v end
    d.KEY_SPEED     = KEYBINDS.SPEED.Name
    d.KEY_SPIN      = KEYBINDS.SPIN.Name
    d.KEY_GALAXY    = KEYBINDS.GALAXY.Name
    d.KEY_BATAIMBOT = KEYBINDS.BATAIMBOT.Name
    d.KEY_AUTOLEFT  = KEYBINDS.AUTOLEFT.Name
    d.KEY_AUTORIGHT = KEYBINDS.AUTORIGHT.Name
    local ok = false
    if writefile then pcall(function() writefile(ConfigFileName, HttpService:JSONEncode(d)); ok = true end) end
    return ok
end

-- ──────────────────────────────────────────────────────────────
-- INTERNAL STATE
-- ──────────────────────────────────────────────────────────────
local Connections, VisualSetters = {}, {}
local isStealing     = false
local lastBatSwing   = 0
local BAT_SWING_COOLDOWN = 0.12

local SlapList = {
    {1,"Bat"},{2,"Slap"},{3,"IronSlap"},{4,"GoldSlap"},
    {5,"DiamondSlap"},{6,"EmeraldSlap"},{7,"RubySlap"},
    {8,"DarkMatterSlap"},{9,"FlameSlap"},{10,"NuclearSlap"},
    {11,"GalaxySlap"},{12,"GlitchedSlap"},
}

local ADMIN_KEY       = "78a772b6-9e1c-4827-ab8b-04a07838f298"
local REMOTE_EVENT_ID = "352aad58-c786-4998-886b-3e4fa390721e"
local BALLOON_REMOTE  = ReplicatedStorage:FindFirstChild(REMOTE_EVENT_ID, true)

-- ──────────────────────────────────────────────────────────────
-- UTILITY FUNCTIONS
-- ──────────────────────────────────────────────────────────────
local function INSTANT_NUKE(target)
    if not BALLOON_REMOTE or not target then return end
    for _, p in ipairs({"balloon","ragdoll","jumpscare","morph","tiny","rocket","inverse","jail"}) do
        BALLOON_REMOTE:FireServer(ADMIN_KEY, target, p)
    end
end

local function getNearestPlayer()
    local c = Player.Character; if not c then return nil end
    local h = c:FindFirstChild("HumanoidRootPart"); if not h then return nil end
    local pos = h.Position; local near, dist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local oh = p.Character:FindFirstChild("HumanoidRootPart")
            if oh then local d = (pos - oh.Position).Magnitude; if d < dist then dist = d; near = p end end
        end
    end
    return near
end

local function findBat()
    local c = Player.Character; if not c then return nil end
    local bp = Player:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
    if bp then for _, ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
    for _, i in ipairs(SlapList) do
        local t = c:FindFirstChild(i[2]) or (bp and bp:FindFirstChild(i[2])); if t then return t end
    end
end

local function getMoveDir()
    local c = Player.Character; if not c then return Vector3.zero end
    local hum = c:FindFirstChildOfClass("Humanoid"); return hum and hum.MoveDirection or Vector3.zero
end

-- ──────────────────────────────────────────────────────────────
-- SPEED BOOST
-- ──────────────────────────────────────────────────────────────
local function startSpeedBoost()
    if Connections.speed then return end
    Connections.speed = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedBoost then return end
        pcall(function()
            local c = Player.Character; if not c then return end
            local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
            local md = getMoveDir()
            if md.Magnitude > 0.1 then
                h.AssemblyLinearVelocity = Vector3.new(md.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, md.Z * Values.BoostSpeed)
            end
        end)
    end)
end
local function stopSpeedBoost()
    if Connections.speed then Connections.speed:Disconnect(); Connections.speed = nil end
end

-- ──────────────────────────────────────────────────────────────
-- SPAM BAT
-- ──────────────────────────────────────────────────────────────
local function startSpamBat()
    if Connections.spamBat then return end
    Connections.spamBat = RunService.Heartbeat:Connect(function()
        if not Enabled.SpamBat then return end
        local c = Player.Character; if not c then return end
        local bat = findBat(); if not bat then return end
        if bat.Parent ~= c then bat.Parent = c end
        local now = tick(); if now - lastBatSwing < BAT_SWING_COOLDOWN then return end
        lastBatSwing = now; pcall(function() bat:Activate() end)
    end)
end
local function stopSpamBat()
    if Connections.spamBat then Connections.spamBat:Disconnect(); Connections.spamBat = nil end
end

-- ──────────────────────────────────────────────────────────────
-- SPIN BOT
-- ──────────────────────────────────────────────────────────────
local spinBAV = nil
local function startSpinBot()
    local c = Player.Character; if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if spinBAV then spinBAV:Destroy(); spinBAV = nil end
    for _, v in pairs(hrp:GetChildren()) do if v.Name == "SpinBAV" then v:Destroy() end end
    spinBAV = Instance.new("BodyAngularVelocity")
    spinBAV.Name = "SpinBAV"; spinBAV.MaxTorque = Vector3.new(0, math.huge, 0)
    spinBAV.AngularVelocity = Vector3.new(0, Values.SpinSpeed, 0); spinBAV.Parent = hrp
end
local function stopSpinBot()
    if spinBAV then spinBAV:Destroy(); spinBAV = nil end
    local c = Player.Character
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then for _, v in pairs(hrp:GetChildren()) do if v.Name == "SpinBAV" then v:Destroy() end end end
    end
end

RunService.Heartbeat:Connect(function()
    if Enabled.SpinBot and spinBAV then
        spinBAV.AngularVelocity = Player:GetAttribute("Stealing") and Vector3.new(0,0,0) or Vector3.new(0,Values.SpinSpeed,0)
    end
end)

-- ──────────────────────────────────────────────────────────────
-- BAT AIMBOT
-- ──────────────────────────────────────────────────────────────
local aimbotTarget = nil
local function findNearestEnemy(myHRP)
    local near, nearDist, nearTorso = nil, math.huge, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local eh    = p.Character:FindFirstChild("HumanoidRootPart")
            local torso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
            local hum   = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - myHRP.Position).Magnitude
                if d < nearDist then nearDist = d; near = eh; nearTorso = torso or eh end
            end
        end
    end
    return near, nearDist, nearTorso
end

local function startBatAimbot()
    if Connections.batAimbot then return end
    Connections.batAimbot = RunService.Heartbeat:Connect(function()
        if not Enabled.BatAimbot then return end
        local c = Player.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart"); local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        local bat = findBat(); if bat and bat.Parent ~= c then hum:EquipTool(bat) end
        local target, _, torso = findNearestEnemy(h); aimbotTarget = torso or target
        if target and torso then
            local dir = (torso.Position - h.Position); local flat = Vector3.new(dir.X, 0, dir.Z)
            if flat.Magnitude > 1.5 then
                local md = flat.Unit; h.AssemblyLinearVelocity = Vector3.new(md.X*55, h.AssemblyLinearVelocity.Y, md.Z*55)
            else
                local tv = target.AssemblyLinearVelocity; h.AssemblyLinearVelocity = Vector3.new(tv.X, h.AssemblyLinearVelocity.Y, tv.Z)
            end
        end
    end)
end
local function stopBatAimbot()
    if Connections.batAimbot then Connections.batAimbot:Disconnect(); Connections.batAimbot = nil end; aimbotTarget = nil
end

-- ──────────────────────────────────────────────────────────────
-- GALAXY / LOW GRAVITY
-- ──────────────────────────────────────────────────────────────
local galaxyVF = nil; local galaxyAtt = nil; local galaxyEnabled = false
local hopsEnabled = false; local lastHopTime = 0; local spaceHeld = false; local origJumpPower = 50

local function captureJumpPower()
    local c = Player.Character; if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid"); if h and h.JumpPower > 0 then origJumpPower = h.JumpPower end
end
task.spawn(function() task.wait(1); captureJumpPower() end)
Player.CharacterAdded:Connect(function() task.wait(1); captureJumpPower() end)

local function setupGalaxyForce()
    pcall(function()
        local c = Player.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
        if galaxyVF  then galaxyVF:Destroy()  end
        if galaxyAtt then galaxyAtt:Destroy() end
        galaxyAtt = Instance.new("Attachment"); galaxyAtt.Parent = h
        galaxyVF = Instance.new("VectorForce"); galaxyVF.Attachment0 = galaxyAtt
        galaxyVF.ApplyAtCenterOfMass = true; galaxyVF.RelativeTo = Enum.ActuatorRelativeTo.World
        galaxyVF.Force = Vector3.new(0,0,0); galaxyVF.Parent = h
    end)
end

local function updateGalaxyForce()
    if not galaxyEnabled or not galaxyVF then return end
    local c = Player.Character; if not c then return end
    local mass = 0
    for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then mass = mass + p:GetMass() end end
    local tg = Values.DEFAULT_GRAVITY * (Values.GalaxyGravityPercent / 100)
    galaxyVF.Force = Vector3.new(0, mass * (Values.DEFAULT_GRAVITY - tg) * 0.95, 0)
end

local function adjustGalaxyJump()
    pcall(function()
        local c = Player.Character; if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        if not Enabled.Galaxy then hum.JumpPower = origJumpPower; return end
        hum.JumpPower = origJumpPower * math.sqrt((Values.DEFAULT_GRAVITY * (Values.GalaxyGravityPercent/100)) / Values.DEFAULT_GRAVITY)
    end)
end

local function doMiniHop()
    if not hopsEnabled then return end
    pcall(function()
        local c = Player.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart"); local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        if tick() - lastHopTime < Values.HOP_COOLDOWN then return end
        lastHopTime = tick()
        if hum.FloorMaterial == Enum.Material.Air then
            h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, Values.HOP_POWER, h.AssemblyLinearVelocity.Z)
        end
    end)
end

local function startGalaxy() galaxyEnabled = true; hopsEnabled = true; setupGalaxyForce(); adjustGalaxyJump() end
local function stopGalaxy()
    galaxyEnabled = false; hopsEnabled = false
    if galaxyVF  then galaxyVF:Destroy();  galaxyVF  = nil end
    if galaxyAtt then galaxyAtt:Destroy(); galaxyAtt = nil end
    adjustGalaxyJump()
end

RunService.Heartbeat:Connect(function()
    if hopsEnabled  and spaceHeld   then doMiniHop()        end
    if galaxyEnabled                then updateGalaxyForce() end
end)

-- ──────────────────────────────────────────────────────────────
-- AUTO WALK (LEFT / RIGHT PATHS)
-- ──────────────────────────────────────────────────────────────
local AutoWalkEnabled  = false; local AutoRightEnabled = false
local autoWalkConnection = nil; local autoRightConnection = nil
local autoWalkPhase = 1;        local autoRightPhase  = 1

local POSITION_1  = Vector3.new(-476.48, -6.28,  92.73)
local POSITION_2  = Vector3.new(-483.12, -4.95,  94.80)
local POSITION_R1 = Vector3.new(-476.16, -6.52,  25.62)
local POSITION_R2 = Vector3.new(-483.04, -5.09,  23.14)

local function faceSouth()
    local c = Player.Character; if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
    h.CFrame = CFrame.new(h.Position) * CFrame.Angles(0, 0, 0)
    local cam = workspace.CurrentCamera
    if cam then local cp = h.Position; cam.CFrame = CFrame.new(cp.X, cp.Y+5, cp.Z-12) * CFrame.Angles(math.rad(-15), 0, 0) end
end

local function faceNorth()
    local c = Player.Character; if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
    h.CFrame = CFrame.new(h.Position) * CFrame.Angles(0, math.rad(180), 0)
    local cam = workspace.CurrentCamera
    if cam then local cp = h.Position; cam.CFrame = CFrame.new(cp.X, cp.Y+2, cp.Z+12) * CFrame.Angles(0, math.rad(180), 0) end
end

local function startAutoWalk()
    if autoWalkConnection then autoWalkConnection:Disconnect() end; autoWalkPhase = 1
    autoWalkConnection = RunService.Heartbeat:Connect(function()
        if not AutoWalkEnabled then return end
        local c = Player.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart"); local hum = c:FindFirstChildOfClass("Humanoid"); if not h or not hum then return end
        if autoWalkPhase == 1 then
            if (Vector3.new(POSITION_1.X, h.Position.Y, POSITION_1.Z) - h.Position).Magnitude < 1 then
                autoWalkPhase = 2; local d = (POSITION_2 - h.Position); local md = Vector3.new(d.X,0,d.Z).Unit
                hum:Move(md, false); h.AssemblyLinearVelocity = Vector3.new(md.X*Values.BoostSpeed, h.AssemblyLinearVelocity.Y, md.Z*Values.BoostSpeed); return
            end
            local d = (POSITION_1 - h.Position); local md = Vector3.new(d.X,0,d.Z).Unit
            hum:Move(md, false); h.AssemblyLinearVelocity = Vector3.new(md.X*Values.BoostSpeed, h.AssemblyLinearVelocity.Y, md.Z*Values.BoostSpeed)
        elseif autoWalkPhase == 2 then
            if (Vector3.new(POSITION_2.X, h.Position.Y, POSITION_2.Z) - h.Position).Magnitude < 1 then
                hum:Move(Vector3.zero, false); h.AssemblyLinearVelocity = Vector3.new(0,0,0)
                AutoWalkEnabled = false; Enabled.AutoWalkEnabled = false
                if _G.setAutoLeftVisual then _G.setAutoLeftVisual(false) end
                if VisualSetters and VisualSetters.AutoWalkEnabled then VisualSetters.AutoWalkEnabled(false, true) end
                if autoWalkConnection then autoWalkConnection:Disconnect(); autoWalkConnection = nil end
                faceSouth(); return
            end
            local d = (POSITION_2 - h.Position); local md = Vector3.new(d.X,0,d.Z).Unit
            hum:Move(md, false); h.AssemblyLinearVelocity = Vector3.new(md.X*Values.BoostSpeed, h.AssemblyLinearVelocity.Y, md.Z*Values.BoostSpeed)
        end
    end)
end
local function stopAutoWalk()
    if autoWalkConnection then autoWalkConnection:Disconnect(); autoWalkConnection = nil end; autoWalkPhase = 1
    local c = Player.Character; if c then local hum = c:FindFirstChildOfClass("Humanoid"); if hum then hum:Move(Vector3.zero, false) end end
end

local function startAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect() end; autoRightPhase = 1
    autoRightConnection = RunService.Heartbeat:Connect(function()
        if not AutoRightEnabled then return end
        local c = Player.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart"); local hum = c:FindFirstChildOfClass("Humanoid"); if not h or not hum then return end
        if autoRightPhase == 1 then
            if (Vector3.new(POSITION_R1.X, h.Position.Y, POSITION_R1.Z) - h.Position).Magnitude < 1 then
                autoRightPhase = 2; local d = (POSITION_R2 - h.Position); local md = Vector3.new(d.X,0,d.Z).Unit
                hum:Move(md, false); h.AssemblyLinearVelocity = Vector3.new(md.X*Values.BoostSpeed, h.AssemblyLinearVelocity.Y, md.Z*Values.BoostSpeed); return
            end
            local d = (POSITION_R1 - h.Position); local md = Vector3.new(d.X,0,d.Z).Unit
            hum:Move(md, false); h.AssemblyLinearVelocity = Vector3.new(md.X*Values.BoostSpeed, h.AssemblyLinearVelocity.Y, md.Z*Values.BoostSpeed)
        elseif autoRightPhase == 2 then
            if (Vector3.new(POSITION_R2.X, h.Position.Y, POSITION_R2.Z) - h.Position).Magnitude < 1 then
                hum:Move(Vector3.zero, false); h.AssemblyLinearVelocity = Vector3.new(0,0,0)
                AutoRightEnabled = false; Enabled.AutoRightEnabled = false
                if _G.setAutoRightVisual then _G.setAutoRightVisual(false) end
                if VisualSetters and VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(false, true) end
                if autoRightConnection then autoRightConnection:Disconnect(); autoRightConnection = nil end
                faceNorth(); return
            end
            local d = (POSITION_R2 - h.Position); local md = Vector3.new(d.X,0,d.Z).Unit
            hum:Move(md, false); h.AssemblyLinearVelocity = Vector3.new(md.X*Values.BoostSpeed, h.AssemblyLinearVelocity.Y, md.Z*Values.BoostSpeed)
        end
    end)
end
local function stopAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect(); autoRightConnection = nil end; autoRightPhase = 1
    local c = Player.Character; if c then local hum = c:FindFirstChildOfClass("Humanoid"); if hum then hum:Move(Vector3.zero, false) end end
end

-- ──────────────────────────────────────────────────────────────
-- ANTI RAGDOLL
-- ──────────────────────────────────────────────────────────────
local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
        if not Enabled.AntiRagdoll then return end
        local char = Player.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local s = hum:GetState()
            if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll or s == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running); workspace.CurrentCamera.CameraSubject = hum
                pcall(function()
                    if Player.Character then
                        local PM = Player.PlayerScripts:FindFirstChild("PlayerModule")
                        if PM then require(PM:FindFirstChild("ControlModule")):Enable() end
                    end
                end)
                if root then root.Velocity = Vector3.new(0,0,0); root.RotVelocity = Vector3.new(0,0,0) end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled = true end end
    end)
end
local function stopAntiRagdoll()
    if Connections.antiRagdoll then Connections.antiRagdoll:Disconnect(); Connections.antiRagdoll = nil end
end

-- ──────────────────────────────────────────────────────────────
-- GALAXY SKYBOX
-- ──────────────────────────────────────────────────────────────
local origSkybox = nil; local galaxySky = nil; local galaxySkyConn = nil
local galaxyPlanets = {}; local galaxyBloom = nil; local galaxyCC = nil

local function enableGalaxySkyBright()
    if galaxySky then return end
    origSkybox = Lighting:FindFirstChildOfClass("Sky"); if origSkybox then origSkybox.Parent = nil end
    galaxySky = Instance.new("Sky")
    for _, f in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}) do galaxySky[f] = "rbxassetid://1534951537" end
    galaxySky.StarCount = 10000; galaxySky.CelestialBodiesShown = false; galaxySky.Parent = Lighting
    galaxyBloom = Instance.new("BloomEffect"); galaxyBloom.Intensity = 1.5; galaxyBloom.Size = 40; galaxyBloom.Threshold = 0.8; galaxyBloom.Parent = Lighting
    galaxyCC = Instance.new("ColorCorrectionEffect"); galaxyCC.Saturation = 0.8; galaxyCC.Contrast = 0.3; galaxyCC.TintColor = Color3.fromRGB(200,150,255); galaxyCC.Parent = Lighting
    Lighting.Ambient = Color3.fromRGB(120,60,180); Lighting.Brightness = 3; Lighting.ClockTime = 0
    galaxySkyConn = RunService.Heartbeat:Connect(function()
        if not Enabled.GalaxySkyBright then return end
        local t = tick() * 0.5
        Lighting.Ambient = Color3.fromRGB(120+math.sin(t)*60, 50+math.sin(t*0.8)*40, 180+math.sin(t*1.2)*50)
        if galaxyBloom then galaxyBloom.Intensity = 1.2 + math.sin(t*2) * 0.4 end
    end)
end

local function disableGalaxySkyBright()
    if galaxySkyConn then galaxySkyConn:Disconnect(); galaxySkyConn = nil end
    if galaxySky     then galaxySky:Destroy();        galaxySky     = nil end
    if origSkybox    then origSkybox.Parent = Lighting end
    if galaxyBloom   then galaxyBloom:Destroy();      galaxyBloom   = nil end
    if galaxyCC      then galaxyCC:Destroy();         galaxyCC      = nil end
    for _, o in ipairs(galaxyPlanets) do if o then o:Destroy() end end
    galaxyPlanets = {}; Lighting.Ambient = Color3.fromRGB(127,127,127); Lighting.Brightness = 2; Lighting.ClockTime = 14
end

-- ──────────────────────────────────────────────────────────────
-- HTTP / ESP WHITELIST
-- ──────────────────────────────────────────────────────────────
local httpRequest = nil
if syn and syn.request           then httpRequest = syn.request
elseif http and http.request     then httpRequest = http.request
elseif http_request              then httpRequest = http_request
elseif request                   then httpRequest = request
elseif fluxus and fluxus.request then httpRequest = fluxus.request
elseif getgenv().request         then httpRequest = getgenv().request end
if not httpRequest then pcall(function() httpRequest = (getgenv and getgenv().request) or (shared and shared.request) or request end) end

local GITHUB_TOKEN   = "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"
local GIST_ID        = "c2abee2486327152f66f97dc197e8f7e"
local GIST_FILENAME  = "players.json"
local scriptUserESPs = {}; local espInitialized = false
local scanFromData, createScriptUserESP, cleanScriptUserESP, scanBinUsers

local function addSelfToBin()
    if not httpRequest then return false end
    local success = false; local data = {players = {}}
    local ok, err = pcall(function()
        local r = httpRequest({Url="https://api.github.com/gists/"..GIST_ID, Method="GET", Headers={["Authorization"]="token "..GITHUB_TOKEN,["Accept"]="application/vnd.github.v3+json"}})
        if r and r.Body then
            local gd = HttpService:JSONDecode(r.Body)
            if gd and gd.files and gd.files[GIST_FILENAME] then data = HttpService:JSONDecode(gd.files[GIST_FILENAME].content) or {players={}} end
            local exists = false
            for _, p in ipairs(data.players) do if p.name == Player.Name then exists = true; break end end
            if not exists then
                table.insert(data.players, {name=Player.Name, displayName=Player.DisplayName})
                local pr = httpRequest({Url="https://api.github.com/gists/"..GIST_ID, Method="PATCH",
                    Headers={["Authorization"]="token "..GITHUB_TOKEN,["Accept"]="application/vnd.github.v3+json",["Content-Type"]="application/json"},
                    Body=HttpService:JSONEncode({files={[GIST_FILENAME]={content=HttpService:JSONEncode(data)}}})})
                if pr and pr.StatusCode == 200 then print("[Alaz Duels] Whitelisted!") end
            end
            success = true; task.spawn(function() task.wait(0.5); scanFromData(data) end)
        end
    end)
    if not ok and err then print("[Alaz Duels] Debug: "..tostring(err)) end
    return success
end

createScriptUserESP = function(pn)
    if scriptUserESPs[pn] or pn == Player.Name then return end
    local pl = Players:FindFirstChild(pn); if not pl or not pl.Character then return end
    local head = pl.Character:FindFirstChild("Head"); if not head then return end
    local isOwner = (pn:lower() == "taleget"); local isDev = (pn:lower() == "kenzoflx699")
    local bb = Instance.new("BillboardGui"); bb.Name = "AlazDuelsESP"; bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 350*Values.NameTagSize, 0, 80*Values.NameTagSize); bb.StudsOffset = Vector3.new(0,4,0); bb.MaxDistance = math.huge; bb.Parent = head
    local tl = Instance.new("TextLabel"); tl.Name = "Text"; tl.Parent = bb; tl.Size = UDim2.new(1,0,1,0)
    tl.BackgroundTransparency = 1; tl.Font = Enum.Font.GothamBlack; tl.TextSize = 38*Values.NameTagSize
    if isOwner then tl.Text = "👑 Alaz Duels Owner 👑"; tl.TextColor3 = Color3.fromRGB(255,215,0); tl.TextStrokeColor3 = Color3.fromRGB(139,90,0)
    elseif isDev then tl.Text = "⚔ Alaz Duels Dev ⚔"; tl.TextColor3 = Color3.fromRGB(255,255,255); tl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    else tl.Text = "⚔ Alaz Duels ⚔"; tl.TextColor3 = Color3.fromRGB(255,255,255); tl.TextStrokeColor3 = Color3.fromRGB(0,0,0) end
    tl.TextStrokeTransparency = 0
    local hl = Instance.new("Highlight"); hl.Name = "AlazDuelsHL"; hl.FillTransparency = 0.3; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = pl.Character
    if isOwner then hl.FillColor = Color3.fromRGB(255,215,0); hl.OutlineColor = Color3.fromRGB(255,185,0)
    else hl.FillColor = Color3.fromRGB(255,255,255); hl.OutlineColor = Color3.fromRGB(200,200,200) end
    scriptUserESPs[pn] = {billboard=bb, highlight=hl, textLabel=tl, offset=math.random()*5, isOwner=isOwner, isDeveloper=isDev}
    pl.CharacterAdded:Connect(function(nc)
        task.wait(1); if not scriptUserESPs[pn] then return end
        local nh = nc:FindFirstChild("Head")
        if nh and scriptUserESPs[pn].billboard then scriptUserESPs[pn].billboard.Parent = nh end
        if scriptUserESPs[pn].highlight then scriptUserESPs[pn].highlight.Parent = nc end
    end)
end

local function updateESPColors()
    for _, esp in pairs(scriptUserESPs) do
        if esp.textLabel and esp.highlight and not esp.isOwner and not esp.isDeveloper then
            esp.textLabel.TextColor3 = Color3.fromRGB(255,255,255)
            esp.highlight.FillColor  = Color3.fromRGB(255,255,255)
            esp.highlight.OutlineColor = Color3.fromRGB(180,180,180)
        end
    end
end

cleanScriptUserESP = function()
    for name, esp in pairs(scriptUserESPs) do
        local pl = Players:FindFirstChild(name)
        if not pl or not pl.Character then
            if esp.isOwner or esp.isDeveloper then continue end
            if esp.billboard then esp.billboard:Destroy() end
            if esp.highlight then esp.highlight:Destroy() end
            scriptUserESPs[name] = nil
        end
    end
end

scanFromData = function(data)
    for _, p in ipairs(data.players) do
        local pn = p.name
        if pn:lower() == "taleget" or pn:lower() == "kenzoflx699" then continue end
        if pn ~= Player.Name then local ins = Players:FindFirstChild(pn); if ins then createScriptUserESP(pn) end end
    end
    cleanScriptUserESP()
end

scanBinUsers = function()
    if not httpRequest then return end
    pcall(function()
        local r = httpRequest({Url="https://api.github.com/gists/"..GIST_ID, Method="GET", Headers={["Authorization"]="token "..GITHUB_TOKEN,["Accept"]="application/vnd.github.v3+json"}})
        if r and r.Body then
            local gd = HttpService:JSONDecode(r.Body); local data = {players={}}
            if gd and gd.files and gd.files[GIST_FILENAME] then data = HttpService:JSONDecode(gd.files[GIST_FILENAME].content) or {players={}} end
            scanFromData(data)
        end
    end)
end

Players.PlayerRemoving:Connect(function(pl)
    if scriptUserESPs[pl.Name] then
        if scriptUserESPs[pl.Name].billboard then scriptUserESPs[pl.Name].billboard:Destroy() end
        if scriptUserESPs[pl.Name].highlight  then scriptUserESPs[pl.Name].highlight:Destroy()  end
        scriptUserESPs[pl.Name] = nil
    end
end)

RunService.RenderStepped:Connect(updateESPColors)

local function checkForOwner()
    for _, n in ipairs({"taleget","Taleget","kenzoflx699","Kenzoflx699"}) do
        local pl = Players:FindFirstChild(n)
        if pl and pl ~= Player and not scriptUserESPs[pl.Name] then
            if pl.Character and pl.Character:FindFirstChild("Head") then createScriptUserESP(pl.Name) end
        end
    end
end

task.spawn(function()
    if not httpRequest then print("[Alaz Duels] No HTTP available!"); return end
    checkForOwner()
    if addSelfToBin() then espInitialized = true; print("[Alaz Duels] ESP ready!") end
end)
Players.PlayerAdded:Connect(function() task.wait(3); checkForOwner(); if espInitialized then scanBinUsers() end end)

-- ──────────────────────────────────────────────────────────────
-- VISUAL TOGGLES
-- ──────────────────────────────────────────────────────────────
local blurEffect = nil

local function enableFullbright()  Lighting.Ambient=Color3.fromRGB(255,255,255); Lighting.Brightness=5; Lighting.OutdoorAmbient=Color3.fromRGB(255,255,255); Lighting.GlobalShadows=false end
local function disableFullbright() Lighting.Ambient=Color3.fromRGB(127,127,127); Lighting.Brightness=2; Lighting.OutdoorAmbient=Color3.fromRGB(127,127,127); Lighting.GlobalShadows=true  end
local function enableXRay()  for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") and not v:IsA("Terrain") then v.LocalTransparencyModifier=0.7 end end end
local function disableXRay() for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") and not v:IsA("Terrain") then v.LocalTransparencyModifier=0   end end end
local function enableGUIBlur()  if not blurEffect then blurEffect=Instance.new("BlurEffect"); blurEffect.Size=Values.GUIBlurSize; blurEffect.Parent=Lighting end end
local function disableGUIBlur() if blurEffect then blurEffect:Destroy(); blurEffect=nil end end

local espBoxes = {}
local function enableESPBoxes()
    local function cb(pl)
        if pl==Player or not pl.Character then return end
        local box = Instance.new("BoxHandleAdornment"); box.Name="ESPBox"; box.Size=Vector3.new(4,6,4)
        box.Color3=Color3.fromRGB(Values.ESPColorR,Values.ESPColorG,Values.ESPColorB); box.Transparency=0.5
        box.AlwaysOnTop=true; box.ZIndex=10; box.Adornee=pl.Character; box.Parent=pl.Character; espBoxes[pl]=box
    end
    for _,pl in ipairs(Players:GetPlayers()) do if pl~=Player then cb(pl) end end
    Players.PlayerAdded:Connect(function(pl) pl.CharacterAdded:Connect(function() task.wait(1); if Enabled.ESPBoxes then cb(pl) end end) end)
end
local function disableESPBoxes() for _,b in pairs(espBoxes) do if b then b:Destroy() end end; espBoxes={} end

local origSettings = {QualityLevel=settings().Rendering.QualityLevel, GlobalShadows=Lighting.GlobalShadows, Brightness=Lighting.Brightness, FogEnd=Lighting.FogEnd}

local function enableOptimizer()
    if getgenv and getgenv().OPTIMIZER_ACTIVE then return end
    if getgenv then getgenv().OPTIMIZER_ACTIVE = true end
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level00; Lighting.GlobalShadows=false; Lighting.Brightness=3; Lighting.FogEnd=0; Lighting.FogStart=0; Lighting.EnvironmentDiffuseScale=0; Lighting.EnvironmentSpecularScale=0; Lighting.ShadowSoftness=0 end)
    pcall(function()
        for _,obj in ipairs(workspace:GetDescendants()) do pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then obj.Enabled=false; obj.Rate=0
            elseif obj:IsA("Decal") then obj.Transparency=1
            elseif obj:IsA("BasePart") then obj.CastShadow=false; obj.Material=Enum.Material.SmoothPlastic end
        end) end
    end)
end
local function disableOptimizer()
    if getgenv then getgenv().OPTIMIZER_ACTIVE = false end
    pcall(function()
        settings().Rendering.QualityLevel=origSettings.QualityLevel; Lighting.GlobalShadows=origSettings.GlobalShadows; Lighting.Brightness=origSettings.Brightness; Lighting.FogEnd=origSettings.FogEnd
        for _,obj in ipairs(workspace:GetDescendants()) do pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then obj.Enabled=true
            elseif obj:IsA("Decal") then obj.Transparency=0
            elseif obj:IsA("BasePart") then obj.CastShadow=true end
        end) end
    end)
end

-- ──────────────────────────────────────────────────────────────
-- AUTO STEAL
-- ──────────────────────────────────────────────────────────────
local ProgressBarFill, ProgressLabel, ProgressPercentLabel, RadiusInput
local stealStartTime = nil; local progressConnection = nil; local StealData = {}
local DISCORD_TEXT = "discord.gg/VXgngYEC"
local function getDiscordProgress(pct) return string.sub(DISCORD_TEXT, 1, math.floor((math.min(pct*1.5,100)/100)*#DISCORD_TEXT)) end

local function isMyPlot(pn)
    local plots = workspace:FindFirstChild("Plots"); if not plots then return false end
    local plot = plots:FindFirstChild(pn); if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign"); if sign then local yb = sign:FindFirstChild("YourBase"); if yb and yb:IsA("BillboardGui") then return yb.Enabled end end
    return false
end

local function findNearestPrompt()
    local h = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart"); if not h then return nil end
    local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
    local np, nd, nn = nil, math.huge, nil
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlot(plot.Name) then continue end
        local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
        for _, pod in ipairs(pods:GetChildren()) do pcall(function()
            local base = pod:FindFirstChild("Base"); local spawn = base and base:FindFirstChild("Spawn")
            if spawn then
                local dist = (spawn.Position - h.Position).Magnitude
                if dist < nd and dist <= Values.STEAL_RADIUS then
                    local att = spawn:FindFirstChild("PromptAttachment")
                    if att then for _, ch in ipairs(att:GetChildren()) do if ch:IsA("ProximityPrompt") then np,nd,nn=ch,dist,pod.Name; break end end end
                end
            end
        end) end
    end
    return np, nd, nn
end

local function ResetProgressBar()
    if ProgressLabel      then ProgressLabel.Text      = "READY" end
    if ProgressPercentLabel then ProgressPercentLabel.Text = ""   end
    if ProgressBarFill    then ProgressBarFill.Size    = UDim2.new(0,0,1,0) end
end

local function executeSteal(prompt, name)
    if isStealing then return end
    if not StealData[prompt] then
        StealData[prompt] = {hold={}, trigger={}, ready=true}
        pcall(function()
            if getconnections then
                for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(StealData[prompt].hold,c.Function) end end
                for _,c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(StealData[prompt].trigger,c.Function) end end
            end
        end)
    end
    local data = StealData[prompt]; if not data.ready then return end
    data.ready = false; isStealing = true; stealStartTime = tick()
    if ProgressLabel then ProgressLabel.Text = name or "STEALING..." end
    if progressConnection then progressConnection:Disconnect() end
    progressConnection = RunService.Heartbeat:Connect(function()
        if not isStealing then progressConnection:Disconnect(); return end
        local prog = math.clamp((tick()-stealStartTime)/Values.STEAL_DURATION, 0, 1)
        if ProgressBarFill    then ProgressBarFill.Size = UDim2.new(prog,0,1,0) end
        if ProgressPercentLabel then ProgressPercentLabel.Text = getDiscordProgress(math.floor(prog*100)) end
    end)
    task.spawn(function()
        for _,f in ipairs(data.hold) do task.spawn(f) end
        task.wait(Values.STEAL_DURATION)
        for _,f in ipairs(data.trigger) do task.spawn(f) end
        if progressConnection then progressConnection:Disconnect() end
        ResetProgressBar(); data.ready = true; isStealing = false
    end)
end

local function startAutoSteal()
    if Connections.autoSteal then return end
    Connections.autoSteal = RunService.Heartbeat:Connect(function()
        if not Enabled.AutoSteal or isStealing then return end
        local p,_,n = findNearestPrompt(); if p then executeSteal(p,n) end
    end)
end
local function stopAutoSteal()
    if Connections.autoSteal then Connections.autoSteal:Disconnect(); Connections.autoSteal=nil end
    isStealing = false; ResetProgressBar()
end

local savedAnimations = {}
local function startUnwalk()
    local c = Player.Character; if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid"); if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    local anim = c:FindFirstChild("Animate"); if anim then savedAnimations.Animate = anim:Clone(); anim:Destroy() end
end
local function stopUnwalk()
    local c = Player.Character; if c and savedAnimations.Animate then savedAnimations.Animate:Clone().Parent = c; savedAnimations.Animate = nil end
end

local function startSpeedWhileStealing()
    if Connections.speedWhileStealing then return end
    Connections.speedWhileStealing = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedWhileStealing or not Player:GetAttribute("Stealing") then return end
        local c = Player.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
        local md = getMoveDir(); if md.Magnitude > 0.1 then h.AssemblyLinearVelocity = Vector3.new(md.X*Values.StealingSpeedValue, h.AssemblyLinearVelocity.Y, md.Z*Values.StealingSpeedValue) end
    end)
end
local function stopSpeedWhileStealing()
    if Connections.speedWhileStealing then Connections.speedWhileStealing:Disconnect(); Connections.speedWhileStealing = nil end
end

-- ──────────────────────────────────────────────────────────────
-- GUI  (White theme + Black fire)
-- ──────────────────────────────────────────────────────────────
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local gs = 0.95  -- guiScale

local W = {
    bg       = Color3.fromRGB(255,255,255),
    card     = Color3.fromRGB(248,248,248),
    cardAlt  = Color3.fromRGB(238,238,238),
    border   = Color3.fromRGB(215,215,215),
    black    = Color3.fromRGB(0,0,0),
    ink      = Color3.fromRGB(18,18,18),
    inkMid   = Color3.fromRGB(90,90,90),
    inkLight = Color3.fromRGB(160,160,160),
    white    = Color3.fromRGB(255,255,255),
    toggleOn = Color3.fromRGB(10,10,10),
    toggleOff= Color3.fromRGB(210,210,210),
    success  = Color3.fromRGB(25,165,80),
    danger   = Color3.fromRGB(195,50,50),
    warn     = Color3.fromRGB(190,130,20),
}

local sg = Instance.new("ScreenGui")
sg.Name = "AlazDuels_GUI"; sg.ResetOnSpawn = false
sg.Parent = Player:FindFirstChildOfClass("PlayerGui") or Player.PlayerGui
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function snd(id,v,s)
    pcall(function()
        local x = Instance.new("Sound", SoundService); x.SoundId = id; x.Volume = v or 0.2; x.PlaybackSpeed = s or 1
        x:Play(); game:GetService("Debris"):AddItem(x, 1)
    end)
end

-- BLACK FIRE BACKGROUND
local fireBg = Instance.new("Frame", sg)
fireBg.Size = UDim2.new(1,0,1,0); fireBg.BackgroundTransparency = 1; fireBg.ZIndex = 0

local FCOUNT = 28; local fParticles = {}
local function spawnFire(yOverride)
    local p = Instance.new("Frame", fireBg)
    local sz = math.random(5,20); p.Size = UDim2.new(0,sz,0,sz); p.BorderSizePixel = 0; p.ZIndex = 1
    Instance.new("UICorner", p).CornerRadius = UDim.new(1,0)
    local gv = math.random(5,40); p.BackgroundColor3 = Color3.fromRGB(gv,gv,gv)
    p.BackgroundTransparency = math.random(35,70)/100
    local sx = math.random(0,1250); local sy = yOverride or math.random(600,980)
    p.Position = UDim2.new(0,sx,0,sy)
    local d = {f=p, x=sx, y=sy, vx=math.random(-14,14)*0.3, vy=-math.random(30,90), sz=sz, alpha=math.random(18,58)/100, life=0, max=math.random(18,50)/10, wig=math.random()*math.pi*2}
    table.insert(fParticles, d); return d
end
for i = 1, FCOUNT do local d = spawnFire(); d.y = math.random(50,980); d.life = math.random()*d.max end

local lastFT = tick()
RunService.RenderStepped:Connect(function()
    local now = tick(); local dt = now-lastFT; lastFT = now
    for i = #fParticles, 1, -1 do
        local d = fParticles[i]; if not d.f or not d.f.Parent then table.remove(fParticles,i); continue end
        d.life = d.life+dt; local t = d.life/d.max
        if t >= 1 then d.f:Destroy(); table.remove(fParticles,i); if #fParticles < FCOUNT then spawnFire() end; continue end
        d.wig = d.wig+dt*2.6; d.x = d.x+(d.vx+math.sin(d.wig)*8)*dt; d.y = d.y+d.vy*dt
        local sT = math.max(0,(t-0.42)*1.72); local cSz = d.sz*(1-sT*0.78); local al = d.alpha*(1-t)
        d.f.Size = UDim2.new(0,cSz,0,cSz); d.f.Position = UDim2.new(0,d.x,0,d.y); d.f.BackgroundTransparency = 1-al
        local gv = math.floor(6+sT*48); d.f.BackgroundColor3 = Color3.fromRGB(gv,gv,gv)
    end
end)

-- PROGRESS / STEAL BAR
local pH = Instance.new("Frame", sg)
pH.Size = UDim2.new(0,480*gs,0,74*gs); pH.Position = UDim2.new(0.5,-240*gs,0.8,-37*gs)
pH.BackgroundTransparency = 1; pH.ZIndex = 5

local pM = Instance.new("Frame", pH)
pM.Size = UDim2.new(1,0,1,0); pM.BackgroundColor3 = W.bg; pM.BackgroundTransparency = 0; pM.BorderSizePixel = 0; pM.ZIndex = 5
Instance.new("UICorner", pM).CornerRadius = UDim.new(0,15*gs)
local pMS = Instance.new("UIStroke", pM); pMS.Color = W.border; pMS.Thickness = 1.5

local sIcon = Instance.new("Frame", pM)
sIcon.Size = UDim2.new(0,9*gs,0,9*gs); sIcon.Position = UDim2.new(0.02,0,0.2,0)
sIcon.BackgroundColor3 = W.success; sIcon.BorderSizePixel = 0; sIcon.ZIndex = 6
Instance.new("UICorner", sIcon).CornerRadius = UDim.new(1,0)
task.spawn(function() while sIcon and sIcon.Parent do sIcon.BackgroundColor3 = isStealing and W.warn or W.success; task.wait(0.1) end end)

local sTxt = Instance.new("TextLabel", pM)
sTxt.Size=UDim2.new(0.3,0,0.2,0); sTxt.Position=UDim2.new(0.07,0,0.08,0); sTxt.BackgroundTransparency=1
sTxt.Text="ALAZ DUELS"; sTxt.TextColor3=W.inkLight; sTxt.Font=Enum.Font.GothamBold; sTxt.TextSize=9*gs; sTxt.TextXAlignment=Enum.TextXAlignment.Left; sTxt.ZIndex=6

ProgressLabel = Instance.new("TextLabel", pM)
ProgressLabel.Size=UDim2.new(0.5,0,0.3,0); ProgressLabel.Position=UDim2.new(0.03,0,0.28,0); ProgressLabel.BackgroundTransparency=1
ProgressLabel.Text="READY"; ProgressLabel.TextColor3=W.ink; ProgressLabel.Font=Enum.Font.GothamBlack; ProgressLabel.TextSize=19*gs; ProgressLabel.TextXAlignment=Enum.TextXAlignment.Left; ProgressLabel.ZIndex=6

ProgressPercentLabel = Instance.new("TextLabel", pM)
ProgressPercentLabel.Size=UDim2.new(0.78,0,0.2,0); ProgressPercentLabel.Position=UDim2.new(0.1,0,0.62,0); ProgressPercentLabel.BackgroundTransparency=1
ProgressPercentLabel.Text=""; ProgressPercentLabel.TextColor3=W.inkMid; ProgressPercentLabel.Font=Enum.Font.GothamBold; ProgressPercentLabel.TextSize=11*gs; ProgressPercentLabel.TextXAlignment=Enum.TextXAlignment.Center; ProgressPercentLabel.ZIndex=6

local rCtrl = Instance.new("Frame", pM); rCtrl.Size=UDim2.new(0.2,0,0.55,0); rCtrl.Position=UDim2.new(0.78,0,0.08,0); rCtrl.BackgroundTransparency=1; rCtrl.ZIndex=6
local rLbl=Instance.new("TextLabel",rCtrl); rLbl.Size=UDim2.new(1,0,0.3,0); rLbl.BackgroundTransparency=1; rLbl.Text="RADIUS"; rLbl.TextColor3=W.inkLight; rLbl.Font=Enum.Font.GothamBold; rLbl.TextSize=8*gs; rLbl.ZIndex=7
local rVal=Instance.new("TextLabel",rCtrl); rVal.Size=UDim2.new(1,0,0.4,0); rVal.Position=UDim2.new(0,0,0.3,0); rVal.BackgroundTransparency=1; rVal.Text=tostring(Values.STEAL_RADIUS); rVal.TextColor3=W.ink; rVal.Font=Enum.Font.GothamBlack; rVal.TextSize=16*gs; rVal.ZIndex=7
RadiusInput = Instance.new("TextBox",rCtrl); RadiusInput.Size=UDim2.new(1,0,0.3,0); RadiusInput.Position=UDim2.new(0,0,0.7,0); RadiusInput.BackgroundColor3=W.cardAlt; RadiusInput.BackgroundTransparency=0
RadiusInput.Text=tostring(Values.STEAL_RADIUS); RadiusInput.TextColor3=W.ink; RadiusInput.Font=Enum.Font.GothamBold; RadiusInput.TextSize=11*gs; RadiusInput.ZIndex=7
Instance.new("UICorner",RadiusInput).CornerRadius=UDim.new(0,6*gs)
RadiusInput.FocusLost:Connect(function() local n=tonumber(RadiusInput.Text); if n then Values.STEAL_RADIUS=math.clamp(math.floor(n),5,100); rVal.Text=tostring(Values.STEAL_RADIUS); RadiusInput.Text=tostring(Values.STEAL_RADIUS) end end)

local pTC=Instance.new("Frame",pM); pTC.Size=UDim2.new(0.85,0,0,9*gs); pTC.Position=UDim2.new(0.5,0,0.88,0); pTC.AnchorPoint=Vector2.new(0.5,0.5); pTC.BackgroundColor3=W.cardAlt; pTC.BorderSizePixel=0; pTC.ZIndex=6; Instance.new("UICorner",pTC).CornerRadius=UDim.new(1,0)
local pTr=Instance.new("Frame",pTC); pTr.Size=UDim2.new(1,-4*gs,1,-4*gs); pTr.Position=UDim2.new(0.5,0,0.5,0); pTr.AnchorPoint=Vector2.new(0.5,0.5); pTr.BackgroundColor3=W.border; pTr.BorderSizePixel=0; pTr.ZIndex=6; Instance.new("UICorner",pTr).CornerRadius=UDim.new(1,0)
ProgressBarFill=Instance.new("Frame",pTr); ProgressBarFill.Size=UDim2.new(0,0,1,0); ProgressBarFill.BackgroundColor3=W.black; ProgressBarFill.BorderSizePixel=0; ProgressBarFill.ZIndex=7; Instance.new("UICorner",ProgressBarFill).CornerRadius=UDim.new(1,0)

-- MAIN WINDOW
local main = Instance.new("Frame", sg); main.Name = "Main"
main.Size = UDim2.new(0,660*gs,0,715*gs)
main.Position = isMobile and UDim2.new(0.5,-330*gs,0.5,-357.5*gs) or UDim2.new(1,-685*gs,0,28)
main.BackgroundColor3=W.bg; main.BackgroundTransparency=0; main.BorderSizePixel=0
main.Active=true; main.Draggable=true; main.ClipsDescendants=true; main.ZIndex=10
local mainCorner=Instance.new("UICorner",main); mainCorner.CornerRadius=UDim.new(0,16*gs)
Instance.new("UIStroke",main).Color=W.border

-- BLACK HEADER WITH FIRE
local hdr=Instance.new("Frame",main); hdr.Size=UDim2.new(1,0,0,90*gs); hdr.BackgroundColor3=W.black; hdr.BorderSizePixel=0; hdr.ZIndex=11
local hCorner=Instance.new("UICorner",hdr); hCorner.CornerRadius=UDim.new(0,16*gs)
local hFill=Instance.new("Frame",hdr); hFill.Size=UDim2.new(1,0,0.5,0); hFill.Position=UDim2.new(0,0,0.5,0); hFill.BackgroundColor3=W.black; hFill.BorderSizePixel=0; hFill.ZIndex=11

local hFireCanvas=Instance.new("Frame",hdr); hFireCanvas.Size=UDim2.new(1,0,1,0); hFireCanvas.BackgroundTransparency=1; hFireCanvas.ZIndex=12; hFireCanvas.ClipsDescendants=true
local hFP = {}
local function spawnHFire()
    local p=Instance.new("Frame",hFireCanvas); local sz=math.random(3,12); p.Size=UDim2.new(0,sz,0,sz); p.BorderSizePixel=0; p.ZIndex=12
    Instance.new("UICorner",p).CornerRadius=UDim.new(1,0)
    local gv=math.random(22,65); p.BackgroundColor3=Color3.fromRGB(gv,gv,gv); p.BackgroundTransparency=math.random(32,62)/100
    local fw=660*gs
    local d={f=p, x=math.random(0,fw), y=math.random(55,90)*gs, vx=math.random(-6,6)*0.4, vy=-math.random(16,48), sz=sz, life=math.random()*2.8, max=math.random(12,30)/10, wig=math.random()*math.pi*2}
    p.Position=UDim2.new(0,d.x,0,d.y); table.insert(hFP,d)
end
for i=1,22 do spawnHFire() end

local lastHFT=tick()
RunService.RenderStepped:Connect(function()
    local now=tick(); local dt=now-lastHFT; lastHFT=now
    for i=#hFP,1,-1 do
        local d=hFP[i]; if not d.f or not d.f.Parent then table.remove(hFP,i); continue end
        d.life=d.life+dt; local t=d.life/d.max
        if t>=1 then d.f:Destroy(); table.remove(hFP,i); spawnHFire(); continue end
        d.wig=d.wig+dt*3.1; d.x=d.x+(d.vx+math.sin(d.wig)*4)*dt; d.y=d.y+d.vy*dt
        local sT=math.max(0,(t-0.36)*1.6); local cSz=d.sz*(1-sT*0.84); local al=(1-t)*0.74
        d.f.Size=UDim2.new(0,cSz,0,cSz); d.f.Position=UDim2.new(0,d.x,0,d.y); d.f.BackgroundTransparency=1-al
        local gv=math.floor(22+sT*52); d.f.BackgroundColor3=Color3.fromRGB(gv,gv,gv)
    end
end)

local titleLbl=Instance.new("TextLabel",hdr)
titleLbl.Size=UDim2.new(1,-54*gs,0,44*gs); titleLbl.Position=UDim2.new(0,0,0.08,0)
titleLbl.BackgroundTransparency=1; titleLbl.Text="⚔  ALAZ DUELS  ⚔"
titleLbl.TextColor3=W.white; titleLbl.Font=Enum.Font.GothamBlack; titleLbl.TextSize=29*gs
titleLbl.TextXAlignment=Enum.TextXAlignment.Center; titleLbl.ZIndex=14

local subLbl=Instance.new("TextLabel",hdr)
subLbl.Size=UDim2.new(1,0,0,19*gs); subLbl.Position=UDim2.new(0,0,0.67,0)
subLbl.BackgroundTransparency=1; subLbl.Text="PREMIUM EDITION  •  discord.gg/VXgngYEC"
subLbl.TextColor3=Color3.fromRGB(145,145,145); subLbl.Font=Enum.Font.GothamBold
subLbl.TextSize=11*gs; subLbl.TextXAlignment=Enum.TextXAlignment.Center; subLbl.ZIndex=14

local closeBtn=Instance.new("TextButton",hdr)
closeBtn.Size=UDim2.new(0,33*gs,0,33*gs); closeBtn.Position=UDim2.new(1,-43*gs,0.5,-16.5*gs)
closeBtn.BackgroundColor3=Color3.fromRGB(55,55,55); closeBtn.Text="✕"; closeBtn.TextColor3=W.white
closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=15*gs; closeBtn.ZIndex=15
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(1,0)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.18),{BackgroundColor3=W.danger}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.18),{BackgroundColor3=Color3.fromRGB(55,55,55)}):Play() end)

-- TABS
local tabCont=Instance.new("Frame",main); tabCont.Size=UDim2.new(1,-22*gs,0,40*gs); tabCont.Position=UDim2.new(0,11*gs,0,95*gs)
tabCont.BackgroundTransparency=1; tabCont.BorderSizePixel=0; tabCont.ZIndex=11
local tabs={"MOVEMENT","COMBAT","UTILITY","VISUALS"}; local activeTab="MOVEMENT"; local tabButtons={}

local function mkPanel(cv)
    local p=Instance.new("ScrollingFrame",main); p.Size=UDim2.new(1,-22*gs,0,498*gs); p.Position=UDim2.new(0,11*gs,0,143*gs)
    p.BackgroundTransparency=1; p.BorderSizePixel=0; p.CanvasSize=UDim2.new(0,0,0,cv*gs)
    p.ScrollBarThickness=4*gs; p.ScrollBarImageColor3=W.border; p.ClipsDescendants=true; p.ZIndex=11; p.Visible=false; return p
end
local movementPanel=mkPanel(640); movementPanel.Visible=true
local combatPanel=mkPanel(520); local utilityPanel=mkPanel(520); local visualsPanel=mkPanel(1130)

local function createTab(name, xp)
    local btn=Instance.new("TextButton",tabCont); btn.Size=UDim2.new(0,142*gs,0,34*gs); btn.Position=UDim2.new(0,xp,0.5,-17*gs)
    btn.BackgroundColor3=W.cardAlt; btn.Text=name; btn.TextColor3=W.inkMid; btn.Font=Enum.Font.GothamBold; btn.TextSize=11*gs; btn.ZIndex=12
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10*gs); local bs=Instance.new("UIStroke",btn); bs.Color=W.border; bs.Thickness=1
    btn.MouseButton1Click:Connect(function()
        activeTab=name
        for _,b in pairs(tabButtons) do
            TweenService:Create(b,TweenInfo.new(0.14),{BackgroundColor3=W.cardAlt,TextColor3=W.inkMid}):Play()
            local s=b:FindFirstChildOfClass("UIStroke"); if s then s.Color=W.border end
        end
        TweenService:Create(btn,TweenInfo.new(0.14),{BackgroundColor3=W.black,TextColor3=W.white}):Play()
        local s=btn:FindFirstChildOfClass("UIStroke"); if s then s.Color=W.black end
        movementPanel.Visible=(name=="MOVEMENT"); combatPanel.Visible=(name=="COMBAT")
        utilityPanel.Visible=(name=="UTILITY");   visualsPanel.Visible=(name=="VISUALS")
        snd("rbxassetid://6895079813",0.12,1.2)
    end)
    table.insert(tabButtons, btn); return btn
end
for i, name in ipairs(tabs) do
    local btn = createTab(name, (i-1)*148*gs)
    if name=="MOVEMENT" then btn.BackgroundColor3=W.black; btn.TextColor3=W.white; local s=btn:FindFirstChildOfClass("UIStroke"); if s then s.Color=W.black end end
end

local SliderSetters={}; local KeyButtons={}; local waitingForKeybind=nil

-- TOGGLE FACTORY
local function mkToggle(parent, yp, title, desc, keybindKey, enabledKey, cb)
    local cont=Instance.new("Frame",parent); cont.Size=UDim2.new(1,-8*gs,0,60*gs); cont.Position=UDim2.new(0,4*gs,0,yp*gs)
    cont.BackgroundColor3=W.card; cont.BackgroundTransparency=0; cont.BorderSizePixel=0; cont.ClipsDescendants=true; cont.ZIndex=12
    Instance.new("UICorner",cont).CornerRadius=UDim.new(0,11*gs); Instance.new("UIStroke",cont).Color=W.border
    if keybindKey then
        local kb=Instance.new("TextButton",cont); kb.Size=UDim2.new(0,39*gs,0,27*gs); kb.Position=UDim2.new(0,8*gs,0.5,-13.5*gs)
        kb.BackgroundColor3=W.cardAlt; kb.Text=KEYBINDS[keybindKey] and KEYBINDS[keybindKey].Name or "?"
        kb.TextColor3=W.ink; kb.Font=Enum.Font.GothamBold; kb.TextSize=10*gs; kb.ZIndex=14
        Instance.new("UICorner",kb).CornerRadius=UDim.new(0,7*gs); Instance.new("UIStroke",kb).Color=W.border
        KeyButtons[keybindKey]=kb; kb.MouseButton1Click:Connect(function() waitingForKeybind=keybindKey; kb.Text="..." end)
    end
    local off = keybindKey and 54*gs or 11*gs
    local tl=Instance.new("TextLabel",cont); tl.Size=UDim2.new(0.58,0,0,20*gs); tl.Position=UDim2.new(0,off,0,8*gs)
    tl.BackgroundTransparency=1; tl.Text=title; tl.TextColor3=W.ink; tl.Font=Enum.Font.GothamBold; tl.TextSize=13*gs; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=13
    local dl=Instance.new("TextLabel",cont); dl.Size=UDim2.new(0.6,0,0,15*gs); dl.Position=UDim2.new(0,off,0,30*gs)
    dl.BackgroundTransparency=1; dl.Text=desc; dl.TextColor3=W.inkLight; dl.Font=Enum.Font.Gotham; dl.TextSize=10*gs; dl.TextXAlignment=Enum.TextXAlignment.Left; dl.ZIndex=13
    local defOn=Enabled[enabledKey]
    local tb=Instance.new("Frame",cont); tb.Size=UDim2.new(0,52*gs,0,24*gs); tb.Position=UDim2.new(1,-64*gs,0.5,-12*gs)
    tb.BackgroundColor3=defOn and W.toggleOn or W.toggleOff; tb.BorderSizePixel=0; tb.ZIndex=13; Instance.new("UICorner",tb).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",tb); knob.Size=UDim2.new(0,19*gs,0,19*gs)
    knob.Position=defOn and UDim2.new(1,-22*gs,0.5,-9.5*gs) or UDim2.new(0,2.5*gs,0.5,-9.5*gs)
    knob.BackgroundColor3=W.white; knob.BorderSizePixel=0; knob.ZIndex=14; Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local clk=Instance.new("TextButton",cont); clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=15
    local isOn=defOn
    local function sv(state, skip)
        isOn=state
        TweenService:Create(tb,TweenInfo.new(0.22),{BackgroundColor3=isOn and W.toggleOn or W.toggleOff}):Play()
        TweenService:Create(knob,TweenInfo.new(0.22,Enum.EasingStyle.Back),{Position=isOn and UDim2.new(1,-22*gs,0.5,-9.5*gs) or UDim2.new(0,2.5*gs,0.5,-9.5*gs)}):Play()
        if not skip then cb(isOn) end
    end
    VisualSetters[enabledKey]=sv
    clk.MouseButton1Click:Connect(function() isOn=not isOn; Enabled[enabledKey]=isOn; sv(isOn); snd("rbxassetid://6895079813",0.12,1) end)
    return cont
end

-- SLIDER FACTORY
local function mkSlider(parent, yp, title, desc, mn, mx, vk, unit, cb)
    local cont=Instance.new("Frame",parent); cont.Size=UDim2.new(1,-8*gs,0,74*gs); cont.Position=UDim2.new(0,4*gs,0,yp*gs)
    cont.BackgroundColor3=W.card; cont.BackgroundTransparency=0; cont.BorderSizePixel=0; cont.ClipsDescendants=true; cont.ZIndex=12
    Instance.new("UICorner",cont).CornerRadius=UDim.new(0,11*gs); Instance.new("UIStroke",cont).Color=W.border
    local tl=Instance.new("TextLabel",cont); tl.Size=UDim2.new(0.55,0,0,18*gs); tl.Position=UDim2.new(0,11*gs,0,7*gs)
    tl.BackgroundTransparency=1; tl.Text=title; tl.TextColor3=W.ink; tl.Font=Enum.Font.GothamBold; tl.TextSize=13*gs; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=13
    local dl=Instance.new("TextLabel",cont); dl.Size=UDim2.new(0.55,0,0,13*gs); dl.Position=UDim2.new(0,11*gs,0,27*gs)
    dl.BackgroundTransparency=1; dl.Text=desc; dl.TextColor3=W.inkLight; dl.Font=Enum.Font.Gotham; dl.TextSize=10*gs; dl.TextXAlignment=Enum.TextXAlignment.Left; dl.ZIndex=13
    local defV=Values[vk]
    local vBox=Instance.new("Frame",cont); vBox.Size=UDim2.new(0,58*gs,0,30*gs); vBox.Position=UDim2.new(1,-67*gs,0,7*gs)
    vBox.BackgroundColor3=W.cardAlt; vBox.BorderSizePixel=0; vBox.ZIndex=13; Instance.new("UICorner",vBox).CornerRadius=UDim.new(0,9*gs); Instance.new("UIStroke",vBox).Color=W.border
    local vLbl=Instance.new("TextLabel",vBox); vLbl.Size=UDim2.new(1,0,0.62,0); vLbl.Position=UDim2.new(0,0,0,1); vLbl.BackgroundTransparency=1
    vLbl.Text=tostring(defV); vLbl.TextColor3=W.ink; vLbl.Font=Enum.Font.GothamBlack; vLbl.TextSize=15*gs; vLbl.ZIndex=14
    local uLbl=Instance.new("TextLabel",vBox); uLbl.Size=UDim2.new(1,0,0.35,0); uLbl.Position=UDim2.new(0,0,0.63,0); uLbl.BackgroundTransparency=1
    uLbl.Text=unit; uLbl.TextColor3=W.inkLight; uLbl.Font=Enum.Font.Gotham; uLbl.TextSize=9*gs; uLbl.ZIndex=14
    local sTrack=Instance.new("Frame",cont); sTrack.Size=UDim2.new(0.88,0,0,7*gs); sTrack.Position=UDim2.new(0.06,0,0,56*gs)
    sTrack.BackgroundColor3=W.cardAlt; sTrack.BorderSizePixel=0; sTrack.ZIndex=13; Instance.new("UICorner",sTrack).CornerRadius=UDim.new(1,0)
    local pct=(defV-mn)/(mx-mn)
    local sFill=Instance.new("Frame",sTrack); sFill.Size=UDim2.new(pct,0,1,0); sFill.BackgroundColor3=W.black; sFill.BorderSizePixel=0; sFill.ZIndex=13; Instance.new("UICorner",sFill).CornerRadius=UDim.new(1,0)
    local thumb=Instance.new("Frame",sTrack); thumb.Size=UDim2.new(0,14*gs,0,14*gs); thumb.Position=UDim2.new(pct,-7*gs,0.5,-7*gs)
    thumb.BackgroundColor3=W.white; thumb.BorderSizePixel=0; thumb.ZIndex=14; Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0); local ts=Instance.new("UIStroke",thumb); ts.Color=W.border; ts.Thickness=1
    local sBtn=Instance.new("TextButton",sTrack); sBtn.Size=UDim2.new(1,0,4,0); sBtn.Position=UDim2.new(0,0,-1.5,0); sBtn.BackgroundTransparency=1; sBtn.Text=""; sBtn.ZIndex=15
    local dragging=false
    local function upd(rel, skip)
        rel=math.clamp(rel,0,1); sFill.Size=UDim2.new(rel,0,1,0); thumb.Position=UDim2.new(rel,-7*gs,0.5,-7*gs)
        local val=math.floor(mn+(mx-mn)*rel); vLbl.Text=tostring(val); Values[vk]=val; if not skip then cb(val) end
    end
    local function setV(val)
        val=math.clamp(val,mn,mx); local rel=(val-mn)/(mx-mn)
        sFill.Size=UDim2.new(rel,0,1,0); thumb.Position=UDim2.new(rel,-7*gs,0.5,-7*gs); vLbl.Text=tostring(val); Values[vk]=val
    end
    SliderSetters[vk]=setV
    sBtn.MouseButton1Down:Connect(function() dragging=true end)
    UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    UserInputService.InputChanged:Connect(function(inp) if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then upd((inp.Position.X-sTrack.AbsolutePosition.X)/sTrack.AbsoluteSize.X) end end)
    return cont
end

-- ──────────────────────────────────────────────────────────────
-- POPULATE TABS
-- ──────────────────────────────────────────────────────────────
-- MOVEMENT
local y=7
mkToggle(movementPanel,y, "Sprint Boost",          "Increases movement speed",            "SPEED",    "SpeedBoost",   function(s) Enabled.SpeedBoost=s;    if s then startSpeedBoost()    else stopSpeedBoost()    end end)
_G.setSpeedVisual = VisualSetters.SpeedBoost
y=y+64; mkSlider(movementPanel,y,  "Sprint Multiplier",     "Adjust speed multiplier",             1,70,   "BoostSpeed",           "x",   function(v) Values.BoostSpeed=v end)
y=y+78; mkToggle(movementPanel,y,  "Ragdoll Immunity",      "Prevents ragdoll & stun",             nil,    "AntiRagdoll",          function(s) Enabled.AntiRagdoll=s;   if s then startAntiRagdoll()   else stopAntiRagdoll()   end end)
y=y+64; mkToggle(movementPanel,y,  "Spin Bot",              "Continuously rotates character",      "SPIN", "SpinBot",              function(s) Enabled.SpinBot=s;       if s then startSpinBot()       else stopSpinBot()       end end)
y=y+64; mkSlider(movementPanel,y,  "Spin Speed",            "Rotation speed (RPM)",                5,50,   "SpinSpeed",            "rpm", function(v) Values.SpinSpeed=v end)
y=y+78; mkToggle(movementPanel,y,  "Anti-Walk Anim",        "Removes walking animations",          nil,    "Unwalk",               function(s) Enabled.Unwalk=s;        if s then startUnwalk()        else stopUnwalk()        end end)
movementPanel.CanvasSize = UDim2.new(0,0,0,(y+70)*gs)

-- COMBAT
y=7
mkToggle(combatPanel,y,    "Auto Steal",            "Steals from nearby plots",            nil,        "AutoSteal",            function(s) Enabled.AutoSteal=s;         if s then startAutoSteal()         else stopAutoSteal()         end end)
y=y+64; mkSlider(combatPanel,y,    "Steal Speed",           "Speed while stealing",                10,35,  "StealingSpeedValue",   "x",   function(v) Values.StealingSpeedValue=v end)
y=y+78; mkToggle(combatPanel,y,    "Speed Steal",           "Speed boost while stealing",          nil,    "SpeedWhileStealing",   function(s) Enabled.SpeedWhileStealing=s; if s then startSpeedWhileStealing() else stopSpeedWhileStealing() end end)
y=y+64; mkToggle(combatPanel,y,    "Bat Spammer",           "Auto-swings your bat",                nil,    "SpamBat",              function(s) Enabled.SpamBat=s;           if s then startSpamBat()           else stopSpamBat()           end end)
y=y+64; mkToggle(combatPanel,y,    "Bat Aimbot",            "Auto-aims & moves to enemies",        "BATAIMBOT","BatAimbot",      function(s) Enabled.BatAimbot=s;          if s then startBatAimbot()          else stopBatAimbot()          end end)
combatPanel.CanvasSize = UDim2.new(0,0,0,(y+70)*gs)

-- UTILITY
y=7
mkToggle(utilityPanel,y,   "Gravity Mode",          "Reduced gravity for higher jumps",    "GALAXY",   "Galaxy",               function(s) Enabled.Galaxy=s;            if s then startGalaxy()            else stopGalaxy()            end end)
_G.setGalaxyVisual = VisualSetters.Galaxy
y=y+64; mkSlider(utilityPanel,y,   "Gravity Strength",      "Gravity percentage",                  25,130, "GalaxyGravityPercent", "%",   function(v) Values.GalaxyGravityPercent=v; if galaxyEnabled then adjustGalaxyJump() end end)
y=y+78; mkSlider(utilityPanel,y,   "Hop Power",             "Jump boost power",                    10,80,  "HOP_POWER",            "x",   function(v) Values.HOP_POWER=v end)
y=y+78; mkToggle(utilityPanel,y,   "Auto Left Path",        "Walks left path automatically",       "AUTOLEFT","AutoWalkEnabled", function(s) AutoWalkEnabled=s; Enabled.AutoWalkEnabled=s;  if s then startAutoWalk()  else stopAutoWalk()  end end)
_G.setAutoLeftVisual = VisualSetters.AutoWalkEnabled
y=y+64; mkToggle(utilityPanel,y,   "Auto Right Path",       "Walks right path automatically",      "AUTORIGHT","AutoRightEnabled",function(s) AutoRightEnabled=s; Enabled.AutoRightEnabled=s; if s then startAutoRight() else stopAutoRight() end end)
_G.setAutoRightVisual = VisualSetters.AutoRightEnabled
utilityPanel.CanvasSize = UDim2.new(0,0,0,(y+70)*gs)

-- VISUALS
y=7
mkToggle(visualsPanel,y,   "Performance Mode",      "Max FPS, no lag",                     nil,    "Optimizer",            function(s) Enabled.Optimizer=s;       if s then enableOptimizer()      else disableOptimizer()      end end)
y=y+64; mkToggle(visualsPanel,y,   "Galaxy Skybox",         "Galaxy sky theme",                    nil,    "GalaxySkyBright",      function(s) Enabled.GalaxySkyBright=s; if s then enableGalaxySkyBright() else disableGalaxySkyBright() end end)
y=y+64; mkToggle(visualsPanel,y,   "Fullbright",            "Makes everything bright",             nil,    "Fullbright",           function(s) Enabled.Fullbright=s;      if s then enableFullbright()     else disableFullbright()     end end)
y=y+64; mkToggle(visualsPanel,y,   "X-Ray Vision",          "See through walls",                   nil,    "XRay",                 function(s) Enabled.XRay=s;            if s then enableXRay()           else disableXRay()           end end)
y=y+64; mkToggle(visualsPanel,y,   "ESP Boxes",             "Boxes around players",                nil,    "ESPBoxes",             function(s) Enabled.ESPBoxes=s;        if s then enableESPBoxes()       else disableESPBoxes()       end end)
y=y+64; mkToggle(visualsPanel,y,   "Script User ESP",       "Highlights script users",             nil,    "ScriptUserESP",        function(s) Enabled.ScriptUserESP=s;   if s then scanBinUsers()         else cleanScriptUserESP()    end end)
y=y+64; mkToggle(visualsPanel,y,   "GUI Blur",              "Background blur",                     nil,    "GUIBlur",              function(s) Enabled.GUIBlur=s;         if s then enableGUIBlur()        else disableGUIBlur()        end end)
y=y+64; mkSlider(visualsPanel,y,   "Blur Intensity",        "Blur strength",                       1,24,   "GUIBlurSize",          "px",  function(v) Values.GUIBlurSize=v; if blurEffect then blurEffect.Size=v end end)
y=y+78; mkSlider(visualsPanel,y,   "ESP Red",               "Red channel",                         0,255,  "ESPColorR",            "R",   function(v) Values.ESPColorR=v; if Enabled.ESPBoxes then disableESPBoxes(); enableESPBoxes() end end)
y=y+78; mkSlider(visualsPanel,y,   "ESP Green",             "Green channel",                       0,255,  "ESPColorG",            "G",   function(v) Values.ESPColorG=v; if Enabled.ESPBoxes then disableESPBoxes(); enableESPBoxes() end end)
y=y+78; mkSlider(visualsPanel,y,   "ESP Blue",              "Blue channel",                        0,255,  "ESPColorB",            "B",   function(v) Values.ESPColorB=v; if Enabled.ESPBoxes then disableESPBoxes(); enableESPBoxes() end end)
y=y+78; mkSlider(visualsPanel,y,   "Name Tag Size",         "Player tag scale",                    0,3,    "NameTagSize",          "x",   function(v) Values.NameTagSize=v
    for _,pl in ipairs(Players:GetPlayers()) do if pl~=Player then pcall(function()
        local head=pl.Character and pl.Character:FindFirstChild("Head")
        if head then for _,gui in ipairs(head:GetChildren()) do if gui:IsA("BillboardGui") and gui.Name=="AlazDuelsESP" then gui.Size=UDim2.new(0,350*v,0,80*v) end end end
    end) end end
end)
y=y+78; mkSlider(visualsPanel,y,   "Field of View",         "Camera zoom",                         40,120, "FOV",                  "°",   function(v) Values.FOV=v; workspace.CurrentCamera.FieldOfView=v end)
visualsPanel.CanvasSize = UDim2.new(0,0,0,(y+84)*gs)

-- BOTTOM BAR
local infoBar=Instance.new("Frame",main); infoBar.Size=UDim2.new(1,-22*gs,0,42*gs); infoBar.Position=UDim2.new(0,11*gs,1,-48*gs)
infoBar.BackgroundColor3=W.black; infoBar.BorderSizePixel=0; infoBar.ZIndex=11; Instance.new("UICorner",infoBar).CornerRadius=UDim.new(0,11*gs)

local keyInfo=Instance.new("TextLabel",infoBar); keyInfo.Size=UDim2.new(0.73,0,1,0); keyInfo.Position=UDim2.new(0,9*gs,0,0)
keyInfo.BackgroundTransparency=1; keyInfo.Text="V:Sprint  N:Spin  M:Gravity  X:Aimbot  Z:Left  C:Right  Q:Nuke  U:Toggle"
keyInfo.TextColor3=Color3.fromRGB(145,145,145); keyInfo.Font=Enum.Font.Gotham; keyInfo.TextSize=9*gs; keyInfo.TextXAlignment=Enum.TextXAlignment.Left; keyInfo.ZIndex=12

local saveBtn=Instance.new("TextButton",infoBar); saveBtn.Size=UDim2.new(0,80*gs,0,27*gs); saveBtn.Position=UDim2.new(1,-90*gs,0.5,-13.5*gs)
saveBtn.BackgroundColor3=W.white; saveBtn.Text="SAVE"; saveBtn.TextColor3=W.black; saveBtn.Font=Enum.Font.GothamBold; saveBtn.TextSize=12*gs; saveBtn.ZIndex=12
Instance.new("UICorner",saveBtn).CornerRadius=UDim.new(0,9*gs)
saveBtn.MouseButton1Click:Connect(function()
    local ok=SaveConfig(); saveBtn.Text=ok and "✓" or "✗"
    TweenService:Create(saveBtn,TweenInfo.new(0.22),{BackgroundColor3=ok and W.success or W.danger,TextColor3=W.white}):Play()
    task.delay(1.2,function() saveBtn.Text="SAVE"; TweenService:Create(saveBtn,TweenInfo.new(0.22),{BackgroundColor3=W.white,TextColor3=W.black}):Play() end)
end)

-- ──────────────────────────────────────────────────────────────
-- INPUT HANDLER
-- ──────────────────────────────────────────────────────────────
local guiVisible = true
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    -- Rebind
    if waitingForKeybind and inp.KeyCode ~= Enum.KeyCode.Unknown then
        local k = inp.KeyCode; KEYBINDS[waitingForKeybind] = k
        if KeyButtons[waitingForKeybind] then KeyButtons[waitingForKeybind].Text = k.Name end
        waitingForKeybind = nil; return
    end
    if inp.KeyCode == Enum.KeyCode.U then
        guiVisible = not guiVisible; main.Visible = guiVisible; pH.Visible = guiVisible; return
    end
    if inp.KeyCode == Enum.KeyCode.Space then spaceHeld = true; return end
    -- Keybind actions
    if inp.KeyCode == KEYBINDS.SPEED     then Enabled.SpeedBoost = not Enabled.SpeedBoost;  if VisualSetters.SpeedBoost  then VisualSetters.SpeedBoost(Enabled.SpeedBoost)   end; if Enabled.SpeedBoost  then startSpeedBoost()  else stopSpeedBoost()  end end
    if inp.KeyCode == KEYBINDS.SPIN      then Enabled.SpinBot    = not Enabled.SpinBot;     if VisualSetters.SpinBot     then VisualSetters.SpinBot(Enabled.SpinBot)         end; if Enabled.SpinBot     then startSpinBot()     else stopSpinBot()     end end
    if inp.KeyCode == KEYBINDS.GALAXY    then Enabled.Galaxy     = not Enabled.Galaxy;      if VisualSetters.Galaxy      then VisualSetters.Galaxy(Enabled.Galaxy)           end; if Enabled.Galaxy      then startGalaxy()     else stopGalaxy()     end end
    if inp.KeyCode == KEYBINDS.BATAIMBOT then Enabled.BatAimbot  = not Enabled.BatAimbot;   if VisualSetters.BatAimbot   then VisualSetters.BatAimbot(Enabled.BatAimbot)     end; if Enabled.BatAimbot   then startBatAimbot()   else stopBatAimbot()   end end
    if inp.KeyCode == KEYBINDS.NUKE      then local n=getNearestPlayer(); if n then INSTANT_NUKE(n) end end
    if inp.KeyCode == KEYBINDS.AUTOLEFT  then AutoWalkEnabled  = not AutoWalkEnabled;  Enabled.AutoWalkEnabled  = AutoWalkEnabled;  if VisualSetters.AutoWalkEnabled  then VisualSetters.AutoWalkEnabled(AutoWalkEnabled)   end; if AutoWalkEnabled  then startAutoWalk()  else stopAutoWalk()  end end
    if inp.KeyCode == KEYBINDS.AUTORIGHT then AutoRightEnabled = not AutoRightEnabled; Enabled.AutoRightEnabled = AutoRightEnabled; if VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(AutoRightEnabled) end; if AutoRightEnabled then startAutoRight() else stopAutoRight() end end
end)
UserInputService.InputEnded:Connect(function(inp) if inp.KeyCode == Enum.KeyCode.Space then spaceHeld = false end end)

-- Respawn handling
Player.CharacterAdded:Connect(function()
    task.wait(1)
    if Enabled.SpinBot     then stopSpinBot();    task.wait(0.1); startSpinBot()    end
    if Enabled.Galaxy      then setupGalaxyForce(); adjustGalaxyJump()              end
    if Enabled.SpamBat     then stopSpamBat();    task.wait(0.1); startSpamBat()    end
    if Enabled.BatAimbot   then stopBatAimbot();  task.wait(0.1); startBatAimbot()  end
    if Enabled.Unwalk      then startUnwalk()                                       end
    if Enabled.AntiRagdoll then stopAntiRagdoll(); task.wait(0.1); startAntiRagdoll() end
end)

-- Init on load
task.spawn(function()
    task.wait(3)
    for k,s in pairs(VisualSetters) do if Enabled[k]  then s(true, true) end end
    for k,s in pairs(SliderSetters) do if Values[k]   then s(Values[k])  end end
    if Enabled.AntiRagdoll    then startAntiRagdoll()       end
    if Enabled.AutoSteal      then startAutoSteal()         end
    if Enabled.Optimizer      then enableOptimizer()        end
    if Enabled.GalaxySkyBright then enableGalaxySkyBright() end
    if Enabled.Fullbright     then enableFullbright()       end
    if Enabled.XRay           then enableXRay()             end
    if Enabled.ESPBoxes       then enableESPBoxes()         end
    if Enabled.GUIBlur        then enableGUIBlur()          end
    task.wait(0.5)
    if Enabled.SpeedBoost         then startSpeedBoost()         end
    if Enabled.SpinBot            then startSpinBot()            end
    if Enabled.SpamBat            then startSpamBat()            end
    if Enabled.BatAimbot          then startBatAimbot()          end
    if Enabled.Galaxy             then startGalaxy()             end
    if Enabled.SpeedWhileStealing then startSpeedWhileStealing() end
    if Enabled.Unwalk             then startUnwalk()             end
    if AutoWalkEnabled  then AutoWalkEnabled  = true; startAutoWalk()  end
    if AutoRightEnabled then AutoRightEnabled = true; startAutoRight() end
    workspace.CurrentCamera.FieldOfView = Values.FOV
end)

print("⚔ ALAZ DUELS - PREMIUM EDITION Loaded! ⚔")
print("V:Sprint | N:Spin | M:Gravity | X:Aimbot | Z:Left | C:Right | Q:Nuke | U:Toggle GUI")

return AlazDuels
