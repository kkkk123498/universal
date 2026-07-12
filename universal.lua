-- Очистка от прошлых запусков скрипта
pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("PlayerESP_UI") then
        game:GetService("CoreGui").PlayerESP_UI:Destroy()
    end
    if _G.PlayerESP_Connections then
        for _, conn in pairs(_G.PlayerESP_Connections) do
            conn:Disconnect()
        end
    end
    if _G.PlayerESP_Drawings then
        for _, draw in ipairs(_G.PlayerESP_Drawings) do
            draw:Remove()
        end
    end
    if _G.PlayerESP_Highlights then
        for _, hl in ipairs(_G.PlayerESP_Highlights) do
            hl:Destroy()
        end
    end
end)

_G.PlayerESP_Connections = {}
_G.PlayerESP_Drawings = {}
_G.PlayerESP_Highlights = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera or workspace.Camera
local localPlayer = Players.LocalPlayer

local ESP_Settings = {
    Enabled = true,
    TeamCheck = false,
    CModelMode = false,
    Box = true,
    NameInfo = true,
    HealthBar = true,
    Chams = false,
    WallCheck = false,
    Tracers = false,
    TracerThickness = 1,
    TracerTransparency = 1,
    ChamsFillAlpha = 0.5,
    ChamsOutlineAlpha = 0.2,
    FadeSpeed = 2.5
}

local ESP_List = {}

-- === ИНТЕРФЕЙС ===
local ESP_GUI = Instance.new("ScreenGui")
ESP_GUI.Name = "PlayerESP_UI"
if syn and syn.protect_gui then
	syn.protect_gui(ESP_GUI)
elseif gethui then
	ESP_GUI.Parent = gethui()
else
	ESP_GUI.Parent = game:GetService("CoreGui")
end
ESP_GUI.ResetOnSpawn = false

local MainFrame = Instance.new("ImageLabel")
MainFrame.Parent = ESP_GUI
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 1.000
MainFrame.Position = UDim2.new(0.6, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 210, 0, 420) -- Немного увеличил высоту для большего пространства
MainFrame.Image = "rbxassetid://3570695787"
MainFrame.ImageColor3 = Color3.fromRGB(22, 22, 22)
MainFrame.ScaleType = Enum.ScaleType.Slice
MainFrame.SliceCenter = Rect.new(100, 100, 100, 100)
MainFrame.SliceScale = 0.120
MainFrame.Active = true

-- Тень или акцентная шапка
local HeaderAccent = Instance.new("Frame")
HeaderAccent.Parent = MainFrame
HeaderAccent.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
HeaderAccent.BorderSizePixel = 0
HeaderAccent.Position = UDim2.new(0, 0, 0, 0)
HeaderAccent.Size = UDim2.new(1, 0, 0, 3)

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1.000
Title.Size = UDim2.new(1, 0, 0, 38)
Title.Font = Enum.Font.GothamBold
Title.Text = "  АНИГИЛЯТОР-3000"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.TextSize = 13.000
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Индикатор хоткея в заголовке
local HintLabel = Instance.new("TextLabel")
HintLabel.Parent = MainFrame
HintLabel.BackgroundTransparency = 1.000
HintLabel.Position = UDim2.new(-0.05, 0, 0, 0)
HintLabel.Size = UDim2.new(1, 0, 0, 38)
HintLabel.Font = Enum.Font.Gotham
HintLabel.Text = "[RightAlt]"
HintLabel.TextColor3 = Color3.fromRGB(90, 90, 90)
HintLabel.TextSize = 10.000
HintLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Скроллинг фрейм для элементов
local Container = Instance.new("ScrollingFrame")
Container.Parent = MainFrame
Container.BackgroundTransparency = 1
Container.Position = UDim2.new(0.05, 0, 0.12, 0)
Container.Size = UDim2.new(0.9, 0, 0.84, 0)
Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Container.ScrollBarThickness = 2
Container.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
Container.BorderSizePixel = 0

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)

