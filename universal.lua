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
local HttpService = game:GetService("HttpService")
local camera = workspace.CurrentCamera or workspace.Camera
local localPlayer = Players.LocalPlayer

local ESP_Settings = {
    Enabled = true,
    TeamCheck = false,
    TeamCheckMode = 1,
    TargetTeams = {},
    CModelMode = false,
    CModelModeType = 1,
    Box = true,
    ShowName = true,
    ShowDistance = true,
    HealthBar = true,
    Chams = false,
    ChamsMode = 1, 
    WallCheck = false,
    Tracers = true,            
    TracerThickness = 1,       
    TracerTransparency = 0.2,   
    ChamsFillAlpha = 0.5,
    ChamsOutlineAlpha = 0.2,
    FadeSpeed = 5,
    Noclip = false,
    Fly = false,
    FlySpeed = 1,
    WalkSpeedEnabled = false,
    WalkSpeed = 16,
    NoclipKey = "NONE",
    FlyKey = "NONE",
    BindList = false, -- Новая настройка для Bind List
    -- === ЦВЕТА ESP ===
    ColorBox = Color3.fromRGB(255, 255, 255),
    ColorBoxVis = Color3.fromRGB(255, 50, 50),
    ColorChams = Color3.fromRGB(255, 50, 50),
    ColorChamsVis = Color3.fromRGB(50, 100, 255),
    ColorTracer = Color3.fromRGB(255, 255, 255),
    ColorFriend = Color3.fromRGB(50, 255, 50),
    
    Friends = {}
}

local bindingFor = nil 
local bindButtons = {}
local toggleVisuals = {}
local inputTextBoxes = {}
local modeCycleButtons = {}
local TC_Modes = {"Standard", "Attributes", "ColorMatch", "Hierarchy", "DeepSearch", "Select"}
local CM_Modes = {"BoundingBox", "Dynamic", "Root Fallback"}
local ESP_List = {}

-- === ЦВЕТА ИЗ ТЕМЫ WINDOWS 3.1 ===
local c_Title = Color3.fromRGB(0, 0, 168)
local c_Background = Color3.fromRGB(252, 252, 252)
local c_Button = Color3.fromRGB(192, 196, 200)
local c_Shadow = Color3.fromRGB(132, 136, 140)
local c_Font = Color3.fromRGB(0, 0, 0)
local mainFont = Enum.Font.Code

-- === СЕРИАЛИЗАЦИЯ НАСТРОЕК СЕЙВ/ЛОАД ===
local function serializeSettings()
    local tbl = {}
    for k, v in pairs(ESP_Settings) do
        if typeof(v) == "Color3" then
            tbl[k] = {typeof = "Color3", r = v.R, g = v.G, b = v.B}
        elseif typeof(v) ~= "table" or k == "Friends" then
            tbl[k] = v
        end
    end
    return HttpService:JSONEncode(tbl)
end

local function deserializeSettings(str)
    local success, tbl = pcall(function() return HttpService:JSONDecode(str) end)
    if success and tbl then
        for k, v in pairs(tbl) do
            if typeof(v) == "table" and v.typeof == "Color3" then
                ESP_Settings[k] = Color3.new(v.r, v.g, v.b)
            else
                ESP_Settings[k] = v
            end
        end
        for settingKey, statusFill in pairs(toggleVisuals) do
            statusFill.Visible = ESP_Settings[settingKey] or false
        end
        for settingKey, btn in pairs(bindButtons) do
            local displayName = (settingKey == "NoclipKey") and "Bind Noclip" or "Bind Fly"
            btn.Text = " " .. displayName .. ": [" .. tostring(ESP_Settings[settingKey]) .. "]"
        end
        for settingKey, input in pairs(inputTextBoxes) do
            input.Text = tostring(ESP_Settings[settingKey])
        end
        for settingKey, data in pairs(modeCycleButtons) do
            if data.options[ESP_Settings[settingKey]] then
                data.btn.Text = " " .. data.name .. ": " .. data.options[ESP_Settings[settingKey]]
            end
        end
    end
end

-- === ИНТЕРФЕЙС ===
local ESP_GUI = Instance.new("ScreenGui")
ESP_GUI.Name = "PlayerESP_UI"
ESP_GUI.ResetOnSpawn = false
if syn and syn.protect_gui then
	syn.protect_gui(ESP_GUI)
elseif gethui then
	ESP_GUI.Parent = gethui()
else
	ESP_GUI.Parent = game:GetService("CoreGui")
end

-- === ФУНКЦИЯ ДЛЯ ПЕРЕТАСКИВАНИЯ ===
local function drag(GuiObj, DragZone)
	local dragToggle, dragInput, dragStart, startPos
	local conn1 = DragZone.InputBegan:Connect(function(input)
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
	local conn3 = DragZone.InputChanged:Connect(function(input)
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

-- Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ESP_GUI
MainFrame.BackgroundColor3 = c_Background
MainFrame.BorderColor3 = c_Font
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.6, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 220, 0, 505)
MainFrame.Active = true

local TitleBar = Instance.new("Frame")
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = c_Title
TitleBar.BorderColor3 = c_Font
TitleBar.BorderSizePixel = 1
TitleBar.Position = UDim2.new(0, 2, 0, 2)
TitleBar.Size = UDim2.new(1, -4, 0, 20)
drag(MainFrame, TitleBar)

local Title = Instance.new("TextLabel")
Title.Parent = TitleBar
Title.BackgroundTransparency = 1.000
Title.Size = UDim2.new(1, -5, 1, 0)
Title.Position = UDim2.new(0, 5, 0, 0)
Title.Font = mainFont
Title.Text = "АННИГИЛЯТОР-3000"
Title.TextColor3 = c_Background
Title.TextSize = 14.000
Title.TextXAlignment = Enum.TextXAlignment.Left

local Container = Instance.new("ScrollingFrame")
Container.Parent = MainFrame
Container.BackgroundColor3 = c_Background
Container.Position = UDim2.new(0, 4, 0, 26)
Container.Size = UDim2.new(1, -8, 1, -30)
Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Container.ScrollBarThickness = 12
Container.ScrollBarImageColor3 = c_Button
Container.BorderColor3 = c_Font
Container.BorderSizePixel = 1

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)

-- === ОКНО BIND LIST ===
local BindListFrame = Instance.new("Frame")
BindListFrame.Name = "BindListFrame"
BindListFrame.Parent = ESP_GUI
BindListFrame.BackgroundColor3 = c_Background
BindListFrame.BorderColor3 = c_Font
BindListFrame.BorderSizePixel = 2
BindListFrame.Position = UDim2.new(0.1, 0, 0.4, 0) 
BindListFrame.Size = UDim2.new(0, 180, 0, 80)
BindListFrame.Visible = false
BindListFrame.Active = true

local BLTitleBar = Instance.new("Frame")
BLTitleBar.Parent = BindListFrame
BLTitleBar.BackgroundColor3 = c_Title
BLTitleBar.BorderColor3 = c_Font
BLTitleBar.BorderSizePixel = 1
BLTitleBar.Position = UDim2.new(0, 2, 0, 2)
BLTitleBar.Size = UDim2.new(1, -4, 0, 20)
drag(BindListFrame, BLTitleBar)

local BLTitle = Instance.new("TextLabel")
BLTitle.Parent = BLTitleBar
BLTitle.BackgroundTransparency = 1.000
BLTitle.Size = UDim2.new(1, -5, 1, 0)
BLTitle.Position = UDim2.new(0, 5, 0, 0)
BLTitle.Font = mainFont
BLTitle.Text = "BIND LIST"
BLTitle.TextColor3 = c_Background
BLTitle.TextSize = 14.000
BLTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Лейблы для списка биндов
local BL_FlyLabel = Instance.new("TextLabel")
BL_FlyLabel.Parent = BindListFrame
BL_FlyLabel.BackgroundTransparency = 1
BL_FlyLabel.Position = UDim2.new(0, 8, 0, 30)
BL_FlyLabel.Size = UDim2.new(1, -16, 0, 20)
BL_FlyLabel.Font = mainFont
BL_FlyLabel.Text = "FLY: OFF [NONE]"
BL_FlyLabel.TextColor3 = c_Font
BL_FlyLabel.TextSize = 13
BL_FlyLabel.TextXAlignment = Enum.TextXAlignment.Left

local BL_NoclipLabel = Instance.new("TextLabel")
BL_NoclipLabel.Parent = BindListFrame
BL_NoclipLabel.BackgroundTransparency = 1
BL_NoclipLabel.Position = UDim2.new(0, 8, 0, 50)
BL_NoclipLabel.Size = UDim2.new(1, -16, 0, 20)
BL_NoclipLabel.Font = mainFont
BL_NoclipLabel.Text = "NOCLIP: OFF [NONE]"
BL_NoclipLabel.TextColor3 = c_Font
BL_NoclipLabel.TextSize = 13
BL_NoclipLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Кнопка растягивания окна в ПРАВОМ НИЖНЕМ углу (для стабильности UI)
local BLResizeBtn = Instance.new("TextButton")
BLResizeBtn.Parent = BindListFrame
BLResizeBtn.BackgroundColor3 = c_Button
BLResizeBtn.BorderColor3 = c_Font
BLResizeBtn.BorderSizePixel = 1
BLResizeBtn.Position = UDim2.new(1, -12, 1, -12)
BLResizeBtn.Size = UDim2.new(0, 12, 0, 12)
BLResizeBtn.Font = Enum.Font.SourceSans
BLResizeBtn.Text = "↘"
BLResizeBtn.TextColor3 = c_Font
BLResizeBtn.TextSize = 10

local blResizing = false
BLResizeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        blResizing = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        blResizing = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if blResizing and input.UserInputType == Enum.UserInputType.MouseMovement then
        local newWidth = input.Position.X - BindListFrame.AbsolutePosition.X
        local newHeight = input.Position.Y - BindListFrame.AbsolutePosition.Y
        BindListFrame.Size = UDim2.new(0, math.max(120, newWidth), 0, math.max(80, newHeight))
    end
