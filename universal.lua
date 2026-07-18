-- Очистка от прошлых запусков скрипта
pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("PlayerESP_UI") then
        game:GetService("CoreGui").PlayerESP_UI:Destroy()
    end
    if _G.PlayerESP_Connections then
        for _, conn in pairs(_G.PlayerESP_Connections) do conn:Disconnect() end
    end
    if _G.PlayerESP_Drawings then
        for _, draw in ipairs(_G.PlayerESP_Drawings) do draw:Remove() end
    end
    if _G.PlayerESP_Highlights then
        for _, hl in ipairs(_G.PlayerESP_Highlights) do hl:Destroy() end
    end
end)

_G.PlayerESP_Connections = {}
_G.PlayerESP_Drawings = {}
_G.PlayerESP_Highlights = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local camera = workspace.CurrentCamera or workspace.Camera
local localPlayer = Players.LocalPlayer

local ESP_Settings = {
    Enabled = true,
    TeamCheck = false,
    TeamCheckMode = 1,
    TargetTeams = {}, -- Таблица выбранных команд {["TeamName"] = true}
    CModelMode = false,
    CModelModeType = 1,
    Box = true,
    NameInfo = true,
    HealthBar = true,
    Chams = false,
    WallCheck = false,
    Tracers = true,            
    TracerThickness = 1,       
    TracerTransparency = 0.2,   
    ChamsFillAlpha = 0.5,
    ChamsOutlineAlpha = 0.2,
    FadeSpeed = 5 
}

local TC_Modes = {"Standard", "Attributes", "ColorMatch", "Hierarchy", "DeepSearch", "Select"}
local CM_Modes = {"BoundingBox", "Dynamic", "Root Fallback"}

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
MainFrame.Size = UDim2.new(0, 210, 0, 420)
MainFrame.Image = "rbxassetid://3570695787"
MainFrame.ImageColor3 = Color3.fromRGB(22, 22, 22)
MainFrame.ScaleType = Enum.ScaleType.Slice
MainFrame.SliceCenter = Rect.new(100, 100, 100, 100)
MainFrame.SliceScale = 0.120
MainFrame.Active = true

local MenuOutline = Instance.new("UIStroke")
MenuOutline.Parent = MainFrame
MenuOutline.Color = Color3.fromRGB(0, 170, 255)
MenuOutline.Thickness = 1.5
MenuOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 12)
MenuCorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1.000
Title.Size = UDim2.new(1, 0, 0, 38)
Title.Font = Enum.Font.GothamBold
Title.Text = "  АННИГИЛЯТОР-3000"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
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

local Container = Instance.new("ScrollingFrame")
Container.Parent = MainFrame
Container.BackgroundTransparency = 1
Container.Position = UDim2.new(0.05, 0, 0.11, 0)
Container.Size = UDim2.new(0.9, 0, 0.86, 0)
Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Container.ScrollBarThickness = 2
Container.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
Container.BorderSizePixel = 0

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)

-- === ДОПОЛНИТЕЛЬНОЕ МЕНЮ ВЫБОРА КОМАНД (СПРАВА) ===
local TeamSelectFrame = Instance.new("ImageLabel")
TeamSelectFrame.Name = "TeamSelectFrame"
TeamSelectFrame.Parent = MainFrame
TeamSelectFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TeamSelectFrame.BackgroundTransparency = 1.000
TeamSelectFrame.Position = UDim2.new(1, 8, 0, 0)
TeamSelectFrame.Size = UDim2.new(0, 180, 0, 320) -- Немного увеличил высоту для подписи
TeamSelectFrame.Image = "rbxassetid://3570695787"
TeamSelectFrame.ImageColor3 = Color3.fromRGB(22, 22, 22)
TeamSelectFrame.ScaleType = Enum.ScaleType.Slice
TeamSelectFrame.SliceCenter = Rect.new(100, 100, 100, 100)
TeamSelectFrame.SliceScale = 0.120
TeamSelectFrame.Visible = false

local TS_Outline = Instance.new("UIStroke")
TS_Outline.Parent = TeamSelectFrame
TS_Outline.Color = Color3.fromRGB(0, 170, 255)
TS_Outline.Thickness = 1.5
TS_Outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local TS_Corner = Instance.new("UICorner")
TS_Corner.CornerRadius = UDim.new(0, 12)
TS_Corner.Parent = TeamSelectFrame

