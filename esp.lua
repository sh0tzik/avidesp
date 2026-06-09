local AvidwareESP = {
    Settings = {
        Enabled = true,
        
        -- Боксы
        ShowBoxes = true,
        BoxColor = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),
        
        -- Скелетон
        ShowSkeletons = true,
        SkeletonColor = Color3.fromRGB(255, 255, 255),
        SkeletonOutlineColor = Color3.fromRGB(0, 0, 0),
        
        -- ХП Бар и Текст
        ShowHealthBar = true,
        HealthBarSide = "Left",
        ShowHealthText = true,
        HealthTextSide = "Left",
        HealthTextColor = Color3.fromRGB(255, 255, 255),
        
        -- Имена и Оружие
        ShowNames = true,
        NameColor = Color3.fromRGB(255, 255, 255),
        ShowWeapon = true,
        WeaponColor = Color3.fromRGB(230, 230, 230)
    },
    Cache = {},
    Connections = {}
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Функция для округления до целых пикселей (чтобы не было кривизны)
local function R(num)
    return math.floor(num + 0.5)
end

local function CreateDrawings()
    local drawings = {
        Box = Drawing.new("Square"),
        BoxOuter = Drawing.new("Square"),
        BoxInner = Drawing.new("Square"),
        HealthBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        HealthText = Drawing.new("Text"),
        Name = Drawing.new("Text"),
        Weapon = Drawing.new("Text"),
        Skeleton = {}
    }
    
    -- Выделяем память под 15 костей (линий) для скелета (хватит и на R15, и на R6)
    for i = 1, 15 do
        drawings.Skeleton[i] = {
            Outline = Drawing.new("Line"),
            Inline = Drawing.new("Line")
        }
    end
    
    return drawings
end

local function HideDrawings(drawings)
    setrenderproperty(drawings.Box, "Visible", false)
    setrenderproperty(drawings.BoxOuter, "Visible", false)
    setrenderproperty(drawings.BoxInner, "Visible", false)
    setrenderproperty(drawings.HealthBG, "Visible", false)
    setrenderproperty(drawings.HealthBar, "Visible", false)
    setrenderproperty(drawings.HealthText, "Visible", false)
    setrenderproperty(drawings.Name, "Visible", false)
    setrenderproperty(drawings.Weapon, "Visible", false)
    
    for i = 1, 15 do
        setrenderproperty(drawings.Skeleton[i].Outline, "Visible", false)
        setrenderproperty(drawings.Skeleton[i].Inline, "Visible", false)
    end
end