end)

-- Обновление текста в Bind List
local bindListUpdateConn = RunService.RenderStepped:Connect(function()
    if ESP_Settings.BindList then
        BindListFrame.Visible = true
        local fState = ESP_Settings.Fly and "ON" or "OFF"
        local nState = ESP_Settings.Noclip and "ON" or "OFF"
        
        BL_FlyLabel.Text = "FLY: " .. fState .. " [" .. ESP_Settings.FlyKey .. "]"
        BL_NoclipLabel.Text = "NOCLIP: " .. nState .. " [" .. ESP_Settings.NoclipKey .. "]"
    else
        BindListFrame.Visible = false
    end
end)
table.insert(_G.PlayerESP_Connections, bindListUpdateConn)


-- === ОКНО КАСТОМИЗАЦИИ ===
local CustomizeFrame = Instance.new("Frame")
CustomizeFrame.Name = "CustomizeFrame"
CustomizeFrame.Parent = MainFrame 
CustomizeFrame.BackgroundColor3 = c_Background
CustomizeFrame.BorderColor3 = c_Font
CustomizeFrame.BorderSizePixel = 2
CustomizeFrame.Position = UDim2.new(0, -224, 0, 0) 
CustomizeFrame.Size = UDim2.new(0, 220, 0, 320)
CustomizeFrame.Visible = false

local CustTitleBar = Instance.new("Frame")
CustTitleBar.Parent = CustomizeFrame
CustTitleBar.BackgroundColor3 = c_Title
CustTitleBar.BorderColor3 = c_Font
CustTitleBar.BorderSizePixel = 1
CustTitleBar.Position = UDim2.new(0, 2, 0, 2)
CustTitleBar.Size = UDim2.new(1, -4, 0, 20)

local Cust_Title = Instance.new("TextLabel")
Cust_Title.Parent = CustTitleBar
Cust_Title.BackgroundTransparency = 1.000
Cust_Title.Size = UDim2.new(1, 0, 1, 0)
Cust_Title.Font = mainFont
Cust_Title.Text = "НАСТРОЙКА ЦВЕТОВ"
Cust_Title.TextColor3 = c_Background
Cust_Title.TextSize = 14.000
Cust_Title.TextXAlignment = Enum.TextXAlignment.Center

local Cust_Container = Instance.new("ScrollingFrame")
Cust_Container.Parent = CustomizeFrame
Cust_Container.BackgroundColor3 = c_Background
Cust_Container.Position = UDim2.new(0, 4, 0, 26)
Cust_Container.Size = UDim2.new(1, -8, 1, -30)
Cust_Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Cust_Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Cust_Container.ScrollBarThickness = 12
Cust_Container.ScrollBarImageColor3 = c_Button
Cust_Container.BorderColor3 = c_Font
Cust_Container.BorderSizePixel = 1

local Cust_ListLayout = Instance.new("UIListLayout")
Cust_ListLayout.Parent = Cust_Container
Cust_ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
Cust_ListLayout.Padding = UDim.new(0, 4)

-- === ОКНО КОНФИГУРАЦИЙ (CONFIG MANAGER) ===
local ConfigFrame = Instance.new("Frame")
ConfigFrame.Name = "ConfigFrame"
ConfigFrame.Parent = MainFrame 
ConfigFrame.BackgroundColor3 = c_Background
ConfigFrame.BorderColor3 = c_Font
ConfigFrame.BorderSizePixel = 2
ConfigFrame.Position = UDim2.new(1, 4, 0, 0) 
ConfigFrame.Size = UDim2.new(0, 220, 0, 380)
ConfigFrame.Visible = false

local ConfigTitleBar = Instance.new("Frame")
ConfigTitleBar.Parent = ConfigFrame
ConfigTitleBar.BackgroundColor3 = c_Title
ConfigTitleBar.BorderColor3 = c_Font
ConfigTitleBar.BorderSizePixel = 1
ConfigTitleBar.Position = UDim2.new(0, 2, 0, 2)
ConfigTitleBar.Size = UDim2.new(1, -4, 0, 20)

local Config_Title = Instance.new("TextLabel")
Config_Title.Parent = ConfigTitleBar
Config_Title.BackgroundTransparency = 1.000
Config_Title.Size = UDim2.new(1, 0, 1, 0)
Config_Title.Font = mainFont
Config_Title.Text = "МЕНЕДЖЕР КОНФИГОВ"
Config_Title.TextColor3 = c_Background
Config_Title.TextSize = 14.000
Config_Title.TextXAlignment = Enum.TextXAlignment.Center

local Config_Container = Instance.new("ScrollingFrame")
Config_Container.Parent = ConfigFrame
Config_Container.BackgroundColor3 = c_Background
Config_Container.Position = UDim2.new(0, 4, 0, 26)
Config_Container.Size = UDim2.new(1, -8, 1, -30)
Config_Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Config_Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Config_Container.ScrollBarThickness = 12
Config_Container.ScrollBarImageColor3 = c_Button
Config_Container.BorderColor3 = c_Font
Config_Container.BorderSizePixel = 1

local Config_ListLayout = Instance.new("UIListLayout")
Config_ListLayout.Parent = Config_Container
Config_ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
Config_ListLayout.Padding = UDim.new(0, 4)

-- === ОКНО ВЫБОРА КОМАНД (ДЛЯ РЕЖИМА SELECT) ===
local TeamSelectFrame = Instance.new("Frame")
TeamSelectFrame.Name = "TeamSelectFrame"
TeamSelectFrame.Parent = MainFrame 
TeamSelectFrame.BackgroundColor3 = c_Background
TeamSelectFrame.BorderColor3 = c_Font
TeamSelectFrame.BorderSizePixel = 2
TeamSelectFrame.Position = UDim2.new(1, 4, 0, 0) 
TeamSelectFrame.Size = UDim2.new(0, 220, 0, 320)
TeamSelectFrame.Visible = false

local TSTitleBar = Instance.new("Frame")
TSTitleBar.Parent = TeamSelectFrame
TSTitleBar.BackgroundColor3 = c_Title
TSTitleBar.BorderColor3 = c_Font
TSTitleBar.BorderSizePixel = 1
TSTitleBar.Position = UDim2.new(0, 2, 0, 2)
TSTitleBar.Size = UDim2.new(1, -4, 0, 20)

local TS_Title = Instance.new("TextLabel")
TS_Title.Parent = TSTitleBar
TS_Title.BackgroundTransparency = 1.000
TS_Title.Size = UDim2.new(1, 0, 1, 0)
TS_Title.Font = mainFont
TS_Title.Text = "ФИЛЬТР КОМАНД"
TS_Title.TextColor3 = c_Background
TS_Title.TextSize = 14.000
TS_Title.TextXAlignment = Enum.TextXAlignment.Center

local TS_Container = Instance.new("ScrollingFrame")
TS_Container.Parent = TeamSelectFrame
TS_Container.BackgroundColor3 = c_Background
TS_Container.Position = UDim2.new(0, 4, 0, 26)
TS_Container.Size = UDim2.new(1, -8, 1, -30)
TS_Container.CanvasSize = UDim2.new(0, 0, 0, 0)
TS_Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
TS_Container.ScrollBarThickness = 12
TS_Container.ScrollBarImageColor3 = c_Button
TS_Container.BorderColor3 = c_Font
TS_Container.BorderSizePixel = 1

local TS_ListLayout = Instance.new("UIListLayout")
TS_ListLayout.Parent = TS_Container
TS_ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TS_ListLayout.Padding = UDim.new(0, 4)