local TS_Title = Instance.new("TextLabel")
TS_Title.Parent = TeamSelectFrame
TS_Title.BackgroundTransparency = 1.000
TS_Title.Size = UDim2.new(1, 0, 0, 35)
TS_Title.Font = Enum.Font.GothamBold
TS_Title.Text = "ФИЛЬТР КОМАНД"
TS_Title.TextColor3 = Color3.fromRGB(240, 240, 240)
TS_Title.TextSize = 11.000
TS_Title.TextXAlignment = Enum.TextXAlignment.Center

-- Новая надпись "ДЛЯ ER:LC" под всеми командами
local ERLC_Label = Instance.new("TextLabel")
ERLC_Label.Parent = TeamSelectFrame
ERLC_Label.BackgroundTransparency = 1.000
ERLC_Label.Position = UDim2.new(0, 0, 1, -25) -- Закреплена в самом низу
ERLC_Label.Size = UDim2.new(1, 0, 0, 20)
ERLC_Label.Font = Enum.Font.GothamBold
ERLC_Label.Text = "ДЛЯ ER:LC"
ERLC_Label.TextColor3 = Color3.fromRGB(0, 170, 255)
ERLC_Label.TextSize = 10.000
ERLC_Label.TextXAlignment = Enum.TextXAlignment.Center

local TS_Container = Instance.new("ScrollingFrame")
TS_Container.Parent = TeamSelectFrame
TS_Container.BackgroundTransparency = 1
TS_Container.Position = UDim2.new(0.05, 0, 0.12, 0)
TS_Container.Size = UDim2.new(0.9, 0, 0.74, 0) -- Высота уменьшена, чтобы не перекрывать надпись
TS_Container.CanvasSize = UDim2.new(0, 0, 0, 0)
TS_Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
TS_Container.ScrollBarThickness = 2
TS_Container.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
TS_Container.BorderSizePixel = 0

local TS_ListLayout = Instance.new("UIListLayout")
TS_ListLayout.Parent = TS_Container
TS_ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TS_ListLayout.Padding = UDim.new(0, 5)

-- Продвинутая функция получения вообще всех существующих названий команд в сессии
local function updateTeamDropdown()
    for _, child in ipairs(TS_Container:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    -- Находим уникальные имена команд
    local foundTeamNames = {}
    
    -- Принудительно добавляем Criminals, если её еще нет в списке игр
    foundTeamNames["Criminals"] = true
    
    for _, team in ipairs(Teams:GetTeams()) do
        foundTeamNames[team.Name] = true
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Team then
            foundTeamNames[player.Team.Name] = true
        end
    end

    -- Сортируем список по алфавиту
    local sortedTeams = {}
    for teamName, _ in pairs(foundTeamNames) do
        table.insert(sortedTeams, teamName)
    end
    table.sort(sortedTeams)

    -- Отрисовка кнопок
    for _, teamName in ipairs(sortedTeams) do
        local tBtn = Instance.new("TextButton")
        tBtn.Parent = TS_Container
        tBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
        tBtn.BorderSizePixel = 0
        tBtn.Size = UDim2.new(1, -4, 0, 28)
        tBtn.Font = Enum.Font.GothamMedium
        tBtn.Text = "  " .. teamName
        tBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
        tBtn.TextSize = 10.5
        tBtn.TextXAlignment = Enum.TextXAlignment.Left

        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(0, 5)
        tCorner.Parent = tBtn

        local checkbox = Instance.new("Frame")
        checkbox.Parent = tBtn
        checkbox.Position = UDim2.new(0.84, 0, 0.25, 0)
        checkbox.Size = UDim2.new(0, 14, 0, 14)
        checkbox.BackgroundColor3 = ESP_Settings.TargetTeams[teamName] and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(50, 50, 50)
        
        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 4)
        cCorner.Parent = checkbox

        local tConn = tBtn.MouseButton1Click:Connect(function()
            ESP_Settings.TargetTeams[teamName] = not ESP_Settings.TargetTeams[teamName]
            checkbox.BackgroundColor3 = ESP_Settings.TargetTeams[teamName] and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(50, 50, 50)
        end)
        table.insert(_G.PlayerESP_Connections, tConn)
    end
end

-- Мониторинг изменений команд и игроков
table.insert(_G.PlayerESP_Connections, Teams.ChildAdded:Connect(function() if TeamSelectFrame.Visible then updateTeamDropdown() end end))
table.insert(_G.PlayerESP_Connections, Teams.ChildRemoved:Connect(function() if TeamSelectFrame.Visible then updateTeamDropdown() end end))
table.insert(_G.PlayerESP_Connections, Players.PlayerAdded:Connect(function() if TeamSelectFrame.Visible then updateTeamDropdown() end end))

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

