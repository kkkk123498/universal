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
local TweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera or workspace.Camera
local localPlayer = Players.LocalPlayer

local ESP_Settings = {
    Enabled = true,
    TeamCheck = false,
    CModelMode = false,
    Box = true,
    WallCheck = true,
    Tracers = true,
    TracerThickness = 1,
    TracerTransparency = 0.8,
    NameInfo = true,
    HealthBar = true,
    Chams = true,
    ChamsTransparency = 0.5,
    FadeSpeed = 3.0
}

local ESP_List = {}

-- === УЛУЧШЕННЫЙ ИНТЕРФЕЙС ===
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

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ESP_GUI
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.Position = UDim2.new(0.5, -125, 0.2, 0)
MainFrame.Size = UDim2.new(0, 250, 0, 500)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = Color3.fromRGB(55, 55, 70)
MainStroke.Thickness = 1.5

local Header = Instance.new("Frame")
Header.Parent = MainFrame
Header.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BorderSizePixel = 0

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Parent = Header
HeaderFix.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
HeaderFix.Position = UDim2.new(0, 0, 0.5, 0)
HeaderFix.Size = UDim2.new(1, 0, 0.5, 0)
HeaderFix.BorderSizePixel = 0

local Title = Instance.new("TextLabel")
Title.Parent = Header
Title.BackgroundTransparency = 1.000
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "NEXUS ESP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14.000
Title.TextXAlignment = Enum.TextXAlignment.Left

local HintLabel = Instance.new("TextLabel")
HintLabel.Parent = Header
HintLabel.BackgroundTransparency = 1.000
HintLabel.Position = UDim2.new(0.4, 0, 0, 0)
HintLabel.Size = UDim2.new(0.53, 0, 1, 0)
HintLabel.Font = Enum.Font.GothamMedium
HintLabel.Text = "[ RightAlt ]"
HintLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
HintLabel.TextSize = 11.000
HintLabel.TextXAlignment = Enum.TextXAlignment.Right

local Container = Instance.new("ScrollingFrame")
Container.Parent = MainFrame
Container.BackgroundTransparency = 1.000
Container.Position = UDim2.new(0, 12, 0, 55)
Container.Size = UDim2.new(1, -24, 1, -65)
Container.CanvasSize = UDim2.new(0, 0, 0, 550)
Container.ScrollBarThickness = 2
Container.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
Container.BorderSizePixel = 0

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

-- Функция перетаскивания (Drag)
local function drag(GuiObj, DragTarget)
	local dragToggle, dragInput, dragStart, startPos
	GuiObj.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragToggle = true; dragStart = input.Position; startPos = DragTarget.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragToggle = false end end)
		end
	end)
	GuiObj.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragToggle then 
            local Delta = input.Position - dragStart
		    DragTarget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
        end
	end)
end
drag(Header, MainFrame)

local function createToggle(name, settingKey)
    local btn = Instance.new("TextButton")
    btn.Parent = Container
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.Font = Enum.Font.GothamMedium
    btn.Text = "    " .. name
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.TextSize = 12.0
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local statusBG = Instance.new("Frame")
    statusBG.Parent = btn
    statusBG.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    statusBG.Position = UDim2.new(1, -34, 0.5, -8)
    statusBG.Size = UDim2.new(0, 24, 0, 16)
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = statusBG

    local status = Instance.new("Frame")
    status.Parent = statusBG
    status.BackgroundColor3 = ESP_Settings[settingKey] and Color3.fromRGB(0, 210, 110) or Color3.fromRGB(210, 45, 45)
    status.Position = ESP_Settings[settingKey] and UDim2.new(0, 10, 0, 2) or UDim2.new(0, 2, 0, 2)
    status.Size = UDim2.new(0, 12, 0, 12)
    local scorr = Instance.new("UICorner")
    scorr.CornerRadius = UDim.new(1, 0)
    scorr.Parent = status

    btn.MouseButton1Click:Connect(function()
        ESP_Settings[settingKey] = not ESP_Settings[settingKey]
        
        local targetColor = ESP_Settings[settingKey] and Color3.fromRGB(0, 210, 110) or Color3.fromRGB(210, 45, 45)
        local targetPos = ESP_Settings[settingKey] and UDim2.new(0, 10, 0, 2) or UDim2.new(0, 2, 0, 2)
        
        TweenService:Create(status, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = targetColor,
            Position = targetPos
        }):Play()
    end)
end

