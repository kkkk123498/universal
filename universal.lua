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
    
    -- Новые настройки слайдеров
    BoxThickness = 1,
    BoxTransparency = 1,
    ChamsFillTransparency = 0.5,
    ChamsOutlineTransparency = 0.2,
    TracersThickness = 1,
    TracersTransparency = 1,
    
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
MainFrame.Size = UDim2.new(0, 230, 0, 420)
MainFrame.Image = "rbxassetid://3570695787"
MainFrame.ImageColor3 = Color3.fromRGB(22, 22, 22)
MainFrame.ScaleType = Enum.ScaleType.Slice
MainFrame.SliceCenter = Rect.new(100, 100, 100, 100)
MainFrame.SliceScale = 0.120

local HeaderAccent = Instance.new("Frame")
HeaderAccent.Parent = MainFrame
HeaderAccent.BackgroundColor3 = Color3.fromRGB(255, 30, 60)
HeaderAccent.BorderSizePixel = 0
HeaderAccent.Position = UDim2.new(0, 0, 0, 0)
HeaderAccent.Size = UDim2.new(1, 0, 0, 3)

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1.000
Title.Size = UDim2.new(1, 0, 0, 38)
Title.Font = Enum.Font.GothamBold
Title.Text = "  АНИГИЛЯТОР-3000"
Title.TextColor3 = Color3.fromRGB(255, 40, 70)
Title.TextSize = 13.000
Title.TextXAlignment = Enum.TextXAlignment.Left

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

-- Бесшовный контейнер прокрутки (ScrollingFrame)
local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Parent = MainFrame
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.Position = UDim2.new(0.04, 0, 0.1, 0)
ScrollContainer.Size = UDim2.new(0.92, 0, 0.88, 0)
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 680)
ScrollContainer.ScrollBarThickness = 2
ScrollContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
ScrollContainer.BorderSizePixel = 0
ScrollContainer.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
ScrollContainer.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollContainer
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)

-- Драг интерфейса
local function drag(GuiObj)
	local dragToggle, dragInput, dragStart, startPos
	GuiObj.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragToggle = true; dragStart = input.Position; startPos = GuiObj.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragToggle = false end end)
		end
	end)
	GuiObj.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragToggle then 
            local Delta = input.Position - dragStart
		    GuiObj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
        end
	end)
end
drag(MainFrame)

local function createToggle(name, settingKey)
    local btn = Instance.new("TextButton")
    btn.Parent = ScrollContainer
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1, -4, 0, 30)
    btn.Font = Enum.Font.GothamMedium
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(210, 210, 210)
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn

    local status = Instance.new("Frame")
    status.Parent = btn
    status.BackgroundColor3 = ESP_Settings[settingKey] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(180, 40, 40)
    status.Position = UDim2.new(0.86, 0, 0.28, 0)
    status.Size = UDim2.new(0, 12, 0, 12)
    local scorr = Instance.new("UICorner")
    scorr.CornerRadius = UDim.new(1, 0)
    scorr.Parent = status

    btn.MouseButton1Click:Connect(function()
        ESP_Settings[settingKey] = not ESP_Settings[settingKey]
        status.BackgroundColor3 = ESP_Settings[settingKey] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(180, 40, 40)
    end)
end