-- Драг интерфейса
local function drag(GuiObj)
	local dragToggle, dragInput, dragStart, startPos
	local conn1 = GuiObj.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragToggle = true; dragStart = input.Position; startPos = GuiObj.Position
			local conn2 
            conn2 = input.Changed:Connect(function() 
                if input.UserInputState == Enum.UserInputState.End then 
                    dragToggle = false 
                    conn2:Disconnect()
                end 
            end)
		end
	end)
	local conn3 = GuiObj.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)
	local conn4 = UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragToggle then 
            local Delta = input.Position - dragStart
		    GuiObj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
        end
	end)
    table.insert(_G.PlayerESP_Connections, conn1)
    table.insert(_G.PlayerESP_Connections, conn3)
    table.insert(_G.PlayerESP_Connections, conn4)
end
drag(MainFrame)

local function createToggle(name, settingKey)
    local btn = Instance.new("TextButton")
    btn.Parent = Container
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1, -5, 0, 31)
    btn.Font = Enum.Font.GothamMedium
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(210, 210, 210)
    btn.TextSize = 11.5
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local status = Instance.new("Frame")
    status.Parent = btn
    status.BackgroundColor3 = ESP_Settings[settingKey] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(180, 40, 40)
    status.Position = UDim2.new(0.84, 0, 0.28, 0)
    status.Size = UDim2.new(0, 13, 0, 13)
    local scorr = Instance.new("UICorner")
    scorr.CornerRadius = UDim.new(1, 0)
    scorr.Parent = status

    local conn = btn.MouseButton1Click:Connect(function()
        ESP_Settings[settingKey] = not ESP_Settings[settingKey]
        status.BackgroundColor3 = ESP_Settings[settingKey] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(180, 40, 40)
    end)
    table.insert(_G.PlayerESP_Connections, conn)
end

local function createSlider(name, settingKey, min, max, isFloat)
    local frame = Instance.new("Frame")
    frame.Parent = Container
    frame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, -5, 0, 42)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Size = UDim2.new(1, -20, 0, 22)
    title.Font = Enum.Font.GothamMedium
    title.Text = name .. ": " .. tostring(ESP_Settings[settingKey])
    title.TextColor3 = Color3.fromRGB(210, 210, 210)
    title.TextSize = 11.5
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    local sliderBg = Instance.new("TextButton")
    sliderBg.Parent = frame
    sliderBg.Text = ""
    sliderBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    sliderBg.Position = UDim2.new(0, 10, 0, 24)
    sliderBg.Size = UDim2.new(1, -20, 0, 8)
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = sliderBg
    
    local fill = Instance.new("Frame")
    fill.Parent = sliderBg
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    fill.Size = UDim2.new(math.clamp((ESP_Settings[settingKey] - min) / (max - min), 0, 1), 0, 1, 0)
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    local dragging = false
    
    local conn1 = sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    
    local conn2 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    local conn3 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local sliderPos = sliderBg.AbsolutePosition.X
            local sliderSize = sliderBg.AbsoluteSize.X
            local mousePos = input.Position.X
            local pct = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
            
            local value = min + (max - min) * pct
            if not isFloat then 
                value = math.floor(value) 
            else 
                value = math.floor(value * 100) / 100 
            end
            
            ESP_Settings[settingKey] = value
            title.Text = name .. ": " .. tostring(value)
            fill.Size = UDim2.new(pct, 0, 1, 0)
        end
    end)
    
    table.insert(_G.PlayerESP_Connections, conn1)
    table.insert(_G.PlayerESP_Connections, conn2)
    table.insert(_G.PlayerESP_Connections, conn3)
end

-- Добавляем элементы в меню
createToggle("Master Switch", "Enabled")
createToggle("Team Check", "TeamCheck")
createToggle("CModel Mode", "CModelMode")
createToggle("Wall Check", "WallCheck")
createToggle("Show Boxes", "Box")
createToggle("Name & Distance", "NameInfo")
createToggle("Health Bar", "HealthBar")
createToggle("Chams", "Chams")
createSlider("Chams Fill %", "ChamsFillAlpha", 0, 1, true)
createSlider("Chams Outline %", "ChamsOutlineAlpha", 0, 1, true)
createToggle("Tracers", "Tracers")
createSlider("Tracer Thickness", "TracerThickness", 1, 5, false)
createSlider("Tracer Transparency", "TracerTransparency", 0, 1, true)