local function updateTeamDropdown()
    for _, child in ipairs(TS_Container:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") or (child:IsA("Frame") and child.Name == "Spacer") then 
            child:Destroy() 
        end
    end

    for _, team in ipairs(Teams:GetTeams()) do
        local tBtn = Instance.new("TextButton")
        tBtn.Parent = TS_Container
        tBtn.BackgroundColor3 = c_Button
        tBtn.BorderColor3 = c_Font
        tBtn.BorderSizePixel = 1
        tBtn.Size = UDim2.new(1, -4, 0, 22)
        tBtn.Font = mainFont
        tBtn.Text = "   " .. team.Name
        tBtn.TextColor3 = c_Font
        tBtn.TextSize = 13
        tBtn.TextXAlignment = Enum.TextXAlignment.Left

        local checkbox = Instance.new("Frame")
        checkbox.Parent = tBtn
        checkbox.BackgroundColor3 = c_Background
        checkbox.BorderColor3 = c_Font
        checkbox.BorderSizePixel = 1
        checkbox.Position = UDim2.new(0, 4, 0.5, -6)
        checkbox.Size = UDim2.new(0, 12, 0, 12)
        
        local statusFill = Instance.new("Frame")
        statusFill.Parent = checkbox
        statusFill.BackgroundColor3 = c_Title
        statusFill.BorderSizePixel = 0
        statusFill.Position = UDim2.new(0.2, 0, 0.2, 0)
        statusFill.Size = UDim2.new(0.6, 0, 0.6, 0)
        statusFill.Visible = ESP_Settings.TargetTeams[team.Name] or false

        local tConn = tBtn.MouseButton1Click:Connect(function()
            ESP_Settings.TargetTeams[team.Name] = not ESP_Settings.TargetTeams[team.Name]
            statusFill.Visible = ESP_Settings.TargetTeams[team.Name]
        end)
        table.insert(_G.PlayerESP_Connections, tConn)
    end
end

table.insert(_G.PlayerESP_Connections, Teams.ChildAdded:Connect(updateTeamDropdown))
table.insert(_G.PlayerESP_Connections, Teams.ChildRemoved:Connect(updateTeamDropdown))

-- Элементы внутри окна конфигураций
local PathFrame = Instance.new("Frame")
PathFrame.Parent = Config_Container
PathFrame.BackgroundTransparency = 1
PathFrame.Size = UDim2.new(1, -6, 0, 36)

local PathLabel = Instance.new("TextLabel")
PathLabel.Parent = PathFrame
PathLabel.BackgroundTransparency = 1
PathLabel.Size = UDim2.new(1, 0, 0, 14)
PathLabel.Font = mainFont
PathLabel.Text = " Путь сохранения (папка):"
PathLabel.TextColor3 = c_Font
PathLabel.TextSize = 12
PathLabel.TextXAlignment = Enum.TextXAlignment.Left

local PathInput = Instance.new("TextBox")
PathInput.Parent = PathFrame
PathInput.BackgroundColor3 = c_Background
PathInput.BorderColor3 = c_Font
PathInput.BorderSizePixel = 1
PathInput.Position = UDim2.new(0, 4, 0, 16)
PathInput.Size = UDim2.new(1, -8, 0, 18)
PathInput.Font = mainFont
PathInput.Text = "PlayerESP_Configs"
PathInput.TextColor3 = c_Font
PathInput.TextSize = 12
PathInput.TextXAlignment = Enum.TextXAlignment.Left
PathInput.ClearTextOnFocus = false

local NameFrame = Instance.new("Frame")
NameFrame.Parent = Config_Container
NameFrame.BackgroundTransparency = 1
NameFrame.Size = UDim2.new(1, -6, 0, 36)

local NameLabel = Instance.new("TextLabel")
NameLabel.Parent = NameFrame
NameLabel.BackgroundTransparency = 1
NameLabel.Size = UDim2.new(1, 0, 0, 14)
NameLabel.Font = mainFont
NameLabel.Text = " Имя файла конфига:"
NameLabel.TextColor3 = c_Font
NameLabel.TextSize = 12
NameLabel.TextXAlignment = Enum.TextXAlignment.Left

local NameInput = Instance.new("TextBox")
NameInput.Parent = NameFrame
NameInput.BackgroundColor3 = c_Background
NameInput.BorderColor3 = c_Font
NameInput.BorderSizePixel = 1
NameInput.Position = UDim2.new(0, 4, 0, 16)
NameInput.Size = UDim2.new(1, -8, 0, 18)
NameInput.Font = mainFont
NameInput.Text = "default"
NameInput.TextColor3 = c_Font
NameInput.TextSize = 12
NameInput.TextXAlignment = Enum.TextXAlignment.Left
NameInput.ClearTextOnFocus = false

local SaveConfigBtn = Instance.new("TextButton")
SaveConfigBtn.Parent = Config_Container
SaveConfigBtn.BackgroundColor3 = c_Button
SaveConfigBtn.BorderColor3 = c_Font
SaveConfigBtn.BorderSizePixel = 1
SaveConfigBtn.Size = UDim2.new(1, -6, 0, 22)
SaveConfigBtn.Font = mainFont
SaveConfigBtn.Text = "Сохранить конфиг"
SaveConfigBtn.TextColor3 = c_Font
SaveConfigBtn.TextSize = 13

local ListLabel = Instance.new("TextLabel")
ListLabel.Parent = Config_Container
ListLabel.BackgroundTransparency = 1
ListLabel.Size = UDim2.new(1, -6, 0, 14)
ListLabel.Font = mainFont
ListLabel.Text = " Список доступных КФГ:"
ListLabel.TextColor3 = c_Font
ListLabel.TextSize = 12
ListLabel.TextXAlignment = Enum.TextXAlignment.Left

local FileListFrame = Instance.new("ScrollingFrame")
FileListFrame.Parent = Config_Container
FileListFrame.BackgroundColor3 = c_Background
FileListFrame.BorderColor3 = c_Font
FileListFrame.BorderSizePixel = 1
FileListFrame.Size = UDim2.new(1, -6, 0, 90)
FileListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
FileListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
FileListFrame.ScrollBarThickness = 8
FileListFrame.ScrollBarImageColor3 = c_Button

local FileListLayout = Instance.new("UIListLayout")
FileListLayout.Parent = FileListFrame
FileListLayout.SortOrder = Enum.SortOrder.LayoutOrder
FileListLayout.Padding = UDim.new(0, 2)

local LoadConfigBtn = Instance.new("TextButton")
LoadConfigBtn.Parent = Config_Container
LoadConfigBtn.BackgroundColor3 = c_Button
LoadConfigBtn.BorderColor3 = c_Font
LoadConfigBtn.BorderSizePixel = 1
LoadConfigBtn.Size = UDim2.new(1, -6, 0, 22)
LoadConfigBtn.Font = mainFont
LoadConfigBtn.Text = "Загрузить конфиг"
LoadConfigBtn.TextColor3 = c_Font
LoadConfigBtn.TextSize = 13

local DeleteConfigBtn = Instance.new("TextButton")
DeleteConfigBtn.Parent = Config_Container
DeleteConfigBtn.BackgroundColor3 = c_Button
DeleteConfigBtn.BorderColor3 = c_Font
DeleteConfigBtn.BorderSizePixel = 1
DeleteConfigBtn.Size = UDim2.new(1, -6, 0, 22)
DeleteConfigBtn.Font = mainFont
DeleteConfigBtn.Text = "Удалить конфиг"
DeleteConfigBtn.TextColor3 = Color3.fromRGB(168, 0, 0)
DeleteConfigBtn.TextSize = 13

local selectedConfigPath = ""

local function refreshConfigList()
    for _, child in ipairs(FileListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local folder = PathInput.Text
    if listfiles and pcall(function() return listfiles("") end) then
        if makefolder then pcall(function() makefolder(folder) end) end
        
        local files = {}
        pcall(function() files = listfiles(folder) end)
        
        for _, filepath in ipairs(files) do
            local filename = filepath:match("([^/^\\]+)$") or filepath
            if filename:sub(-5) == ".json" or filename:sub(-4) == ".cfg" or filename:sub(-4) == ".txt" then
                local fileBtn = Instance.new("TextButton")
                fileBtn.Parent = FileListFrame
                fileBtn.BackgroundColor3 = (selectedConfigPath == filepath) and c_Title or c_Button
                fileBtn.BorderColor3 = c_Font
                fileBtn.BorderSizePixel = 1
                fileBtn.Size = UDim2.new(1, -4, 0, 18)
                fileBtn.Font = mainFont
                fileBtn.Text = " " .. filename
                fileBtn.TextColor3 = (selectedConfigPath == filepath) and c_Background or c_Font
                fileBtn.TextSize = 12
                fileBtn.TextXAlignment = Enum.TextXAlignment.Left
                
                fileBtn.MouseButton1Click:Connect(function()
                    selectedConfigPath = filepath
                    NameInput.Text = filename:gsub("%.json$", ""):gsub("%.cfg$", ""):gsub("%.txt$", "")
                    refreshConfigList()
                end)
            end
        end
    end
end

PathInput.FocusLost:Connect(function() refreshConfigList() end)

SaveConfigBtn.MouseButton1Click:Connect(function()
    local folder = PathInput.Text
    local name = NameInput.Text
    if folder == "" or name == "" then return end
    
    if writefile then
        if makefolder then pcall(function() makefolder(folder) end) end
        local fullPath = folder .. "/" .. name .. ".json"
        local str = serializeSettings()
        local success = pcall(function() writefile(fullPath, str) end)
        if success then
            selectedConfigPath = fullPath
            refreshConfigList()
        end
    end
end)

LoadConfigBtn.MouseButton1Click:Connect(function()
    if selectedConfigPath ~= "" and readfile then
        local content
        local success = pcall(function() content = readfile(selectedConfigPath) end)
        if success and content then
            deserializeSettings(content)
        end
    end
end)

DeleteConfigBtn.MouseButton1Click:Connect(function()
    if selectedConfigPath ~= "" and delfile then
        local success = pcall(function() delfile(selectedConfigPath) end)
        if success then
            selectedConfigPath = ""
            refreshConfigList()
        end
    end
end)

refreshConfigList()

-- === COLOR PICKER GUI ===
local CP_Frame = Instance.new("Frame")
CP_Frame.Parent = ESP_GUI
CP_Frame.BackgroundColor3 = c_Background
CP_Frame.BorderColor3 = c_Font
CP_Frame.BorderSizePixel = 2
CP_Frame.Position = UDim2.new(0.5, -125, 0.5, -150)
CP_Frame.Size = UDim2.new(0, 250, 0, 330)
CP_Frame.Visible = false
CP_Frame.ZIndex = 10

local CP_TitleBar = Instance.new("Frame")
CP_TitleBar.Parent = CP_Frame
CP_TitleBar.BackgroundColor3 = c_Title
CP_TitleBar.BorderColor3 = c_Font
CP_TitleBar.BorderSizePixel = 1
CP_TitleBar.Position = UDim2.new(0, 2, 0, 2)
CP_TitleBar.Size = UDim2.new(1, -4, 0, 20)
CP_TitleBar.ZIndex = 11
drag(CP_Frame, CP_TitleBar)

local CP_Title = Instance.new("TextLabel")
CP_Title.Parent = CP_TitleBar
CP_Title.BackgroundTransparency = 1
CP_Title.Size = UDim2.new(1, -30, 1, 0)
CP_Title.Position = UDim2.new(0, 5, 0, 0)
CP_Title.Font = mainFont
CP_Title.Text = "RGB Color Picker"
CP_Title.TextColor3 = c_Background
CP_Title.TextSize = 14
CP_Title.TextXAlignment = Enum.TextXAlignment.Left
CP_Title.ZIndex = 11

local CP_CloseBtn = Instance.new("TextButton")
CP_CloseBtn.Parent = CP_TitleBar
CP_CloseBtn.BackgroundColor3 = c_Button
CP_CloseBtn.BorderColor3 = c_Font
CP_CloseBtn.BorderSizePixel = 1
CP_CloseBtn.Position = UDim2.new(1, -18, 0, 2)
CP_CloseBtn.Size = UDim2.new(0, 16, 0, 16)
CP_CloseBtn.Font = mainFont
CP_CloseBtn.Text = "X"
CP_CloseBtn.TextColor3 = c_Font
CP_CloseBtn.TextSize = 12
CP_CloseBtn.ZIndex = 12

local CP_Preview = Instance.new("Frame")
CP_Preview.Parent = CP_Frame
CP_Preview.BackgroundColor3 = Color3.new(1, 1, 1)
CP_Preview.BorderColor3 = c_Font
CP_Preview.BorderSizePixel = 1
CP_Preview.Position = UDim2.new(0, 10, 0, 35)
CP_Preview.Size = UDim2.new(0, 40, 0, 40)
CP_Preview.ZIndex = 11

local CP_RGBText = Instance.new("TextBox")
CP_RGBText.Parent = CP_Frame
CP_RGBText.BackgroundColor3 = c_Background
CP_RGBText.BorderColor3 = c_Font
CP_RGBText.BorderSizePixel = 1
CP_RGBText.Position = UDim2.new(0, 60, 0, 35)
CP_RGBText.Size = UDim2.new(1, -70, 0, 18)
CP_RGBText.Font = mainFont
CP_RGBText.Text = "rgb(255, 255, 255)"
CP_RGBText.TextColor3 = c_Font
CP_RGBText.TextSize = 12
CP_RGBText.TextXAlignment = Enum.TextXAlignment.Left
CP_RGBText.ClearTextOnFocus = false
CP_RGBText.ZIndex = 11

local CP_HexText = Instance.new("TextBox")
CP_HexText.Parent = CP_Frame
CP_HexText.BackgroundColor3 = c_Background
CP_HexText.BorderColor3 = c_Font
CP_HexText.BorderSizePixel = 1
CP_HexText.Position = UDim2.new(0, 60, 0, 57)
CP_HexText.Size = UDim2.new(1, -70, 0, 18)
CP_HexText.Font = mainFont
CP_HexText.Text = "#FFFFFF"
CP_HexText.TextColor3 = c_Font
CP_HexText.TextSize = 12
CP_HexText.TextXAlignment = Enum.TextXAlignment.Left
CP_HexText.ClearTextOnFocus = false
CP_HexText.ZIndex = 11

local CP_ColorMap = Instance.new("Frame")
CP_ColorMap.Parent = CP_Frame
CP_ColorMap.BackgroundColor3 = Color3.new(1, 0, 0)
CP_ColorMap.BorderColor3 = c_Font
CP_ColorMap.BorderSizePixel = 1
CP_ColorMap.Position = UDim2.new(0, 10, 0, 85)
CP_ColorMap.Size = UDim2.new(1, -20, 0, 180)
CP_ColorMap.ZIndex = 11

local CP_WhiteGradient = Instance.new("Frame")
CP_WhiteGradient.Parent = CP_ColorMap
CP_WhiteGradient.BackgroundColor3 = Color3.new(1, 1, 1)
CP_WhiteGradient.BorderSizePixel = 0
CP_WhiteGradient.Size = UDim2.new(1, 0, 1, 0)
CP_WhiteGradient.ZIndex = 12
local UIGradientW = Instance.new("UIGradient")
UIGradientW.Parent = CP_WhiteGradient
UIGradientW.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
UIGradientW.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
UIGradientW.Rotation = 0

local CP_BlackGradient = Instance.new("Frame")
CP_BlackGradient.Parent = CP_ColorMap
CP_BlackGradient.BackgroundColor3 = Color3.new(0, 0, 0)
CP_BlackGradient.BorderSizePixel = 0
CP_BlackGradient.Size = UDim2.new(1, 0, 1, 0)
CP_BlackGradient.ZIndex = 13
local UIGradientB = Instance.new("UIGradient")
UIGradientB.Parent = CP_BlackGradient
UIGradientB.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))
UIGradientB.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
UIGradientB.Rotation = 90