local function createModeCycle(name, settingKey, optionsArray, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = Container
    btn.BackgroundColor3 = Color3.fromRGB(25, 35, 45)
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1, -5, 0, 28)
    btn.Font = Enum.Font.GothamMedium
    btn.Text = "  " .. name .. ": " .. optionsArray[ESP_Settings[settingKey]]
    btn.TextColor3 = Color3.fromRGB(150, 200, 255)
    btn.TextSize = 10.5
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local conn = btn.MouseButton1Click:Connect(function()
        local current = ESP_Settings[settingKey]
        current = current + 1
        if current > #optionsArray then current = 1 end
        ESP_Settings[settingKey] = current
        btn.Text = "  " .. name .. ": " .. optionsArray[current]
        
        if callback then callback(current) end
    end)
    table.insert(_G.PlayerESP_Connections, conn)
end

local function createInputField(name, settingKey, min, max, isFloat)
    local frame = Instance.new("Frame")
    frame.Parent = Container
    frame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, -5, 0, 35)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Size = UDim2.new(0.65, -10, 1, 0)
    title.Font = Enum.Font.GothamMedium
    title.Text = name
    title.TextColor3 = Color3.fromRGB(210, 210, 210)
    title.TextSize = 11.5
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    local input = Instance.new("TextBox")
    input.Parent = frame
    input.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    input.BorderSizePixel = 0
    input.Position = UDim2.new(0.65, 0, 0.15, 0)
    input.Size = UDim2.new(0.3, 0, 0.7, 0)
    input.Font = Enum.Font.Gotham
    input.Text = tostring(ESP_Settings[settingKey])
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.TextSize = 11
    input.ClipsDescendants = true
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = input
    
    local conn = input.FocusLost:Connect(function()
        local val = tonumber(input.Text)
        if val then
            if not isFloat then val = math.floor(val) end
            val = math.clamp(val, min, max)
            ESP_Settings[settingKey] = val
        end
        input.Text = tostring(ESP_Settings[settingKey])
    end)
    table.insert(_G.PlayerESP_Connections, conn)
end

createToggle("Master Switch", "Enabled")
createToggle("Team Check", "TeamCheck")

createModeCycle("TC Mode", "TeamCheckMode", TC_Modes, function(currentIndex)
    if TeamSelectFrame then
        TeamSelectFrame.Visible = (currentIndex == 6)
        if currentIndex == 6 then
            updateTeamDropdown()
        end
    end
end)

TeamSelectFrame.Visible = (ESP_Settings.TeamCheckMode == 6)
if ESP_Settings.TeamCheckMode == 6 then updateTeamDropdown() end

createToggle("CModel Mode", "CModelMode")
createModeCycle("CM Mode", "CModelModeType", CM_Modes)
createToggle("Wall Check", "WallCheck")
createToggle("Show Boxes", "Box")
createToggle("Name & Distance", "NameInfo")
createToggle("Health Bar", "HealthBar")
createToggle("Chams", "Chams")
createInputField("Chams Fill %", "ChamsFillAlpha", 0, 1, true)
createInputField("Chams Outline %", "ChamsOutlineAlpha", 0, 1, true)
createToggle("Tracers", "Tracers")
createInputField("Tracer Thickness", "TracerThickness", 1, 10, false)
createInputField("Tracer Transp", "TracerTransparency", 0, 1, true)

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
killBtn.BackgroundColor3 = Color3.fromRGB(120, 25, 25)
killBtn.BorderSizePixel = 0
killBtn.Size = UDim2.new(1, -5, 0, 31)
killBtn.Font = Enum.Font.GothamBold
killBtn.Text = "  Kill Script"
killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
killBtn.TextSize = 12.000
killBtn.TextXAlignment = Enum.TextXAlignment.Left
local kCorner = Instance.new("UICorner")
kCorner.CornerRadius = UDim.new(0, 6)
kCorner.Parent = killBtn
local killConn = killBtn.MouseButton1Click:Connect(function() killScript() end)
table.insert(_G.PlayerESP_Connections, killConn)

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

local function hideESP(data)
    data.Box.Visible = false
    data.NameText.Visible = false
    data.HealthBar.Visible = false
    data.HealthBarBG.Visible = false
    data.Tracer.Visible = false
    if data.Chams then data.Chams.Enabled = false end
end

local function getTeamColor(player)
	if player.Team then return player.Team.TeamColor.Color end
	return Color3.new(1, 1, 1)
