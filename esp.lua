local AvidwareESP = {
    Settings = {
        Enabled = true,
        
        -- Боксы и аутлайны
        ShowBoxes = true,
        BoxColor = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),
        
        -- Полоска здоровья
        ShowHealthBar = true,
        HealthBarSide = "Left", -- "Left" (слева), "Right" (справа), "Bottom" (снизу)
        
        -- Текст здоровья (цифры)
        ShowHealthText = true,
        HealthTextSide = "Left", -- "Left", "Right", "Bottom"
        HealthTextColor = Color3.fromRGB(255, 255, 255),
        
        -- Никнейм
        ShowNames = true,
        NameColor = Color3.fromRGB(255, 255, 255),
        
        -- Оружие
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

-- Создаем пулл объектов отрисовки для одного игрока
local function CreateDrawings()
    return {
        Box = Drawing.new("Square"),
        BoxOuter = Drawing.new("Square"),
        BoxInner = Drawing.new("Square"),
        
        HealthBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        HealthText = Drawing.new("Text"),
        
        Name = Drawing.new("Text"),
        Weapon = Drawing.new("Text")
    }
end

-- Функция для скрытия всех объектов игрока
local function HideDrawings(drawings)
    setrenderproperty(drawings.Box, "Visible", false)
    setrenderproperty(drawings.BoxOuter, "Visible", false)
    setrenderproperty(drawings.BoxInner, "Visible", false)
    setrenderproperty(drawings.HealthBG, "Visible", false)
    setrenderproperty(drawings.HealthBar, "Visible", false)
    setrenderproperty(drawings.HealthText, "Visible", false)
    setrenderproperty(drawings.Name, "Visible", false)
    setrenderproperty(drawings.Weapon, "Visible", false)
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
                        -- Рассчитываем динамический размер бокса в зависимости от дистанции
                        local sizeX = 2000 / vector.Z
                        local sizeY = 3000 / vector.Z
                        local posX = vector.X - sizeX / 2
                        local posY = vector.Y - sizeY / 2

                        -- 1. ОТРИСОВКА BOX + OUTLINES
                        if AvidwareESP.Settings.ShowBoxes then
                            -- Внешний аутлайн (+1 пиксель наружу)
                            setrenderproperty(drawings.BoxOuter, "Size", Vector2.new(sizeX + 2, sizeY + 2))
                            setrenderproperty(drawings.BoxOuter, "Position", Vector2.new(posX - 1, posY - 1))
                            setrenderproperty(drawings.BoxOuter, "Color", AvidwareESP.Settings.OutlineColor)
                            setrenderproperty(drawings.BoxOuter, "Thickness", 1)
                            setrenderproperty(drawings.BoxOuter, "Filled", false)
                            setrenderproperty(drawings.BoxOuter, "Visible", true)

                            -- Внутренний аутлайн (-1 пиксель внутрь)
                            setrenderproperty(drawings.BoxInner, "Size", Vector2.new(sizeX - 2, sizeY - 2))
                            setrenderproperty(drawings.BoxInner, "Position", Vector2.new(posX + 1, posY + 1))
                            setrenderproperty(drawings.BoxInner, "Color", AvidwareESP.Settings.OutlineColor)
                            setrenderproperty(drawings.BoxInner, "Thickness", 1)
                            setrenderproperty(drawings.BoxInner, "Filled", false)
                            setrenderproperty(drawings.BoxInner, "Visible", true)

                            -- Основной бокс
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

                        -- Расчет процентов здоровья
                        local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                        local healthColor = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), healthPercent) -- Плавный переход от красного к зеленому

                        -- 2. ОТРИСОВКА HEALTH BAR
                        if AvidwareESP.Settings.ShowHealthBar then
                            local side = AvidwareESP.Settings.HealthBarSide
                            local barX, barY, barW, barH
                            local fillX, fillY, fillW, fillH

                            if side == "Left" then
                                barX, barY, barW, barH = posX - 6, posY, 4, sizeY
                                fillX, fillY, fillW, fillH = posX - 5, posY + sizeY - (sizeY * healthPercent), 2, (sizeY * healthPercent)
                            elseif side == "Right" then
                                barX, barY, barW, barH = posX + sizeX + 3, posY, 4, sizeY
                                fillX, fillY, fillW, fillH = posX + sizeX + 4, posY + sizeY - (sizeY * healthPercent), 2, (sizeY * healthPercent)
                            elseif side == "Bottom" then
                                barX, barY, barW, barH = posX, posY + sizeY + 3, sizeX, 4
                                fillX, fillY, fillW, fillH = posX, posY + sizeY + 4, (sizeX * healthPercent), 2
                            end

                            -- Задний фон полоски хп (черный аутлайн)
                            setrenderproperty(drawings.HealthBG, "Size", Vector2.new(barW, barH))
                            setrenderproperty(drawings.HealthBG, "Position", Vector2.new(barX, barY))
                            setrenderproperty(drawings.HealthBG, "Color", AvidwareESP.Settings.OutlineColor)
                            setrenderproperty(drawings.HealthBG, "Filled", true)
                            setrenderproperty(drawings.HealthBG, "Visible", true)

                            -- Сама полоска хп
                            setrenderproperty(drawings.HealthBar, "Size", Vector2.new(fillW, fillH))
                            setrenderproperty(drawings.HealthBar, "Position", Vector2.new(fillX, fillY))
                            setrenderproperty(drawings.HealthBar, "Color", healthColor)
                            setrenderproperty(drawings.HealthBar, "Filled", true)
                            setrenderproperty(drawings.HealthBar, "Visible", true)
                        else
                            setrenderproperty(drawings.HealthBG, "Visible", false)
                            setrenderproperty(drawings.HealthBar, "Visible", false)
                        end

                        -- 3. ОТРИСОВКА HEALTH TEXT
                        if AvidwareESP.Settings.ShowHealthText then
                            local hSide = AvidwareESP.Settings.HealthTextSide
                            local textPos
                            
                            if hSide == "Left" then
                                textPos = Vector2.new(posX - (AvidwareESP.Settings.ShowHealthBar and 22 or 14), posY + sizeY - (sizeY * healthPercent) - 7)
                            elseif hSide == "Right" then
                                textPos = Vector2.new(posX + sizeX + (AvidwareESP.Settings.ShowHealthBar and 14 or 6), posY + sizeY - (sizeY * healthPercent) - 7)
                            elseif hSide == "Bottom" then
                                textPos = Vector2.new(posX + (sizeX * healthPercent) - 5, posY + sizeY + (AvidwareESP.Settings.ShowHealthBar and 10 or 4))
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

                        -- 4. ОТРИСОВКА NAME TEXT
                        if AvidwareESP.Settings.ShowNames then
                            setrenderproperty(drawings.Name, "Text", player.Name)
                            setrenderproperty(drawings.Name, "Position", Vector2.new(vector.X, posY - 16))
                            setrenderproperty(drawings.Name, "Color", AvidwareESP.Settings.NameColor)
                            setrenderproperty(drawings.Name, "Size", 14)
                            setrenderproperty(drawings.Name, "Center", true)
                            setrenderproperty(drawings.Name, "Outline", true)
                            setrenderproperty(drawings.Name, "Visible", true)
                        else
                            setrenderproperty(drawings.Name, "Visible", false)
                        end

                        -- 5. ОТРИСОВКА WEAPON TEXT
                        if AvidwareESP.Settings.ShowWeapon then
                            local equippedWeapon = "None"
                            local tool = character:FindFirstChildOfClass("Tool")
                            if tool then
                                equippedWeapon = tool.Name
                            end

                            -- Смещаем оружие чуть ниже, если под боксом уже находится хп-бар
                            local weaponOffset = (AvidwareESP.Settings.ShowHealthBar and AvidwareESP.Settings.HealthBarSide == "Bottom") and 12 or 4
                            
                            setrenderproperty(drawings.Weapon, "Text", equippedWeapon)
                            setrenderproperty(drawings.Weapon, "Position", Vector2.new(vector.X, posY + sizeY + weaponOffset))
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

-- Очистка при выходе игрока
table.insert(AvidwareESP.Connections, Players.PlayerRemoving:Connect(function(player)
    if AvidwareESP.Cache[player] then
        for _, drawing in pairs(AvidwareESP.Cache[player]) do
            drawing:Destroy()
        end
        AvidwareESP.Cache[player] = nil
    end
end))

-- Запуск рендера
table.insert(AvidwareESP.Connections, RunService.RenderStepped:Connect(UpdateESP))

function AvidwareESP:Unload()
    self.Settings.Enabled = false
    for _, conn in pairs(self.Connections) do
        conn:Disconnect()
    end
    self.Connections = {}
    
    if cleardrawcache then
        cleardrawcache()
    else
        for _, pDrawings in pairs(self.Cache) do
            for _, drawing in pairs(pDrawings) do
                drawing:Destroy()
            end
        end
    end
    self.Cache = {}
end

return AvidwareESP