local CP_MapCursor = Instance.new("Frame")
CP_MapCursor.Parent = CP_ColorMap
CP_MapCursor.BackgroundColor3 = Color3.new(1, 1, 1)
CP_MapCursor.BorderColor3 = Color3.new(0, 0, 0)
CP_MapCursor.BorderSizePixel = 1
CP_MapCursor.Size = UDim2.new(0, 6, 0, 6)
CP_MapCursor.Position = UDim2.new(1, -3, 0, -3)
CP_MapCursor.ZIndex = 14

local CP_HueSlider = Instance.new("Frame")
CP_HueSlider.Parent = CP_Frame
CP_HueSlider.BackgroundColor3 = Color3.new(1, 1, 1)
CP_HueSlider.BorderColor3 = c_Font
CP_HueSlider.BorderSizePixel = 1
CP_HueSlider.Position = UDim2.new(0, 10, 0, 275)
CP_HueSlider.Size = UDim2.new(1, -20, 0, 20)
CP_HueSlider.ZIndex = 11

local UIGradientHue = Instance.new("UIGradient")
UIGradientHue.Parent = CP_HueSlider
UIGradientHue.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
})

local CP_HueCursor = Instance.new("Frame")
CP_HueCursor.Parent = CP_HueSlider
CP_HueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
CP_HueCursor.BorderColor3 = Color3.new(0, 0, 0)
CP_HueCursor.BorderSizePixel = 1
CP_HueCursor.Size = UDim2.new(0, 6, 1, 4)
CP_HueCursor.Position = UDim2.new(0, -3, 0, -2)
CP_HueCursor.ZIndex = 14

local activeColorSetting = nil
local activePreviewBox = nil
local currentHue, currentSat, currentVal = 1, 1, 1

local function rgbToHex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

local function updateColorPickerUI()
    local color = Color3.fromHSV(currentHue, currentSat, currentVal)
    CP_ColorMap.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
    CP_Preview.BackgroundColor3 = color
    
    local r, g, b = math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255)
    CP_RGBText.Text = "rgb(" .. r .. ", " .. g .. ", " .. b .. ")"
    CP_HexText.Text = rgbToHex(color)
    
    CP_MapCursor.Position = UDim2.new(currentSat, -3, 1 - currentVal, -3)
    CP_HueCursor.Position = UDim2.new(currentHue, -3, 0, -2)
    
    if activeColorSetting then
        ESP_Settings[activeColorSetting] = color
    end
    if activePreviewBox then
        activePreviewBox.BackgroundColor3 = color
    end
end

local function OpenColorPicker(settingKey, previewBox)
    activeColorSetting = settingKey
    activePreviewBox = previewBox
    
    local c = ESP_Settings[settingKey]
    currentHue, currentSat, currentVal = c:ToHSV()
    
    updateColorPickerUI()
    CP_Frame.Visible = true
end

CP_CloseBtn.MouseButton1Click:Connect(function()
    CP_Frame.Visible = false
    activeColorSetting = nil
    activePreviewBox = nil
end)

local function HandleMapInput(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseMovement then
        local pos = input.Position
        local relativeX = math.clamp((pos.X - CP_ColorMap.AbsolutePosition.X) / CP_ColorMap.AbsoluteSize.X, 0, 1)
        local relativeY = math.clamp((pos.Y - CP_ColorMap.AbsolutePosition.Y) / CP_ColorMap.AbsoluteSize.Y, 0, 1)
        currentSat = relativeX
        currentVal = 1 - relativeY
        updateColorPickerUI()
    end
end

local function HandleHueInput(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseMovement then
        local pos = input.Position
        local relativeX = math.clamp((pos.X - CP_HueSlider.AbsolutePosition.X) / CP_HueSlider.AbsoluteSize.X, 0, 1)
        currentHue = relativeX
        updateColorPickerUI()
    end
end

local mapDragging = false
CP_ColorMap.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mapDragging = true
        HandleMapInput(input)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mapDragging = false
        hueDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if mapDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        HandleMapInput(input)
    elseif hueDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        HandleHueInput(input)
    end
end)

local hueDragging = false
CP_HueSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        hueDragging = true
        HandleHueInput(input)
    end
end)

local function createColorInput(name, settingKey)
    local frame = Instance.new("Frame")
    frame.Parent = Cust_Container
    frame.BackgroundColor3 = c_Background
    frame.BorderColor3 = c_Font
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, -6, 0, 36)
    
    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 2, 0, 0)
    title.Size = UDim2.new(1, -4, 0.5, 0)
    title.Font = mainFont
    title.Text = name
    title.TextColor3 = c_Font
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left

    local previewBox = Instance.new("Frame")
    previewBox.Parent = frame
    previewBox.BackgroundColor3 = ESP_Settings[settingKey]
    previewBox.BorderColor3 = c_Font
    previewBox.BorderSizePixel = 1
    previewBox.Position = UDim2.new(0, 2, 0.5, 2)
    previewBox.Size = UDim2.new(0, 16, 0, 14)

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundColor3 = c_Button
    btn.BorderColor3 = c_Font
    btn.BorderSizePixel = 1
    btn.Position = UDim2.new(0, 24, 0.5, 2)
    btn.Size = UDim2.new(1, -28, 0, 14)
    btn.Font = mainFont
    btn.Text = "[ Choose Color ]"
    btn.TextColor3 = c_Font
    btn.TextSize = 12
    
    local conn = btn.MouseButton1Click:Connect(function()
        OpenColorPicker(settingKey, previewBox)
    end)
    table.insert(_G.PlayerESP_Connections, conn)
end


