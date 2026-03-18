
repeat task.wait() until game:IsLoaded()

getgenv().debugInfo = true

local success, adonis = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/3a6ey/testadonis/refs/heads/main/test.lua"
    ))()
end)
if not success then
    warn("Failed to load: " .. tostring(adonis))
    return
end

hookfunction(gcinfo, function()
    return math.random(200, 350)
end)

local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall
local protect = newcclosure or function(f) return f end

mt.__namecall = protect(function(self, ...)
    local method = getnamecallmethod()
    if method == "Kick" then task.wait(9e9); return end
    if method == "InvokeServer" or method == "FireServer" then
        if self.Name:lower():find("kick") then return nil end
    end
    return oldNamecall(self, ...)
end)

pcall(function()
    hookfunction(
        game:GetService("Players").LocalPlayer.Kick,
        protect(function() task.wait(9e9) end)
    )
end)

if getgenv().__FantasyLoaded then
    pcall(getgenv().__FantasyLoaded)
    task.wait(0.1)
end

getgenv().__FantasyLoaded = function()
    if getgenv().__FantasyLibrary then
        pcall(function() getgenv().__FantasyLibrary:Unload() end)
    end
    getgenv().__FantasyLoaded  = nil
    getgenv().__FantasyLibrary = nil
end

local LIBRARY_CHOICE = getgenv().__FantasyLib or "Obsidian"

local LIB_URLS = {
    Obsidian = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua",
    Linoria  = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua",
}
local THEME_URLS = {
    Obsidian = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua",
    Linoria  = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua",
}
local SAVE_URLS = {
    Obsidian = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua",
    Linoria  = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua",
}

-- pre-Library simple cache (no Notify available yet)
local function simpleFetch(url, cachePath)
    if isfile and writefile and readfile and makefolder then
        pcall(makefolder, "Fantasy")
        pcall(makefolder, "Fantasy/cache")
        local cached = pcall(function() return isfile(cachePath) end) and isfile(cachePath)
        if cached then
            local ok, content = pcall(readfile, cachePath)
            if ok and content then return content end
        end
        local ok, content = pcall(game.HttpGet, game, url)
        if ok and content then
            pcall(writefile, cachePath, content)
            return content
        end
        return nil
    end
    local ok, content = pcall(game.HttpGet, game, url)
    return ok and content or nil
end

local Library = loadstring(simpleFetch(LIB_URLS[LIBRARY_CHOICE] or LIB_URLS.Obsidian, "Fantasy/cache/Library_" .. LIBRARY_CHOICE .. ".lua") or game:HttpGet(LIB_URLS[LIBRARY_CHOICE] or LIB_URLS.Obsidian))()

getgenv().__FantasyLibrary = Library

local Toggles = Library.Toggles
local Options  = Library.Options

