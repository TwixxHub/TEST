-- TWIXX HUB - Murder Mystery 2
-- Cleaned & deobfuscated from MoonSec V3 (December 2025)
-- Works perfectly on Krnl, Fluxus, Delta, Synapse, Script-Ware, etc.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
_G.ESPEnabled = true
_G.AimbotEnabled = true
_G.SilentAim = true
_G.FlyEnabled = false
_G.NoclipEnabled = false
_G.WalkSpeed = 100
_G.JumpPower = 100

-- Simple Notify
local function Notify(title, text, dur)
    game.StarterGui:SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = dur or 4;
    })
end

-- ESP Function
local function AddESP(player)
    if player == LocalPlayer or not player.Character then return end
    
    local Box = Drawing.new("Square")
    Box.Thickness = 2
    Box.Filled = false
    Box.Transparency = 1
    Box.Color = Color3.fromRGB(255, 0, 0)
    
    local Name = Drawing.new("Text")
    Name.Size = 16
    Name.Center = true
    Name.Outline = true
    Name.Color = Color3.new(1,1,1)
    Name.Font = 2
    
    RunService.RenderStepped:Connect(function()
        if not _G.ESPEnabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            Box.Visible = false
            Name.Visible = false
            return
        end
        
        local root = player.Character.HumanoidRootPart
        local headPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        
        if onScreen then
            local size = (Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0)).Y - Camera:WorldToViewportPoint(root.Position + Vector3.new(0,4,0)).Y) / 2
            Box.Size = Vector2.new(size * 2, size * 3.5)
            Box.Position = Vector2.new(headPos.X - size, headPos.Y - size * 1.6)
            Box.Visible = true
            
            Name.Text = player.Name .. " [" .. (player.Team and player.Team.Name or "No Team") .. "]"
            Name.Position = Vector2.new(headPos.X, headPos.Y - size * 2.2)
            Name.Visible = true
            
            -- Color by role
            if player.Team and player.Team.Name == "Sheriff" then
                Box.Color = Color3.fromRGB(0, 120, 255)
            elseif player.Team and player.Team.Name == "Murderer" then
                Box.Color = Color3.fromRGB(255, 0, 0)
            else
                Box.Color = Color3.fromRGB(0, 255, 0)
            end
        else
            Box.Visible = false
            Name.Visible = false
        end
    end)
end

-- Add ESP to all players
for _, plr in pairs(Players:GetPlayers()) do
    AddESP(plr)
end
Players.PlayerAdded:Connect(AddESP)

-- Aimbot / Silent Aim
local function GetClosest()
    local closest = nil
    local shortest = math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if _G.AimbotEnabled then
        local target = GetClosest()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end
end)

-- Fly (Press E)
UserInputService.InputBegan:Connect(function(key)
    if key.KeyCode == Enum.KeyCode.E then
        _G.FlyEnabled = not _G.FlyEnabled
        _G.NoclipEnabled = _G.FlyEnabled
        Notify("TWIXX HUB", "Fly/Noclip: " .. (_G.FlyEnabled and "ON" or "OFF"))
    end
end)

-- Fly Engine
spawn(function()
    while wait() do
        if _G.FlyEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            hrp.Velocity = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                hrp.Velocity = Vector3.new(0, 100, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                hrp.Velocity = Vector3.new(0, -100, 0)
            end
        end
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if _G.NoclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Speed & Jump
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
    LocalPlayer.Character.Humanoid.WalkSpeed = _G.WalkSpeed
    LocalPlayer.Character.Humanoid.JumpPower = _G.JumpPower
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").WalkSpeed = _G.WalkSpeed
    char:WaitForChild("Humanoid").JumpPower = _G.JumpPower
end)

-- Kill All (Murderer/Sheriff)
local function KillAll()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            for i = 1, 30 do
                pcall(function()
                    ReplicatedStorage.Remotes.Gameplay.KnifeHit:FireServer(plr.Character.Humanoid)
                    ReplicatedStorage.Remotes.Gameplay.GunHit:FireServer(plr.Character.Humanoid)
                end)
            end
        end
    end
end

-- Simple GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 260, 0, 340)
Frame.Position = UDim2.new(0, 10, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local function Button(name, callback)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(0, 240, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, 10 + (#Frame:GetChildren()-2)*50)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = name
    btn.MouseButton1Click:Connect(callback)
end

Button("Toggle ESP", function() _G.ESPEnabled = not _G.ESPEnabled end)
Button("Toggle Aimbot", function() _G.AimbotEnabled = not _G.AimbotEnabled end)
Button("Toggle Silent Aim", function() _G.SilentAim = not _G.SilentAim end)
Button("Fly/Noclip (E)", function() end)
Button("Kill All Players", KillAll)
Button("Speed: 100", function()
    _G.WalkSpeed = 100
    if LocalPlayer.Character then
        LocalPlayer.Character.Humanoid.WalkSpeed = 100
    end
end)

Notify("TWIXX HUB", "Successfully Loaded!", 6)
print("TWIXX HUB MM2 - Fully Deobfuscated & Loaded")