-- === МЕНЮ: ЭЛЕМЕНТЫ СОЗДАНИЯ (ТОГГЛЫ И Т.Д.) ===
local function createToggle(name, settingKey)
    local btn = Instance.new("TextButton")
    btn.Parent = Container
    btn.BackgroundColor3 = c_Button
    btn.BorderColor3 = c_Font
    btn.BorderSizePixel = 1
    btn.Size = UDim2.new(1, -6, 0, 22)
    btn.Font = mainFont
    btn.Text = "   " .. name
    btn.TextColor3 = c_Font
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local statusBox = Instance.new("Frame")
    statusBox.Parent = btn
    statusBox.BackgroundColor3 = c_Background
    statusBox.BorderColor3 = c_Font
    statusBox.BorderSizePixel = 1
    statusBox.Position = UDim2.new(0, 4, 0.5, -6)
    statusBox.Size = UDim2.new(0, 12, 0, 12)

    local statusFill = Instance.new("Frame")
    statusFill.Parent = statusBox
    statusFill.BackgroundColor3 = c_Title
    statusFill.BorderSizePixel = 0
    statusFill.Position = UDim2.new(0.2, 0, 0.2, 0)
    statusFill.Size = UDim2.new(0.6, 0, 0.6, 0)
    statusFill.Visible = ESP_Settings[settingKey] or false

    toggleVisuals[settingKey] = statusFill

    local conn = btn.MouseButton1Click:Connect(function()
        ESP_Settings[settingKey] = not ESP_Settings[settingKey]
        statusFill.Visible = ESP_Settings[settingKey]
    end)
    table.insert(_G.PlayerESP_Connections, conn)
end

local function updateToggleVisual(settingKey)
    if toggleVisuals[settingKey] then
        toggleVisuals[settingKey].Visible = ESP_Settings[settingKey]
    end
end

local function createModeCycle(name, settingKey, optionsArray, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = Container
    btn.BackgroundColor3 = c_Button
    btn.BorderColor3 = c_Font
    btn.BorderSizePixel = 1
    btn.Size = UDim2.new(1, -6, 0, 22)
    btn.Font = mainFont
    btn.Text = " " .. name .. ": " .. optionsArray[ESP_Settings[settingKey]]
    btn.TextColor3 = c_Title
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left

    modeCycleButtons[settingKey] = {btn = btn, name = name, options = optionsArray}

    local conn = btn.MouseButton1Click:Connect(function()
        local current = ESP_Settings[settingKey]
        current = current + 1
        if current > #optionsArray then current = 1 end
        ESP_Settings[settingKey] = current
        btn.Text = " " .. name .. ": " .. optionsArray[current]
        
        if callback then callback(current) end
    end)
    table.insert(_G.PlayerESP_Connections, conn)
end

local function createInputField(name, settingKey, min, max, isFloat)
    local frame = Instance.new("Frame")
    frame.Parent = Container
    frame.BackgroundColor3 = c_Background
    frame.BorderColor3 = c_Font
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, -6, 0, 24)
    
    local title = Instance.new("TextLabel")
    title.Parent = frame
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 2, 0, 0)
    title.Size = UDim2.new(0.65, -10, 1, 0)
    title.Font = mainFont
    title.Text = name
    title.TextColor3 = c_Font
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    local input = Instance.new("TextBox")
    input.Parent = frame
    input.BackgroundColor3 = c_Background
    input.BorderColor3 = c_Font
    input.BorderSizePixel = 1
    input.Position = UDim2.new(0.65, 0, 0.15, 0)
    input.Size = UDim2.new(0.3, 0, 0.7, 0)
    input.Font = mainFont
    input.Text = tostring(ESP_Settings[settingKey])
    input.TextColor3 = c_Font
    input.TextSize = 13
    input.ClipsDescendants = true
    
    inputTextBoxes[settingKey] = input
    
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

local function createKeybindField(name, settingKey)
    local btn = Instance.new("TextButton")
    btn.Parent = Container
    btn.BackgroundColor3 = c_Button
    btn.BorderColor3 = c_Font
    btn.BorderSizePixel = 1
    btn.Size = UDim2.new(1, -6, 0, 22)
    btn.Font = mainFont
    btn.Text = " " .. name .. ": [" .. tostring(ESP_Settings[settingKey]) .. "]"
    btn.TextColor3 = c_Font
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left

    bindButtons[settingKey] = btn

    local conn = btn.MouseButton1Click:Connect(function()
        bindingFor = settingKey
        btn.Text = " " .. name .. ": [...]"
        btn.TextColor3 = c_Title
    end)
    table.insert(_G.PlayerESP_Connections, conn)
end

local globalBindConn = UserInputService.InputBegan:Connect(function(input, processed)
    if bindingFor and not processed then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyName = input.KeyCode.Name
            ESP_Settings[bindingFor] = keyName
            
            local displayName = (bindingFor == "NoclipKey") and "Bind Noclip" or "Bind Fly"
            if bindButtons[bindingFor] then
                bindButtons[bindingFor].Text = " " .. displayName .. ": [" .. keyName .. "]"
                bindButtons[bindingFor].TextColor3 = c_Font
            end
            bindingFor = nil
        end
    elseif not bindingFor and not processed then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyName = input.KeyCode.Name
            if keyName == ESP_Settings.NoclipKey and ESP_Settings.NoclipKey ~= "NONE" then
                ESP_Settings.Noclip = not ESP_Settings.Noclip
                updateToggleVisual("Noclip")
            elseif keyName == ESP_Settings.FlyKey and ESP_Settings.FlyKey ~= "NONE" then
                ESP_Settings.Fly = not ESP_Settings.Fly
                updateToggleVisual("Fly")
            end
        end
    end
end)
table.insert(_G.PlayerESP_Connections, globalBindConn)

-- === СОЗДАНИЕ КНОПОК МЕНЮ ===
createToggle("Master Switch", "Enabled")
createToggle("Team Check", "TeamCheck")

createModeCycle("TC Mode", "TeamCheckMode", TC_Modes, function(currentIndex)
    if TeamSelectFrame then
        TeamSelectFrame.Visible = (currentIndex == 6)
        if currentIndex == 6 then
            updateTeamDropdown()
            if ConfigFrame then ConfigFrame.Visible = false end 
        end
    end
end)
TeamSelectFrame.Visible = (ESP_Settings.TeamCheckMode == 6)
if ESP_Settings.TeamCheckMode == 6 then updateTeamDropdown() end

createToggle("CModel Mode", "CModelMode")
createModeCycle("CM Mode", "CModelModeType", CM_Modes)
createToggle("Wall Check", "WallCheck")
createToggle("Show Boxes", "Box")
createToggle("Show Name", "ShowName")
createToggle("Show Distance", "ShowDistance")
createToggle("Health Bar", "HealthBar")

createToggle("Chams", "Chams")
local Chams_ModesArray = {"Highlight", "Adornments"}
createModeCycle("Chams Mode", "ChamsMode", Chams_ModesArray)

createInputField("Chams Fill %", "ChamsFillAlpha", 0, 1, true)
createInputField("Chams Outline %", "ChamsOutlineAlpha", 0, 1, true)
createToggle("Tracers", "Tracers")
createInputField("Tracer Thick", "TracerThickness", 1, 10, false)
createInputField("Tracer Trans", "TracerTransparency", 0, 1, true)

local extraSpacer = Instance.new("Frame")
extraSpacer.Parent = Container
extraSpacer.BackgroundTransparency = 1
extraSpacer.Size = UDim2.new(1, 0, 0, 5)

-- Кнопка для включения/выключения Bind List
createToggle("Show Bind List", "BindList")

createToggle("Noclip", "Noclip")
createKeybindField("Bind Noclip", "NoclipKey")

createToggle("Fly", "Fly")
createInputField("Fly Speed", "FlySpeed", 0.1, 50, true)
createKeybindField("Bind Fly", "FlyKey")

createToggle("WalkSpeed", "WalkSpeedEnabled")
createInputField("Speed Value", "WalkSpeed", 0, 500, true)

-- Кнопки в самом низу
local function killScript()
    ESP_Settings.Enabled = false
    ESP_Settings.Fly = false
    ESP_Settings.Noclip = false
    ESP_Settings.WalkSpeedEnabled = false
    
    if _G.PlayerESP_Drawings then
        for _, draw in ipairs(_G.PlayerESP_Drawings) do pcall(function() draw:Remove() end) end
    end
    if _G.PlayerESP_Highlights then
        for _, hl in ipairs(_G.PlayerESP_Highlights) do pcall(function() hl:Destroy() end) end
    end
    if _G.PlayerESP_Connections then
        for _, conn in pairs(_G.PlayerESP_Connections) do pcall(function() conn:Disconnect() end) end
    end
    
    if localPlayer.Character then
        local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16; hum.PlatformStand = false end
        for _, child in pairs(localPlayer.Character:GetDescendants()) do
            if child:IsA("BasePart") then child.CanCollide = true end
        end
    end
    if ESP_GUI then ESP_GUI:Destroy() end
end

local Spacer = Instance.new("Frame")
Spacer.Parent = Container
Spacer.BackgroundTransparency = 1
Spacer.Size = UDim2.new(1, 0, 0, 5)

local killBtn = Instance.new("TextButton")
killBtn.Parent = Container
killBtn.BackgroundColor3 = c_Button
killBtn.BorderColor3 = c_Font
killBtn.BorderSizePixel = 1
killBtn.Size = UDim2.new(1, -6, 0, 22)
killBtn.Font = mainFont
killBtn.Text = "Kill Script"
killBtn.TextColor3 = Color3.fromRGB(168, 0, 0)
killBtn.TextSize = 13
local killConn = killBtn.MouseButton1Click:Connect(function() killScript() end)
table.insert(_G.PlayerESP_Connections, killConn)

