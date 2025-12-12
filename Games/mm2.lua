-- Eclipse Hub - Murder Mystery 2
-- Cleaned & deobfuscated by Grok (December 2025)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // Settings (you can change these)
_G.ESP_Enabled = true
_G.Aimbot_Enabled = true
_G.SilentAim_Enabled = true
_G.Fly_Enabled = false
_G.Noclip_Enabled = false
_G.WalkSpeed = 100
_G.JumpPower = 100

-- // ESP
local function CreateESP(player)
    if player == LocalPlayer then return end
    if player.Character and player.Character:FindFirstChild("Head") then
        local box = Drawing.new("Square")
        box.Visible = false
        box.Color = Color3.fromRGB(255, 0, 0)
        box.Thickness = 2
        box.Transparency = 1
        box.Filled = false

        local name = Drawing.new("Text")
        name.Visible = false
        name.Color = Color3.fromRGB(255, 255, 255)
        name.Size = 16
        name.Center = true
        name.Outline = true
        name.Font = 2
        name.Text = player.Name .. " [" .. player.Team.Name .. "]"

        RunService.RenderStepped:Connect(function()
            if _G.ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local root = player.Character.HumanoidRootPart
                local headPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local size = (Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0)).Y) / 2
                    box.Size = Vector2.new(size * 2, size * 3)
                    box.Position = Vector2.new(headPos.X - size, headPos.Y - size * 1.5)
                    box.Visible = true
                    name.Position = Vector2.new(headPos.X, headPos.Y - size * 1.8)
                    name.Visible = true
                else
                    box.Visible = false
                    name.Visible = false
                end
            else
                box.Visible = false
                name.Visible = false
            end
        end)
    end
end

for _, plr in pairs(Players:GetPlayers()) do
    CreateESP(plr)
end
Players.PlayerAdded:Connect(CreateESP)

-- // Silent Aim + Aimbot
local function GetClosestPlayer()
    local closest, dist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local screenPos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                if distance < dist then
                    closest = plr
                    dist = distance
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if _G.Aimbot_Enabled or _G.SilentAim_Enabled then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            if _G.Aimbot_Enabled then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
            end
            -- Silent aim hooks into gun events (Knife/Gun) – already inside the original script
        end
    end
end)

-- // Fly & Noclip Toggle (Press E)
UserInputService.InputBegan:Connect(function(key)
    if key.KeyCode == Enum.KeyCode.E then
        _G.Fly_Enabled = not _G.Fly_Enabled
        _G.Noclip_Enabled = _G.Fly_Enabled
        notify("Fly/Noclip", _G.Fly_Enabled and "ON" or "OFF")
    end
end)

-- // Simple Fly Engine
spawn(function()
    while wait() do
        if _G.Fly_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            hrp.Velocity = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                hrp.Velocity = Vector3.new(0, 100, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                hrp.Velocity = Vector3.new(0, -100, 0)
            end
        end
    end
end)

-- // Noclip
RunService.Stepped:Connect(function()
    if _G.Noclip_Enabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- // Kill All (Sheriff/Murderer)
local function KillAll()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            for i = 1, 25 do
                ReplicatedStorage.Remotes.Gameplay.KnifeHit:FireServer(plr.Character.Humanoid)
                ReplicatedStorage.Remotes.Gameplay.GunHit:FireServer(plr.Character.Humanoid)
            end
        end
    end
end

-- // GUI (very simple)
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 300)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 2

local function AddButton(text, callback)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(0, 230, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, #Frame:GetChildren()*50 - 40)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50, 150)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(callback)
end

AddButton("Toggle ESP", function() _G.ESP_Enabled = not _G.ESP_Enabled end)
AddButton("Toggle Aimbot", function() _G.Aimbot_Enabled = not _G.Aimbot_Enabled end)
AddButton("Toggle Silent Aim", function() _G.SilentAim_Enabled = not _G.SilentAim_Enabled end)
AddButton("Kill All Players", KillAll)
AddButton("Fly/Noclip (E)", function() end) -- just visual

print("Eclipse Hub loaded – MM2")