end

-- Внутренняя сверка имени команды или кастомного параметра игрока в ER:LC
local function checkPlayerTeamName(player)
    if player.Team and player.Team.Name then
        return player.Team.Name
    end
    -- Запасная проверка: если игра выставляет кастомные атрибуты/значения
    if player:GetAttribute("Team") then return player:GetAttribute("Team") end
    if player.Character and player.Character:GetAttribute("Team") then return player.Character:GetAttribute("Team") end
    return nil
end

local function isTeammateCheck(player, character)
    if player == localPlayer then return true end
    local mode = ESP_Settings.TeamCheckMode
    local lpChar = localPlayer.Character

    if mode == 1 then 
        if localPlayer.Team ~= nil and player.Team == localPlayer.Team then return true end
        if localPlayer.TeamColor ~= nil and player.TeamColor == localPlayer.TeamColor and not player.Neutral then return true end
    elseif mode == 2 then 
        if character then
            for _, attrName in ipairs({"Team", "Clan", "Faction", "Group", "Alliance", "Side"}) do
                local charAttr = character:GetAttribute(attrName)
                local localAttr = lpChar and lpChar:GetAttribute(attrName)
                if charAttr and localAttr and charAttr == localAttr then return true end
            end
        end
    elseif mode == 3 then 
        if character and lpChar then
            local pPart = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Head")
            local lPart = lpChar:FindFirstChild("Torso") or lpChar:FindFirstChild("UpperTorso") or lpChar:FindFirstChild("Head")
            if pPart and lPart and pPart.Color == lPart.Color then return true end
        end
    elseif mode == 4 then 
        if character and lpChar and character.Parent and lpChar.Parent then
            if character.Parent == lpChar.Parent and character.Parent ~= workspace then return true end
        end
    elseif mode == 6 then
        local pTeamName = checkPlayerTeamName(player)
        if pTeamName and ESP_Settings.TargetTeams[pTeamName] then
            return false -- Не скрываем, эта команда выбрана в фильтре
        else
            return true -- Скрываем команду, так как её чекбокс пуст
        end
    end
    return false
end

-- === УСКОРЕННЫЙ УМНЫЙ WALL CHECK ===
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