local function createSlider(name, settingKey, min, max, isFloat)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = Container
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 42)
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = "    " .. name .. ": " .. tostring(ESP_Settings[settingKey])
    lbl.TextColor3 = Color3.fromRGB(180, 180, 195)
    lbl.TextSize = 11.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local bg = Instance.new("Frame")
    bg.Parent = lbl
    bg.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    bg.Position = UDim2.new(0.04, 0, 0.65, 0)
    bg.Size = UDim2.new(0.92, 0, 0, 8)
    bg.BorderSizePixel = 0
    local bgc = Instance.new("UICorner")
    bgc.CornerRadius = UDim.new(1, 0); bgc.Parent = bg

    local fill = Instance.new("Frame")
    fill.Parent = bg
    fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    fill.Size = UDim2.new((ESP_Settings[settingKey] - min) / (max - min), 0, 1, 0)
    fill.BorderSizePixel = 0
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill

    local dragging = false
    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
            local val = min + (max - min) * pos
            if not isFloat then val = math.floor(val + 0.5) else val = math.floor(val * 10 + 0.5) / 10 end
            ESP_Settings[settingKey] = val
            TweenService:Create(fill, TweenInfo.new(0.1), {Size = UDim2.new((val - min) / (max - min), 0, 1, 0)}):Play()
            lbl.Text = "    " .. name .. ": " .. tostring(val)
        end
    end)
end

-- Добавление элементов UI
createToggle("Master Switch", "Enabled")
createToggle("Team Check", "TeamCheck")
createToggle("Wall Check", "WallCheck")
createToggle("Show Boxes", "Box")
createToggle("Tracers", "Tracers")
createSlider("Tracer Thickness", "TracerThickness", 1, 5, false)
createSlider("Tracer Alpha", "TracerTransparency", 0.1, 1, true)
createToggle("Chams", "Chams")
createSlider("Chams Alpha", "ChamsTransparency", 0.1, 1, true)
createToggle("Name & Distance", "NameInfo")
createToggle("Health Bar", "HealthBar")

local Divider = Instance.new("Frame")
Divider.Parent = Container
Divider.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
Divider.Size = UDim2.new(1, 0, 0, 1)
Divider.BorderSizePixel = 0

local function killScript()
    ESP_Settings.Enabled = false
    if _G.PlayerESP_Drawings then
        for _, draw in ipairs(_G.PlayerESP_Drawings) do pcall(function() draw:Remove() end) end
    end
    if _G.PlayerESP_Highlights then
        for _, hl in ipairs(_G.PlayerESP_Highlights) do pcall(function() hl:Destroy() end) end
    end
    if _G.PlayerESP_Connections then
        for _, conn in pairs(_G.PlayerESP_Connections) do pcall(function() conn:Disconnect() end) end
    end
    if ESP_GUI then ESP_GUI:Destroy() end
end

local killBtn = Instance.new("TextButton")
killBtn.Parent = Container
killBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
killBtn.BorderSizePixel = 0
killBtn.Size = UDim2.new(1, 0, 0, 36)
killBtn.Font = Enum.Font.GothamBold
killBtn.Text = "Unload Script"
killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
killBtn.TextSize = 12.0

local kCorner = Instance.new("UICorner")
kCorner.CornerRadius = UDim.new(0, 6)
kCorner.Parent = killBtn

killBtn.MouseButton1Click:Connect(function() killScript() end)

local uiToggleConn = UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        MainFrame.Visible = not MainFrame.Visible
    end
end)
table.insert(_G.PlayerESP_Connections, uiToggleConn)

local function hideESP(data)
    data.Box.Visible = false
    data.Tracer.Visible = false
    data.NameText.Visible = false
    data.HealthBar.Visible = false
    data.HealthBarBG.Visible = false
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
    return false
end

-- Проверка WallCheck
local function isVisible(targetPart)
    if not targetPart then return false end
    local origin = camera.CFrame.Position
    local direction = targetPart.Position - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = RaycastFilterType.Exclude
    local filter = {localPlayer.Character}
    if targetPart.Parent then table.insert(filter, targetPart.Parent) end
    raycastParams.FilterDescendantsInstances = filter
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    return result == nil 
end

local function createESP(player)
    if player == localPlayer then return nil end

    local data = {
        Player = player,
        FadeAlpha = 0,
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        NameText = Drawing.new("Text"),
        HealthBarBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Chams = Instance.new("Highlight")
    }

    data.Box.Visible = false; data.Box.Thickness = 1; data.Box.Filled = false
    table.insert(_G.PlayerESP_Drawings, data.Box)

    data.Tracer.Visible = false
    table.insert(_G.PlayerESP_Drawings, data.Tracer)

    data.NameText.Visible = false; data.NameText.Color = Color3.fromRGB(255, 255, 255); data.NameText.Center = true; data.NameText.Outline = true; data.NameText.Size = 13; data.NameText.Font = 2
    table.insert(_G.PlayerESP_Drawings, data.NameText)

    data.HealthBarBG.Visible = false; data.HealthBarBG.Color = Color3.fromRGB(0, 0, 0); data.HealthBarBG.Thickness = 1; data.HealthBarBG.Filled = true
    table.insert(_G.PlayerESP_Drawings, data.HealthBarBG)

    data.HealthBar.Visible = false; data.HealthBar.Color = Color3.fromRGB(0, 255, 0); data.HealthBar.Thickness = 1; data.HealthBar.Filled = true
    table.insert(_G.PlayerESP_Drawings, data.HealthBar)

    data.Chams.Name = "Chams_" .. player.Name
    data.Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    data.Chams.Enabled = false
    data.Chams.Parent = ESP_GUI
    table.insert(_G.PlayerESP_Highlights, data.Chams)

    return data
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then ESP_List[player] = createESP(player) end
end