-- === ФУНКЦИЯ ПОЛНОГО ОТКЛЮЧЕНИЯ (Kill Script) ===
local function killScript()
    ESP_Settings.Enabled = false
    
    if _G.PlayerESP_Drawings then
        for _, draw in ipairs(_G.PlayerESP_Drawings) do
            pcall(function() draw:Remove() end)
        end
    end
    
    if _G.PlayerESP_Highlights then
        for _, hl in ipairs(_G.PlayerESP_Highlights) do
            pcall(function() hl:Destroy() end)
        end
    end
    
    if _G.PlayerESP_Connections then
        for _, conn in pairs(_G.PlayerESP_Connections) do
            pcall(function() conn:Disconnect() end)
        end
    end
    
    if ESP_GUI then
        ESP_GUI:Destroy()
    end
end

local killBtn = Instance.new("TextButton")
killBtn.Parent = Container
killBtn.BackgroundColor3 = Color3.fromRGB(120, 25, 25)
killBtn.BorderSizePixel = 0
killBtn.Size = UDim2.new(1, -5, 0, 33)
killBtn.Font = Enum.Font.GothamBold
killBtn.Text = "  Kill Script"
killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
killBtn.TextSize = 12.000
killBtn.TextXAlignment = Enum.TextXAlignment.Left

local kCorner = Instance.new("UICorner")
kCorner.CornerRadius = UDim.new(0, 6)
kCorner.Parent = killBtn

local killConn = killBtn.MouseButton1Click:Connect(function()
    killScript()
end)
table.insert(_G.PlayerESP_Connections, killConn)

-- Пустое место в конце скролла
local Spacer = Instance.new("Frame")
Spacer.Parent = Container
Spacer.BackgroundTransparency = 1
Spacer.Size = UDim2.new(1, 0, 0, 5)

local uiToggleConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        MainFrame.Visible = not MainFrame.Visible
    end
end)
table.insert(_G.PlayerESP_Connections, uiToggleConn)

-- === ЛОГИКА ESP ===
local function hideESP(data)
    data.Box.Visible = false
    data.NameText.Visible = false
    data.HealthBar.Visible = false
    data.HealthBarBG.Visible = false
    data.Tracer.Visible = false
    if data.Chams then data.Chams.Enabled = false end
end

local function isTeammateCheck(player, character)
    if player == localPlayer then return true end
    if localPlayer.Team ~= nil and player.Team == localPlayer.Team then return true end
    if localPlayer.TeamColor ~= nil and player.TeamColor == localPlayer.TeamColor and not player.Neutral then return true end
    
    if character then
        for _, attrName in ipairs({"Team", "Clan", "Faction", "Group", "Alliance"}) do
            local charAttr = character:GetAttribute(attrName)
            local localAttr = localPlayer.Character and localPlayer.Character:GetAttribute(attrName)
            if charAttr and localAttr and charAttr == localAttr then return true end
        end
    end
    
    for _, attrName in ipairs({"Team", "Clan", "Faction"}) do
        local pAttr = player:GetAttribute(attrName)
        local lAttr = localPlayer:GetAttribute(attrName)
        if pAttr and lAttr and pAttr == lAttr then return true end
    end
    
    return false
end

-- Функция проверки видимости (WallCheck)
local function checkVisibility(targetPart, targetCharacter)
    if not targetPart or not targetCharacter then return false end
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {camera, localPlayer.Character, targetCharacter}
    params.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, params)
    return result == nil -- Если ничего не пересекли, значит видим
end