local function checkVisibility(targetPart, targetCharacter)
    if not targetPart or not targetCharacter then return false end
    local origin = camera.CFrame.Position
    local direction = targetPart.Position - origin
    
    local ignoreList = {camera, localPlayer.Character, targetCharacter}
    raycastParams.FilterDescendantsInstances = ignoreList
    
    local iterations = 0
    while iterations < 10 do
        local result = workspace:Raycast(origin, direction, raycastParams)
        
        if not result then
            return true 
        end
        
        local hitPart = result.Instance
        if hitPart.CanCollide == false or hitPart.Transparency == 1 or hitPart.Name == "HumanoidRootPart" then
            table.insert(ignoreList, hitPart)
            raycastParams.FilterDescendantsInstances = ignoreList
            iterations = iterations + 1
        else
            return false 
        end
    end
    
    return false 
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

    data.Box.Visible = false; data.Box.Thickness = 1.5; data.Box.Filled = false
    table.insert(_G.PlayerESP_Drawings, data.Box)

    data.NameText.Visible = false; data.NameText.Center = true; data.NameText.Outline = true; data.NameText.Size = 13; data.NameText.Font = 2
    table.insert(_G.PlayerESP_Drawings, data.NameText)

    data.HealthBarBG.Visible = false; data.HealthBarBG.Color = Color3.fromRGB(0, 0, 0); data.HealthBarBG.Filled = true
    table.insert(_G.PlayerESP_Drawings, data.HealthBarBG)

    data.HealthBar.Visible = false; data.HealthBar.Filled = true
    table.insert(_G.PlayerESP_Drawings, data.HealthBar)

    data.Tracer.Visible = false; data.Tracer.Color = Color3.new(1, 1, 1)
    table.insert(_G.PlayerESP_Drawings, data.Tracer)

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
    if ESP_List[player] then
        hideESP(ESP_List[player])
        ESP_List[player] = nil
    end
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
            if targetPlayer and data then data.IsTeammate = isTeammateCheck(targetPlayer, targetPlayer.Character) end
        end
    end

    local viewportSize = camera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

    for player, data in pairs(ESP_List) do
        local character = player.Character
        local isTeammate = data.IsTeammate or false

        local shouldShow = ESP_Settings.Enabled and character and not (ESP_Settings.TeamCheck and isTeammate)
        local rootPos, headPos, legPos, targetPart
        local hum = character and character:FindFirstChildOfClass("Humanoid") or nil

        if shouldShow then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if ESP_Settings.CModelMode then
                local cmMode = ESP_Settings.CModelModeType
                if cmMode == 1 then
                    local cframe, size = character:GetBoundingBox()
                    if not cframe or size == Vector3.new() then shouldShow = false else
                        rootPos = cframe.Position
                        targetPart = hrp or character.PrimaryPart
                        local heightY = math.max(size.Y, 2) 
                        headPos = rootPos + Vector3.new(0, heightY * 0.5, 0)
                        legPos = rootPos - Vector3.new(0, heightY * 0.5, 0)
                    end
                elseif cmMode == 2 then
                    local root = character.PrimaryPart or hrp
                    if not root then shouldShow = false else
                        rootPos = root.Position
                        targetPart = root
                        local highestY, lowestY = rootPos.Y + 1, rootPos.Y - 2.5
                        local head = character:FindFirstChild("Head")
                        local lLeg = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
                        
                        if head then highestY = head.Position.Y + (head.Size.Y * 0.5) end
                        if lLeg then lowestY = lLeg.Position.Y - (lLeg.Size.Y * 0.5) end
                        
                        headPos = Vector3.new(rootPos.X, highestY, rootPos.Z)
                        legPos = Vector3.new(rootPos.X, lowestY, rootPos.Z)
                    end
                elseif cmMode == 3 then
                    if not hrp then shouldShow = false else
                        targetPart = hrp
                        rootPos = hrp.Position
                        headPos = rootPos + Vector3.new(0, 2.5, 0)
                        legPos = rootPos - Vector3.new(0, 3, 0)
                    end
                end
            else
                if not hrp or not hum then shouldShow = false else
                    targetPart = hrp
                    rootPos = hrp.Position
                    local head = character:FindFirstChild("Head")
                    headPos = head and head.Position or (rootPos + Vector3.new(0, 2, 0))
                    legPos = rootPos - Vector3.new(0, 3, 0)
                end
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
            data.FadeAlpha = math.clamp(data.FadeAlpha - (deltaTime * (ESP_Settings.FadeSpeed * 2)), 0, 1)
        end

        if data.FadeAlpha > 0.01 then
            local isVisible = false
            if ESP_Settings.WallCheck and targetPart then
                isVisible = checkVisibility(targetPart, character)
            end

            local activeBoxColor = Color3.fromRGB(255, 255, 255)
            local activeChamsColor = Color3.fromRGB(255, 50, 50)

            if ESP_Settings.WallCheck then
                if isVisible then
                    activeBoxColor = Color3.fromRGB(255, 50, 50)
                    activeChamsColor = Color3.fromRGB(50, 100, 255)
                end
            end

            data.Box.Color = activeBoxColor
            data.Box.Transparency = data.FadeAlpha
            data.NameText.Color = activeBoxColor
            data.NameText.Transparency = data.FadeAlpha
            data.HealthBar.Transparency = data.FadeAlpha
            data.HealthBarBG.Transparency = data.FadeAlpha

            if ESP_Settings.Chams then
                if data.Chams.Adornee ~= character then data.Chams.Adornee = character end
                data.Chams.FillColor = activeChamsColor
                data.Chams.FillTransparency = ESP_Settings.ChamsFillAlpha + ((1 - ESP_Settings.ChamsFillAlpha) * (1 - data.FadeAlpha))
                data.Chams.OutlineTransparency = ESP_Settings.ChamsOutlineAlpha + ((1 - ESP_Settings.ChamsOutlineAlpha) * (1 - data.FadeAlpha))
                data.Chams.Enabled = true
            else
                data.Chams.Enabled = false
            end

            if vector and headPos and legPos then
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
                    local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    if healthPct ~= healthPct then healthPct = 1 end 

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
                    data.Tracer.From = screenCenter
                    data.Tracer.To = Vector2.new(vector.X, vector.Y)
                    data.Tracer.Color = getTeamColor(player)
                    data.Tracer.Thickness = ESP_Settings.TracerThickness
                    data.Tracer.Transparency = (1 - ESP_Settings.TracerTransparency) * data.FadeAlpha
                    data.Tracer.Visible = true
                else
                    data.Tracer.Visible = false
                end
            end
        else
            hideESP(data)
        end
    end
end)
table.insert(_G.PlayerESP_Connections, renderConn)