local addedConn = Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then ESP_List[player] = createESP(player) end
end)
table.insert(_G.PlayerESP_Connections, addedConn)

local removedConn = Players.PlayerRemoving:Connect(function(player)
    if ESP_List[player] then hideESP(ESP_List[player]); ESP_List[player] = nil end
end)
table.insert(_G.PlayerESP_Connections, removedConn)

local function getPlayersArray()
    local arr = {}
    for p, data in pairs(ESP_List) do
        if p and p.Parent then table.insert(arr, p) else ESP_List[p] = nil end
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
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp or not hum then shouldShow = false else
                rootPos = hrp.Position
                targetPart = hrp
                local head = character:FindFirstChild("Head")
                headPos = head and head.Position or (rootPos + Vector3.new(0, 2, 0))
                legPos = rootPos - Vector3.new(0, 3, 0)
            end
        end

        if hum and hum.Health <= 0 then shouldShow = false end

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
            local visible = isVisible(targetPart)

            -- Дефолтные цвета, если за стеной
            local boxColor = Color3.fromRGB(255, 255, 255)
            local chamsFillColor = Color3.fromRGB(255, 50, 50) 
            local tracerColor = Color3.fromRGB(255, 255, 255)

            -- WallCheck активирован
            if ESP_Settings.WallCheck then
                if visible then
                    boxColor = Color3.fromRGB(255, 0, 0) -- Красный Box, если видно
                    chamsFillColor = Color3.fromRGB(0, 120, 255) -- Синий Chams, если видно
                    tracerColor = Color3.fromRGB(255, 0, 0)
                end
            end

            data.Box.Transparency = data.FadeAlpha
            data.NameText.Transparency = data.FadeAlpha
            data.HealthBar.Transparency = data.FadeAlpha
            data.HealthBarBG.Transparency = data.FadeAlpha

            if ESP_Settings.Chams then
                data.Chams.Adornee = character
                data.Chams.FillColor = chamsFillColor
                data.Chams.FillTransparency = 1 - ((1 - ESP_Settings.ChamsTransparency) * data.FadeAlpha)
                data.Chams.OutlineTransparency = 1 - (0.8 * data.FadeAlpha) 
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
                data.Box.Color = boxColor
                data.Box.Visible = true
            else
                data.Box.Visible = false
            end

            if ESP_Settings.Tracers then
                data.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                data.Tracer.To = Vector2.new(vector.X, vector.Y + height / 2)
                data.Tracer.Color = tracerColor
                data.Tracer.Thickness = ESP_Settings.TracerThickness
                data.Tracer.Transparency = ESP_Settings.TracerTransparency * data.FadeAlpha
                data.Tracer.Visible = true
            else
                data.Tracer.Visible = false
            end

            if ESP_Settings.NameInfo then
                local dist = math.floor((camera.CFrame.Position - rootPos).Magnitude)
                data.NameText.Text = player.Name .. " [" .. dist .. "]"
                data.NameText.Position = Vector2.new(vector.X, vector.Y - height / 2 - 17)
                data.NameText.Visible = true
            else
                data.NameText.Visible = false
            end

            if ESP_Settings.HealthBar and hum then
                local healthPct = hum.Health / hum.MaxHealth
                if healthPct ~= healthPct or healthPct == math.huge then healthPct = 1 end 
                healthPct = math.clamp(healthPct, 0, 1)

                data.HealthBarBG.Size = Vector2.new(3, height)
                data.HealthBarBG.Position = Vector2.new(vector.X - width / 2 - 6, vector.Y - height / 2)

                data.HealthBar.Size = Vector2.new(1, height * healthPct - 2)
                data.HealthBar.Position = Vector2.new(vector.X - width / 2 - 5, (vector.Y - height / 2 + 1) + (height - (height * healthPct)))
                data.HealthBar.Color = Color3.fromHSV(healthPct * 0.3, 1, 1)

                data.HealthBarBG.Visible = true
                data.HealthBar.Visible = true
            else
                data.HealthBarBG.Visible = false
                data.HealthBar.Visible = false
            end
        end
    end
end)
table.insert(_G.PlayerESP_Connections, renderConn)