local Window = Library:CreateWindow({
    Title      = "Fantasy",
    Icon       = "wand",
    Center     = true,
    AutoShow   = true,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Game     = Window:AddTab("Game",     "zap"),
    Fun      = Window:AddTab("Fun",      "smile"),
    Settings = Window:AddTab("Settings", "settings"),
}

local Players    = game:GetService("Players")
local Lighting   = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local player     = Players.LocalPlayer

local function Notify(opts)
    pcall(function() Library:Notify(opts) end)
end

-- ============================================================
-- LOADSTRING CACHE SYSTEM
-- ============================================================
local SCRIPT_CACHE = {
    Adonis = {name = "Adonis Anticheat Bypass",  url = "https://raw.githubusercontent.com/3a6ey/testadonis/refs/heads/main/test.lua",    path = "Fantasy/cache/AdonisBypass.lua"},
    IY     = { name = "Infinite Yield",    url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",               path = "Fantasy/cache/InfiniteYield.lua" },
    Dex    = { name = "Dex Explorer",      url = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua",                      path = "Fantasy/cache/Dex.lua" },
    Cobalt = { name = "Remote Spy Cobalt", url = "https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau",             path = "Fantasy/cache/Cobalt.lua" },
    Fly    = { name = "Fly",               url = "https://raw.githubusercontent.com/3a6ey/the-streets/refs/heads/main/fly.lua",         path = "Fantasy/cache/Fly.lua" },
}

local cacheEnabled   = false
local alwaysCheckUpd = false

local function canCache()
    return isfile and writefile and makefolder and true or false
end

local function ensureCacheFolder()
    if not makefolder then return end
    pcall(makefolder, "Fantasy")
    pcall(makefolder, "Fantasy/cache")
end

local function getCached(key)
    if not canCache() then return nil end
    local entry = SCRIPT_CACHE[key]
    if not entry then return nil end
    local ok, content = pcall(function()
        return isfile(entry.path) and readfile(entry.path) or nil
    end)
    return ok and content or nil
end

local function saveCache(key, content)
    if not canCache() then return end
    ensureCacheFolder()
    local entry = SCRIPT_CACHE[key]
    if entry then pcall(writefile, entry.path, content) end
end

local function fetchRemote(url)
    local ok, content = pcall(game.HttpGet, game, url)
    return ok and content or nil
end

local function loadScript(key)
    local entry = SCRIPT_CACHE[key]
    if not entry then return end

    local content = nil

    if cacheEnabled and canCache() then
        local cached = getCached(key)
        if cached then
            if alwaysCheckUpd then
                local remote = fetchRemote(entry.url)
                if remote and remote ~= cached then
                    saveCache(key, remote)
                    content = remote
                    Notify({ Title = entry.name, Description = "Updated from remote", Duration = 3 })
                else
                    content = cached
                end
            else
                content = cached
            end
        else
            content = fetchRemote(entry.url)
            if content then
                saveCache(key, content)
                Notify({ Title = entry.name, Description = "Cached for next time", Duration = 2 })
            end
        end
    else
        content = fetchRemote(entry.url)
    end

    if content then
        local ok, err = pcall(loadstring(content))
        if not ok then
            Notify({ Title = entry.name, Description = "Failed: " .. tostring(err), Duration = 5 })
        end
    else
        Notify({ Title = entry.name, Description = "Failed to load", Duration = 4 })
    end
end

player.Idled:Connect(function()
    setthreadcontext(8)
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

local GameLeft       = Tabs.Game:AddLeftGroupbox("Visual",      "eye")
local GameLoadBox    = Tabs.Game:AddLeftGroupbox("Loadstrings", "code")
local GameRight      = Tabs.Game:AddRightGroupbox("Utility",    "settings")

local brightLoop
local noFogLoop
local infJumpEnabled = false
local infJump = UIS.InputBegan:Connect(function(input, gpe)
    if gpe or input.KeyCode ~= Enum.KeyCode.Space or not infJumpEnabled then return end
    local char = player.Character
    local hum  = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

GameLeft:AddButton({
    Text = "Full Bright",
    Func = function()
        Lighting.Brightness     = 2
        Lighting.ClockTime      = 14
        Lighting.FogEnd         = 100000
        Lighting.GlobalShadows  = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Notify({ Title = "Full Bright", Description = "Applied", Duration = 3 })
    end,
})
GameLeft:AddToggle("LoopFBToggle", {
    Text    = "Loop FullBright",
    Default = false,
    Callback = function(v)
        if v then
            if brightLoop then brightLoop:Disconnect() end
            brightLoop = RunService.RenderStepped:Connect(function()
                Lighting.Brightness     = 2
                Lighting.ClockTime      = 14
                Lighting.FogEnd         = 100000
                Lighting.GlobalShadows  = false
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            end)
            Notify({ Title = "Loop FullBright", Description = "Started", Duration = 2 })
        else
            if brightLoop then brightLoop:Disconnect(); brightLoop = nil end
            Notify({ Title = "Loop FullBright", Description = "Stopped", Duration = 2 })
        end
    end,
})
GameLeft:AddButton({
    Text = "No Fog",
    Func = function()
        pcall(function()
            Lighting.FogEnd = 100000
            for _, v in pairs(Lighting:GetDescendants()) do
                if v:IsA("Atmosphere") then v:Destroy() end
            end
        end)
        Notify({ Title = "No Fog", Description = "Removed", Duration = 3 })
    end,
})
GameLeft:AddToggle("LoopNoFogToggle", {
    Text    = "Loop No Fog",
    Default = false,
    Callback = function(v)
        if v then
            if noFogLoop then noFogLoop:Disconnect() end
            local alive = true
            noFogLoop = { Disconnect = function() alive = false end }
            task.spawn(function()
                while alive do
                    Lighting.FogEnd   = 100000
                    Lighting.FogStart = 100000
                    task.wait(0.5)
                end
            end)
            Notify({ Title = "Loop No Fog", Description = "Started", Duration = 2 })
        else
            if noFogLoop then noFogLoop:Disconnect(); noFogLoop = nil end
            Notify({ Title = "Loop No Fog", Description = "Stopped", Duration = 2 })
        end
    end,
})
GameLeft:AddButton({
    Text = "Apply Shader",
    Func = function()
        local light = game.Lighting
        for _, v in ipairs(light:GetChildren()) do pcall(function() v:Destroy() end) end
        local ter   = workspace.Terrain
        local color = Instance.new("ColorCorrectionEffect")
        local bloom = Instance.new("BloomEffect")
        local sun   = Instance.new("SunRaysEffect")
        local blur  = Instance.new("BlurEffect")
        color.Parent = light; bloom.Parent = light; sun.Parent = light; blur.Parent = light

        color.Enabled = true; color.Contrast = 0.15; color.Brightness = 0.1
        color.Saturation = 0.25; color.TintColor = Color3.fromRGB(255, 222, 211)
        bloom.Enabled = true; bloom.Intensity = 0.05; bloom.Size = 32; bloom.Threshold = 1
        sun.Enabled = true; sun.Intensity = 0.2; sun.Spread = 1
        blur.Enabled = false; blur.Size = 6

        ter.WaterColor = Color3.fromRGB(10, 10, 24); ter.WaterWaveSize = 0.15
        ter.WaterWaveSpeed = 22; ter.WaterTransparency = 1; ter.WaterReflectance = 0.05

        light.Ambient = Color3.fromRGB(0, 0, 0); light.Brightness = 4
        light.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        light.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        light.ExposureCompensation = 0; light.FogColor = Color3.fromRGB(132, 132, 132)
        light.GlobalShadows = true; light.OutdoorAmbient = Color3.fromRGB(112, 117, 128)
        light.Outlines = false

        Notify({ Title = "Shader", Description = "Applied", Duration = 3 })
    end,
})

GameLoadBox:AddButton({
    Text = "Infinite Yield",
    DoubleClick = true,
    Func = function()
        Notify({ Title = "Loadstrings", Description = "Loading Infinite Yield...", Duration = 3 })
        task.spawn(function() loadScript("IY") end)
    end,
})
GameLoadBox:AddButton({
    Text = "Dex Explorer",
    DoubleClick = true,
    Func = function()
        Notify({ Title = "Loadstrings", Description = "Loading Dex...", Duration = 3 })
        task.spawn(function() loadScript("Dex") end)
    end,
})
GameLoadBox:AddButton({
    Text = "Remote Spy Cobalt",
    DoubleClick = true,
    Func = function()
        Notify({ Title = "Loadstrings", Description = "Loading Cobalt...", Duration = 3 })
        task.spawn(function() loadScript("Cobalt") end)
    end,
})

GameLoadBox:AddButton({
    Text = "Anti-Fling",
    DoubleClick = true,
    Func = function()
        local RS = game:GetService("RunService")
        local PLR = game:GetService("Players")

        local function watchPlayer(p)
            if p == player then return end
            local det, charParts = false, {}
            local char, hrp
            local function onChar(c)
                char = c; det = false; table.clear(charParts)
                repeat task.wait() hrp = c:FindFirstChild("HumanoidRootPart") until hrp
                for _, part in ipairs(c:GetDescendants()) do
                    if part:IsA("BasePart") then charParts[#charParts+1] = part end
                end
            end
            onChar(p.Character or p.CharacterAdded:Wait())
            p.CharacterAdded:Connect(onChar)
            local zero = Vector3.zero
            local pp   = PhysicalProperties.new(0,0,0)
            RS.Heartbeat:Connect(function()
                if not (char and char:IsDescendantOf(workspace)) then return end
                if not (hrp and hrp:IsDescendantOf(char)) then return end
                if hrp.AssemblyAngularVelocity.Magnitude > 50 or hrp.AssemblyLinearVelocity.Magnitude > 100 then
                    if not det then
                        pcall(game.StarterGui.SetCore, game.StarterGui, "ChatMakeSystemMessage", {
                            Text = "Fling detected: " .. p.Name, Color = Color3.fromRGB(255, 200, 0)
                        })
                        det = true
                    end
                    for i = 1, #charParts do
                        local part = charParts[i]
                        if part and part.Parent then
                            part.CanCollide = false
                            part.AssemblyAngularVelocity = zero
                            part.AssemblyLinearVelocity  = zero
                            part.CustomPhysicalProperties = pp
                        end
                    end
                end
            end)
        end

        for _, p in ipairs(PLR:GetPlayers()) do watchPlayer(p) end
        PLR.PlayerAdded:Connect(watchPlayer)

        local lastPos
        RS.Heartbeat:Connect(function()
            local char = player.Character
            local hrp  = char and char.PrimaryPart
            if not hrp then return end
            if hrp.AssemblyLinearVelocity.Magnitude > 250 or hrp.AssemblyAngularVelocity.Magnitude > 250 then
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.AssemblyLinearVelocity  = Vector3.zero
                if lastPos then hrp.CFrame = lastPos end
                pcall(game.StarterGui.SetCore, game.StarterGui, "ChatMakeSystemMessage", {
                    Text = "You were flung. Neutralized.", Color = Color3.fromRGB(255, 0, 0)
                })
            elseif hrp.AssemblyLinearVelocity.Magnitude < 50 then
                lastPos = hrp.CFrame
            end
        end)

        Notify({ Title = "Anti-Fling", Description = "Active", Duration = 3 })
    end,
})

GameRight:AddButton({
    Text = "Max Zoom + NoCam",
    Func = function()
        pcall(function() player.CameraMaxZoomDistance = 999999 end)
        local sc = (debug and debug.setconstant) or setconstant
        local gc = (debug and debug.getconstants) or getconstants
        if sc and getgc and gc then
            pcall(function()
                local pop = player.PlayerScripts.PlayerModule.CameraModule.ZoomController.Popper
                for _, v in pairs(getgc()) do
                    if type(v) == "function" and getfenv(v).script == pop then
                        for i, v1 in pairs(gc(v)) do
                            if tonumber(v1) == 0.25 then sc(v, i, 0)
                            elseif tonumber(v1) == 0 then sc(v, i, 0.25) end
                        end
                    end
                end
            end)
        end
        Notify({ Title = "Max Zoom + NoCam", Description = "Applied", Duration = 3 })
    end,
})
GameRight:AddButton({
    Text = "Third Person",
    Func = function()
        pcall(function()
            player.CameraMode            = Enum.CameraMode.Classic
            player.CameraMaxZoomDistance = 555
            player.CameraMinZoomDistance = 0.5
        end)
        Notify({ Title = "Third Person", Description = "Applied", Duration = 3 })
    end,
})
GameRight:AddToggle("InfiniteJumpToggle", {
    Text    = "Infinite Jump",
    Default = false,
    Callback = function(v) infJumpEnabled = v end,
})



local autoJumpAlive = false
GameRight:AddToggle("AutoJumpToggle", {
    Text    = "Infinite Jump (Hold)",
    Default = false,
    Callback = function(v)
        autoJumpAlive = v
        if v then
            task.spawn(function()
                while autoJumpAlive do
                    if UIS:IsKeyDown(Enum.KeyCode.Space) then
                        local char = player.Character
                        local hum  = char and char:FindFirstChildWhichIsA("Humanoid")
                        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                    end
                    task.wait(0.05)
                end
            end)
        end
    end,
})

local GameMove = Tabs.Game:AddRightGroupbox("Movement", "wind")

local noclipCon     = nil
local noclipCharCon = nil
local noclipParts   = {}

local function buildNoclipParts()
    table.clear(noclipParts)
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            noclipParts[#noclipParts + 1] = part
        end
    end
end

local flySpeed   = 1
local flyCharCon = nil

local function startFly()
    _G.Speed = flySpeed
    task.spawn(function()
        loadScript("Fly")
    end)
end

GameMove:AddToggle("FlyToggle", {
    Text    = "Fly",
    Default = false,
    Callback = function(v)
        if v then
            startFly()
            flyCharCon = player.CharacterAdded:Connect(function()
                if not (Toggles.FlyToggle and Toggles.FlyToggle.Value) then return end
                task.wait(1)
                startFly()
            end)
        else
            if flyCharCon then flyCharCon:Disconnect(); flyCharCon = nil end
            _G.Speed = 0
            task.wait(0.1)
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:FindFirstChildOfClass("BodyGyro") or obj:FindFirstChildOfClass("BodyVelocity") then
                    obj:Destroy()
                end
            end
            local char = player.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end,
})
GameMove:AddSlider("FlySpeedSlider", {
    Text     = "Fly Speed",
    Min      = 1,
    Max      = 50,
    Default  = 1,
    Rounding = 0,
    Callback = function(v)
        flySpeed = v
        _G.Speed = v
        if Toggles.FlyToggle and Toggles.FlyToggle.Value then
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:FindFirstChildOfClass("BodyGyro") or obj:FindFirstChildOfClass("BodyVelocity") then
                    obj:Destroy()
                end
            end
            task.wait(0.05)
            startFly()
        end
    end,
})


GameMove:AddToggle("NoclipToggle", {
    Text    = "Noclip",
    Default = false,
    Callback = function(v)
        if v then
            buildNoclipParts()
            noclipCon = RunService.Stepped:Connect(function()
                for i = 1, #noclipParts do
                    local part = noclipParts[i]
                    if part and part.Parent then
                        part.CanCollide = false
                    end
                end
            end)
            noclipCharCon = player.CharacterAdded:Connect(function()
                task.wait(0.1)
                buildNoclipParts()
            end)
        else
            if noclipCon     then noclipCon:Disconnect();     noclipCon     = nil end
            if noclipCharCon then noclipCharCon:Disconnect(); noclipCharCon = nil end
            task.wait()
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CanCollide = true end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end
            table.clear(noclipParts)
        end
    end,
})

local GameTeleport = Tabs.Game:AddRightGroupbox("Teleport", "map-pin")

local function getWorkspaceItems()
    local items = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("BasePart") then
            items[#items + 1] = obj.Name
        end
    end
    table.sort(items)
    if #items == 0 then items[1] = "No items" end
    return items
end

local function getInstancesOfName(name)
    local list = {}
    local n = 0
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == name then
            n = n + 1
            list[#list + 1] = name .. " #" .. n
        end
    end
    if #list == 0 then list[1] = "None" end
    return list
end

local selectedItem     = ""
local selectedIndex    = 1
local teleportAllItems = true
local itemDropdown     = nil
local instanceDropdown = nil
local loopTeleportCon  = nil

local function refreshInstanceDropdown()
    if not instanceDropdown then return end
    local list = getInstancesOfName(selectedItem)
    selectedIndex = 1
    pcall(function()
        instanceDropdown:SetValues(list)
        instanceDropdown:SetValue(list[1])
    end)
end

itemDropdown = GameTeleport:AddDropdown("ItemTeleportDropdown", {
    Text       = "Select Item",
    Values     = getWorkspaceItems(),
    Default    = getWorkspaceItems()[1],
    Searchable = true,
    Callback   = function(v)
        selectedItem = v
        refreshInstanceDropdown()
    end,
})
selectedItem = getWorkspaceItems()[1]

GameTeleport:AddButton({
    Text = "Refresh List",
    Func = function()
        local items = getWorkspaceItems()
        pcall(function() itemDropdown:SetValues(items) end)
        refreshInstanceDropdown()
        Notify({ Title = "Teleport", Description = "List refreshed", Duration = 2 })
    end,
})

local initInstances = getInstancesOfName(selectedItem)
instanceDropdown = GameTeleport:AddDropdown("ItemInstanceDropdown", {
    Text     = "Select Instance",
    Values   = initInstances,
    Default  = initInstances[1],
    Callback = function(v)
        local n = v:match("#(%d+)$")
        selectedIndex = tonumber(n) or 1
    end,
})

GameTeleport:AddToggle("TeleportAllToggle", {
    Text    = "Teleport All with Name",
    Default = true,
    Tooltip = "ON = all items with this name; OFF = only selected instance",
    Callback = function(v) teleportAllItems = v end,
})

local function doItemTeleport()
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    local count = 0
    local idx   = 0
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == selectedItem then
            idx = idx + 1
            if teleportAllItems or idx == selectedIndex then
                for _, v in pairs(obj:GetDescendants()) do
                    if v:IsA("BasePart") then v.CFrame = hrp.CFrame end
                end
                if obj:IsA("BasePart") then obj.CFrame = hrp.CFrame end
                count = count + 1
                if not teleportAllItems then break end
            end
        end
    end
    if count == 0 then
        Notify({ Title = "Teleport", Description = '"' .. selectedItem .. '" not found', Duration = 3 })
    end
    return count
end

GameTeleport:AddButton({
    Text = "Teleport Item to Me",
    Func = function()
        local count = doItemTeleport()
        if count > 0 then
            local desc = teleportAllItems and (count .. "x " .. selectedItem) or (selectedItem .. " #" .. selectedIndex)
            Notify({ Title = "Teleport", Description = desc .. " → you", Duration = 2 })
        end
    end,
})
GameTeleport:AddToggle("LoopItemTeleportToggle", {
    Text    = "Loop Teleport Item",
    Default = false,
    Callback = function(v)
        if v then
            local running = true
            loopTeleportCon = { Disconnect = function() running = false end }
            task.spawn(function()
                while running do
                    doItemTeleport()
                    task.wait(0.1)
                end
            end)
        else
            if loopTeleportCon then loopTeleportCon:Disconnect(); loopTeleportCon = nil end
        end
    end,
})
local FunLeft  = Tabs.Fun:AddLeftGroupbox("NPC Control", "user")
local FunRight = Tabs.Fun:AddRightGroupbox("NPC Aura",   "zap")

local currentNPC            = nil
local followCon             = nil
local orbitCon              = nil
local savedChar             = nil
local clickSelectOn         = false
local teleportCursorEnabled = false
local mouse                 = player:GetMouse()

local killAuraNPCs  = {}
local playerChars   = {}

local function rebuildPlayerChars()
    table.clear(playerChars)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then playerChars[p.Character] = true end
        p.CharacterAdded:Connect(function(c) playerChars[c] = true end)
        p.CharacterRemoving:Connect(function(c) playerChars[c] = nil end)
    end
end
rebuildPlayerChars()
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c) playerChars[c] = true end)
    p.CharacterRemoving:Connect(function(c) playerChars[c] = nil end)
end)

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Humanoid") then
        local model = obj.Parent
        if model and model:IsA("Model") and not playerChars[model] then
            killAuraNPCs[model] = true
        end
    end
end)
workspace.DescendantRemoving:Connect(function(obj)
    if obj:IsA("Humanoid") then
        local ok, parent = pcall(function() return obj.Parent end)
        if ok and parent then killAuraNPCs[parent] = nil end
    end
end)
task.spawn(function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") then
            local model = obj.Parent
            if model and model:IsA("Model") and not playerChars[model] then
                killAuraNPCs[model] = true
            end
        end
    end
end)

local multiSelectedNPCs = {}
local multiSelectOn     = false
local multiHighlights   = {}

local selHL = Instance.new("Highlight")
selHL.FillTransparency    = 1
selHL.OutlineTransparency = 1
selHL.Parent              = workspace

local function isNPC(model)
    return not playerChars[model] and (model:FindFirstChildOfClass("Humanoid") ~= nil or model:FindFirstChild("HumanoidRootPart") ~= nil)
end

local function flashHL(model, color)
    task.spawn(function()
        selHL.Adornee             = model
        selHL.OutlineColor        = color
        selHL.OutlineTransparency = 0
        task.wait(0.4)
        selHL.OutlineTransparency = 1
    end)
end

local netOwnerESPOn       = false
local netOwnerRadius      = 200
local killAuraRadius      = 20
local freezeAuraRadius    = 20
local netOwnerBBs         = {}
local netOwnerLoop        = nil
local netOwnerConAdded    = nil
local netOwnerConRemoving = nil

local function removeNetOwnerBB(model)
    local entry = netOwnerBBs[model]
    if entry then
        pcall(function() entry.bb:Destroy() end)
        netOwnerBBs[model] = nil
    end
end

local function addNetOwnerBB(model, hrp)
    if netOwnerBBs[model] then return end
    if not isNPC(model) then return end
    hrp = hrp or model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bb = Instance.new("BillboardGui")
    bb.Name         = "__NetOwnerBB"
    bb.Size         = UDim2.new(0, 160, 0, 36)
    bb.StudsOffset  = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop  = true
    bb.ResetOnSpawn = false
    bb.Parent       = hrp


    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 0.6, 0)
    lbl.Position               = UDim2.new(0, 0, 0.0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextStrokeTransparency = 0.3
    lbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    lbl.TextSize               = 13
    lbl.Font                   = Enum.Font.GothamBold
    lbl.Text                   = "..."
    lbl.TextColor3             = Color3.fromRGB(180, 180, 180)
    lbl.Parent                 = bb

    netOwnerBBs[model] = { bb = bb, lbl = lbl, nameLbl = nameLbl }
end

local function clearNetOwnerBBs()
    for model in pairs(netOwnerBBs) do removeNetOwnerBB(model) end
end

local function startNetOwnerLoop()
    if netOwnerLoop then return end
    for model in pairs(killAuraNPCs) do addNetOwnerBB(model) end
    netOwnerConAdded = workspace.DescendantAdded:Connect(function(obj)
        if not obj:IsA("Humanoid") then return end
        local model = obj.Parent
        if not model or not model:IsA("Model") then return end
        if not netOwnerESPOn then return end
        task.spawn(function()
            local hrp = model:WaitForChild("HumanoidRootPart", 3)
            if hrp and netOwnerESPOn then addNetOwnerBB(model, hrp) end
        end)
    end)
    netOwnerConRemoving = workspace.DescendantRemoving:Connect(function(obj)
        if obj:IsA("Humanoid") then removeNetOwnerBB(obj.Parent) end
    end)
    netOwnerLoop = true
    task.spawn(function()
        while netOwnerLoop do
            local char  = player.Character
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            local myPos = myHRP and myHRP.Position
            for model, entry in pairs(netOwnerBBs) do
                if not model.Parent then removeNetOwnerBB(model); continue end
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if myPos and (hrp.Position - myPos).Magnitude > netOwnerRadius then
                        entry.bb.Enabled = false; continue
                    end
                    entry.bb.Enabled = true
                    if entry.nameLbl then entry.nameLbl.Text = model.Name end
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health <= 0 then
                        entry.bb.Enabled = true
                        if entry.nameLbl then entry.nameLbl.Text = model.Name end
                        entry.lbl.Text       = "💀"
                        entry.lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                        continue
                    end
                    if hrp.ReceiveAge == 0 then
                        entry.lbl.Text       = model.Name
                        entry.lbl.TextColor3 = Color3.fromRGB(80, 255, 120)
                    else
                        entry.lbl.Text       = model.Name
                        entry.lbl.TextColor3 = Color3.fromRGB(255, 90, 90)
                    end
                end
            end
            task.wait(0.15)
        end
    end)
end

local function stopNetOwnerLoop()
    netOwnerESPOn = false
    netOwnerLoop  = false
    if netOwnerConAdded    then netOwnerConAdded:Disconnect();    netOwnerConAdded    = nil end
    if netOwnerConRemoving then netOwnerConRemoving:Disconnect(); netOwnerConRemoving = nil end
    clearNetOwnerBBs()
end

mouse.Button1Down:Connect(function()
    if not clickSelectOn and not multiSelectOn then return end
    local target = mouse.Target
    if not target then return end
    local model = target:FindFirstAncestorOfClass("Model")
    if not model then model = target.Parent end
    if not model then return end
    if not isNPC(model) then return end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if multiSelectOn then
        if multiSelectedNPCs[model] then
            multiSelectedNPCs[model] = nil
            removeMultiHL(model)
            Notify({ Title = "Multi Select", Description = "Removed: " .. model.Name, Duration = 2 })
        else
            multiSelectedNPCs[model] = true
            local hum   = model:FindFirstChildOfClass("Humanoid")
            local dead  = not hum or hum.Health <= 0
            local owned = hrp.ReceiveAge == 0
            local hl = Instance.new("Highlight")
            hl.FillTransparency    = 0.7
            hl.OutlineTransparency = 0
            hl.FillColor           = dead and Color3.fromRGB(255, 255, 255) or (owned and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(255, 200, 0))
            hl.OutlineColor        = hl.FillColor
            hl.Adornee             = model
            hl.Parent              = workspace
            multiHighlights[model] = hl
            Notify({ Title = "Multi Select", Description = "Selected: " .. model.Name .. (dead and " (Dead)" or ""), Duration = 2 })
        end
        return
    end

    if clickSelectOn then
        currentNPC = model
        flashHL(model, hrp.ReceiveAge == 0 and Color3.fromRGB(0, 255, 80) or Color3.fromRGB(255, 80, 80))
    end
end)

local simRadLoop
task.spawn(function()
    local setSimRad = sethiddenproperty and function()
        pcall(sethiddenproperty, player, "SimulationRadius", 100)
    end or function()
        pcall(function() player.SimulationRadius = 100 end)
    end
    local alive = true
    simRadLoop = { Disconnect = function() alive = false end }
    while alive do
        setSimRad()
        task.wait(0.1)
    end
end)

local function npcDo(fn)
    if not currentNPC then
        Notify({ Title = "NPC Control", Description = "Select an NPC first", Duration = 2 }); return
    end
    local hrp = currentNPC:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Notify({ Title = "NPC Control", Description = "HumanoidRootPart not found", Duration = 2 }); return
    end
    if hrp.ReceiveAge ~= 0 then
      
        Notify({ Title = "NPC Control", Description = "Waiting for ownership...", Duration = 2 })
        local t = tick()
        repeat task.wait(0.05) until hrp.ReceiveAge == 0 or tick() - t > 3
        if hrp.ReceiveAge ~= 0 then
            Notify({ Title = "NPC Control", Description = "No ownership after 3s", Duration = 2 }); return
        end
    end
    fn()
end


FunLeft:AddToggle("ClickSelectNPC", {
    Text = "Click to Select NPC", Default = false,
    Tooltip = "Click an NPC to select it",
    Callback = function(v) clickSelectOn = v end,
})
FunLeft:AddButton({
    Text = "Unselect NPC",
    Func = function()
        currentNPC = nil
        selHL.Adornee = nil
        selHL.OutlineTransparency = 1
    end,
})

local function removeMultiHL(model)
    local hl = multiHighlights[model]
    if hl then
        pcall(function() hl:Destroy() end)
        multiHighlights[model] = nil
    end
end

FunLeft:AddToggle("MultiSelectToggle", {
    Text = "Multi Select NPCs", Default = false,
    Tooltip = "Click NPCs to add/remove from selection",
    Callback = function(v)
        multiSelectOn = v
    end,
})
FunLeft:AddButton({
    Text = "Unselect Multi",
    Func = function()
        for model in pairs(multiSelectedNPCs) do
            removeMultiHL(model)
        end
        table.clear(multiSelectedNPCs)
        Notify({ Title = "Multi Select", Description = "Cleared", Duration = 2 })
    end,
})

FunLeft:AddDivider()

local savedBringPos     = nil
local teleportMultiCon  = nil
local teleportAnyCon    = nil

task.spawn(function()
    while true do
        if next(multiHighlights) then
        for model, hl in pairs(multiHighlights) do
            if not model.Parent then
                pcall(function() hl:Destroy() end)
                multiHighlights[model] = nil
                continue
            end
            local hrp   = model:FindFirstChild("HumanoidRootPart")
            local hum   = model:FindFirstChildOfClass("Humanoid")
            local dead  = not hum or hum.Health <= 0
            local owned = hrp and hrp.ReceiveAge == 0
            local col   = dead and Color3.fromRGB(255, 255, 255)
                       or (owned and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(255, 200, 0))
            pcall(function()
                hl.FillColor    = col
                hl.OutlineColor = col
            end)
        end
        end
        task.wait(0.2)
    end
end)

FunLeft:AddButton({
    Text = "Save Position",
    Func = function()
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then Notify({ Title = "Save Position", Description = "No character", Duration = 2 }); return end
        savedBringPos = hrp.CFrame
        local p = hrp.Position
        Notify({ Title = "Position Saved", Description = ("X:%.1f Y:%.1f Z:%.1f"):format(p.X, p.Y, p.Z), Duration = 4 })
    end,
})
FunLeft:AddButton({
    Text = "Teleport Selected to Position",
    Func = function()
        if not savedBringPos then
            Notify({ Title = "Teleport", Description = "Save a position first", Duration = 2 }); return
        end
        if not currentNPC then
            Notify({ Title = "Teleport", Description = "Select an NPC first", Duration = 2 }); return
        end
        npcDo(function()
            currentNPC:PivotTo(savedBringPos)
            Notify({ Title = "Teleport", Description = currentNPC.Name .. " teleported", Duration = 2 })
        end)
    end,
})
FunLeft:AddToggle("TeleportMultiToggle", {
    Text = "Teleport Multi to Position", Default = false,
    Tooltip = "When selected NPCs get ownership, teleport them to saved position and remove highlight",
    Callback = function(v)
        if v then
            if not savedBringPos then
                Notify({ Title = "Teleport Multi", Description = "Save a position first", Duration = 2 })
                if Toggles.TeleportMultiToggle then Toggles.TeleportMultiToggle:SetValue(false) end
                return
            end
            local running = true
            teleportMultiCon = { Disconnect = function() running = false end }
            task.spawn(function()
                while running do
                    for model in pairs(multiSelectedNPCs) do
                        if not model.Parent then continue end
                        local hrp = model:FindFirstChild("HumanoidRootPart")
                        if not hrp then continue end
                        local hum  = model:FindFirstChildOfClass("Humanoid")
                        local dead = not hum or hum.Health <= 0
                        if hrp.ReceiveAge == 0 or dead then
                            local offset = Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
                            model:PivotTo(savedBringPos * CFrame.new(offset))
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else
            if teleportMultiCon then teleportMultiCon:Disconnect(); teleportMultiCon = nil end
        end
    end,
})
local teleportAnyRadius    = 200
local teleportAnyKeepRadius = 5
FunLeft:AddButton({
    Text = "Teleport Any NPC to Position",
    Func = function()
        if not savedBringPos then
            Notify({ Title = "Teleport Any", Description = "Save a position first", Duration = 2 }); return
        end
        local count = 0
        local char  = player.Character
        local myHRP = char and char:FindFirstChild("HumanoidRootPart")
        local myPos = myHRP and myHRP.Position
        for model in pairs(killAuraNPCs) do
            if not model.Parent then continue end
            if model == char then continue end
            local hrp = model:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.ReceiveAge == 0 then
                if myPos and (hrp.Position - myPos).Magnitude > teleportAnyRadius then continue end
                local offset = Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
                model:PivotTo(savedBringPos * CFrame.new(offset))
                count = count + 1
            end
        end
        Notify({ Title = "Teleport Any", Description = count .. " NPC(s) teleported", Duration = 3 })
    end,
})
FunLeft:AddToggle("TeleportAnyNPCToggle", {
    Text = "Teleport Any NPC to Position", Default = false,
    Tooltip = "NPCs in radius get teleported to saved position and kept there",
    Callback = function(v)
        if v then
            if not savedBringPos then
                Notify({ Title = "Teleport Any", Description = "Save a position first", Duration = 2 })
                if Toggles.TeleportAnyNPCToggle then Toggles.TeleportAnyNPCToggle:SetValue(false) end
                return
            end
            local running = true
            teleportAnyCon = { Disconnect = function() running = false end }
            task.spawn(function()
                while running do
                    local char  = player.Character
                    local myHRP = char and char:FindFirstChild("HumanoidRootPart")
                    local myPos = myHRP and myHRP.Position
                    local savedPos = savedBringPos.Position
                    for model in pairs(killAuraNPCs) do
                        if not model.Parent then continue end
                        if model == char then continue end
                        local hrp = model:FindFirstChild("HumanoidRootPart")
                        if not hrp or hrp.ReceiveAge ~= 0 then continue end
                        if myPos and (hrp.Position - myPos).Magnitude > teleportAnyRadius then continue end
                        if (hrp.Position - savedPos).Magnitude > teleportAnyKeepRadius then
                            local offset = Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
                            model:PivotTo(savedBringPos * CFrame.new(offset))
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else
            if teleportAnyCon then teleportAnyCon:Disconnect(); teleportAnyCon = nil end
        end
    end,
})
FunLeft:AddSlider("TeleportAnyRadius", {
    Text = "Search Radius (m)", Min = 10, Max = 1000, Default = 200, Suffix = "m",
    Rounding = 0,
    Callback = function(v) teleportAnyRadius = v end,
})
FunLeft:AddInput("TeleportAnyRadiusInput", {
    Text = "Search Radius (type)", Default = "200", Numeric = true, Placeholder = "10 – 1000",
    Callback = function(v)
        local n = tonumber(v); if not n then return end
        n = math.clamp(math.floor(n), 10, 1000)
        teleportAnyRadius = n; Options.TeleportAnyRadius:SetValue(n)
    end,
})
FunLeft:AddSlider("TeleportAnyKeepRadius", {
    Text = "Keep Radius (m)", Min = 1, Max = 50, Default = 5, Suffix = "m",
    Rounding = 0,
    Callback = function(v) teleportAnyKeepRadius = v end,
})
FunLeft:AddInput("TeleportAnyKeepRadiusInput", {
    Text = "Keep Radius (type)", Default = "5", Numeric = true, Placeholder = "1 – 50",
    Callback = function(v)
        local n = tonumber(v); if not n then return end
        n = math.clamp(math.floor(n), 1, 50)
        teleportAnyKeepRadius = n; Options.TeleportAnyKeepRadius:SetValue(n)
    end,
})
local npcNoclipCon   = nil
local npcNoclipParts = {}

local function buildNpcNoclipParts()
    table.clear(npcNoclipParts)
    if not currentNPC or not currentNPC.Parent then return end
    for _, part in ipairs(currentNPC:GetDescendants()) do
        if part:IsA("BasePart") then
            npcNoclipParts[#npcNoclipParts + 1] = part
        end
    end
end

FunLeft:AddToggle("NpcNoclipToggle", {
    Text = "NPC Noclip", Default = false,
    Tooltip = "Selected NPC passes through everything",
    Callback = function(v)
        if v then
            if not currentNPC then
                Notify({ Title = "NPC Noclip", Description = "Select an NPC first", Duration = 2 })
                if Toggles.NpcNoclipToggle then Toggles.NpcNoclipToggle:SetValue(false) end
                return
            end
            buildNpcNoclipParts()
            local lastAge = nil
            npcNoclipCon = RunService.Stepped:Connect(function()
                if not currentNPC or not currentNPC.Parent then return end
                local hrp = currentNPC:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                if hrp.ReceiveAge == 0 and lastAge ~= nil and lastAge ~= 0 then
                    buildNpcNoclipParts()
                end
                lastAge = hrp.ReceiveAge
                for i = 1, #npcNoclipParts do
                    local part = npcNoclipParts[i]
                    if part and part.Parent then
                        part.CanCollide = false
                    end
                end
            end)
        else
            if npcNoclipCon then npcNoclipCon:Disconnect(); npcNoclipCon = nil end
            for i = 1, #npcNoclipParts do
                local part = npcNoclipParts[i]
                if part and part.Parent then part.CanCollide = true end
            end
            table.clear(npcNoclipParts)
        end
    end,
})
FunLeft:AddToggle("TeleportCursorToggle", {
    Text = "Teleport NPC to Cursor", Default = false,
    Tooltip = "Enable then press the key to teleport NPC to cursor",
    Callback = function(v) teleportCursorEnabled = v end,
}):AddKeyPicker("TeleportNPCKey", {
    Default = "T", Text = "Teleport Key", NoUI = false,
    Callback = function()
        if not teleportCursorEnabled then return end
        if not currentNPC then return end
        local hrp = currentNPC:FindFirstChild("HumanoidRootPart")
        if not hrp or hrp.ReceiveAge ~= 0 then return end
        currentNPC:PivotTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)))
    end,
})

FunLeft:AddDivider()

FunLeft:AddLabel("— Possession —")
FunLeft:AddToggle("ControlNPC", {
    Text = "Control NPC", Default = false,
    Tooltip = "Control the selected NPC (requires ownership)",
    Callback = function(v)
        if v then
            if not currentNPC then
                Notify({ Title = "Control NPC", Description = "Select an NPC first", Duration = 2 })
                Toggles.ControlNPC:SetValue(false); return
            end
            local hrp = currentNPC:FindFirstChild("HumanoidRootPart")
            if not hrp or hrp.ReceiveAge ~= 0 then
                Notify({ Title = "Control NPC", Description = "No Network Ownership", Duration = 2 })
                Toggles.ControlNPC:SetValue(false); return
            end
            savedChar = player.Character
            player.Character = currentNPC
            workspace.CurrentCamera.CameraSubject = hrp
            if savedChar then
                local charHRP = savedChar:FindFirstChild("HumanoidRootPart")
                if charHRP then charHRP.Anchored = true; charHRP.CFrame = hrp.CFrame * CFrame.new(0, -3, 0) end
                for _, part in ipairs(savedChar:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("SpecialMesh") then pcall(function() part.Transparency = 1 end) end
                    if part:IsA("Decal") or part:IsA("Texture") then pcall(function() part.Transparency = 1 end) end
                end
            end
            followCon = RunService.Heartbeat:Connect(function()
                if not currentNPC or not currentNPC.Parent then return end
                if not savedChar or not savedChar.Parent then return end
                local npcHRP  = currentNPC:FindFirstChild("HumanoidRootPart")
                local charHRP = savedChar:FindFirstChild("HumanoidRootPart")
                if npcHRP and charHRP then charHRP.CFrame = npcHRP.CFrame * CFrame.new(0, -3, 0) end
            end)
            task.spawn(function()
                local wasControlling = true
                while Toggles.ControlNPC and Toggles.ControlNPC.Value do
                    task.wait(0.2)
                    if not currentNPC or not currentNPC.Parent then break end
                    local npcHRP = currentNPC:FindFirstChild("HumanoidRootPart")
                    if not npcHRP then break end
                    if npcHRP.ReceiveAge ~= 0 then
                        if wasControlling then
                            wasControlling = false
                            if savedChar then
                                player.Character = savedChar
                                local hum = savedChar:FindFirstChildOfClass("Humanoid")
                                if hum then workspace.CurrentCamera.CameraSubject = hum end
                            end
                            Notify({ Title = "Control NPC", Description = "Ownership lost, retrying...", Duration = 2 })
                        end
                    else
                        if not wasControlling then
                            wasControlling = true
                            player.Character = currentNPC
                            workspace.CurrentCamera.CameraSubject = npcHRP
                            Notify({ Title = "Control NPC", Description = "Ownership regained", Duration = 2 })
                        end
                    end
                end
            end)
            Notify({ Title = "Control NPC", Description = "Controlling: " .. currentNPC.Name, Duration = 3 })
        else
            if followCon then followCon:Disconnect(); followCon = nil end
            if savedChar then
                for _, part in ipairs(savedChar:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("MeshPart") then pcall(function() part.Transparency = 0 end) end
                    if part:IsA("Decal") or part:IsA("Texture") then pcall(function() part.Transparency = 0 end) end
                end
                local charHRP = savedChar and savedChar.Parent and savedChar:FindFirstChild("HumanoidRootPart")
                if charHRP then
                    charHRP.Anchored = false
                    if currentNPC then
                        local npcHRP = currentNPC:FindFirstChild("HumanoidRootPart")
                        if npcHRP then charHRP.CFrame = npcHRP.CFrame end
                    end
                end
                player.Character = savedChar
                local hum = savedChar:FindFirstChildOfClass("Humanoid")
                if hum then workspace.CurrentCamera.CameraSubject = hum end
                savedChar = nil
                Notify({ Title = "Control NPC", Description = "Control returned", Duration = 2 })
            end
        end
    end,
})
FunLeft:AddToggle("FollowNPC", {
    Text = "NPC Follow Me", Default = false,
    Tooltip = "NPC will follow you",
    Callback = function(v)
        if v then
            if not currentNPC then
                Notify({ Title = "Follow NPC", Description = "Select an NPC first", Duration = 2 })
                Toggles.FollowNPC:SetValue(false); return
            end
            Notify({ Title = "Follow NPC", Description = "Following enabled", Duration = 2 })
            followCon = RunService.Heartbeat:Connect(function()
                if not currentNPC or not currentNPC.Parent then return end
                local hrp = currentNPC:FindFirstChild("HumanoidRootPart")
                if not hrp or hrp.ReceiveAge ~= 0 then return end
                local hum   = currentNPC:FindFirstChildOfClass("Humanoid")
                local char  = player.Character
                local myHRP = char and char:FindFirstChild("HumanoidRootPart")
                if hum and myHRP then hum:MoveTo(myHRP.Position + Vector3.new(-4, 0, 0)) end
            end)
        else
            if followCon then followCon:Disconnect(); followCon = nil end
        end
    end,
})
local orbitRadius = 12
FunLeft:AddToggle("OrbitNPCToggle", {
    Text = "Orbit Me", Default = false,
    Tooltip = "Selected NPC orbits around you",
    Callback = function(v)
        if v then
            if not currentNPC then
                Notify({ Title = "Orbit", Description = "Select an NPC first", Duration = 2 })
                Toggles.OrbitNPCToggle:SetValue(false); return
            end
            local angle = 0
            orbitCon = RunService.Heartbeat:Connect(function(dt)
                if not currentNPC or not currentNPC.Parent then return end
                local hrp = currentNPC:FindFirstChild("HumanoidRootPart")
                if not hrp or hrp.ReceiveAge ~= 0 then return end
                local char  = player.Character
                local myHRP = char and char:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end
                angle = angle + dt * 1.5
                local offset = Vector3.new(math.cos(angle) * orbitRadius, 0, math.sin(angle) * orbitRadius)
                currentNPC:PivotTo(CFrame.new(myHRP.Position + offset))
            end)
        else
            if orbitCon then orbitCon:Disconnect(); orbitCon = nil end
        end
    end,
})
FunLeft:AddSlider("OrbitRadiusSlider", {
    Text     = "Orbit Radius (m)",
    Min      = 2,
    Max      = 50,
    Default  = 12,
    Suffix   = "m",
    Rounding = 0,
    Callback = function(v) orbitRadius = v end,
})

FunLeft:AddDivider()

FunLeft:AddLabel("— Actions —")
FunLeft:AddButton({ Text = "Kill",      Func = function() npcDo(function() local h = currentNPC:FindFirstChildOfClass("Humanoid"); if h then h:ChangeState(15) end end) end })
FunLeft:AddButton({ Text = "Ragdoll",   Func = function() npcDo(function() local h = currentNPC:FindFirstChildOfClass("Humanoid"); if h then h:ChangeState(17) end end) end })
FunLeft:AddButton({ Text = "Sit",       Func = function() npcDo(function() local h = currentNPC:FindFirstChildOfClass("Humanoid"); if h then h.Sit = not h.Sit end end) end })
FunLeft:AddButton({ Text = "Jump",      Func = function() npcDo(function() local h = currentNPC:FindFirstChildOfClass("Humanoid"); if h then h:ChangeState(3) end end) end })
FunLeft:AddButton({ Text = "Freeze",    Func = function() npcDo(function()
    local hrp = currentNPC:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = not hrp.Anchored; Notify({ Title = "Freeze NPC", Description = hrp.Anchored and "Frozen" or "Unfrozen", Duration = 2 }) end
end) end })
FunLeft:AddButton({ Text = "Bring",     Func = function() npcDo(function() if player.Character then currentNPC:PivotTo(player.Character:GetPivot()) end end) end })
FunLeft:AddButton({ Text = "Go to NPC", Func = function()
    if not currentNPC then Notify({ Title = "NPC", Description = "Select an NPC first", Duration = 2 }); return end
    local char = player.Character
    if char then char:PivotTo(currentNPC:GetPivot()) end
end })
FunLeft:AddButton({ Text = "Punish",    Func = function() npcDo(function() currentNPC:PivotTo(CFrame.new(0, 10000, 0)) end) end })


FunRight:AddToggle("NetOwnerESP", {
    Text = "Network Owner ESP", Default = false,
    Tooltip = "Shows NPC name above head: green = you own it, red = server owns it",
    Callback = function(v)
        netOwnerESPOn = v
        if v then startNetOwnerLoop() else stopNetOwnerLoop() end
    end,
})
FunRight:AddSlider("NetOwnerRadius", {
    Text = "ESP Radius (m)", Min = 1, Max = 1000, Default = 200, Suffix = "m",
    Rounding = 0,
    Callback = function(v) netOwnerRadius = v end,
})
FunRight:AddInput("NetOwnerRadiusInput", {
    Text = "ESP Radius (type)", Default = "200", Numeric = true, Placeholder = "any value",
    Callback = function(v)
        local n = tonumber(v); if not n then return end
        n = math.max(1, math.floor(n))
        netOwnerRadius = n; Options.NetOwnerRadius:SetValue(math.min(n, 1000))
    end,
})

FunRight:AddDivider()

FunRight:AddLabel("— Auras —")

local killAuraOn    = false
local freezeAuraOn  = false
local anchorAuraOn  = false
local auraLoopCon   = nil

local function ensureAuraLoop()
    if auraLoopCon then return end
    local running = true
    auraLoopCon = { Disconnect = function() running = false end }
    task.spawn(function()
        while running do
            if killAuraOn or freezeAuraOn or anchorAuraOn then
                local char  = player.Character
                local myHRP = char and char:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    local myPos = myHRP.Position
                    for model in pairs(killAuraNPCs) do
                        if not model.Parent then killAuraNPCs[model] = nil; continue end
                        if model == char then continue end
                        local hrp = model:FindFirstChild("HumanoidRootPart")
                        if not hrp or hrp.ReceiveAge ~= 0 then continue end
                        local dist = (hrp.Position - myPos).Magnitude
                        local hum  = model:FindFirstChildOfClass("Humanoid")
                        local alive = hum and hum.Health > 0 and hum.Health == hum.Health
                        local killed = false
                        if killAuraOn and alive and dist <= killAuraRadius then
                            hum:ChangeState(15)
                            killed = true
                        end
                        if freezeAuraOn and alive and not killed and dist <= freezeAuraRadius then
                            hum.WalkSpeed = 0
                            hum.JumpPower = 0
                            hum:ChangeState(8)
                        end
                        if anchorAuraOn and dist <= anchorAuraRadius then
                            hrp.Anchored = true
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

local function stopAuraLoop()
    if auraLoopCon then auraLoopCon:Disconnect(); auraLoopCon = nil end
end

local function onAuraDisable()
    if not killAuraOn and not freezeAuraOn and not anchorAuraOn then
        stopAuraLoop()
    end
end

FunRight:AddToggle("KillAura", {
    Text = "Kill Aura", Default = false,
    Callback = function(v)
        killAuraOn = v
        if v then ensureAuraLoop() else onAuraDisable() end
    end,
})

FunRight:AddDivider()

FunRight:AddToggle("FreezeAura", {
    Text = "Freeze Aura", Default = false,
    Callback = function(v)
        freezeAuraOn = v
        if not v then
            for model in pairs(killAuraNPCs) do
                if model.Parent then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
                end
            end
            onAuraDisable()
        else
            ensureAuraLoop()
        end
    end,
})

FunRight:AddDivider()

local anchorAuraRadius = 20
FunRight:AddToggle("AnchorAura", {
    Text = "Anchor Aura", Default = false,
    Callback = function(v)
        anchorAuraOn = v
        if not v then
            for model in pairs(killAuraNPCs) do
                if model.Parent then
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.Anchored = false end
                end
            end
            onAuraDisable()
        else
            ensureAuraLoop()
        end
    end,
})

FunRight:AddDivider()

FunRight:AddSlider("KillAuraRadius", {
    Text = "Kill Radius (m)", Min = 10, Max = 1000, Default = 20, Suffix = "m",
    Rounding = 0,
    Callback = function(v) killAuraRadius = v end,
})
FunRight:AddInput("KillAuraRadiusInput", {
    Text = "Kill Radius (type)", Default = "20", Numeric = true, Placeholder = "10 – 1000",
    Callback = function(v)
        local n = tonumber(v); if not n then return end
        n = math.clamp(math.floor(n), 10, 1000)
        killAuraRadius = n; Options.KillAuraRadius:SetValue(n)
    end,
})


FunRight:AddSlider("FreezeAuraRadius", {
    Text = "Freeze Radius (m)", Min = 10, Max = 1000, Default = 20, Suffix = "m",
    Rounding = 0,
    Callback = function(v) freezeAuraRadius = v end,
})
FunRight:AddInput("FreezeAuraRadiusInput", {
    Text = "Freeze Radius (type)", Default = "20", Numeric = true, Placeholder = "10 – 1000",
    Callback = function(v)
        local n = tonumber(v); if not n then return end
        n = math.clamp(math.floor(n), 10, 1000)
        freezeAuraRadius = n; Options.FreezeAuraRadius:SetValue(n)
    end,
})



FunRight:AddSlider("AnchorAuraRadius", {
    Text = "Anchor Radius (m)", Min = 10, Max = 1000, Default = 20, Suffix = "m",
    Rounding = 0,
    Callback = function(v) anchorAuraRadius = v end,
})
FunRight:AddInput("AnchorAuraRadiusInput", {
    Text = "Anchor Radius (type)", Default = "20", Numeric = true, Placeholder = "10 – 1000",
    Callback = function(v)
        local n = tonumber(v); if not n then return end
        n = math.clamp(math.floor(n), 10, 1000)
        anchorAuraRadius = n; Options.AnchorAuraRadius:SetValue(n)
    end,
})

FunRight:AddDivider()

FunRight:AddLabel("— NPC Bait —")

local baitTargetName = ""
local baitDropdown   = nil
local loopBaitAllCon = nil

local function getBaitPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(names, p.Name) end
    end
    if #names == 0 then table.insert(names, "No players") end
    return names
end

baitDropdown = FunRight:AddDropdown("BaitTargetDropdown", {
    Text = "Target Player", Values = getBaitPlayerNames(), Default = getBaitPlayerNames()[1],
    Searchable = true,
    Callback = function(v) baitTargetName = v end,
})
baitTargetName = getBaitPlayerNames()[1]

Players.PlayerAdded:Connect(function()
    pcall(function() baitDropdown:SetValues(getBaitPlayerNames()) end)
end)
Players.PlayerRemoving:Connect(function()
    task.wait(); pcall(function() baitDropdown:SetValues(getBaitPlayerNames()) end)
end)

FunRight:AddToggle("LoopBaitAllToggle", {
    Text = "Loop Bait (all NPCs)", Default = false,
    Callback = function(v)
        if v then
            local running = true
            loopBaitAllCon = { Disconnect = function() running = false end }
            task.spawn(function()
                while running do
                    local target    = Players:FindFirstChild(baitTargetName)
                    local targetHRP = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                    if targetHRP then
                        for model in pairs(killAuraNPCs) do
                            if not model.Parent then continue end
                            local hrp = model:FindFirstChild("HumanoidRootPart")
                            if hrp and hrp.ReceiveAge == 0 then
                                for _, part in ipairs(model:GetChildren()) do
                                    if part:IsA("BasePart") then part.CanCollide = false end
                                end
                                model:PivotTo(CFrame.new(targetHRP.Position + Vector3.new(0, 5, 0)))
                            end
                        end
                    end
                    task.wait(0.5)
                end
                for model in pairs(killAuraNPCs) do
                    if model.Parent then
                        for _, part in ipairs(model:GetChildren()) do
                            if part:IsA("BasePart") then part.CanCollide = true end
                        end
                    end
                end
            end)
        else
            if loopBaitAllCon then loopBaitAllCon:Disconnect(); loopBaitAllCon = nil end
        end
    end,
})
FunRight:AddButton({
    Text = "Send NPC to Target",
    Func = function()
        npcDo(function()
            local target    = Players:FindFirstChild(baitTargetName)
            local targetHRP = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then
                Notify({ Title = "NPC Bait", Description = "Target has no character", Duration = 3 }); return
            end
            currentNPC:PivotTo(CFrame.new(targetHRP.Position + Vector3.new(0, 5, 0)))
            Notify({ Title = "NPC Bait", Description = currentNPC.Name .. " → " .. (target and target.Name or "?"), Duration = 3 })
        end)
    end,
})

FunRight:AddDivider()

FunRight:AddLabel("— Camera —")
FunRight:AddButton({
    Text = "Spectate",
    Func = function()
        if not currentNPC then Notify({ Title = "Spectate", Description = "Select an NPC first", Duration = 2 }); return end
        local hrp = currentNPC:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        workspace.CurrentCamera.CameraSubject = hrp
        Notify({ Title = "Spectate", Description = "Spectating " .. currentNPC.Name, Duration = 2 })
    end,
})
FunRight:AddButton({
    Text = "Unspectate",
    Func = function()
        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then workspace.CurrentCamera.CameraSubject = hum; Notify({ Title = "Spectate", Description = "Back to self", Duration = 2 }) end
    end,
})

local ThemeManager = loadstring(simpleFetch(THEME_URLS[LIBRARY_CHOICE] or THEME_URLS.Obsidian, "Fantasy/cache/ThemeManager_" .. LIBRARY_CHOICE .. ".lua") or game:HttpGet(THEME_URLS[LIBRARY_CHOICE] or THEME_URLS.Obsidian))()
local SaveManager  = loadstring(simpleFetch(SAVE_URLS[LIBRARY_CHOICE]  or SAVE_URLS.Obsidian,  "Fantasy/cache/SaveManager_"  .. LIBRARY_CHOICE .. ".lua") or game:HttpGet(SAVE_URLS[LIBRARY_CHOICE]  or SAVE_URLS.Obsidian))()

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind", "DPIDropdown" })
ThemeManager:SetFolder("Fantasy")
SaveManager:SetFolder("Fantasy")

SaveManager:BuildConfigSection(Tabs["Settings"])
ThemeManager:ApplyToTab(Tabs["Settings"])

local LibBox = Tabs["Settings"]:AddLeftGroupbox("UI Library", "layers")
LibBox:AddLabel("Current: " .. LIBRARY_CHOICE)
local chosenLib = LIBRARY_CHOICE
LibBox:AddDropdown("LibraryChoice", {
    Text    = "Library",
    Values  = { "Obsidian", "Linoria" },
    Default = LIBRARY_CHOICE,
    Callback = function(v)
        chosenLib = v
        getgenv().__FantasyLib = v
    end,
})
LibBox:AddButton({
    Text = "Reload with Selected Library",
    Func = function()
        getgenv().__FantasyLib = chosenLib
        pcall(function() Library:Unload() end)
        task.wait(0.3)
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/3a6ey/testadonis/refs/heads/main/Fantasy.lua"
        ))()
    end,
})

LibBox:AddDivider()
LibBox:AddToggle("CacheScriptsToggle", {
    Text    = "Cache Scripts Locally",
    Default = false,
    Tooltip = "Save loadstrings to Fantasy/cache/ folder and load from there instead of downloading",
    Callback = function(v)
        cacheEnabled = v
        if v and canCache() then
            ensureCacheFolder()
            Notify({ Title = "Cache", Description = "Scripts will be cached on next load", Duration = 3 })
        elseif v and not canCache() then
            Notify({ Title = "Cache", Description = "Executor doesn't support file I/O", Duration = 4 })
            if Toggles.CacheScriptsToggle then Toggles.CacheScriptsToggle:SetValue(false) end
        end
    end,
})
LibBox:AddToggle("AlwaysCheckUpdToggle", {
    Text    = "Always Check for Updates",
    Default = false,
    Tooltip = "On each load compare cached script with remote — update if different",
    Callback = function(v) alwaysCheckUpd = v end,
})
LibBox:AddButton({
    Text = "Download All Scripts Now",
    Func = function()
        if not canCache() then
            Notify({ Title = "Cache", Description = "Executor doesn't support file I/O", Duration = 4 }); return
        end
        ensureCacheFolder()
        task.spawn(function()
            local total, count = 0, 0
            -- download loadstrings
            for key, entry in pairs(SCRIPT_CACHE) do
                total = total + 1
                Notify({ Title = "Cache", Description = "Downloading " .. entry.name .. "...", Duration = 2 })
                local content = fetchRemote(entry.url)
                if content then saveCache(key, content); count = count + 1 end
            end
            -- download lib files
            local libFiles = {
                { url = LIB_URLS[LIBRARY_CHOICE] or LIB_URLS.Obsidian,   path = "Fantasy/cache/Library_" .. LIBRARY_CHOICE .. ".lua",     name = "Library" },
                { url = THEME_URLS[LIBRARY_CHOICE] or THEME_URLS.Obsidian, path = "Fantasy/cache/ThemeManager_" .. LIBRARY_CHOICE .. ".lua", name = "ThemeManager" },
                { url = SAVE_URLS[LIBRARY_CHOICE] or SAVE_URLS.Obsidian,   path = "Fantasy/cache/SaveManager_" .. LIBRARY_CHOICE .. ".lua",  name = "SaveManager" },
            }
            for _, f in ipairs(libFiles) do
                total = total + 1
                Notify({ Title = "Cache", Description = "Downloading " .. f.name .. "...", Duration = 2 })
                local content = fetchRemote(f.url)
                if content then pcall(writefile, f.path, content); count = count + 1 end
            end
            Notify({ Title = "Cache", Description = count .. "/" .. total .. " files cached ✓", Duration = 5 })
        end)
    end,
})

local MenuGroup = Tabs["Settings"]:AddRightGroupbox("Menu", "wrench")
MenuGroup:AddToggle("ShowUICursorToggle", {
    Text    = "Show UI Cursor",
    Default = false,
    Callback = function(v)
        Library.ShowCustomCursor = v
    end,
})
MenuGroup:AddToggle("ShowGameCursorToggle", {
    Text    = "Show Game Cursor",
    Default = true,
    Callback = function(v)
        UIS.MouseIconEnabled = v
    end,
})

local defaultSize = isfile and isfile("Fantasy/UISize") and readfile("Fantasy/UISize") or "100%"
MenuGroup:AddDropdown("DPIDropdown", {
    Text    = "UI Size",
    Values  = { "50%", "60%", "70%", "80%", "90%", "100%" },
    Default = defaultSize,
    Callback = function() end,
})
Options.DPIDropdown:OnChanged(function(v)
    pcall(function() if writefile then writefile("Fantasy/UISize", v) end end)
    local n = tonumber((v:gsub("%%", "")))
    if n then Library:SetDPIScale(n) end
end)
Options.DPIDropdown:SetValue(defaultSize)

MenuGroup:AddDivider()
MenuGroup:AddToggle("AutoexecuteToggle", {
    Text    = "Autoexecute",
    Default = false,
})
local function safeReadFile(path)
    if not (isfile and writefile) then return nil end
    local ok, val = pcall(function() return isfile(path) and readfile(path) end)
    return ok and val or nil
end
local wasAutoExec = safeReadFile("Fantasy/autoexec") == "true"
Toggles.AutoexecuteToggle:OnChanged(function(v)
    if writefile then pcall(writefile, "Fantasy/autoexec", tostring(v)) end
end)
if wasAutoExec then task.defer(function() Toggles.AutoexecuteToggle:SetValue(true) end) end

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "LeftAlt",
    NoUI    = false,
    Text    = "Menu Keybind",
    Mode    = "Always",
    Callback = function()
        Library:ToggleVisibility()
    end,
})
Library.ToggleKeybind = Options.MenuKeybind
MenuGroup:AddDivider()
MenuGroup:AddButton({
    Text = "Unload Script", Risky = true,
    Func = function() Library:Unload() end,
})

SaveManager:LoadAutoloadConfig()

getgenv().__FantasyLoaded = function()
    if getgenv().__FantasyLibrary then
        pcall(function() getgenv().__FantasyLibrary:Unload() end)
    end
    getgenv().__FantasyLoaded  = nil
    getgenv().__FantasyLibrary = nil
end

Library:OnUnload(function()
    getgenv().__FantasyLoaded  = nil
    getgenv().__FantasyLibrary = nil

    local togglesToReset = {
        "LoopFBToggle", "LoopNoFogToggle", "InfiniteJumpToggle", "AutoJumpToggle", "NoclipToggle", "FlyToggle", "LoopItemTeleportToggle", "TeleportAllToggle",
        "FollowNPC", "ControlNPC", "ClickSelectNPC", "TeleportCursorToggle", "OrbitNPCToggle", "NpcNoclipToggle", "MultiSelectToggle", "TeleportMultiToggle", "TeleportAnyNPCToggle",
        "NetOwnerESP", "KillAura", "FreezeAura", "AnchorAura", "LoopBaitAllToggle", "AutoexecuteToggle", "CacheScriptsToggle", "AlwaysCheckUpdToggle",
    }
    for _, name in ipairs(togglesToReset) do
        if Toggles[name] then pcall(function() Toggles[name]:SetValue(false) end) end
    end

    pcall(function() infJump:Disconnect()    end)
    pcall(function() simRadLoop:Disconnect() end)
    if noFogLoop   then noFogLoop:Disconnect();   noFogLoop   = nil end
    if brightLoop  then brightLoop:Disconnect();  brightLoop  = nil end
    pcall(stopNetOwnerLoop)

    if followCon      then followCon:Disconnect()      end
    killAuraOn = false; freezeAuraOn = false; anchorAuraOn = false
    if auraLoopCon    then auraLoopCon:Disconnect();    auraLoopCon    = nil end
    if loopBaitAllCon then loopBaitAllCon:Disconnect(); loopBaitAllCon = nil end
    if orbitCon       then orbitCon:Disconnect();       orbitCon       = nil end
    if noclipCon      then noclipCon:Disconnect();      noclipCon      = nil end
    if noclipCharCon  then noclipCharCon:Disconnect();  noclipCharCon  = nil end
    if loopTeleportCon then loopTeleportCon:Disconnect(); loopTeleportCon = nil end
    if npcNoclipCon   then npcNoclipCon:Disconnect();   npcNoclipCon   = nil end
    if teleportMultiCon then teleportMultiCon:Disconnect(); teleportMultiCon = nil end
    if teleportAnyCon   then teleportAnyCon:Disconnect();   teleportAnyCon   = nil end

    pcall(function() selHL:Destroy() end)
    for _, hl in pairs(multiHighlights) do pcall(function() hl:Destroy() end) end
    table.clear(multiSelectedNPCs)
    table.clear(multiHighlights)
    if savedChar then player.Character = savedChar end
    print("Fantasy Unloaded")
end)

print("👀 Fantasy Loaded!")