local custBtn = Instance.new("TextButton")
custBtn.Parent = Container
custBtn.BackgroundColor3 = c_Button
custBtn.BorderColor3 = c_Font
custBtn.BorderSizePixel = 1
custBtn.Size = UDim2.new(1, -6, 0, 22)
custBtn.Font = mainFont
custBtn.Text = "Customize GUI"
custBtn.TextColor3 = c_Font
custBtn.TextSize = 13
local custConn = custBtn.MouseButton1Click:Connect(function() 
    CustomizeFrame.Visible = not CustomizeFrame.Visible 
end)
table.insert(_G.PlayerESP_Connections, custConn)

local configBtn = Instance.new("TextButton")
configBtn.Parent = Container
configBtn.BackgroundColor3 = c_Button
configBtn.BorderColor3 = c_Font
configBtn.BorderSizePixel = 1
configBtn.Size = UDim2.new(1, -6, 0, 22)
configBtn.Font = mainFont
configBtn.Text = "Config Menu"
configBtn.TextColor3 = c_Font
configBtn.TextSize = 13
local configConn = configBtn.MouseButton1Click:Connect(function() 
    ConfigFrame.Visible = not ConfigFrame.Visible 
    if ConfigFrame.Visible then 
        refreshConfigList() 
        if TeamSelectFrame then TeamSelectFrame.Visible = false end
    end
end)
table.insert(_G.PlayerESP_Connections, configConn)

-- === ЗАПОЛНЕНИЕ МЕНЮ КАСТОМИЗАЦИИ ===
createColorInput("Box Color", "ColorBox")
createColorInput("Box Color (Wallcheck)", "ColorBoxVis")
createColorInput("Chams Color", "ColorChams")
createColorInput("Chams Color (Wallcheck)", "ColorChamsVis")
createColorInput("Tracers Color", "ColorTracer")
createColorInput("Friends Color", "ColorFriend")

local uiToggleConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        MainFrame.Visible = not MainFrame.Visible
        if not MainFrame.Visible then 
            CP_Frame.Visible = false 
            ConfigFrame.Visible = false
            CustomizeFrame.Visible = false
            if TeamSelectFrame then TeamSelectFrame.Visible = false end
        end
    end
end)
table.insert(_G.PlayerESP_Connections, uiToggleConn)

-- === ЛОГИКА ДВИЖЕНИЯ ===
local FlyKeys = {W = false, A = false, S = false, D = false, Q = false, E = false}
local flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.W then FlyKeys.W = true
    elseif input.KeyCode == Enum.KeyCode.S then FlyKeys.S = true
    elseif input.KeyCode == Enum.KeyCode.A then FlyKeys.A = true
    elseif input.KeyCode == Enum.KeyCode.D then FlyKeys.D = true
    elseif input.KeyCode == Enum.KeyCode.Q then FlyKeys.Q = true
    elseif input.KeyCode == Enum.KeyCode.E then FlyKeys.E = true end
end)
local flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.W then FlyKeys.W = false
    elseif input.KeyCode == Enum.KeyCode.S then FlyKeys.S = false
    elseif input.KeyCode == Enum.KeyCode.A then FlyKeys.A = false
    elseif input.KeyCode == Enum.KeyCode.D then FlyKeys.D = false
    elseif input.KeyCode == Enum.KeyCode.Q then FlyKeys.Q = false
    elseif input.KeyCode == Enum.KeyCode.E then FlyKeys.E = false end
end)
table.insert(_G.PlayerESP_Connections, flyKeyDown)
table.insert(_G.PlayerESP_Connections, flyKeyUp)

local flyAndNoclipConn = RunService.Stepped:Connect(function()
    if ESP_Settings.Noclip and localPlayer.Character then
        for _, child in pairs(localPlayer.Character:GetDescendants()) do
            if child:IsA("BasePart") and child.CanCollide then child.CanCollide = false end
        end
    end
    if localPlayer.Character then
        local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if ESP_Settings.WalkSpeedEnabled and hum then hum.WalkSpeed = ESP_Settings.WalkSpeed end
        if hrp then
            if ESP_Settings.Fly then
                if not hrp:FindFirstChild("IY_FlyGyro") then
                    local bg = Instance.new("BodyGyro"); bg.Name = "IY_FlyGyro"; bg.P = 9e4; bg.maxTorque = Vector3.new(9e9, 9e9, 9e9); bg.cframe = hrp.CFrame; bg.Parent = hrp
                    local bv = Instance.new("BodyVelocity"); bv.Name = "IY_FlyVel"; bv.velocity = Vector3.new(0, 0, 0); bv.maxForce = Vector3.new(9e9, 9e9, 9e9); bv.Parent = hrp
                    if hum then hum.PlatformStand = true end
                end
                local bg = hrp:FindFirstChild("IY_FlyGyro"); local bv = hrp:FindFirstChild("IY_FlyVel")
                if bg and bv then
                    local camCFrame = camera.CoordinateFrame
                    local speed = ESP_Settings.FlySpeed * 50 
                    local moveDir = Vector3.new((FlyKeys.D and 1 or 0) - (FlyKeys.A and 1 or 0), (FlyKeys.E and 1 or 0) - (FlyKeys.Q and 1 or 0), (FlyKeys.S and 1 or 0) - (FlyKeys.W and 1 or 0))
                    bg.cframe = camCFrame
                    if moveDir.Magnitude > 0 then bv.velocity = camCFrame:VectorToWorldSpace(moveDir.Unit) * speed else bv.velocity = Vector3.new(0, 0, 0) end
                end
            else
                local bg = hrp:FindFirstChild("IY_FlyGyro"); local bv = hrp:FindFirstChild("IY_FlyVel")
                if bg then bg:Destroy() end; if bv then bv:Destroy() end
                if hum and hum.PlatformStand then hum.PlatformStand = false end
            end
        end
    end
end)
table.insert(_G.PlayerESP_Connections, flyAndNoclipConn)

local function hideESP(data)
    data.Box.Visible = false; data.NameText.Visible = false; data.HealthBar.Visible = false; data.HealthBarBG.Visible = false; data.Tracer.Visible = false
    if data.Chams then data.Chams.Enabled = false end
    if data.Adornments then for _, adorn in pairs(data.Adornments) do adorn.Visible = false end end
end

local function isTeammateCheck(player, character)
    if player == localPlayer then return true end
    local mode = ESP_Settings.TeamCheckMode; local lpChar = localPlayer.Character
    
    if mode == 1 then 
        if localPlayer.Team ~= nil and player.Team == localPlayer.Team then return true end
        if localPlayer.TeamColor ~= nil and player.TeamColor == localPlayer.TeamColor and not player.Neutral then return true end
    elseif mode == 2 then
        local lpTeam = localPlayer:GetAttribute("Team") or localPlayer:GetAttribute("Faction") or localPlayer:GetAttribute("Side") or localPlayer:GetAttribute("TeamID")
        local pTeam = player:GetAttribute("Team") or player:GetAttribute("Faction") or player:GetAttribute("Side") or player:GetAttribute("TeamID")
        if lpTeam and pTeam and lpTeam == pTeam then return true end
    elseif mode == 3 then
        if localPlayer.TeamColor == player.TeamColor then return true end
    elseif mode == 4 then
        local lpStats = localPlayer:FindFirstChild("leaderstats") or localPlayer:FindFirstChild("Data")
        local pStats = player:FindFirstChild("leaderstats") or player:FindFirstChild("Data")
        if lpStats and pStats then
            local lpT = lpStats:FindFirstChild("Team") or lpStats:FindFirstChild("Faction") or lpStats:FindFirstChild("TeamValue")
            local pT = pStats:FindFirstChild("Team") or pStats:FindFirstChild("Faction") or pStats:FindFirstChild("TeamValue")
            if lpT and pT and lpT.Value == pT.Value then return true end
        end
    elseif mode == 5 then
        local lpT = localPlayer:FindFirstChild("Team", true) or localPlayer:FindFirstChild("Faction", true)
        local pT = player:FindFirstChild("Team", true) or player:FindFirstChild("Faction", true)
        if lpT and pT and lpT.Value == pT.Value then return true end
        if character and localPlayer.Character then
            local lpCharT = localPlayer.Character:FindFirstChild("Team", true) or localPlayer.Character:FindFirstChild("Faction", true)
            local pCharT = character:FindFirstChild("Team", true) or character:FindFirstChild("Faction", true)
            if lpCharT and pCharT and lpCharT.Value == pCharT.Value then return true end
        end
    elseif mode == 6 then
        local tName = player.Team and player.Team.Name or ""
        if ESP_Settings.TargetTeams[tName] then 
            return false 
        else 
            return true 
        end
    end
    
    return false
end

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
        if not result then return true end
        local hitPart = result.Instance
        if hitPart.CanCollide == false or hitPart.Transparency == 1 or hitPart.Name == "HumanoidRootPart" then
            table.insert(ignoreList, hitPart); raycastParams.FilterDescendantsInstances = ignoreList; iterations = iterations + 1
        else return false end
    end
    return false 
end

local function createESP(player)
    if player == localPlayer then return nil end
    local data = {
        Player = player, FadeAlpha = 0,
        Box = Drawing.new("Square"), NameText = Drawing.new("Text"),
        HealthBarBG = Drawing.new("Square"), HealthBar = Drawing.new("Square"),
        Tracer = Drawing.new("Line"), Chams = Instance.new("Highlight")
    }
    data.Box.Visible = false; data.Box.Thickness = 1.5; data.Box.Filled = false; table.insert(_G.PlayerESP_Drawings, data.Box)
    data.NameText.Visible = false; data.NameText.Center = true; data.NameText.Outline = true; data.NameText.Size = 13; data.NameText.Font = 2; table.insert(_G.PlayerESP_Drawings, data.NameText)
    data.HealthBarBG.Visible = false; data.HealthBarBG.Color = Color3.fromRGB(0, 0, 0); data.HealthBarBG.Filled = true; table.insert(_G.PlayerESP_Drawings, data.HealthBarBG)
    data.HealthBar.Visible = false; data.HealthBar.Filled = true; table.insert(_G.PlayerESP_Drawings, data.HealthBar)
    data.Tracer.Visible = false; data.Tracer.Color = Color3.new(1, 1, 1); table.insert(_G.PlayerESP_Drawings, data.Tracer)
    data.Chams.Name = "Chams_" .. player.Name; data.Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; data.Chams.Enabled = false; data.Chams.Parent = ESP_GUI; table.insert(_G.PlayerESP_Highlights, data.Chams)
    data.Adornments = {}
    return data