local function createESP(player)
    if player == localPlayer then return nil end

    local data = {
        Player = player,
        FadeAlpha = 0,
        Box = Drawing.new("Square"),
        NameText = Drawing.new("Text"),
        HealthBarBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Chams = Instance.new("Highlight")
    }

    data.Box.Visible = false; data.Box.Color = Color3.fromRGB(255, 255, 255); data.Box.Thickness = 1; data.Box.Transparency = 0; data.Box.Filled = false
    table.insert(_G.PlayerESP_Drawings, data.Box)

    data.NameText.Visible = false; data.NameText.Color = Color3.fromRGB(255, 255, 255); data.NameText.Center = true; data.NameText.Outline = true; data.NameText.Size = 13; data.NameText.Font = 2; data.NameText.Transparency = 0
    table.insert(_G.PlayerESP_Drawings, data.NameText)

    data.HealthBarBG.Visible = false; data.HealthBarBG.Color = Color3.fromRGB(0, 0, 0); data.HealthBarBG.Thickness = 1; data.HealthBarBG.Filled = true; data.HealthBarBG.Transparency = 0
    table.insert(_G.PlayerESP_Drawings, data.HealthBarBG)

    data.HealthBar.Visible = false; data.HealthBar.Color = Color3.fromRGB(0, 255, 0); data.HealthBar.Thickness = 1; data.HealthBar.Filled = true; data.HealthBar.Transparency = 0
    table.insert(_G.PlayerESP_Drawings, data.HealthBar)

    data.Tracer.Visible = false; data.Tracer.Color = Color3.fromRGB(255, 255, 255); data.Tracer.Thickness = 1; data.Tracer.Transparency = 0
    table.insert(_G.PlayerESP_Drawings, data.Tracer)

    data.Chams.Name = "Chams_" .. player.Name
    data.Chams.FillColor = Color3.fromRGB(255, 50, 50); data.Chams.OutlineColor = Color3.fromRGB(255, 255, 255)
    data.Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    data.Chams.Enabled = false
    data.Chams.Parent = ESP_GUI
    table.insert(_G.PlayerESP_Highlights, data.Chams)

    return data
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        ESP_List[player] = createESP(player)
    end
end

local addedConn = Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        ESP_List[player] = createESP(player)
    end
end)
table.insert(_G.PlayerESP_Connections, addedConn)

local removedConn = Players.PlayerRemoving:Connect(function(player)
    if ESP_List[player] then
        hideESP(ESP_List[player])
        ESP_List[player] = nil
    end
end)
table.insert(_G.PlayerESP_Connections, removedConn)

local function getPlayersArray()
    local arr = {}
    for p, data in pairs(ESP_List) do
        if p and p.Parent then
            table.insert(arr, p)
        else
            ESP_List[p] = nil
        end
    end
    return arr
end

local currentIndex = 1
local lastCheckTick = tick()
local checkInterval = 0.5

