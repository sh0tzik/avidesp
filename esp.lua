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

-- Инициализация и скачивание кастомного шрифта
local request = request or http_request or (syn and syn.request) or (http and http.request)
local customFont = Enum.Font.Verdana -- Дефолтный шрифт, если скачивание не удалось

if request and writefile and isfile then
    local fontFileName = "avidware_esp.ttf"
    if not isfile(fontFileName) then
        local success, result = pcall(function()
            return request({
                Url = "https://raw.githubusercontent.com/sh0tzik/avidesp/main/esp.ttf",
                Method = "GET"
            })
        end)
        if success and result.StatusCode == 200 then
            writefile(fontFileName, result.Body)
        end
    end
    
    if isfile(fontFileName) then
        -- Пробуем получить ассет. Если getcustomasset нет, отдаем имя файла напрямую
        customFont = (getcustomasset and getcustomasset(fontFileName)) or fontFileName
    end
end

-- Функция безопасной установки шрифта (чтобы не крашить RenderStepped из-за причуд Drawing API)
local function SafeSetFont(drawingText, font)
    local success = pcall(function()
        setrenderproperty(drawingText, "Font", font)
    end)
    if not success then
        pcall(function()
            setrenderproperty(drawingText, "Font", Enum.Font.Verdana)
        end)
    end
end

-- Функция точного округления пикселей
local function R(num)
    return math.floor(num + 0.5)
end