end

for _, player in ipairs(Players:GetPlayers()) do if player ~= localPlayer then ESP_List[player] = createESP(player) end end
local addedConn = Players.PlayerAdded:Connect(function(player) if player ~= localPlayer then ESP_List[player] = createESP(player) end end)
table.insert(_G.PlayerESP_Connections, addedConn)
local removedConn = Players.PlayerRemoving:Connect(function(player) if ESP_List[player] then hideESP(ESP_List[player]); ESP_List[player] = nil end end)
table.insert(_G.PlayerESP_Connections, removedConn)

local function getPlayersArray()
    local arr = {}
    for p, data in pairs(ESP_List) do if p and p.Parent then table.insert(arr, p) else ESP_List[p] = nil end end
    return arr
end

local currentIndex = 1; local lastCheckTick = tick(); local checkInterval = 0.5
-- ==========================================
-- ОСНОВНЫЕ НАСТРОЙКИ И ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

-- Таблицы для безопасного удаления скрипта (Kill Script)
_G.PlayerESP_Drawings = _G.PlayerESP_Drawings or {}
_G.PlayerESP_Highlights = _G.PlayerESP_Highlights or {}
_G.PlayerESP_Connections = _G.PlayerESP_Connections or {}
_G.PlayerESP_Instances = _G.PlayerESP_Instances or {}

local ESP_Settings = {
    OreESP = false,
    ShowDistance = true, -- Новая настройка дистанции
    OreMaxDistance = 1500,
    OreTextSize = 14,
    OreTextTrans = 1,
}

local OreColors = {
    ["coal"]     = Color3.fromRGB(150, 150, 150),
    ["copper"]   = Color3.fromRGB(255, 140, 0),
    ["iron"]     = Color3.fromRGB(255, 255, 255),
    ["gold"]     = Color3.fromRGB(255, 215, 0),
    ["titan"]    = Color3.fromRGB(64, 224, 208),
    ["obsidian"] = Color3.fromRGB(128, 0, 128),
    ["diamond"]  = Color3.fromRGB(0, 191, 255),
    ["ruby"]     = Color3.fromRGB(255, 0, 0),
    ["emerald"]  = Color3.fromRGB(50, 205, 50),
    ["mythril"]  = Color3.fromRGB(0, 0, 255)
}

-- Добавляем настройки для каждой руды по умолчанию (все включены)
for key, _ in pairs(OreColors) do
    ESP_Settings["Show_" .. key] = true
end

-- ==========================================
-- СОЗДАНИЕ ИНТЕРФЕЙСА (GUI)
-- ==========================================
local ESP_GUI = Instance.new("ScreenGui")
ESP_GUI.Name = "CustomOreESP"
ESP_GUI.ResetOnSpawn = false
-- Пытаемся поместить в CoreGui для защиты, если не выйдет - в PlayerGui
local success = pcall(function() ESP_GUI.Parent = CoreGui end)
if not success then ESP_GUI.Parent = localPlayer:WaitForChild("PlayerGui") end
table.insert(_G.PlayerESP_Instances, ESP_GUI)

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ESP_GUI
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Position = UDim2.new(0, 50, 0, 50)
MainFrame.Size = UDim2.new(0, 250, 0, 480)
MainFrame.Active = true
MainFrame.Draggable = true

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.Code
Title.Text = "  Ore ESP Menu [Right Ctrl]"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Функция создания переключателей в меню
local function createToggle(text, settingKey)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.BackgroundColor3 = ESP_Settings[settingKey] and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
    btn.Size = UDim2.new(1, -10, 0, 25)
    btn.Position = UDim2.new(0, 5, 0, 0)
    btn.Font = Enum.Font.Code
    btn.Text = " " .. text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    
    btn.MouseButton1Click:Connect(function()
        ESP_Settings[settingKey] = not ESP_Settings[settingKey]
        btn.BackgroundColor3 = ESP_Settings[settingKey] and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
    end)
end

-- ==========================================
-- УПРАВЛЕНИЕ МЕНЮ И ЛОГИКА ORE ESP
-- ==========================================

-- Биндим закрытие/открытие меню на Правый Контрол
local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)
table.insert(_G.PlayerESP_Connections, inputConn)

-- Основные настройки
createToggle("Enable Ore ESP", "OreESP")
createToggle("Show Distance", "ShowDistance")

local OreTitle = Instance.new("TextLabel")
OreTitle.Parent = MainFrame
OreTitle.BackgroundTransparency = 1
OreTitle.Size = UDim2.new(1, 0, 0, 20)
OreTitle.Font = Enum.Font.Code
OreTitle.Text = " -- Select Ores --"
OreTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
OreTitle.TextSize = 14

-- Генерируем кнопки для каждой руды
for key, color in pairs(OreColors) do
    local displayName = string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
    createToggle("Show " .. displayName, "Show_" .. key)
end

local OreCache = {}

local function GetOreData(name)
    local lowerName = string.lower(name)
    for key, color in pairs(OreColors) do
        if string.find(lowerName, key) then
            return key, color, string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
        end
    end
    return nil, nil, nil
end

local function addOre(instance)
    if not instance:IsA("BasePart") and not instance:IsA("Model") then return end
    
    local oreKey, oreColor, oreName = GetOreData(instance.Name)
    if oreKey then
        local textDraw = Drawing.new("Text")
        textDraw.Visible = false
        textDraw.Center = true
        textDraw.Outline = true
        textDraw.Font = 2
        
        local chams = Instance.new("Highlight")
        chams.FillColor = oreColor
        chams.OutlineColor = Color3.new(1, 1, 1)
        chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        chams.Parent = ESP_GUI
        chams.Adornee = instance
        chams.Enabled = false

        OreCache[instance] = { 
            Text = textDraw, 
            Chams = chams, 
            Key = oreKey,
            Type = oreName, 
            Color = oreColor 
        }
        
        table.insert(_G.PlayerESP_Drawings, textDraw)
        table.insert(_G.PlayerESP_Highlights, chams)
    end
end

-- Плавное сканирование существующих объектов, чтобы избежать зависаний
task.spawn(function()
    local descendants = workspace:GetDescendants()
    local processCount = 0
    
    for i = 1, #descendants do
        addOre(descendants[i])
        processCount = processCount + 1
        
        -- Делаем микро-паузу каждые 150 объектов
        if processCount % 150 == 0 then
            task.wait()
        end
    end
end)

-- Отслеживание появления и удаления
table.insert(_G.PlayerESP_Connections, workspace.DescendantAdded:Connect(addOre))
table.insert(_G.PlayerESP_Connections, workspace.DescendantRemoving:Connect(function(instance)
    if OreCache[instance] then
        OreCache[instance].Text:Remove()
        OreCache[instance].Chams:Destroy()
        OreCache[instance] = nil
    end
end))

-- Рендер ESP
local renderConn = RunService.RenderStepped:Connect(function()
    for instance, data in pairs(OreCache) do
        -- Проверяем включен ли общий ESP и включена ли конкретная руда
        if ESP_Settings.OreESP and ESP_Settings["Show_" .. data.Key] and instance.Parent ~= nil then
            local pos = instance:IsA("Model") and (instance.PrimaryPart and instance.PrimaryPart.Position or instance:GetBoundingBox().Position) or instance.Position
            local dist = (camera.CFrame.Position - pos).Magnitude
            
            if dist <= ESP_Settings.OreMaxDistance then
                local screenPos, onScreen = camera:WorldToViewportPoint(pos)
                if onScreen then
                    data.Text.Position = Vector2.new(screenPos.X, screenPos.Y)
                    
                    -- Проверка настройки отображения дистанции
                    if ESP_Settings.ShowDistance then
                        data.Text.Text = data.Type .. " [" .. math.floor(dist) .. "m]"
                    else
                        data.Text.Text = data.Type
                    end
                    
                    data.Text.Color = data.Color
                    data.Text.Size = ESP_Settings.OreTextSize
                    data.Text.Transparency = ESP_Settings.OreTextTrans
                    data.Text.Visible = true
                    
                    data.Chams.Enabled = true
                    data.Chams.FillTransparency = 0.5
                    data.Chams.OutlineTransparency = 0.2
                else
                    data.Text.Visible = false
                    data.Chams.Enabled = false
                end
            else
                data.Text.Visible = false
                data.Chams.Enabled = false
            end
        else
            data.Text.Visible = false
            data.Chams.Enabled = false
        end
    end
end)
table.insert(_G.PlayerESP_Connections, renderConn)

-- ==========================================
-- КНОПКА KILL SCRIPT (ОЧИСТКА)
-- ==========================================
local KillButton = Instance.new("TextButton")
KillButton.Parent = MainFrame
KillButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
KillButton.Size = UDim2.new(1, -10, 0, 30)
KillButton.Position = UDim2.new(0, 5, 0, 0)
KillButton.Font = Enum.Font.Code
KillButton.Text = "Kill Script"
KillButton.TextColor3 = Color3.new(1, 1, 1)
KillButton.TextSize = 16