-- Плавный слайдер
local function createSlider(name, settingKey, min, max, roundTo)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Parent = ScrollContainer
    sliderFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    sliderFrame.Size = UDim2.new(1, -4, 0, 42)
    sliderFrame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = sliderFrame

    local label = Instance.new("TextLabel")
    label.Parent = sliderFrame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0.05, 0, 0.08, 0)
    label.Size = UDim2.new(0.9, 0, 0.4, 0)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 10
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local container = Instance.new("Frame")
    container.Parent = sliderFrame
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0.05, 0, 0.55, 0)
    container.Size = UDim2.new(0.9, 0, 0.25, 0)

    local bg = Instance.new("Frame")
    bg.Parent = container
    bg.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Parent = container
    fill.BackgroundColor3 = Color3.fromRGB(255, 40, 70)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local function update(input)
        local pos = math.clamp((input.Position.X - container.AbsolutePosition.X) / container.AbsoluteSize.Width, 0, 1)
        local value = min + (max - min) * pos
        if roundTo then
            value = math.round(value / roundTo) * roundTo
        end
        ESP_Settings[settingKey] = value
        fill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = name .. ": " .. string.format("%." .. (roundTo < 1 and "1" or "0") .. "f", value)
    end

    local initialPos = (ESP_Settings[settingKey] - min) / (max - min)
    fill.Size = UDim2.new(initialPos, 0, 1, 0)
    label.Text = name .. ": " .. string.format("%." .. (roundTo < 1 and "1" or "0") .. "f", ESP_Settings[settingKey])

    local sliding = false
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            update(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
end

createToggle("Master Switch", "Enabled")
createToggle("Team Check", "TeamCheck")
createToggle("CModel Mode", "CModelMode")
createToggle("Show Boxes", "Box")
createSlider("Box Thickness", "BoxThickness", 1, 5, 1)
createSlider("Box Transparency", "BoxTransparency", 0.1, 1, 0.1)

createToggle("Name & Distance", "NameInfo")
createToggle("Health Bar", "HealthBar")

createToggle("Chams", "Chams")
createSlider("Chams Fill Trans.", "ChamsFillTransparency", 0, 1, 0.1)
createSlider("Chams Outl. Trans.", "ChamsOutlineTransparency", 0, 1, 0.1)

createToggle("Wall Check", "WallCheck")

createToggle("Tracers", "Tracers")
createSlider("Tracers Thickness", "TracersThickness", 1, 5, 1)
createSlider("Tracers Transparency", "TracersTransparency", 0.1, 1, 0.1)

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
killBtn.Parent = ScrollContainer
killBtn.BackgroundColor3 = Color3.fromRGB(120, 25, 25)
killBtn.BorderSizePixel = 0
killBtn.Size = UDim2.new(1, -4, 0, 32)
killBtn.Font = Enum.Font.GothamBold
killBtn.Text = "  Kill Script"
killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
killBtn.TextSize = 11
killBtn.TextXAlignment = Enum.TextXAlignment.Left

local kCorner = Instance.new("UICorner")
kCorner.CornerRadius = UDim.new(0, 4)
kCorner.Parent = killBtn

killBtn.MouseButton1Click:Connect(killScript)

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

-- Проверка препятствий (WallCheck)
local function checkWall(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then return false end
    
    local targetPart = character.HumanoidRootPart
    local castParts = camera:GetPartsObscuringTarget({localPlayer.Character, character}, {workspace.CurrentCamera})
    
    return #castParts > 0
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
        local rootPos, headPos, legPos
        local hum = character and character:FindFirstChildOfClass("Humanoid") or nil

        if shouldShow then
            if ESP_Settings.CModelMode then
                local cframe, size = character:GetBoundingBox()
                if not cframe or size == Vector3.new() then shouldShow = false else
                    rootPos = cframe.Position
                    local heightY = math.max(size.Y, 2) 
                    headPos = rootPos + Vector3.new(0, heightY / 2, 0)
                    legPos = rootPos - Vector3.new(0, heightY / 2, 0)
                end
            else
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp or not hum then shouldShow = false else
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
            -- Определение видимости за стеной
            local isBehindWall = false
            if ESP_Settings.WallCheck then
                isBehindWall = checkWall(character)
            end

            -- Логика цветов на базе WallCheck
            local finalBoxColor = Color3.fromRGB(255, 255, 255)
            local finalChamsColor = Color3.fromRGB(255, 50, 50)
            
            if ESP_Settings.WallCheck then
                if isBehindWall then
                    finalBoxColor = Color3.fromRGB(255, 255, 255) -- Стандартный
                    finalChamsColor = Color3.fromRGB(255, 50, 50) -- Стандартный
                else
                    finalBoxColor = Color3.fromRGB(255, 0, 0)   -- Красный (открыт)
                    finalChamsColor = Color3.fromRGB(0, 120, 255) -- Синий (открыт)
                end
            end

            -- Общие настройки прозрачностей и толщины
            data.Box.Transparency = data.FadeAlpha * ESP_Settings.BoxTransparency
            data.Box.Thickness = ESP_Settings.BoxThickness
            data.Box.Color = finalBoxColor

            data.NameText.Transparency = data.FadeAlpha
            data.HealthBar.Transparency = data.FadeAlpha
            data.HealthBarBG.Transparency = data.FadeAlpha

            if ESP_Settings.Chams then
                data.Chams.Adornee = character
                data.Chams.FillColor = finalChamsColor
                data.Chams.FillTransparency = 1 - ((1 - ESP_Settings.ChamsFillTransparency) * data.FadeAlpha)
                data.Chams.OutlineTransparency = 1 - ((1 - ESP_Settings.ChamsOutlineTransparency) * data.FadeAlpha)
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

            -- Логика Трейсеров (Tracers)
            if ESP_Settings.Tracers then
                data.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                data.Tracer.To = Vector2.new(vector.X, vector.Y + height / 2)
                data.Tracer.Thickness = ESP_Settings.TracersThickness
                data.Tracer.Transparency = data.FadeAlpha * ESP_Settings.TracersTransparency
                data.Tracer.Color = finalBoxColor
                data.Tracer.Visible = true
            else
                data.Tracer.Visible = false
            end
        end
    end
end)
table.insert(_G.PlayerESP_Connections, renderConn)