-- Точный расчет 3D-to-2D Бокса (Подгнан под рост персонажа 5.3 studs)
local function GetBoundingBox(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local size = Vector3.new(4, 5.3, 3.5) 
    local cframe = hrp.CFrame * CFrame.new(0, -0.3, 0) 
    
    local points = {
        (cframe * CFrame.new(-size.X/2, size.Y/2, -size.Z/2)).Position,
        (cframe * CFrame.new(size.X/2, size.Y/2, -size.Z/2)).Position,
        (cframe * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)).Position,
        (cframe * CFrame.new(size.X/2, -size.Y/2, -size.Z/2)).Position,
        (cframe * CFrame.new(-size.X/2, size.Y/2, size.Z/2)).Position,
        (cframe * CFrame.new(size.X/2, size.Y/2, size.Z/2)).Position,
        (cframe * CFrame.new(-size.X/2, -size.Y/2, size.Z/2)).Position,
        (cframe * CFrame.new(size.X/2, -size.Y/2, size.Z/2)).Position,
    }
    
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyOnScreen = false
    
    for _, point in pairs(points) do
        local vector, onScreen = Camera:WorldToViewportPoint(point)
        if vector.Z > 0 then
            if onScreen then anyOnScreen = true end
            if vector.X < minX then minX = vector.X end
            if vector.Y < minY then minY = vector.Y end
            if vector.X > maxX then maxX = vector.X end
            if vector.Y > maxY then maxY = vector.Y end
        end
    end
    
    if not anyOnScreen or minX == math.huge then return nil end
    
    return Vector2.new(R(minX), R(minY)), Vector2.new(R(maxX - minX), R(maxY - minY))
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
    
    setrenderproperty(drawings.Box, "Transparency", 1)
    setrenderproperty(drawings.BoxOuter, "Transparency", 1)
    setrenderproperty(drawings.BoxInner, "Transparency", 1)
    setrenderproperty(drawings.HealthBG, "Transparency", 1)
    setrenderproperty(drawings.HealthBar, "Transparency", 1)
    setrenderproperty(drawings.HealthText, "Transparency", 1)
    setrenderproperty(drawings.Name, "Transparency", 1)
    setrenderproperty(drawings.Weapon, "Transparency", 1)

    for i = 1, 15 do
        drawings.Skeleton[i] = {
            Outline = Drawing.new("Line"),
            Inline = Drawing.new("Line")
        }
        setrenderproperty(drawings.Skeleton[i].Outline, "Transparency", 1)
        setrenderproperty(drawings.Skeleton[i].Inline, "Transparency", 1)
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
                
                if humanoid.Health > 0 then
                    local boxPos, boxSize = GetBoundingBox(character)

                    if boxPos and boxSize then
                        local posX, posY = boxPos.X, boxPos.Y
                        local sizeX, sizeY = boxSize.X, boxSize.Y

                        -- 1. BOX ESP
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

                            setrenderproperty(drawings.Box, "Size", boxSize)
                            setrenderproperty(drawings.Box, "Position", boxPos)
                            setrenderproperty(drawings.Box, "Color", AvidwareESP.Settings.BoxColor)
                            setrenderproperty(drawings.Box, "Thickness", 1)
                            setrenderproperty(drawings.Box, "Filled", false)
                            setrenderproperty(drawings.Box, "Visible", true)
                        else
                            setrenderproperty(drawings.Box, "Visible", false)
                            setrenderproperty(drawings.BoxOuter, "Visible", false)
                            setrenderproperty(drawings.BoxInner, "Visible", false)
                        end

                        -- 2. SKELETON ESP
                        if AvidwareESP.Settings.ShowSkeletons then
                            local bones = {}
                            
                            if humanoid.RigType == Enum.HumanoidRigType.R15 then
                                local function get(n) local p = character:FindFirstChild(n); return p and p.Position or nil end
                                bones = {
                                    {get("Head"), get("UpperTorso")}, {get("UpperTorso"), get("LowerTorso")},
                                    {get("UpperTorso"), get("LeftUpperArm")}, {get("LeftUpperArm"), get("LeftLowerArm")}, {get("LeftLowerArm"), get("LeftHand")},
                                    {get("UpperTorso"), get("RightUpperArm")}, {get("RightUpperArm"), get("RightLowerArm")}, {get("RightLowerArm"), get("RightHand")},
                                    {get("LowerTorso"), get("LeftUpperLeg")}, {get("LeftUpperLeg"), get("LeftLowerLeg")}, {get("LeftLowerLeg"), get("LeftFoot")},
                                    {get("LowerTorso"), get("RightUpperLeg")}, {get("RightUpperLeg"), get("RightLowerLeg")}, {get("RightLowerLeg"), get("RightFoot")}
                                }
                            else
                                local function getCF(n, off) local p = character:FindFirstChild(n); return p and (p.CFrame * off).Position or nil end
                                if character:FindFirstChild("Torso") and character:FindFirstChild("Head") then
                                    bones = {
                                        {getCF("Head", CFrame.new(0, 0, 0)), getCF("Torso", CFrame.new(0, 0.8, 0))},
                                        {getCF("Torso", CFrame.new(0, 0.8, 0)), getCF("Torso", CFrame.new(0, -0.8, 0))},
                                        {getCF("Torso", CFrame.new(0, 0.8, 0)), getCF("Left Arm", CFrame.new(0, 0.8, 0))},
                                        {getCF("Left Arm", CFrame.new(0, 0.8, 0)), getCF("Left Arm", CFrame.new(0, -0.8, 0))},
                                        {getCF("Torso", CFrame.new(0, 0.8, 0)), getCF("Right Arm", CFrame.new(0, 0.8, 0))},
                                        {getCF("Right Arm", CFrame.new(0, 0.8, 0)), getCF("Right Arm", CFrame.new(0, -0.8, 0))},
                                        {getCF("Torso", CFrame.new(0, -0.8, 0)), getCF("Left Leg", CFrame.new(0, 0.8, 0))},
                                        {getCF("Left Leg", CFrame.new(0, 0.8, 0)), getCF("Left Leg", CFrame.new(0, -0.8, 0))},
                                        {getCF("Torso", CFrame.new(0, -0.8, 0)), getCF("Right Leg", CFrame.new(0, 0.8, 0))},
                                        {getCF("Right Leg", CFrame.new(0, 0.8, 0)), getCF("Right Leg", CFrame.new(0, -0.8, 0))}
                                    }
                                end
                            end

                            for i = 1, 15 do
                                local bonePair = bones[i]
                                if bonePair and bonePair[1] and bonePair[2] then
                                    local p1, on1 = Camera:WorldToViewportPoint(bonePair[1])
                                    local p2, on2 = Camera:WorldToViewportPoint(bonePair[2])

                                    if p1.Z > 0 and p2.Z > 0 then
                                        local v1 = Vector2.new(R(p1.X), R(p1.Y))
                                        local v2 = Vector2.new(R(p2.X), R(p2.Y))

                                        setrenderproperty(drawings.Skeleton[i].Outline, "From", v1)
                                        setrenderproperty(drawings.Skeleton[i].Outline, "To", v2)
                                        setrenderproperty(drawings.Skeleton[i].Outline, "Color", AvidwareESP.Settings.SkeletonOutlineColor)
                                        setrenderproperty(drawings.Skeleton[i].Outline, "Thickness", 2.5)
                                        setrenderproperty(drawings.Skeleton[i].Outline, "Visible", true)

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

                        -- 3. HEALTH BAR
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

                        -- 4. HEALTH TEXT
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
                            SafeSetFont(drawings.HealthText, customFont) -- Безопасный кастомный шрифт
                            setrenderproperty(drawings.HealthText, "Outline", true)
                            setrenderproperty(drawings.HealthText, "Center", hSide == "Bottom")
                            setrenderproperty(drawings.HealthText, "Visible", true)
                        else
                            setrenderproperty(drawings.HealthText, "Visible", false)
                        end

                        -- 5. NAMES
                        if AvidwareESP.Settings.ShowNames then
                            local hrp2 = character:FindFirstChild("HumanoidRootPart")
                            local midX = hrp2 and Camera:WorldToViewportPoint(hrp2.Position).X or (posX + sizeX / 2)
                            
                            setrenderproperty(drawings.Name, "Text", player.Name)
                            setrenderproperty(drawings.Name, "Position", Vector2.new(R(midX), posY - 16))
                            setrenderproperty(drawings.Name, "Color", AvidwareESP.Settings.NameColor)
                            setrenderproperty(drawings.Name, "Size", 14)
                            SafeSetFont(drawings.Name, customFont) -- Безопасный кастомный шрифт
                            setrenderproperty(drawings.Name, "Center", true)
                            setrenderproperty(drawings.Name, "Outline", true)
                            setrenderproperty(drawings.Name, "Visible", true)
                        else
                            setrenderproperty(drawings.Name, "Visible", false)
                        end

                        -- 6. WEAPONS
                        if AvidwareESP.Settings.ShowWeapon then
                            local equippedWeapon = "None"
                            local tool = character:FindFirstChildOfClass("Tool")
                            if tool then equippedWeapon = tool.Name end
                            
                            local hrp2 = character:FindFirstChild("HumanoidRootPart")
                            local midX = hrp2 and Camera:WorldToViewportPoint(hrp2.Position).X or (posX + sizeX / 2)
                            local weaponOffset = (AvidwareESP.Settings.ShowHealthBar and AvidwareESP.Settings.HealthBarSide == "Bottom") and 12 or 4
                            
                            setrenderproperty(drawings.Weapon, "Text", equippedWeapon)
                            setrenderproperty(drawings.Weapon, "Position", Vector2.new(R(midX), posY + sizeY + weaponOffset))
                            setrenderproperty(drawings.Weapon, "Color", AvidwareESP.Settings.WeaponColor)
                            setrenderproperty(drawings.Weapon, "Size", 13)
                            SafeSetFont(drawings.Weapon, customFont) -- Безопасный кастомный шрифт
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