local renderConn = RunService.RenderStepped:Connect(function(deltaTime)
    local currentTime = tick()
    local playersArr = getPlayersArray()
    
    if currentTime - lastCheckTick >= (checkInterval / math.max(#playersArr, 1)) then
        lastCheckTick = currentTime
        if #playersArr > 0 then
            currentIndex = (currentIndex % #playersArr) + 1
            local targetPlayer = playersArr[currentIndex]
            local data = ESP_List[targetPlayer]
            if targetPlayer and data then
                data.IsTeammate = isTeammateCheck(targetPlayer, targetPlayer.Character)
            end
        end
    end

    for player, data in pairs(ESP_List) do
        local character = player.Character
        local isTeammate = data.IsTeammate or false

        local shouldShow = ESP_Settings.Enabled and character and not (ESP_Settings.TeamCheck and isTeammate)
        local rootPos, headPos, legPos, targetPart
        local hum = character and character:FindFirstChildOfClass("Humanoid") or nil

        if shouldShow then
            if ESP_Settings.CModelMode then
                local cframe, size = character:GetBoundingBox()
                if not cframe or size == Vector3.new() then shouldShow = false else
                    rootPos = cframe.Position
                    targetPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
                    local heightY = math.max(size.Y, 2) 
                    headPos = rootPos + Vector3.new(0, heightY / 2, 0)
                    legPos = rootPos - Vector3.new(0, heightY / 2, 0)
                end
            else
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp or not hum then shouldShow = false else
                    targetPart = hrp
                    rootPos = hrp.Position
                    local head = character:FindFirstChild("Head")
                    headPos = head and head.Position or (rootPos + Vector3.new(0, 2, 0))
                    legPos = rootPos - Vector3.new(0, 3, 0)
                end
            end
        end

        if hum and hum.Health <= 0 then
            shouldShow = false
        end

        local vector, onScreen = nil, false
        if shouldShow and rootPos then
            vector, onScreen = camera:WorldToViewportPoint(rootPos)
            if not onScreen then shouldShow = false end
        end

        if shouldShow then
            data.FadeAlpha = math.clamp(data.FadeAlpha + (deltaTime * ESP_Settings.FadeSpeed), 0, 1)
        else
            data.FadeAlpha = 0 
            hideESP(data)
            continue
        end

        if data.FadeAlpha > 0.01 then
            
            -- Проверка WallCheck и назначение цветов
            local isVisible = false
            if ESP_Settings.WallCheck and targetPart then
                isVisible = checkVisibility(targetPart, character)
            end

            local activeBoxColor = Color3.fromRGB(255, 255, 255)
            local activeChamsColor = Color3.fromRGB(255, 50, 50)

            if ESP_Settings.WallCheck then
                if isVisible then
                    activeBoxColor = Color3.fromRGB(255, 50, 50) -- Красный Box, если видим
                    activeChamsColor = Color3.fromRGB(50, 100, 255) -- Синий Chams, если видим
                end
            end

            data.Box.Color = activeBoxColor
            data.Box.Transparency = data.FadeAlpha
            data.NameText.Transparency = data.FadeAlpha
            data.HealthBar.Transparency = data.FadeAlpha
            data.HealthBarBG.Transparency = data.FadeAlpha

            if ESP_Settings.Chams then
                data.Chams.Adornee = character
                data.Chams.FillColor = activeChamsColor
                data.Chams.FillTransparency = ESP_Settings.ChamsFillAlpha + ((1 - ESP_Settings.ChamsFillAlpha) * (1 - data.FadeAlpha))
                data.Chams.OutlineTransparency = ESP_Settings.ChamsOutlineAlpha + ((1 - ESP_Settings.ChamsOutlineAlpha) * (1 - data.FadeAlpha))
                data.Chams.Enabled = true
            else
                data.Chams.Adornee = nil
                data.Chams.Enabled = false
            end

            local headScreen = camera:WorldToViewportPoint(headPos)
            local legScreen = camera:WorldToViewportPoint(legPos)

            local height = math.abs(headScreen.Y - legScreen.Y)
            local width = height / 2

            if ESP_Settings.Box then
                data.Box.Size = Vector2.new(width, height)
                data.Box.Position = Vector2.new(vector.X - width / 2, vector.Y - height / 2)
                data.Box.Visible = true
            else
                data.Box.Visible = false
            end

            if ESP_Settings.NameInfo then
                local dist = math.floor((camera.CFrame.Position - rootPos).Magnitude)
                data.NameText.Text = player.Name .. " [" .. dist .. "]"
                data.NameText.Position = Vector2.new(vector.X, vector.Y - height / 2 - 15)
                data.NameText.Visible = true
            else
                data.NameText.Visible = false
            end

            if ESP_Settings.HealthBar and hum then
                local healthPct = hum.Health / hum.MaxHealth
                if healthPct ~= healthPct or healthPct == math.huge then healthPct = 1 end 
                healthPct = math.clamp(healthPct, 0, 1)

                data.HealthBarBG.Size = Vector2.new(2, height)
                data.HealthBarBG.Position = Vector2.new(vector.X - width / 2 - 5, vector.Y - height / 2)

                data.HealthBar.Size = Vector2.new(2, height * healthPct)
                data.HealthBar.Position = Vector2.new(vector.X - width / 2 - 5, (vector.Y - height / 2) + (height - (height * healthPct)))
                data.HealthBar.Color = Color3.fromHSV(healthPct * 0.3, 1, 1)

                data.HealthBarBG.Visible = true
                data.HealthBar.Visible = true
            else
                data.HealthBarBG.Visible = false
                data.HealthBar.Visible = false
            end

            if ESP_Settings.Tracers and onScreen then
                data.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                data.Tracer.To = Vector2.new(vector.X, legScreen.Y)
                data.Tracer.Thickness = ESP_Settings.TracerThickness
                data.Tracer.Transparency = (1 - ESP_Settings.TracerTransparency) * data.FadeAlpha
                data.Tracer.Color = activeBoxColor
                data.Tracer.Visible = true
            else
                data.Tracer.Visible = false
            end
        end
    end
end)
table.insert(_G.PlayerESP_Connections, renderConn)