local function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not AvidwareESP.Cache[player] then
                AvidwareESP.Cache[player] = CreateDrawings()
            end

            local drawings = AvidwareESP.Cache[player]
            local character = player.Character
            
            if AvidwareESP.Settings.Enabled and character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                local hrp = character.HumanoidRootPart
                
                if humanoid.Health > 0 then
                    local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                    if onScreen then
                        -- Округляем размеры для идеальных пикселей
                        local sizeX = R(2000 / vector.Z)
                        local sizeY = R(3000 / vector.Z)
                        local posX = R(vector.X - sizeX / 2)
                        local posY = R(vector.Y - sizeY / 2)

                        -- 1. BOX ESP (Идеально ровные линии)
                        if AvidwareESP.Settings.ShowBoxes then
                            setrenderproperty(drawings.BoxOuter, "Size", Vector2.new(sizeX + 2, sizeY + 2))
                            setrenderproperty(drawings.BoxOuter, "Position", Vector2.new(posX - 1, posY - 1))
                            setrenderproperty(drawings.BoxOuter, "Color", AvidwareESP.Settings.OutlineColor)
                            setrenderproperty(drawings.BoxOuter, "Thickness", 1)
                            setrenderproperty(drawings.BoxOuter, "Filled", false)
                            setrenderproperty(drawings.BoxOuter, "Visible", true)

                            setrenderproperty(drawings.BoxInner, "Size", Vector2.new(sizeX - 2, sizeY - 2))
                            setrenderproperty(drawings.BoxInner, "Position", Vector2.new(posX + 1, posY + 1))
                            setrenderproperty(drawings.BoxInner, "Color", AvidwareESP.Settings.OutlineColor)
                            setrenderproperty(drawings.BoxInner, "Thickness", 1)
                            setrenderproperty(drawings.BoxInner, "Filled", false)
                            setrenderproperty(drawings.BoxInner, "Visible", true)

                            setrenderproperty(drawings.Box, "Size", Vector2.new(sizeX, sizeY))
                            setrenderproperty(drawings.Box, "Position", Vector2.new(posX, posY))
                            setrenderproperty(drawings.Box, "Color", AvidwareESP.Settings.BoxColor)
                            setrenderproperty(drawings.Box, "Thickness", 1)
                            setrenderproperty(drawings.Box, "Filled", false)
                            setrenderproperty(drawings.Box, "Visible", true)
                        else
                            setrenderproperty(drawings.Box, "Visible", false)
                            setrenderproperty(drawings.BoxOuter, "Visible", false)
                            setrenderproperty(drawings.BoxInner, "Visible", false)
                        end

                        -- 2. SKELETON ESP (Fake Bones для R6 и Real Bones для R15)
                        if AvidwareESP.Settings.ShowSkeletons then
                            local bones = {}
                            
                            if humanoid.RigType == Enum.HumanoidRigType.R15 then
                                -- R15 Кости
                                local function get(n) local p = character:FindFirstChild(n); return p and p.Position or nil end
                                local head, uTorso, lTorso = get("Head"), get("UpperTorso"), get("LowerTorso")
                                local lUArm, lLArm, lHand = get("LeftUpperArm"), get("LeftLowerArm"), get("LeftHand")
                                local rUArm, rLArm, rHand = get("RightUpperArm"), get("RightLowerArm"), get("RightHand")
                                local lULeg, lLLeg, lFoot = get("LeftUpperLeg"), get("LeftLowerLeg"), get("LeftFoot")
                                local rULeg, rLLeg, rFoot = get("RightUpperLeg"), get("RightLowerLeg"), get("RightFoot")

                                bones = {
                                    {head, uTorso}, {uTorso, lTorso},
                                    {uTorso, lUArm}, {lUArm, lLArm}, {lLArm, lHand},
                                    {uTorso, rUArm}, {rUArm, rLArm}, {rLArm, rHand},
                                    {lTorso, lULeg}, {lULeg, lLLeg}, {lLLeg, lFoot},
                                    {lTorso, rULeg}, {rULeg, rLLeg}, {rLLeg, rFoot}
                                }
                            else
                                -- R6 Фейковые кости (избегаем Патрика)
                                local function getCF(n, off) local p = character:FindFirstChild(n); return p and (p.CFrame * off).Position or nil end
                                local head = getCF("Head", CFrame.new(0, 0, 0))
                                local spineTop = getCF("Torso", CFrame.new(0, 0.8, 0))
                                local spineBot = getCF("Torso", CFrame.new(0, -0.8, 0))
                                local lShoulder = getCF("Left Arm", CFrame.new(0, 0.8, 0))
                                local rShoulder = getCF("Right Arm", CFrame.new(0, 0.8, 0))
                                local lHand = getCF("Left Arm", CFrame.new(0, -0.8, 0))
                                local rHand = getCF("Right Arm", CFrame.new(0, -0.8, 0))
                                local lHip = getCF("Left Leg", CFrame.new(0, 0.8, 0))
                                local rHip = getCF("Right Leg", CFrame.new(0, 0.8, 0))
                                local lFoot = getCF("Left Leg", CFrame.new(0, -0.8, 0))
                                local rFoot = getCF("Right Leg", CFrame.new(0, -0.8, 0))

                                bones = {
                                    {head, spineTop}, {spineTop, spineBot},
                                    {spineTop, lShoulder}, {lShoulder, lHand},
                                    {spineTop, rShoulder}, {rShoulder, rHand},
                                    {spineBot, lHip}, {lHip, lFoot},
                                    {spineBot, rHip}, {rHip, rFoot}
                                }
                            end

                            for i = 1, 15 do
                                local bonePair = bones[i]
                                if bonePair and bonePair[1] and bonePair[2] then
                                    local p1, on1 = Camera:WorldToViewportPoint(bonePair[1])
                                    local p2, on2 = Camera:WorldToViewportPoint(bonePair[2])

                                    if p1.Z > 0 and p2.Z > 0 then
                                        local v1 = Vector2.new(R(p1.X), R(p1.Y))
                                        local v2 = Vector2.new(R(p2.X), R(p2.Y))

                                        -- Аутлайн кости
                                        setrenderproperty(drawings.Skeleton[i].Outline, "From", v1)
                                        setrenderproperty(drawings.Skeleton[i].Outline, "To", v2)
                                        setrenderproperty(drawings.Skeleton[i].Outline, "Color", AvidwareESP.Settings.SkeletonOutlineColor)
                                        setrenderproperty(drawings.Skeleton[i].Outline, "Thickness", 2.5)
                                        setrenderproperty(drawings.Skeleton[i].Outline, "Visible", true)

                                        -- Внутренняя кость
                                        setrenderproperty(drawings.Skeleton[i].Inline, "From", v1)
                                        setrenderproperty(drawings.Skeleton[i].Inline, "To", v2)
                                        setrenderproperty(drawings.Skeleton[i].Inline, "Color", AvidwareESP.Settings.SkeletonColor)
                                        setrenderproperty(drawings.Skeleton[i].Inline, "Thickness", 1)
                                        setrenderproperty(drawings.Skeleton[i].Inline, "Visible", true)
                                    else
                                        setrenderproperty(drawings.Skeleton[i].Outline, "Visible", false)
                                        setrenderproperty(drawings.Skeleton[i].Inline, "Visible", false)
                                    end
                                else
                                    setrenderproperty(drawings.Skeleton[i].Outline, "Visible", false)
                                    setrenderproperty(drawings.Skeleton[i].Inline, "Visible", false)
                                end
                            end
                        else
                            for i = 1, 15 do
                                setrenderproperty(drawings.Skeleton[i].Outline, "Visible", false)
                                setrenderproperty(drawings.Skeleton[i].Inline, "Visible", false)
                            end
                        end

                        -- HEALTH BAR / TEXT / NAMES / WEAPONS логика остается прежней, 
                        -- только с использованием округленных R() позиций для идеальной ровности

                        local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                        local healthColor = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), healthPercent)

                        if AvidwareESP.Settings.ShowHealthBar then
                            local side = AvidwareESP.Settings.HealthBarSide
                            local barX, barY, barW, barH
                            local fillX, fillY, fillW, fillH

                            if side == "Left" then
                                barX, barY, barW, barH = posX - 6, posY, 4, sizeY
                                fillX, fillY, fillW, fillH = posX - 5, posY + sizeY - R(sizeY * healthPercent), 2, R(sizeY * healthPercent)
                            elseif side == "Right" then
                                barX, barY, barW, barH = posX + sizeX + 3, posY, 4, sizeY
                                fillX, fillY, fillW, fillH = posX + sizeX + 4, posY + sizeY - R(sizeY * healthPercent), 2, R(sizeY * healthPercent)
                            elseif side == "Bottom" then
                                barX, barY, barW, barH = posX, posY + sizeY + 3, sizeX, 4
                                fillX, fillY, fillW, fillH = posX, posY + sizeY + 4, R(sizeX * healthPercent), 2
                            end

                            setrenderproperty(drawings.HealthBG, "Size", Vector2.new(barW, barH))
                            setrenderproperty(drawings.HealthBG, "Position", Vector2.new(barX, barY))
                            setrenderproperty(drawings.HealthBG, "Color", AvidwareESP.Settings.OutlineColor)
                            setrenderproperty(drawings.HealthBG, "Filled", true)
                            setrenderproperty(drawings.HealthBG, "Visible", true)

                            setrenderproperty(drawings.HealthBar, "Size", Vector2.new(fillW, fillH))
                            setrenderproperty(drawings.HealthBar, "Position", Vector2.new(fillX, fillY))
                            setrenderproperty(drawings.HealthBar, "Color", healthColor)
                            setrenderproperty(drawings.HealthBar, "Filled", true)
                            setrenderproperty(drawings.HealthBar, "Visible", true)
                        else
                            setrenderproperty(drawings.HealthBG, "Visible", false)
                            setrenderproperty(drawings.HealthBar, "Visible", false)
                        end

                        if AvidwareESP.Settings.ShowHealthText then
                            local hSide = AvidwareESP.Settings.HealthTextSide
                            local textPos
                            if hSide == "Left" then
                                textPos = Vector2.new(posX - (AvidwareESP.Settings.ShowHealthBar and 22 or 14), posY + sizeY - R(sizeY * healthPercent) - 7)
                            elseif hSide == "Right" then
                                textPos = Vector2.new(posX + sizeX + (AvidwareESP.Settings.ShowHealthBar and 14 or 6), posY + sizeY - R(sizeY * healthPercent) - 7)
                            elseif hSide == "Bottom" then
                                textPos = Vector2.new(posX + R(sizeX * healthPercent) - 5, posY + sizeY + (AvidwareESP.Settings.ShowHealthBar and 10 or 4))
                            end

                            setrenderproperty(drawings.HealthText, "Text", tostring(math.floor(humanoid.Health)))
                            setrenderproperty(drawings.HealthText, "Position", textPos)
                            setrenderproperty(drawings.HealthText, "Color", AvidwareESP.Settings.HealthTextColor)
                            setrenderproperty(drawings.HealthText, "Size", 14)
                            setrenderproperty(drawings.HealthText, "Outline", true)
                            setrenderproperty(drawings.HealthText, "Center", hSide == "Bottom")
                            setrenderproperty(drawings.HealthText, "Visible", true)
                        else
                            setrenderproperty(drawings.HealthText, "Visible", false)
                        end

                        if AvidwareESP.Settings.ShowNames then
                            setrenderproperty(drawings.Name, "Text", player.Name)
                            setrenderproperty(drawings.Name, "Position", Vector2.new(R(vector.X), posY - 16))
                            setrenderproperty(drawings.Name, "Color", AvidwareESP.Settings.NameColor)
                            setrenderproperty(drawings.Name, "Size", 14)
                            setrenderproperty(drawings.Name, "Center", true)
                            setrenderproperty(drawings.Name, "Outline", true)
                            setrenderproperty(drawings.Name, "Visible", true)
                        else
                            setrenderproperty(drawings.Name, "Visible", false)
                        end

                        if AvidwareESP.Settings.ShowWeapon then
                            local equippedWeapon = "None"
                            local tool = character:FindFirstChildOfClass("Tool")
                            if tool then equippedWeapon = tool.Name end
                            local weaponOffset = (AvidwareESP.Settings.ShowHealthBar and AvidwareESP.Settings.HealthBarSide == "Bottom") and 12 or 4
                            
                            setrenderproperty(drawings.Weapon, "Text", equippedWeapon)
                            setrenderproperty(drawings.Weapon, "Position", Vector2.new(R(vector.X), posY + sizeY + weaponOffset))
                            setrenderproperty(drawings.Weapon, "Color", AvidwareESP.Settings.WeaponColor)
                            setrenderproperty(drawings.Weapon, "Size", 13)
                            setrenderproperty(drawings.Weapon, "Center", true)
                            setrenderproperty(drawings.Weapon, "Outline", true)
                            setrenderproperty(drawings.Weapon, "Visible", true)
                        else
                            setrenderproperty(drawings.Weapon, "Visible", false)
                        end

                    else
                        HideDrawings(drawings)
                    end
                else
                    HideDrawings(drawings)
                end
            else
                if drawings then HideDrawings(drawings) end
            end
        end
    end
end

table.insert(AvidwareESP.Connections, Players.PlayerRemoving:Connect(function(player)
    if AvidwareESP.Cache[player] then
        for _, drawing in pairs(AvidwareESP.Cache[player]) do
            if type(drawing) == "table" then
                -- Это массив скелетов
                for _, bone in pairs(drawing) do
                    bone.Outline:Destroy()
                    bone.Inline:Destroy()
                end
            else
                drawing:Destroy()
            end
        end
        AvidwareESP.Cache[player] = nil
    end
end))

table.insert(AvidwareESP.Connections, RunService.RenderStepped:Connect(UpdateESP))

function AvidwareESP:Unload()
    self.Settings.Enabled = false
    for _, conn in pairs(self.Connections) do conn:Disconnect() end
    self.Connections = {}
    if cleardrawcache then cleardrawcache() end
    self.Cache = {}
end

return AvidwareESP