KillButton.MouseButton1Click:Connect(function()
    -- Удаляем все Drawings (Тексты)
    for _, drawing in pairs(_G.PlayerESP_Drawings) do
        if drawing and drawing.Remove then drawing:Remove() end
    end
    -- Удаляем Highlights
    for _, highlight in pairs(_G.PlayerESP_Highlights) do
        if highlight and highlight.Destroy then highlight:Destroy() end
    end
    -- Отключаем события
    for _, connection in pairs(_G.PlayerESP_Connections) do
        if connection and connection.Disconnect then connection:Disconnect() end
    end
    -- Удаляем GUI
    for _, instance in pairs(_G.PlayerESP_Instances) do
        if instance and instance.Destroy then instance:Destroy() end
    end
    
    -- Очищаем таблицы
    _G.PlayerESP_Drawings = {}
    _G.PlayerESP_Highlights = {}
    _G.PlayerESP_Connections = {}
    _G.PlayerESP_Instances = {}
    OreCache = {}
end)
local renderConn = RunService.RenderStepped:Connect(function(deltaTime)
    local currentTime = tick(); local playersArr = getPlayersArray()
    if currentTime - lastCheckTick >= (checkInterval / math.max(#playersArr, 1)) then
        lastCheckTick = currentTime
        if #playersArr > 0 then
            currentIndex = (currentIndex % #playersArr) + 1
            local targetPlayer = playersArr[currentIndex]
            local data = ESP_List[targetPlayer]
            if targetPlayer and data then data.IsTeammate = isTeammateCheck(targetPlayer, targetPlayer.Character) end
        end
    end

    local viewportSize = camera.ViewportSize; local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

    for player, data in pairs(ESP_List) do
        local character = player.Character; local isTeammate = data.IsTeammate or false; local isFriend = ESP_Settings.Friends[player.Name:lower()] or false
        local shouldShow = ESP_Settings.Enabled and character and (isFriend or not (ESP_Settings.TeamCheck and isTeammate))
        local rootPos, headPos, legPos, targetPart
        local hum = character and character:FindFirstChildOfClass("Humanoid") or nil
        local isAlive = true
        if not character or not character:IsDescendantOf(workspace) or (hum and hum.Health <= 0) or (isAlive and not character:FindFirstChild("HumanoidRootPart") and not character.PrimaryPart) then isAlive = false end

        if not isAlive then shouldShow = false; data.FadeAlpha = 0; hideESP(data) end

        if shouldShow then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if ESP_Settings.CModelMode then
                local cmMode = ESP_Settings.CModelModeType
                if cmMode == 1 then
                    local cframe, size = character:GetBoundingBox()
                    if not cframe or size == Vector3.new() then shouldShow = false else
                        rootPos = cframe.Position; targetPart = hrp or character.PrimaryPart
                        local heightY = math.max(size.Y, 2); headPos = rootPos + Vector3.new(0, heightY * 0.5, 0); legPos = rootPos - Vector3.new(0, heightY * 0.5, 0)
                    end
                elseif cmMode == 2 then
                    local root = character.PrimaryPart or hrp
                    if not root then shouldShow = false else
                        rootPos = root.Position; targetPart = root; local highestY, lowestY = rootPos.Y + 1, rootPos.Y - 2.5
                        local head = character:FindFirstChild("Head"); local lLeg = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
                        if head then highestY = head.Position.Y + (head.Size.Y * 0.5) end; if lLeg then lowestY = lLeg.Position.Y - (lLeg.Size.Y * 0.5) end
                        headPos = Vector3.new(rootPos.X, highestY, rootPos.Z); legPos = Vector3.new(rootPos.X, lowestY, rootPos.Z)
                    end
                elseif cmMode == 3 then
                    if not hrp then shouldShow = false else targetPart = hrp; rootPos = hrp.Position; headPos = rootPos + Vector3.new(0, 2.5, 0); legPos = rootPos - Vector3.new(0, 3, 0) end
                end
            else
                if not hrp or not hum then shouldShow = false else targetPart = hrp; rootPos = hrp.Position; local head = character:FindFirstChild("Head"); headPos = head and head.Position or (rootPos + Vector3.new(0, 2, 0)); legPos = rootPos - Vector3.new(0, 3, 0) end
            end
        end

        local vector, onScreen = nil, false
        if shouldShow and rootPos then vector, onScreen = camera:WorldToViewportPoint(rootPos); if not onScreen then shouldShow = false end end

        if shouldShow then data.FadeAlpha = math.clamp(data.FadeAlpha + (deltaTime * ESP_Settings.FadeSpeed), 0, 1) else data.FadeAlpha = math.clamp(data.FadeAlpha - (deltaTime * (ESP_Settings.FadeSpeed * 2)), 0, 1) end

        if data.FadeAlpha > 0.01 then
            local isVisible = false
            if ESP_Settings.WallCheck and targetPart and not isFriend then isVisible = checkVisibility(targetPart, character) end

            local activeBoxColor = ESP_Settings.ColorBox; local activeChamsColor = ESP_Settings.ColorChams
            if isFriend then activeBoxColor = ESP_Settings.ColorFriend; activeChamsColor = ESP_Settings.ColorFriend elseif ESP_Settings.WallCheck and isVisible then activeBoxColor = ESP_Settings.ColorBoxVis; activeChamsColor = ESP_Settings.ColorChamsVis end

            data.Box.Color = activeBoxColor; data.Box.Transparency = data.FadeAlpha; data.NameText.Color = isFriend and ESP_Settings.ColorFriend or activeBoxColor; data.NameText.Transparency = data.FadeAlpha; data.HealthBar.Transparency = data.FadeAlpha; data.HealthBarBG.Transparency = data.FadeAlpha

            if ESP_Settings.Chams or isFriend then 
                if ESP_Settings.ChamsMode == 1 then
                    if data.Chams.Adornee ~= character then data.Chams.Adornee = character end
                    data.Chams.FillColor = activeChamsColor; data.Chams.FillTransparency = ESP_Settings.ChamsFillAlpha + ((1 - ESP_Settings.ChamsFillAlpha) * (1 - data.FadeAlpha)); data.Chams.OutlineTransparency = ESP_Settings.ChamsOutlineAlpha + ((1 - ESP_Settings.ChamsOutlineAlpha) * (1 - data.FadeAlpha)); data.Chams.Enabled = true
                    for _, adorn in pairs(data.Adornments) do adorn.Visible = false end
                else
                    data.Chams.Enabled = false
                    for _, part in pairs(character:GetChildren()) do
                        if part:IsA("BasePart") then
                            if not data.Adornments[part] then
                                local box = Instance.new("BoxHandleAdornment"); box.Size = part.Size + Vector3.new(0.05, 0.05, 0.05); box.Adornee = part; box.AlwaysOnTop = true; box.ZIndex = 5; box.Transparency = ESP_Settings.ChamsFillAlpha + ((1 - ESP_Settings.ChamsFillAlpha) * (1 - data.FadeAlpha)); box.Color3 = activeChamsColor; box.Parent = ESP_GUI; data.Adornments[part] = box; table.insert(_G.PlayerESP_Highlights, box)
                            else local box = data.Adornments[part]; box.Size = part.Size + Vector3.new(0.05, 0.05, 0.05); box.Transparency = ESP_Settings.ChamsFillAlpha + ((1 - ESP_Settings.ChamsFillAlpha) * (1 - data.FadeAlpha)); box.Color3 = activeChamsColor; box.Visible = true end
                        end
                    end
                    for part, box in pairs(data.Adornments) do if not part or part.Parent ~= character then box.Visible = false; box:Destroy(); data.Adornments[part] = nil end end
                end
            else data.Chams.Enabled = false; for _, adorn in pairs(data.Adornments) do adorn.Visible = false end end

            if vector and headPos and legPos then
                local headScreen = camera:WorldToViewportPoint(headPos); local legScreen = camera:WorldToViewportPoint(legPos); local height = math.abs(headScreen.Y - legScreen.Y); local width = height / 2

                if ESP_Settings.Box then data.Box.Size = Vector2.new(width, height); data.Box.Position = Vector2.new(vector.X - width / 2, vector.Y - height / 2); data.Box.Visible = true else data.Box.Visible = false end

                if ESP_Settings.ShowName or ESP_Settings.ShowDistance then
                    local distStr = ESP_Settings.ShowDistance and " [" .. math.floor((camera.CFrame.Position - rootPos).Magnitude) .. "]" or ""
                    local nameStr = ESP_Settings.ShowName and player.Name or ""; local prefix = isFriend and "[FRIEND] " or ""
                    data.NameText.Text = prefix .. nameStr .. distStr; data.NameText.Position = Vector2.new(vector.X, vector.Y - height / 2 - 15); data.NameText.Visible = true
                else data.NameText.Visible = false end

                if ESP_Settings.HealthBar and hum then
                    local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1); if healthPct ~= healthPct then healthPct = 1 end 
                    data.HealthBarBG.Size = Vector2.new(2, height); data.HealthBarBG.Position = Vector2.new(vector.X - width / 2 - 5, vector.Y - height / 2); data.HealthBar.Size = Vector2.new(2, height * healthPct); data.HealthBar.Position = Vector2.new(vector.X - width / 2 - 5, (vector.Y - height / 2) + (height - (height * healthPct))); data.HealthBar.Color = Color3.fromHSV(healthPct * 0.3, 1, 1); data.HealthBarBG.Visible = true; data.HealthBar.Visible = true
                else data.HealthBarBG.Visible = false; data.HealthBar.Visible = false end

                if ESP_Settings.Tracers and onScreen then
                    data.Tracer.From = screenCenter; data.Tracer.To = Vector2.new(vector.X, vector.Y); data.Tracer.Color = isFriend and ESP_Settings.ColorFriend or ESP_Settings.ColorTracer; data.Tracer.Thickness = ESP_Settings.TracerThickness; data.Tracer.Transparency = (1 - ESP_Settings.TracerTransparency) * data.FadeAlpha; data.Tracer.Visible = true
                else data.Tracer.Visible = false end
            end
        else hideESP(data) end
    end
end)
table.insert(_G.PlayerESP_Connections, renderConn)
