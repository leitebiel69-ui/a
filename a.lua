--[[
    Nameless · Astra UI
    Place: 13132367906 (Delta)
    Toggle: RightShift
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local PLACE_ID = 13132367906
local PLACE_NAME = "Delta"

pcall(function()
	if getgenv and getgenv().NamelessUnload then getgenv().NamelessUnload() end
end)
pcall(function()
	local hui = (gethui and gethui()) or CoreGui
	for _, n in ipairs({ "AstraUI", "Nameless" }) do
		local g = hui:FindFirstChild(n)
		if g then g:Destroy() end
		local pg = LP:FindFirstChild("PlayerGui")
		if pg and pg:FindFirstChild(n) then pg[n]:Destroy() end
	end
end)

-------------------------------------------------------------------------------
-- Astra
-------------------------------------------------------------------------------
local Library
do
	local src = [=[
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"))()
end)

local function ResolveIcon(Icon)
	if type(Icon) == "number" then return "rbxassetid://" .. Icon end
	if type(Icon) == "string" then
		if string.match(Icon, "^rbxassetid://") then return Icon end
		if string.match(Icon, "^%d+$") then return "rbxassetid://" .. Icon end
		local Name = string.lower(Icon)
		if type(Lucide) == "function" then
			local ok, Data = pcall(Lucide, Name)
			if ok and type(Data) == "table" then
				local Id = Data.id or Data.Id or Data[1]
				local Size = Data.imageRectSize or Data.ImageRectSize or Data[2]
				local Offset = Data.imageRectOffset or Data.imageRectPosition or Data.ImageRectOffset or Data[3]
				if Id then return "rbxassetid://" .. tostring(Id), Offset, Size end
			end
		elseif type(Lucide) == "table" then
			for _, Set in { Lucide["48px"], Lucide["256px"], Lucide } do
				if type(Set) == "table" then
					local Data = Set[Name]
					if type(Data) == "table" and Data[1] then
						return "rbxassetid://" .. tostring(Data[1]), Data[3], Data[2]
					end
				end
			end
		end
	end
	return "rbxassetid://0"
end

local function ToVector2(Value)
	if typeof(Value) == "Vector2" then return Value end
	if type(Value) == "table" then return Vector2.new(Value[1] or Value.X or 0, Value[2] or Value.Y or 0) end
	return Vector2.new(0, 0)
end

local function ApplyIcon(Object, Icon)
	if not Icon then return end
	local Image, Offset, Size = ResolveIcon(Icon)
	Object.Image = Image
	if Offset then Object.ImageRectOffset = ToVector2(Offset) end
	if Size then Object.ImageRectSize = ToVector2(Size) end
end

local FONT_REGULAR = Font.new("rbxasset://fonts/families/PlusJakartaSans.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
local FONT_MEDIUM  = Font.new("rbxasset://fonts/families/PlusJakartaSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
local FONT_BOLD    = Font.new("rbxasset://fonts/families/PlusJakartaSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

local COLOR_BG           = Color3.fromRGB(12, 12, 14)
local COLOR_BORDER       = Color3.fromRGB(28, 28, 34)
local COLOR_TEXT_WHITE   = Color3.fromRGB(245, 245, 250)
local COLOR_TEXT_MUTED   = Color3.fromRGB(160, 160, 172)
local COLOR_TEXT_SUB     = Color3.fromRGB(90, 90, 102)
local COLOR_ACTIVE_BG    = Color3.fromRGB(22, 22, 28)
local COLOR_SEARCH_BG    = Color3.fromRGB(18, 18, 22)
local COLOR_CARD_BG      = Color3.fromRGB(16, 16, 20)
local COLOR_BOX_INACTIVE = Color3.fromRGB(22, 22, 28)
local COLOR_BOX_BORDER   = Color3.fromRGB(55, 55, 68)

local Library = {}
Library.__index = Library

local ConfigRegistry = {}
local AutoloadKey = "astra_autoload"

local function EnsureFolder(folderName)
	if not isfolder(folderName) then
		makefolder(folderName)
	end
end

local function SaveConfig(folderName, configName, data)
	EnsureFolder(folderName)
	local path = folderName .. "/" .. configName .. ".json"
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
	if ok then
		writefile(path, encoded)
		return true
	end
	return false
end

local function LoadConfig(folderName, configName)
	local path = folderName .. "/" .. configName .. ".json"
	if isfile(path) then
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(path))
		if ok then return decoded end
	end
	return nil
end

local function ListConfigs(folderName)
	EnsureFolder(folderName)
	local files = {}
	local ok, result = pcall(listfiles, folderName)
	if ok then
		for _, path in ipairs(result) do
			local name = string.match(path, "[/\\]([^/\\]+)%.json$")
			if name then
				table.insert(files, name)
			end
		end
	end
	return files
end

local function DeleteConfig(folderName, configName)
	local path = folderName .. "/" .. configName .. ".json"
	if isfile(path) then
		local ok = pcall(delfile, path)
		return ok
	end
	return false
end

local function GetAutoload(folderName)
	local path = folderName .. "/" .. AutoloadKey .. ".txt"
	if isfile(path) then
		return readfile(path)
	end
	return nil
end

local function SetAutoload(folderName, configName)
	EnsureFolder(folderName)
	local path = folderName .. "/" .. AutoloadKey .. ".txt"
	if configName then
		writefile(path, configName)
	else
		if isfile(path) then pcall(delfile, path) end
	end
end

local function CollectConfigData()
	local data = {}
	for key, entry in pairs(ConfigRegistry) do
		local ok, val = pcall(entry.Get)
		if ok then
			data[key] = val
		end
	end
	return data
end

local function ApplyConfigData(data)
	for key, val in pairs(data) do
		if ConfigRegistry[key] then
			local ok = pcall(ConfigRegistry[key].Set, val)
		end
	end
end

local ParentGui = LocalPlayer:WaitForChild("PlayerGui")
if gethui then
	ParentGui = gethui()
elseif syn and syn.protect_gui then
	local sg = Instance.new("ScreenGui")
	syn.protect_gui(sg)
	ParentGui = CoreGui
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AstraUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = ParentGui

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "NotificationContainer"
NotificationContainer.Size = UDim2.new(0, 260, 1, -40)
NotificationContainer.Position = UDim2.new(1, -20, 1, -20)
NotificationContainer.AnchorPoint = Vector2.new(1, 1)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.Parent = ScreenGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.Parent = NotificationContainer

local function Notify(config)
	config = config or {}
	local title = config.Title or "Notification"
	local text = config.Text or ""
	local icon = config.Icon or "bell"
	local duration = config.Duration or 3

	local NotifCard = Instance.new("Frame")
	NotifCard.Name = "Notification"
	NotifCard.Size = UDim2.new(1, 0, 0, 0)
	NotifCard.AutomaticSize = Enum.AutomaticSize.Y
	NotifCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NotifCard.BorderSizePixel = 0
	NotifCard.ClipsDescendants = true
	NotifCard.BackgroundTransparency = 1

	local NotifCorner = Instance.new("UICorner")
	NotifCorner.CornerRadius = UDim.new(0, 6)
	NotifCorner.Parent = NotifCard

	local NotifGradient = Instance.new("UIGradient")
	NotifGradient.Rotation = 90
	NotifGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20))
	})
	NotifGradient.Parent = NotifCard

	local NotifStroke = Instance.new("UIStroke")
	NotifStroke.Color = Color3.fromRGB(45, 45, 55)
	NotifStroke.Thickness = 1.2
	NotifStroke.Transparency = 1
	NotifStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	NotifStroke.Parent = NotifCard

	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0, 10)
	Padding.PaddingBottom = UDim.new(0, 18)
	Padding.PaddingLeft = UDim.new(0, 12)
	Padding.PaddingRight = UDim.new(0, 12)
	Padding.Parent = NotifCard

	local HeaderFrame = Instance.new("Frame")
	HeaderFrame.Name = "Header"
	HeaderFrame.Size = UDim2.new(1, 0, 0, 16)
	HeaderFrame.BackgroundTransparency = 1
	HeaderFrame.Parent = NotifCard

	local HeaderLayout = Instance.new("UIListLayout")
	HeaderLayout.SortOrder = Enum.SortOrder.LayoutOrder
	HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
	HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	HeaderLayout.Padding = UDim.new(0, 8)
	HeaderLayout.Parent = HeaderFrame

	local NotifIcon = Instance.new("ImageLabel")
	NotifIcon.Name = "Icon"
	NotifIcon.Size = UDim2.new(0, 14, 0, 14)
	NotifIcon.BackgroundTransparency = 1
	NotifIcon.ImageColor3 = COLOR_TEXT_WHITE
	NotifIcon.ImageTransparency = 1
	NotifIcon.LayoutOrder = 1
	ApplyIcon(NotifIcon, icon)
	NotifIcon.Parent = HeaderFrame

	local TitleLbl = Instance.new("TextLabel")
	TitleLbl.Name = "Title"
	TitleLbl.Size = UDim2.new(1, -22, 1, 0)
	TitleLbl.BackgroundTransparency = 1
	TitleLbl.FontFace = FONT_BOLD
	TitleLbl.Text = title
	TitleLbl.TextColor3 = COLOR_TEXT_WHITE
	TitleLbl.TextTransparency = 1
	TitleLbl.TextSize = 12
	TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
	TitleLbl.LayoutOrder = 2
	TitleLbl.Parent = HeaderFrame

	local DescriptionLbl = Instance.new("TextLabel")
	DescriptionLbl.Name = "Description"
	DescriptionLbl.Size = UDim2.new(1, 0, 0, 0)
	DescriptionLbl.Position = UDim2.new(0, 0, 0, 20)
	DescriptionLbl.AutomaticSize = Enum.AutomaticSize.Y
	DescriptionLbl.BackgroundTransparency = 1
	DescriptionLbl.FontFace = FONT_REGULAR
	DescriptionLbl.Text = text
	DescriptionLbl.TextColor3 = COLOR_TEXT_MUTED
	DescriptionLbl.TextTransparency = 1
	DescriptionLbl.TextSize = 11
	DescriptionLbl.TextXAlignment = Enum.TextXAlignment.Left
	DescriptionLbl.TextWrapped = true
	DescriptionLbl.Parent = NotifCard

	local ProgressBar = Instance.new("Frame")
	ProgressBar.Name = "Progress"
	ProgressBar.Size = UDim2.new(1, 0, 0, 2)
	ProgressBar.Position = UDim2.new(0, 0, 1, 12)
	ProgressBar.BackgroundColor3 = COLOR_TEXT_WHITE
	ProgressBar.BorderSizePixel = 0
	ProgressBar.BackgroundTransparency = 1
	ProgressBar.Parent = NotifCard

	local ProgressCorner = Instance.new("UICorner")
	ProgressCorner.CornerRadius = UDim.new(1, 0)
	ProgressCorner.Parent = ProgressBar

	NotifCard.Parent = NotificationContainer

	TweenService:Create(NotifCard, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
	TweenService:Create(NotifStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0}):Play()
	TweenService:Create(NotifIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
	TweenService:Create(TitleLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	TweenService:Create(DescriptionLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	TweenService:Create(ProgressBar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.4}):Play()
	TweenService:Create(ProgressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()

	task.delay(duration, function()
		local fadeOut = TweenService:Create(NotifCard, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
		TweenService:Create(NotifStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
		TweenService:Create(NotifIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {ImageTransparency = 1}):Play()
		TweenService:Create(TitleLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
		TweenService:Create(DescriptionLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
		TweenService:Create(ProgressBar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			NotifCard:Destroy()
		end)
	end)
end

local function MakeDraggable(guiObject)
	local dragging = false
	local dragInput, dragStart, startPos

	guiObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	guiObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

function Library.CreateWindow(config)
	config = config or {}
	local windowTitle = config.Title or "Astra"
	local windowLogo = config.Logo
	local isAnonymous = config.Anonymous or false
	local configFolder = config.ConfigFolder or "AstraConfigs"

	EnsureFolder(configFolder)

	local Window = {}
	Window._configFolder = configFolder
	Window._tabs = {}
	Window._activeTabRef = nil
	Window._activeSubTabRef = nil

	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.fromOffset(740, 500)
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = COLOR_BG
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = ScreenGui

	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 10)
	MainCorner.Parent = MainFrame

	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color = COLOR_BORDER
	MainStroke.Thickness = 1.2
	MainStroke.Parent = MainFrame

	local SizeConstraint = Instance.new("UISizeConstraint")
	SizeConstraint.MinSize = Vector2.new(640, 420)
	SizeConstraint.MaxSize = Vector2.new(860, 580)
	SizeConstraint.Parent = MainFrame

	local MobileToggleBtn = Instance.new("TextButton")
	MobileToggleBtn.Name = "MobileToggleBtn"
	MobileToggleBtn.Size = UDim2.new(0, 65, 0, 28)
	MobileToggleBtn.Position = UDim2.new(0, 15, 0.5, -14)
	MobileToggleBtn.BackgroundColor3 = COLOR_CARD_BG
	MobileToggleBtn.BorderSizePixel = 0
	MobileToggleBtn.FontFace = FONT_BOLD
	MobileToggleBtn.Text = "Close"
	MobileToggleBtn.TextColor3 = COLOR_TEXT_WHITE
	MobileToggleBtn.TextSize = 12
	MobileToggleBtn.AutoButtonColor = false
	MobileToggleBtn.ZIndex = 100
	MobileToggleBtn.Parent = ScreenGui

	local ToggleCorner = Instance.new("UICorner")
	ToggleCorner.CornerRadius = UDim.new(0, 6)
	ToggleCorner.Parent = MobileToggleBtn

	local ToggleStroke = Instance.new("UIStroke")
	ToggleStroke.Color = COLOR_BORDER
	ToggleStroke.Thickness = 1.2
	ToggleStroke.Parent = MobileToggleBtn

	local function ToggleUI()
		MainFrame.Visible = not MainFrame.Visible
		MobileToggleBtn.Text = MainFrame.Visible and "Close" or "Open"
	end

	MobileToggleBtn.MouseButton1Click:Connect(ToggleUI)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
			ToggleUI()
		end
	end)

	MakeDraggable(MainFrame)
	MakeDraggable(MobileToggleBtn)

	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0.24, 0, 1, 0)
	Sidebar.BackgroundTransparency = 1
	Sidebar.BorderSizePixel = 0
	Sidebar.Parent = MainFrame

	local SidebarDivider = Instance.new("Frame")
	SidebarDivider.Name = "SidebarDivider"
	SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
	SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
	SidebarDivider.BackgroundColor3 = COLOR_BORDER
	SidebarDivider.BorderSizePixel = 0
	SidebarDivider.Parent = Sidebar

	local TitleBarFrame = Instance.new("Frame")
	TitleBarFrame.Name = "TitleBar"
	TitleBarFrame.Size = UDim2.new(1, -20, 0, 38)
	TitleBarFrame.Position = UDim2.new(0, 10, 0, 6)
	TitleBarFrame.BackgroundTransparency = 1
	TitleBarFrame.Parent = Sidebar

	local TitleBarLayout = Instance.new("UIListLayout")
	TitleBarLayout.FillDirection = Enum.FillDirection.Horizontal
	TitleBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	TitleBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TitleBarLayout.Padding = UDim.new(0, 6)
	TitleBarLayout.Parent = TitleBarFrame

	if windowLogo then
		local LogoImg = Instance.new("ImageLabel")
		LogoImg.Name = "Logo"
		LogoImg.Size = UDim2.new(0, 22, 0, 22)
		LogoImg.BackgroundTransparency = 1
		LogoImg.Image = "rbxassetid://" .. tostring(windowLogo)
		LogoImg.LayoutOrder = 1
		LogoImg.Parent = TitleBarFrame
	end

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "Title"
	TitleLabel.Size = UDim2.new(1, 0, 1, 0)
	TitleLabel.AutomaticSize = Enum.AutomaticSize.X
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.FontFace = FONT_BOLD
	TitleLabel.Text = windowTitle
	TitleLabel.TextColor3 = COLOR_TEXT_WHITE
	TitleLabel.TextSize = 17
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.LayoutOrder = 2
	TitleLabel.Parent = TitleBarFrame

	local SearchContainer = Instance.new("Frame")
	SearchContainer.Name = "SearchContainer"
	SearchContainer.Size = UDim2.new(1, -20, 0, 30)
	SearchContainer.Position = UDim2.new(0, 10, 0, 46)
	SearchContainer.BackgroundColor3 = COLOR_SEARCH_BG
	SearchContainer.BorderSizePixel = 0
	SearchContainer.Parent = Sidebar

	local SearchCorner = Instance.new("UICorner")
	SearchCorner.CornerRadius = UDim.new(0, 6)
	SearchCorner.Parent = SearchContainer

	local SearchStroke = Instance.new("UIStroke")
	SearchStroke.Color = COLOR_BORDER
	SearchStroke.Thickness = 1
	SearchStroke.Parent = SearchContainer

	local SearchIcon = Instance.new("ImageLabel")
	SearchIcon.Name = "Icon"
	SearchIcon.Size = UDim2.new(0, 14, 0, 14)
	SearchIcon.Position = UDim2.new(0, 8, 0.5, -7)
	SearchIcon.BackgroundTransparency = 1
	SearchIcon.ImageColor3 = COLOR_TEXT_MUTED
	ApplyIcon(SearchIcon, "search")
	SearchIcon.Parent = SearchContainer

	local SearchInput = Instance.new("TextBox")
	SearchInput.Name = "Input"
	SearchInput.Size = UDim2.new(1, -28, 1, 0)
	SearchInput.Position = UDim2.new(0, 28, 0, 0)
	SearchInput.BackgroundTransparency = 1
	SearchInput.FontFace = FONT_REGULAR
	SearchInput.PlaceholderText = "Search"
	SearchInput.PlaceholderColor3 = COLOR_TEXT_SUB
	SearchInput.Text = ""
	SearchInput.TextColor3 = COLOR_TEXT_WHITE
	SearchInput.TextSize = 13
	SearchInput.TextXAlignment = Enum.TextXAlignment.Left
	SearchInput.Parent = SearchContainer

	local SearchDivider = Instance.new("Frame")
	SearchDivider.Name = "SearchDivider"
	SearchDivider.Size = UDim2.new(1, -20, 0, 1)
	SearchDivider.Position = UDim2.new(0, 10, 0, 82)
	SearchDivider.BackgroundColor3 = COLOR_BORDER
	SearchDivider.BorderSizePixel = 0
	SearchDivider.Parent = Sidebar

	local NavContainer = Instance.new("ScrollingFrame")
	NavContainer.Name = "NavContainer"
	NavContainer.Size = UDim2.new(1, -20, 1, -145)
	NavContainer.Position = UDim2.new(0, 10, 0, 90)
	NavContainer.BackgroundTransparency = 1
	NavContainer.BorderSizePixel = 0
	NavContainer.Active = true
	NavContainer.ScrollingEnabled = true
	NavContainer.ScrollBarThickness = 0
	NavContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	NavContainer.ClipsDescendants = true
	NavContainer.Parent = Sidebar

	local NavLayout = Instance.new("UIListLayout")
	NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
	NavLayout.Padding = UDim.new(0, 3)
	NavLayout.Parent = NavContainer

	NavLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		NavContainer.CanvasSize = UDim2.new(0, 0, 0, NavLayout.AbsoluteContentSize.Y + 10)
	end)

	local UserDivider = Instance.new("Frame")
	UserDivider.Name = "UserDivider"
	UserDivider.Size = UDim2.new(1, -20, 0, 1)
	UserDivider.Position = UDim2.new(0, 10, 1, -52)
	UserDivider.BackgroundColor3 = COLOR_BORDER
	UserDivider.BorderSizePixel = 0
	UserDivider.Parent = Sidebar

	local UserContainer = Instance.new("Frame")
	UserContainer.Name = "UserContainer"
	UserContainer.Size = UDim2.new(1, -20, 0, 42)
	UserContainer.Position = UDim2.new(0, 10, 1, -47)
	UserContainer.BackgroundTransparency = 1
	UserContainer.Parent = Sidebar

	local AvatarBox = Instance.new("Frame")
	AvatarBox.Name = "AvatarBox"
	AvatarBox.Size = UDim2.new(0, 30, 0, 30)
	AvatarBox.Position = UDim2.new(0, 0, 0.5, -15)
	AvatarBox.BackgroundColor3 = COLOR_SEARCH_BG
	AvatarBox.BorderSizePixel = 0
	AvatarBox.ClipsDescendants = true
	AvatarBox.Parent = UserContainer

	local AvatarCorner = Instance.new("UICorner")
	AvatarCorner.CornerRadius = UDim.new(0, 6)
	AvatarCorner.Parent = AvatarBox

	local AvatarStroke = Instance.new("UIStroke")
	AvatarStroke.Color = COLOR_BORDER
	AvatarStroke.Thickness = 1
	AvatarStroke.Parent = AvatarBox

	local AvatarImage = Instance.new("ImageLabel")
	AvatarImage.Name = "AvatarImage"
	AvatarImage.Size = UDim2.new(1, 0, 1, 0)
	AvatarImage.BackgroundTransparency = 1
	AvatarImage.Parent = AvatarBox

	local AvatarImgCorner = Instance.new("UICorner")
	AvatarImgCorner.CornerRadius = UDim.new(0, 6)
	AvatarImgCorner.Parent = AvatarImage

	if isAnonymous then
		AvatarImage.Image = "rbxassetid://0"
	else
		AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
		task.spawn(function()
			local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			if isReady and content then
				AvatarImage.Image = content
			end
		end)
	end

	local UserTitle = Instance.new("TextLabel")
	UserTitle.Name = "UserName"
	UserTitle.Size = UDim2.new(1, -38, 0, 15)
	UserTitle.Position = UDim2.new(0, 38, 0, 5)
	UserTitle.BackgroundTransparency = 1
	UserTitle.FontFace = FONT_BOLD
	UserTitle.Text = isAnonymous and "Anonymous" or LocalPlayer.DisplayName
	UserTitle.TextColor3 = COLOR_TEXT_WHITE
	UserTitle.TextSize = 13
	UserTitle.TextXAlignment = Enum.TextXAlignment.Left
	UserTitle.Parent = UserContainer

	local UserBadge = Instance.new("TextLabel")
	UserBadge.Name = "UserBadge"
	UserBadge.Size = UDim2.new(1, -38, 0, 13)
	UserBadge.Position = UDim2.new(0, 38, 0, 21)
	UserBadge.BackgroundTransparency = 1
	UserBadge.FontFace = FONT_MEDIUM
	UserBadge.Text = "BETA"
	UserBadge.TextColor3 = COLOR_TEXT_SUB
	UserBadge.TextSize = 11
	UserBadge.TextXAlignment = Enum.TextXAlignment.Left
	UserBadge.Parent = UserContainer

	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "ContentFrame"
	ContentFrame.Size = UDim2.new(0.76, 0, 1, 0)
	ContentFrame.Position = UDim2.new(0.24, 0, 0, 0)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.Parent = MainFrame

	local ContentHeaderFrame = Instance.new("Frame")
	ContentHeaderFrame.Name = "HeaderFrame"
	ContentHeaderFrame.Size = UDim2.new(1, -24, 0, 44)
	ContentHeaderFrame.Position = UDim2.new(0, 14, 0, 4)
	ContentHeaderFrame.BackgroundTransparency = 1
	ContentHeaderFrame.Parent = ContentFrame

	local HeaderLayout = Instance.new("UIListLayout")
	HeaderLayout.SortOrder = Enum.SortOrder.LayoutOrder
	HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
	HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	HeaderLayout.Padding = UDim.new(0, 8)
	HeaderLayout.Parent = ContentHeaderFrame

	local ContentHeaderIcon = Instance.new("ImageLabel")
	ContentHeaderIcon.Name = "HeaderIcon"
	ContentHeaderIcon.Size = UDim2.new(0, 18, 0, 18)
	ContentHeaderIcon.BackgroundTransparency = 1
	ContentHeaderIcon.ImageColor3 = COLOR_TEXT_WHITE
	ContentHeaderIcon.LayoutOrder = 1
	ApplyIcon(ContentHeaderIcon, "layout")
	ContentHeaderIcon.Parent = ContentHeaderFrame

	local ContentHeader = Instance.new("TextLabel")
	ContentHeader.Name = "HeaderTitle"
	ContentHeader.Size = UDim2.new(0, 0, 1, 0)
	ContentHeader.AutomaticSize = Enum.AutomaticSize.X
	ContentHeader.BackgroundTransparency = 1
	ContentHeader.FontFace = FONT_BOLD
	ContentHeader.Text = ""
	ContentHeader.TextColor3 = COLOR_TEXT_WHITE
	ContentHeader.TextSize = 17
	ContentHeader.TextXAlignment = Enum.TextXAlignment.Left
	ContentHeader.LayoutOrder = 2
	ContentHeader.Parent = ContentHeaderFrame

	local ContentHeaderDivider = Instance.new("Frame")
	ContentHeaderDivider.Name = "HeaderDivider"
	ContentHeaderDivider.Size = UDim2.new(1, 0, 0, 1)
	ContentHeaderDivider.Position = UDim2.new(0, 0, 0, 48)
	ContentHeaderDivider.BackgroundColor3 = COLOR_BORDER
	ContentHeaderDivider.BorderSizePixel = 0
	ContentHeaderDivider.Parent = ContentFrame

	local ContentArea = Instance.new("Frame")
	ContentArea.Name = "ContentArea"
	ContentArea.Size = UDim2.new(1, -28, 1, -62)
	ContentArea.Position = UDim2.new(0, 14, 0, 54)
	ContentArea.BackgroundTransparency = 1
	ContentArea.Parent = ContentFrame

	Window._navContainer = NavContainer
	Window._navLayout = NavLayout
	Window._contentArea = ContentArea
	Window._contentHeader = ContentHeader
	Window._contentHeaderIcon = ContentHeaderIcon
	Window._tabIndex = 0

	local function UpdateHeader(title, icon)
		ContentHeader.Text = title
		ApplyIcon(ContentHeaderIcon, icon)
	end

	local function SetTabActive(tabObj, isActive)
		tabObj.Btn.BackgroundColor3 = isActive and COLOR_ACTIVE_BG or Color3.fromRGB(0, 0, 0)
		tabObj.Btn.BackgroundTransparency = isActive and 0 or 1
		tabObj.Icon.ImageColor3 = isActive and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
		tabObj.Label.TextColor3 = isActive and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
		tabObj.Label.FontFace = isActive and FONT_BOLD or FONT_MEDIUM
		if tabObj.Indicator then tabObj.Indicator.Visible = isActive end
		if tabObj.ContentPage then tabObj.ContentPage.Visible = isActive end
	end

	local function SetSubTabActive(subObj, isActive)
		subObj.Btn.BackgroundColor3 = isActive and COLOR_ACTIVE_BG or Color3.fromRGB(0, 0, 0)
		subObj.Btn.BackgroundTransparency = isActive and 0 or 1
		subObj.Icon.ImageColor3 = isActive and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
		subObj.Label.TextColor3 = isActive and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
		subObj.Label.FontFace = isActive and FONT_BOLD or FONT_MEDIUM
		if subObj.Indicator then subObj.Indicator.Visible = isActive end
		if subObj.ContentPage then subObj.ContentPage.Visible = isActive end
	end

	Window._SetTabActive = SetTabActive
	Window._SetSubTabActive = SetSubTabActive
	Window._UpdateHeader = UpdateHeader

	function Window:CreateTab(tabConfig)
		tabConfig = tabConfig or {}
		local tabName = tabConfig.Name or "Tab"
		local tabIcon = tabConfig.Icon or "layout"
		local subTabsData = tabConfig.SubTabs

		self._tabIndex = self._tabIndex + 1
		local idx = self._tabIndex

		local tabObj = {}
		tabObj.Name = tabName
		tabObj.Icon = tabIcon
		tabObj.Expanded = false
		tabObj.SubObjects = {}

		local ContentPage = Instance.new("Frame")
		ContentPage.Name = "Page_" .. tabName
		ContentPage.Size = UDim2.new(1, 0, 1, 0)
		ContentPage.BackgroundTransparency = 1
		ContentPage.Visible = false
		ContentPage.Parent = ContentArea

		local PageLayout = Instance.new("UIListLayout")
		PageLayout.FillDirection = Enum.FillDirection.Horizontal
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Padding = UDim.new(0, 12)
		PageLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		PageLayout.Parent = ContentPage

		-- single full-width scroll column (readable controls)
		local LeftColumn = Instance.new("ScrollingFrame")
		LeftColumn.Name = "LeftColumn"
		LeftColumn.Size = UDim2.new(1, 0, 1, 0)
		LeftColumn.BackgroundTransparency = 1
		LeftColumn.BorderSizePixel = 0
		LeftColumn.ScrollBarThickness = 4
		LeftColumn.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 95)
		LeftColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
		LeftColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
		LeftColumn.ScrollingDirection = Enum.ScrollingDirection.Y
		LeftColumn.LayoutOrder = 1
		LeftColumn.Parent = ContentPage

		local LeftPad = Instance.new("UIPadding")
		LeftPad.PaddingRight = UDim.new(0, 10)
		LeftPad.PaddingLeft = UDim.new(0, 6)
		LeftPad.PaddingTop = UDim.new(0, 4)
		LeftPad.PaddingBottom = UDim.new(0, 16)
		LeftPad.Parent = LeftColumn

		local LeftColLayout = Instance.new("UIListLayout")
		LeftColLayout.SortOrder = Enum.SortOrder.LayoutOrder
		LeftColLayout.FillDirection = Enum.FillDirection.Vertical
		LeftColLayout.Padding = UDim.new(0, 14)
		LeftColLayout.Parent = LeftColumn

		-- right column unused (kept for API compatibility, hidden)
		local RightColumn = Instance.new("ScrollingFrame")
		RightColumn.Name = "RightColumn"
		RightColumn.Size = UDim2.new(0, 0, 0, 0)
		RightColumn.Visible = false
		RightColumn.BackgroundTransparency = 1
		RightColumn.BorderSizePixel = 0
		RightColumn.LayoutOrder = 2
		RightColumn.Parent = ContentPage

		local RightColLayout = Instance.new("UIListLayout")
		RightColLayout.SortOrder = Enum.SortOrder.LayoutOrder
		RightColLayout.FillDirection = Enum.FillDirection.Vertical
		RightColLayout.Padding = UDim.new(0, 10)
		RightColLayout.Parent = RightColumn

		tabObj.ContentPage = ContentPage
		tabObj._pageLayout = PageLayout
		tabObj._leftColumn = LeftColumn
		tabObj._rightColumn = RightColumn
		tabObj._leftColLayout = LeftColLayout
		tabObj._rightColLayout = RightColLayout

		local TabBtn = Instance.new("TextButton")
		TabBtn.Name = "Tab_" .. tabName
		TabBtn.Size = UDim2.new(1, 0, 0, 30)
		TabBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TabBtn.BackgroundTransparency = 1
		TabBtn.BorderSizePixel = 0
		TabBtn.AutoButtonColor = false
		TabBtn.Text = ""
		TabBtn.LayoutOrder = idx * 10
		TabBtn.Parent = NavContainer
		tabObj.Btn = TabBtn

		local TabCorner = Instance.new("UICorner")
		TabCorner.CornerRadius = UDim.new(0, 6)
		TabCorner.Parent = TabBtn

		local ActiveIndicator = Instance.new("Frame")
		ActiveIndicator.Name = "Indicator"
		ActiveIndicator.Size = UDim2.new(0, 3, 0, 16)
		ActiveIndicator.Position = UDim2.new(0, 0, 0.5, -8)
		ActiveIndicator.BackgroundColor3 = COLOR_TEXT_WHITE
		ActiveIndicator.BorderSizePixel = 0
		ActiveIndicator.Visible = false
		ActiveIndicator.Parent = TabBtn
		tabObj.Indicator = ActiveIndicator

		local IndCorner = Instance.new("UICorner")
		IndCorner.CornerRadius = UDim.new(0, 2)
		IndCorner.Parent = ActiveIndicator

		local TabIcon = Instance.new("ImageLabel")
		TabIcon.Name = "Icon"
		TabIcon.Size = UDim2.new(0, 15, 0, 15)
		TabIcon.Position = UDim2.new(0, 10, 0.5, -7.5)
		TabIcon.BackgroundTransparency = 1
		TabIcon.ImageColor3 = COLOR_TEXT_MUTED
		ApplyIcon(TabIcon, tabIcon)
		TabIcon.Parent = TabBtn
		tabObj.Icon = TabIcon

		local TabLabel = Instance.new("TextLabel")
		TabLabel.Name = "Label"
		TabLabel.Size = UDim2.new(1, -48, 1, 0)
		TabLabel.Position = UDim2.new(0, 32, 0, 0)
		TabLabel.BackgroundTransparency = 1
		TabLabel.FontFace = FONT_MEDIUM
		TabLabel.Text = tabName
		TabLabel.TextColor3 = COLOR_TEXT_MUTED
		TabLabel.TextSize = 13
		TabLabel.TextXAlignment = Enum.TextXAlignment.Left
		TabLabel.Parent = TabBtn
		tabObj.Label = TabLabel

		local Tab = {}
		Tab._tabObj = tabObj
		Tab._window = self
		Tab._sections = {}

		if subTabsData then
			local ChevronIcon = Instance.new("ImageLabel")
			ChevronIcon.Name = "Chevron"
			ChevronIcon.Size = UDim2.new(0, 12, 0, 12)
			ChevronIcon.Position = UDim2.new(1, -16, 0.5, -6)
			ChevronIcon.BackgroundTransparency = 1
			ChevronIcon.ImageColor3 = COLOR_TEXT_MUTED
			ApplyIcon(ChevronIcon, "chevron-down")
			ChevronIcon.Parent = TabBtn
			tabObj.Chevron = ChevronIcon

			local SubContainer = Instance.new("Frame")
			SubContainer.Name = "SubContainer_" .. tabName
			SubContainer.Size = UDim2.new(1, 0, 0, 0)
			SubContainer.AutomaticSize = Enum.AutomaticSize.Y
			SubContainer.BackgroundTransparency = 1
			SubContainer.LayoutOrder = (idx * 10) + 1
			SubContainer.Visible = false
			SubContainer.Parent = NavContainer
			tabObj.SubContainer = SubContainer

			local SubLayout = Instance.new("UIListLayout")
			SubLayout.SortOrder = Enum.SortOrder.LayoutOrder
			SubLayout.Padding = UDim.new(0, 2)
			SubLayout.Parent = SubContainer

			for j, subData in ipairs(subTabsData) do
				local subObj = {}
				subObj.Data = subData

				local SubPage = Instance.new("Frame")
				SubPage.Name = "SubPage_" .. subData.Name
				SubPage.Size = UDim2.new(1, 0, 1, 0)
				SubPage.BackgroundTransparency = 1
				SubPage.Visible = false
				SubPage.Parent = ContentArea

				local SubPageLayout = Instance.new("UIListLayout")
				SubPageLayout.FillDirection = Enum.FillDirection.Horizontal
				SubPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
				SubPageLayout.Padding = UDim.new(0, 12)
				SubPageLayout.VerticalAlignment = Enum.VerticalAlignment.Top
				SubPageLayout.Parent = SubPage

				local SubLeftCol = Instance.new("Frame")
				SubLeftCol.Name = "LeftColumn"
				SubLeftCol.Size = UDim2.new(0.5, -6, 1, 0)
				SubLeftCol.BackgroundTransparency = 1
				SubLeftCol.LayoutOrder = 1
				SubLeftCol.Parent = SubPage

				local SubLeftColLayout = Instance.new("UIListLayout")
				SubLeftColLayout.SortOrder = Enum.SortOrder.LayoutOrder
				SubLeftColLayout.FillDirection = Enum.FillDirection.Vertical
				SubLeftColLayout.Padding = UDim.new(0, 10)
				SubLeftColLayout.Parent = SubLeftCol

				local SubRightCol = Instance.new("Frame")
				SubRightCol.Name = "RightColumn"
				SubRightCol.Size = UDim2.new(0.5, -6, 1, 0)
				SubRightCol.BackgroundTransparency = 1
				SubRightCol.LayoutOrder = 2
				SubRightCol.Parent = SubPage

				local SubRightColLayout = Instance.new("UIListLayout")
				SubRightColLayout.SortOrder = Enum.SortOrder.LayoutOrder
				SubRightColLayout.FillDirection = Enum.FillDirection.Vertical
				SubRightColLayout.Padding = UDim.new(0, 10)
				SubRightColLayout.Parent = SubRightCol

				subObj.ContentPage = SubPage
				subObj._pageLayout = SubPageLayout
				subObj._leftColumn = SubLeftCol
				subObj._rightColumn = SubRightCol

				local SubBtn = Instance.new("TextButton")
				SubBtn.Name = "SubTab_" .. subData.Name
				SubBtn.Size = UDim2.new(1, 0, 0, 28)
				SubBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				SubBtn.BackgroundTransparency = 1
				SubBtn.BorderSizePixel = 0
				SubBtn.AutoButtonColor = false
				SubBtn.Text = ""
				SubBtn.LayoutOrder = j
				SubBtn.Parent = SubContainer
				subObj.Btn = SubBtn

				local SubCorner = Instance.new("UICorner")
				SubCorner.CornerRadius = UDim.new(0, 6)
				SubCorner.Parent = SubBtn

				local SubIndicator = Instance.new("Frame")
				SubIndicator.Name = "Indicator"
				SubIndicator.Size = UDim2.new(0, 3, 0, 14)
				SubIndicator.Position = UDim2.new(0, 12, 0.5, -7)
				SubIndicator.BackgroundColor3 = COLOR_TEXT_WHITE
				SubIndicator.BorderSizePixel = 0
				SubIndicator.Visible = false
				SubIndicator.Parent = SubBtn
				subObj.Indicator = SubIndicator

				local SubIndCorner = Instance.new("UICorner")
				SubIndCorner.CornerRadius = UDim.new(0, 2)
				SubIndCorner.Parent = SubIndicator

				local SubIcon = Instance.new("ImageLabel")
				SubIcon.Name = "Icon"
				SubIcon.Size = UDim2.new(0, 13, 0, 13)
				SubIcon.Position = UDim2.new(0, 22, 0.5, -6.5)
				SubIcon.BackgroundTransparency = 1
				SubIcon.ImageColor3 = COLOR_TEXT_MUTED
				ApplyIcon(SubIcon, subData.Icon)
				SubIcon.Parent = SubBtn
				subObj.Icon = SubIcon

				local SubLabel = Instance.new("TextLabel")
				SubLabel.Name = "Label"
				SubLabel.Size = UDim2.new(1, -44, 1, 0)
				SubLabel.Position = UDim2.new(0, 42, 0, 0)
				SubLabel.BackgroundTransparency = 1
				SubLabel.FontFace = FONT_MEDIUM
				SubLabel.Text = subData.Name
				SubLabel.TextColor3 = COLOR_TEXT_MUTED
				SubLabel.TextSize = 12
				SubLabel.TextXAlignment = Enum.TextXAlignment.Left
				SubLabel.Parent = SubBtn
				subObj.Label = SubLabel

				SubBtn.MouseButton1Click:Connect(function()
					if self._activeTabRef then SetTabActive(self._activeTabRef, false) end
					if self._activeSubTabRef then SetSubTabActive(self._activeSubTabRef, false) end
					self._activeTabRef = nil
					self._activeSubTabRef = subObj
					SetSubTabActive(subObj, true)
					UpdateHeader(tabName .. " / " .. subData.Name, subData.Icon)
				end)

				table.insert(tabObj.SubObjects, subObj)
			end

			TabBtn.MouseButton1Click:Connect(function()
				tabObj.Expanded = not tabObj.Expanded
				tabObj.SubContainer.Visible = tabObj.Expanded
				tabObj.Chevron.Rotation = tabObj.Expanded and 180 or 0

				if tabObj.Expanded and #tabObj.SubObjects > 0 then
					local isSubActive = false
					for _, sub in ipairs(tabObj.SubObjects) do
						if sub == self._activeSubTabRef then
							isSubActive = true
							break
						end
					end
					if not isSubActive then
						if self._activeTabRef then SetTabActive(self._activeTabRef, false) end
						if self._activeSubTabRef then SetSubTabActive(self._activeSubTabRef, false) end
						self._activeTabRef = nil
						self._activeSubTabRef = tabObj.SubObjects[1]
						SetSubTabActive(tabObj.SubObjects[1], true)
						UpdateHeader(tabName .. " / " .. tabObj.SubObjects[1].Data.Name, tabObj.SubObjects[1].Data.Icon)
					end
				end
			end)
		else
			TabBtn.MouseButton1Click:Connect(function()
				if self._activeTabRef then SetTabActive(self._activeTabRef, false) end
				if self._activeSubTabRef then SetSubTabActive(self._activeSubTabRef, false) end
				self._activeSubTabRef = nil
				self._activeTabRef = tabObj
				SetTabActive(tabObj, true)
				UpdateHeader(tabName, tabIcon)
			end)
		end

		function Tab:CreateSection(sectionConfig)
			sectionConfig = sectionConfig or {}
			local sectionName = sectionConfig.Name or "Section"
			local side = sectionConfig.Side or "Left"

			local column
			if side == "Left" then
				column = tabObj._leftColumn
			else
				column = tabObj._rightColumn
			end

			local existingInCol = 0
			for _, c in ipairs(column:GetChildren()) do
				if c:IsA("Frame") and c.Name:sub(1, 8) == "Section_" then
					existingInCol = existingInCol + 1
				end
			end

			local SectionFrame = Instance.new("Frame")
			SectionFrame.Name = "Section_" .. sectionName
			SectionFrame.BackgroundColor3 = COLOR_CARD_BG
			SectionFrame.BorderSizePixel = 0
			SectionFrame.ClipsDescendants = true
			SectionFrame.LayoutOrder = existingInCol + 1

			-- auto-height sections (prevents overflow / buttons off-screen)
			SectionFrame.Size = UDim2.new(1, 0, 0, 0)
			SectionFrame.AutomaticSize = Enum.AutomaticSize.Y

			SectionFrame.Parent = column

			local SecCorner = Instance.new("UICorner")
			SecCorner.CornerRadius = UDim.new(0, 8)
			SecCorner.Parent = SectionFrame

			local SecStroke = Instance.new("UIStroke")
			SecStroke.Color = COLOR_BORDER
			SecStroke.Thickness = 1.2
			SecStroke.Parent = SectionFrame

			local SecTitle = Instance.new("TextLabel")
			SecTitle.Name = "Title"
			SecTitle.Size = UDim2.new(1, -40, 0, 34)
			SecTitle.Position = UDim2.new(0, 12, 0, 0)
			SecTitle.BackgroundTransparency = 1
			SecTitle.FontFace = FONT_BOLD
			SecTitle.Text = sectionName
			SecTitle.TextColor3 = COLOR_TEXT_WHITE
			SecTitle.TextSize = 14
			SecTitle.TextXAlignment = Enum.TextXAlignment.Left
			SecTitle.Parent = SectionFrame

			local SecDivider = Instance.new("Frame")
			SecDivider.Name = "Divider"
			SecDivider.Size = UDim2.new(1, 0, 0, 1)
			SecDivider.Position = UDim2.new(0, 0, 0, 34)
			SecDivider.BackgroundColor3 = COLOR_BORDER
			SecDivider.BorderSizePixel = 0
			SecDivider.Parent = SectionFrame

			local SecContent = Instance.new("Frame")
			SecContent.Name = "Content"
			SecContent.Size = UDim2.new(1, 0, 0, 0)
			SecContent.AutomaticSize = Enum.AutomaticSize.Y
			SecContent.Position = UDim2.new(0, 0, 0, 35)
			SecContent.BackgroundTransparency = 1
			SecContent.BorderSizePixel = 0
			SecContent.Parent = SectionFrame

			local SecPadding = Instance.new("UIPadding")
			SecPadding.PaddingLeft = UDim.new(0, 14)
			SecPadding.PaddingRight = UDim.new(0, 14)
			SecPadding.PaddingTop = UDim.new(0, 12)
			SecPadding.PaddingBottom = UDim.new(0, 14)
			SecPadding.Parent = SecContent

			local SecLayout = Instance.new("UIListLayout")
			SecLayout.SortOrder = Enum.SortOrder.LayoutOrder
			SecLayout.Padding = UDim.new(0, 10)
			SecLayout.Parent = SecContent

			SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				SecContent.CanvasSize = UDim2.new(0, 0, 0, SecLayout.AbsoluteContentSize.Y + 20)
			end)

			local ToggleBtn2 = Instance.new("ImageButton")
			ToggleBtn2.Name = "ToggleChevron"
			ToggleBtn2.Size = UDim2.new(0, 16, 0, 16)
			ToggleBtn2.Position = UDim2.new(1, -12, 0, 9)
			ToggleBtn2.AnchorPoint = Vector2.new(1, 0)
			ToggleBtn2.BackgroundTransparency = 1
			ToggleBtn2.ImageColor3 = COLOR_TEXT_MUTED
			ApplyIcon(ToggleBtn2, "chevron-down")
			ToggleBtn2.Parent = SectionFrame

			-- collapse disabled: always show controls
			ToggleBtn2.Visible = false
			SecContent.Visible = true
			if SecDivider then SecDivider.Visible = true end

			local Section = {}
			Section._content = SecContent
			Section._sectionFrame = SectionFrame
			Section._window = self._window

			function Section:AddLabel(text)
				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 18)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Label = Instance.new("TextLabel")
				Label.Size = UDim2.new(1, 0, 1, 0)
				Label.BackgroundTransparency = 1
				Label.FontFace = FONT_MEDIUM
				Label.Text = text
				Label.TextColor3 = COLOR_TEXT_MUTED
				Label.TextSize = 12
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Parent = Container

				return Container
			end

			function Section:AddToggle(toggleConfig)
				toggleConfig = toggleConfig or {}
				local labelText = toggleConfig.Name or "Toggle"
				local defaultState = toggleConfig.Default or false
				local callback = toggleConfig.Callback
				local configKey = toggleConfig.ConfigKey

				local state = defaultState

				local TogBtn = Instance.new("TextButton")
				TogBtn.Size = UDim2.new(1, 0, 0, 22)
				TogBtn.BackgroundTransparency = 1
				TogBtn.Text = ""
				TogBtn.AutoButtonColor = false
				TogBtn.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, -24, 1, 0)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = state and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = TogBtn

				local Box = Instance.new("Frame")
				Box.Size = UDim2.new(0, 16, 0, 16)
				Box.Position = UDim2.new(1, 0, 0.5, 0)
				Box.AnchorPoint = Vector2.new(1, 0.5)
				Box.BackgroundColor3 = state and COLOR_TEXT_WHITE or COLOR_BOX_INACTIVE
				Box.BorderSizePixel = 0
				Box.Parent = TogBtn

				local BoxCorner = Instance.new("UICorner")
				BoxCorner.CornerRadius = UDim.new(0, 4)
				BoxCorner.Parent = Box

				local BoxStroke = Instance.new("UIStroke")
				BoxStroke.Color = state and COLOR_TEXT_WHITE or COLOR_BOX_BORDER
				BoxStroke.Thickness = 1
				BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				BoxStroke.Parent = Box

				local CheckIcon = Instance.new("ImageLabel")
				CheckIcon.Size = UDim2.new(0, 10, 0, 10)
				CheckIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
				CheckIcon.AnchorPoint = Vector2.new(0.5, 0.5)
				CheckIcon.BackgroundTransparency = 1
				CheckIcon.ImageColor3 = COLOR_BG
				CheckIcon.ImageTransparency = state and 0 or 1
				ApplyIcon(CheckIcon, "check")
				CheckIcon.Parent = Box

				local function Refresh()
					Box.BackgroundColor3 = state and COLOR_TEXT_WHITE or COLOR_BOX_INACTIVE
					BoxStroke.Color = state and COLOR_TEXT_WHITE or COLOR_BOX_BORDER
					CheckIcon.ImageTransparency = state and 0 or 1
					Lbl.TextColor3 = state and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
				end

				TogBtn.MouseButton1Click:Connect(function()
					state = not state
					Refresh()
					if callback then callback(state) end
				end)

				local Toggle = {}
				Toggle.Set = function(val)
					state = val
					Refresh()
					if callback then callback(state) end
				end
				Toggle.Get = function() return state end

				if configKey then
					ConfigRegistry[configKey] = { Get = Toggle.Get, Set = Toggle.Set }
				end

				return Toggle
			end

			function Section:AddSlider(sliderConfig)
				sliderConfig = sliderConfig or {}
				local labelText = sliderConfig.Name or "Slider"
				local min = sliderConfig.Min or 0
				local max = sliderConfig.Max or 100
				local default = sliderConfig.Default or min
				local callback = sliderConfig.Callback
				local configKey = sliderConfig.ConfigKey

				local value = math.clamp(default, min, max)
				local dragging = false

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 42)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(0.6, 0, 0, 16)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_WHITE
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = Container

				local ValLbl = Instance.new("TextLabel")
				ValLbl.Size = UDim2.new(0.4, 0, 0, 16)
				ValLbl.Position = UDim2.new(1, 0, 0, 0)
				ValLbl.AnchorPoint = Vector2.new(1, 0)
				ValLbl.BackgroundTransparency = 1
				ValLbl.FontFace = FONT_REGULAR
				ValLbl.Text = tostring(value)
				ValLbl.TextColor3 = COLOR_TEXT_MUTED
				ValLbl.TextSize = 11
				ValLbl.TextXAlignment = Enum.TextXAlignment.Right
				ValLbl.Parent = Container

				local Track = Instance.new("Frame")
				Track.Size = UDim2.new(1, 0, 0, 4)
				Track.Position = UDim2.new(0, 0, 0, 22)
				Track.BackgroundColor3 = COLOR_BOX_INACTIVE
				Track.BorderSizePixel = 0
				Track.Parent = Container

				local TrackCorner = Instance.new("UICorner")
				TrackCorner.CornerRadius = UDim.new(1, 0)
				TrackCorner.Parent = Track

				local TrackStroke = Instance.new("UIStroke")
				TrackStroke.Color = COLOR_BORDER
				TrackStroke.Thickness = 1
				TrackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				TrackStroke.Parent = Track

				local Fill = Instance.new("Frame")
				Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
				Fill.BackgroundColor3 = COLOR_TEXT_WHITE
				Fill.BorderSizePixel = 0
				Fill.Parent = Track

				local FillCorner = Instance.new("UICorner")
				FillCorner.CornerRadius = UDim.new(1, 0)
				FillCorner.Parent = Fill

				local function UpdateSlider(input)
					local posX = math.clamp(input.Position.X - Track.AbsolutePosition.X, 0, Track.AbsoluteSize.X)
					local pct = math.clamp(posX / Track.AbsoluteSize.X, 0, 1)
					value = math.floor(min + (max - min) * pct + 0.5)
					Fill.Size = UDim2.new(pct, 0, 1, 0)
					ValLbl.Text = tostring(value)
					if callback then callback(value) end
				end

				Track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						UpdateSlider(input)
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						UpdateSlider(input)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)

				local Slider = {}
				Slider.Set = function(val)
					value = math.clamp(val, min, max)
					local pct = (value - min) / (max - min)
					Fill.Size = UDim2.new(pct, 0, 1, 0)
					ValLbl.Text = tostring(value)
					if callback then callback(value) end
				end
				Slider.Get = function() return value end

				if configKey then
					ConfigRegistry[configKey] = { Get = Slider.Get, Set = Slider.Set }
				end

				return Slider
			end

			function Section:AddInput(inputConfig)
				inputConfig = inputConfig or {}
				local labelText = inputConfig.Name or "Input"
				local placeholder = inputConfig.Placeholder or "Type here..."
				local default = inputConfig.Default or ""
				local callback = inputConfig.Callback
				local configKey = inputConfig.ConfigKey

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 52)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, 0, 0, 16)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_WHITE
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = Container

				local BoxContainer = Instance.new("Frame")
				BoxContainer.Size = UDim2.new(1, 0, 0, 24)
				BoxContainer.Position = UDim2.new(0, 0, 0, 18)
				BoxContainer.BackgroundColor3 = COLOR_BOX_INACTIVE
				BoxContainer.BorderSizePixel = 0
				BoxContainer.Parent = Container

				local BoxCorner = Instance.new("UICorner")
				BoxCorner.CornerRadius = UDim.new(0, 5)
				BoxCorner.Parent = BoxContainer

				local BoxStroke = Instance.new("UIStroke")
				BoxStroke.Color = COLOR_BOX_BORDER
				BoxStroke.Thickness = 1
				BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				BoxStroke.Parent = BoxContainer

				local TextBox = Instance.new("TextBox")
				TextBox.Size = UDim2.new(1, -16, 1, 0)
				TextBox.Position = UDim2.new(0, 8, 0, 0)
				TextBox.BackgroundTransparency = 1
				TextBox.FontFace = FONT_REGULAR
				TextBox.PlaceholderText = placeholder
				TextBox.PlaceholderColor3 = COLOR_TEXT_SUB
				TextBox.Text = default
				TextBox.TextColor3 = COLOR_TEXT_WHITE
				TextBox.TextSize = 11
				TextBox.TextXAlignment = Enum.TextXAlignment.Left
				TextBox.ClearTextOnFocus = false
				TextBox.Parent = BoxContainer

				TextBox.Focused:Connect(function() BoxStroke.Color = COLOR_TEXT_WHITE end)
				TextBox.FocusLost:Connect(function(enterPressed)
					BoxStroke.Color = COLOR_BOX_BORDER
					if callback then callback(TextBox.Text, enterPressed) end
				end)

				local Input = {}
				Input.Set = function(val) TextBox.Text = val end
				Input.Get = function() return TextBox.Text end

				if configKey then
					ConfigRegistry[configKey] = { Get = Input.Get, Set = Input.Set }
				end

				return Input
			end

			function Section:AddDropdown(dropConfig)
				dropConfig = dropConfig or {}
				local labelText = dropConfig.Name or "Dropdown"
				local options = dropConfig.Options or {}
				local default = dropConfig.Default or (options and options[1]) or "None"
				local callback = dropConfig.Callback
				local configKey = dropConfig.ConfigKey

				local selected = default
				local isOpen = false

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 52)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, 0, 0, 16)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_MUTED
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = Container

				local Header = Instance.new("TextButton")
				Header.Size = UDim2.new(1, 0, 0, 26)
				Header.Position = UDim2.new(0, 0, 0, 18)
				Header.BackgroundColor3 = COLOR_BOX_INACTIVE
				Header.BorderSizePixel = 0
				Header.AutoButtonColor = false
				Header.Text = ""
				Header.Parent = Container

				local HeaderCorner = Instance.new("UICorner")
				HeaderCorner.CornerRadius = UDim.new(0, 5)
				HeaderCorner.Parent = Header

				local HeaderStroke = Instance.new("UIStroke")
				HeaderStroke.Color = COLOR_BOX_BORDER
				HeaderStroke.Thickness = 1
				HeaderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				HeaderStroke.Parent = Header

				local SelText = Instance.new("TextLabel")
				SelText.Size = UDim2.new(1, -28, 1, 0)
				SelText.Position = UDim2.new(0, 8, 0, 0)
				SelText.BackgroundTransparency = 1
				SelText.FontFace = FONT_MEDIUM
				SelText.Text = selected
				SelText.TextColor3 = COLOR_TEXT_WHITE
				SelText.TextSize = 12
				SelText.TextXAlignment = Enum.TextXAlignment.Left
				SelText.Parent = Header

				local Chevron = Instance.new("ImageLabel")
				Chevron.Size = UDim2.new(0, 12, 0, 12)
				Chevron.Position = UDim2.new(1, -8, 0.5, 0)
				Chevron.AnchorPoint = Vector2.new(1, 0.5)
				Chevron.BackgroundTransparency = 1
				Chevron.ImageColor3 = COLOR_TEXT_MUTED
				ApplyIcon(Chevron, "chevron-down")
				Chevron.Parent = Header

				local OptionHolder = Instance.new("Frame")
				OptionHolder.Size = UDim2.new(1, 0, 0, 0)
				OptionHolder.Position = UDim2.new(0, 0, 0, 48)
				OptionHolder.BackgroundColor3 = COLOR_BOX_INACTIVE
				OptionHolder.BorderSizePixel = 0
				OptionHolder.Visible = false
				OptionHolder.ClipsDescendants = true
				OptionHolder.ZIndex = 10
				OptionHolder.Parent = Container

				local HolderCorner = Instance.new("UICorner")
				HolderCorner.CornerRadius = UDim.new(0, 5)
				HolderCorner.Parent = OptionHolder

				local HolderStroke = Instance.new("UIStroke")
				HolderStroke.Color = COLOR_BOX_BORDER
				HolderStroke.Thickness = 1
				HolderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				HolderStroke.Parent = OptionHolder

				local HolderLayout = Instance.new("UIListLayout")
				HolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
				HolderLayout.Padding = UDim.new(0, 2)
				HolderLayout.Parent = OptionHolder

				local HolderPadding = Instance.new("UIPadding")
				HolderPadding.PaddingTop = UDim.new(0, 4)
				HolderPadding.PaddingBottom = UDim.new(0, 4)
				HolderPadding.PaddingLeft = UDim.new(0, 4)
				HolderPadding.PaddingRight = UDim.new(0, 4)
				HolderPadding.Parent = OptionHolder

				local function ToggleList()
					isOpen = not isOpen
					OptionHolder.Visible = isOpen
					Chevron.Rotation = isOpen and 180 or 0
					HeaderStroke.Color = isOpen and COLOR_TEXT_WHITE or COLOR_BOX_BORDER
					if isOpen then
						local totalHeight = (#options * 24) + 8
						OptionHolder.Size = UDim2.new(1, 0, 0, math.min(totalHeight, 120))
						Container.Size = UDim2.new(1, 0, 0, 48 + math.min(totalHeight, 120) + 4)
					else
						Container.Size = UDim2.new(1, 0, 0, 52)
					end
				end

				Header.MouseButton1Click:Connect(ToggleList)

				for _, opt in ipairs(options) do
					local OptBtn = Instance.new("TextButton")
					OptBtn.Size = UDim2.new(1, 0, 0, 22)
					OptBtn.BackgroundColor3 = COLOR_ACTIVE_BG
					OptBtn.BackgroundTransparency = (opt == selected) and 0 or 1
					OptBtn.BorderSizePixel = 0
					OptBtn.FontFace = FONT_REGULAR
					OptBtn.Text = opt
					OptBtn.TextColor3 = (opt == selected) and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
					OptBtn.TextSize = 11
					OptBtn.TextXAlignment = Enum.TextXAlignment.Left
					OptBtn.AutoButtonColor = false
					OptBtn.Parent = OptionHolder

					local OptPad = Instance.new("UIPadding")
					OptPad.PaddingLeft = UDim.new(0, 6)
					OptPad.Parent = OptBtn

					local OptCorner = Instance.new("UICorner")
					OptCorner.CornerRadius = UDim.new(0, 4)
					OptCorner.Parent = OptBtn

					OptBtn.MouseEnter:Connect(function()
						OptBtn.BackgroundTransparency = 0
						OptBtn.TextColor3 = COLOR_TEXT_WHITE
					end)
					OptBtn.MouseLeave:Connect(function()
						if opt ~= selected then
							OptBtn.BackgroundTransparency = 1
							OptBtn.TextColor3 = COLOR_TEXT_MUTED
						end
					end)
					OptBtn.MouseButton1Click:Connect(function()
						selected = opt
						SelText.Text = selected
						ToggleList()
						for _, child in ipairs(OptionHolder:GetChildren()) do
							if child:IsA("TextButton") then
								local isSel = (child.Text == selected)
								child.BackgroundTransparency = isSel and 0 or 1
								child.TextColor3 = isSel and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
							end
						end
						if callback then callback(selected) end
					end)
				end

				local Dropdown = {}
				Dropdown.Set = function(val)
					selected = val
					SelText.Text = val
					for _, child in ipairs(OptionHolder:GetChildren()) do
						if child:IsA("TextButton") then
							local isSel = (child.Text == selected)
							child.BackgroundTransparency = isSel and 0 or 1
							child.TextColor3 = isSel and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
						end
					end
					if callback then callback(selected) end
				end
				Dropdown.Get = function() return selected end

				if configKey then
					ConfigRegistry[configKey] = { Get = Dropdown.Get, Set = Dropdown.Set }
				end

				return Dropdown
			end

			function Section:AddMultiDropdown(dropConfig)
				dropConfig = dropConfig or {}
				local labelText = dropConfig.Name or "Multi Dropdown"
				local options = dropConfig.Options or {}
				local defaultSelected = dropConfig.Default or {}
				local callback = dropConfig.Callback
				local configKey = dropConfig.ConfigKey

				local selected = {}
				if type(defaultSelected) == "table" then
					for _, item in ipairs(defaultSelected) do
						selected[item] = true
					end
				end
				local isOpen = false

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 52)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, 0, 0, 16)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_MUTED
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = Container

				local Header = Instance.new("TextButton")
				Header.Size = UDim2.new(1, 0, 0, 26)
				Header.Position = UDim2.new(0, 0, 0, 18)
				Header.BackgroundColor3 = COLOR_BOX_INACTIVE
				Header.BorderSizePixel = 0
				Header.AutoButtonColor = false
				Header.Text = ""
				Header.Parent = Container

				local HeaderCorner = Instance.new("UICorner")
				HeaderCorner.CornerRadius = UDim.new(0, 5)
				HeaderCorner.Parent = Header

				local HeaderStroke = Instance.new("UIStroke")
				HeaderStroke.Color = COLOR_BOX_BORDER
				HeaderStroke.Thickness = 1
				HeaderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				HeaderStroke.Parent = Header

				local SelText = Instance.new("TextLabel")
				SelText.Size = UDim2.new(1, -28, 1, 0)
				SelText.Position = UDim2.new(0, 8, 0, 0)
				SelText.BackgroundTransparency = 1
				SelText.FontFace = FONT_MEDIUM
				SelText.TextColor3 = COLOR_TEXT_WHITE
				SelText.TextSize = 12
				SelText.TextXAlignment = Enum.TextXAlignment.Left
				SelText.TextTruncate = Enum.TextTruncate.AtEnd
				SelText.Parent = Header

				local function FormatSelected()
					local list = {}
					for _, opt in ipairs(options) do
						if selected[opt] then table.insert(list, opt) end
					end
					return #list == 0 and "None" or table.concat(list, ", ")
				end

				SelText.Text = FormatSelected()

				local Chevron = Instance.new("ImageLabel")
				Chevron.Size = UDim2.new(0, 12, 0, 12)
				Chevron.Position = UDim2.new(1, -8, 0.5, 0)
				Chevron.AnchorPoint = Vector2.new(1, 0.5)
				Chevron.BackgroundTransparency = 1
				Chevron.ImageColor3 = COLOR_TEXT_MUTED
				ApplyIcon(Chevron, "chevron-down")
				Chevron.Parent = Header

				local OptionHolder = Instance.new("Frame")
				OptionHolder.Size = UDim2.new(1, 0, 0, 0)
				OptionHolder.Position = UDim2.new(0, 0, 0, 48)
				OptionHolder.BackgroundColor3 = COLOR_BOX_INACTIVE
				OptionHolder.BorderSizePixel = 0
				OptionHolder.Visible = false
				OptionHolder.ClipsDescendants = true
				OptionHolder.ZIndex = 10
				OptionHolder.Parent = Container

				local HolderCorner = Instance.new("UICorner")
				HolderCorner.CornerRadius = UDim.new(0, 5)
				HolderCorner.Parent = OptionHolder

				local HolderStroke = Instance.new("UIStroke")
				HolderStroke.Color = COLOR_BOX_BORDER
				HolderStroke.Thickness = 1
				HolderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				HolderStroke.Parent = OptionHolder

				local HolderLayout = Instance.new("UIListLayout")
				HolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
				HolderLayout.Padding = UDim.new(0, 2)
				HolderLayout.Parent = OptionHolder

				local HolderPadding = Instance.new("UIPadding")
				HolderPadding.PaddingTop = UDim.new(0, 4)
				HolderPadding.PaddingBottom = UDim.new(0, 4)
				HolderPadding.PaddingLeft = UDim.new(0, 4)
				HolderPadding.PaddingRight = UDim.new(0, 4)
				HolderPadding.Parent = OptionHolder

				local function ToggleList()
					isOpen = not isOpen
					OptionHolder.Visible = isOpen
					Chevron.Rotation = isOpen and 180 or 0
					HeaderStroke.Color = isOpen and COLOR_TEXT_WHITE or COLOR_BOX_BORDER
					if isOpen then
						local totalHeight = (#options * 24) + 8
						OptionHolder.Size = UDim2.new(1, 0, 0, math.min(totalHeight, 120))
						Container.Size = UDim2.new(1, 0, 0, 48 + math.min(totalHeight, 120) + 4)
					else
						Container.Size = UDim2.new(1, 0, 0, 52)
					end
				end

				Header.MouseButton1Click:Connect(ToggleList)

				for _, opt in ipairs(options) do
					local OptBtn = Instance.new("TextButton")
					OptBtn.Size = UDim2.new(1, 0, 0, 22)
					OptBtn.BackgroundColor3 = COLOR_ACTIVE_BG
					OptBtn.BackgroundTransparency = selected[opt] and 0 or 1
					OptBtn.BorderSizePixel = 0
					OptBtn.FontFace = FONT_REGULAR
					OptBtn.Text = opt
					OptBtn.TextColor3 = selected[opt] and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
					OptBtn.TextSize = 11
					OptBtn.TextXAlignment = Enum.TextXAlignment.Left
					OptBtn.AutoButtonColor = false
					OptBtn.Parent = OptionHolder

					local OptPad = Instance.new("UIPadding")
					OptPad.PaddingLeft = UDim.new(0, 6)
					OptPad.Parent = OptBtn

					local OptCorner = Instance.new("UICorner")
					OptCorner.CornerRadius = UDim.new(0, 4)
					OptCorner.Parent = OptBtn

					OptBtn.MouseButton1Click:Connect(function()
						selected[opt] = not selected[opt]
						OptBtn.BackgroundTransparency = selected[opt] and 0 or 1
						OptBtn.TextColor3 = selected[opt] and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
						SelText.Text = FormatSelected()
						if callback then callback(selected) end
					end)
				end

				local MultiDropdown = {}
				MultiDropdown.Set = function(val)
					selected = {}
					if type(val) == "table" then
						for _, item in ipairs(val) do selected[item] = true end
					end
					SelText.Text = FormatSelected()
					for _, child in ipairs(OptionHolder:GetChildren()) do
						if child:IsA("TextButton") then
							local isSel = selected[child.Text] == true
							child.BackgroundTransparency = isSel and 0 or 1
							child.TextColor3 = isSel and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
						end
					end
					if callback then callback(selected) end
				end
				MultiDropdown.Get = function()
					local list = {}
					for k, v in pairs(selected) do if v then table.insert(list, k) end end
					return list
				end

				if configKey then
					ConfigRegistry[configKey] = { Get = MultiDropdown.Get, Set = MultiDropdown.Set }
				end

				return MultiDropdown
			end

			function Section:AddColorPicker(pickerConfig)
				pickerConfig = pickerConfig or {}
				local labelText = pickerConfig.Name or "Color Picker"
				local default = pickerConfig.Default or Color3.fromRGB(0, 230, 150)
				local callback = pickerConfig.Callback
				local configKey = pickerConfig.ConfigKey

				local color = default
				local h, s, v = color:ToHSV()
				local isOpen = false

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 24)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local TopHeader = Instance.new("Frame")
				TopHeader.Size = UDim2.new(1, 0, 0, 24)
				TopHeader.BackgroundTransparency = 1
				TopHeader.Parent = Container

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, -45, 1, 0)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_MUTED
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = TopHeader

				local PreviewBtn = Instance.new("TextButton")
				PreviewBtn.Size = UDim2.new(0, 32, 0, 16)
				PreviewBtn.Position = UDim2.new(1, 0, 0.5, 0)
				PreviewBtn.AnchorPoint = Vector2.new(1, 0.5)
				PreviewBtn.BackgroundColor3 = color
				PreviewBtn.BorderSizePixel = 0
				PreviewBtn.Text = ""
				PreviewBtn.AutoButtonColor = false
				PreviewBtn.Parent = TopHeader

				local PreviewCorner = Instance.new("UICorner")
				PreviewCorner.CornerRadius = UDim.new(0, 4)
				PreviewCorner.Parent = PreviewBtn

				local PreviewStroke = Instance.new("UIStroke")
				PreviewStroke.Color = COLOR_BOX_BORDER
				PreviewStroke.Thickness = 1
				PreviewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				PreviewStroke.Parent = PreviewBtn

				local PickerPanel = Instance.new("Frame")
				PickerPanel.Size = UDim2.new(1, 0, 0, 142)
				PickerPanel.Position = UDim2.new(0, 0, 0, 28)
				PickerPanel.BackgroundColor3 = COLOR_BOX_INACTIVE
				PickerPanel.BorderSizePixel = 0
				PickerPanel.Visible = false
				PickerPanel.ClipsDescendants = true
				PickerPanel.ZIndex = 12
				PickerPanel.Parent = Container

				local PanelCorner = Instance.new("UICorner")
				PanelCorner.CornerRadius = UDim.new(0, 6)
				PanelCorner.Parent = PickerPanel

				local PanelStroke = Instance.new("UIStroke")
				PanelStroke.Color = COLOR_BOX_BORDER
				PanelStroke.Thickness = 1
				PanelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				PanelStroke.Parent = PickerPanel

				local SVBox = Instance.new("Frame")
				SVBox.Size = UDim2.new(1, -36, 0, 95)
				SVBox.Position = UDim2.new(0, 8, 0, 8)
				SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				SVBox.BorderSizePixel = 0
				SVBox.Parent = PickerPanel

				local SVCorner = Instance.new("UICorner")
				SVCorner.CornerRadius = UDim.new(0, 4)
				SVCorner.Parent = SVBox

				local WhiteGradFrame = Instance.new("Frame")
				WhiteGradFrame.Size = UDim2.new(1, 0, 1, 0)
				WhiteGradFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				WhiteGradFrame.BorderSizePixel = 0
				WhiteGradFrame.Parent = SVBox

				local WhiteCorner = Instance.new("UICorner")
				WhiteCorner.CornerRadius = UDim.new(0, 4)
				WhiteCorner.Parent = WhiteGradFrame

				local WhiteGrad = Instance.new("UIGradient")
				WhiteGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
				WhiteGrad.Parent = WhiteGradFrame

				local BlackGradFrame = Instance.new("Frame")
				BlackGradFrame.Size = UDim2.new(1, 0, 1, 0)
				BlackGradFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				BlackGradFrame.BorderSizePixel = 0
				BlackGradFrame.Parent = SVBox

				local BlackCorner = Instance.new("UICorner")
				BlackCorner.CornerRadius = UDim.new(0, 4)
				BlackCorner.Parent = BlackGradFrame

				local BlackGrad = Instance.new("UIGradient")
				BlackGrad.Rotation = 90
				BlackGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
				BlackGrad.Parent = BlackGradFrame

				local SVCursor = Instance.new("Frame")
				SVCursor.Size = UDim2.new(0, 10, 0, 10)
				SVCursor.AnchorPoint = Vector2.new(0.5, 0.5)
				SVCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				SVCursor.BackgroundColor3 = color
				SVCursor.BorderSizePixel = 0
				SVCursor.ZIndex = 2
				SVCursor.Parent = SVBox

				local SVCursorCorner = Instance.new("UICorner")
				SVCursorCorner.CornerRadius = UDim.new(1, 0)
				SVCursorCorner.Parent = SVCursor

				local SVCursorStroke = Instance.new("UIStroke")
				SVCursorStroke.Color = Color3.fromRGB(255, 255, 255)
				SVCursorStroke.Thickness = 1.5
				SVCursorStroke.Parent = SVCursor

				local HueBar = Instance.new("Frame")
				HueBar.Size = UDim2.new(0, 12, 0, 95)
				HueBar.Position = UDim2.new(1, -18, 0, 8)
				HueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				HueBar.BorderSizePixel = 0
				HueBar.Parent = PickerPanel

				local HueCorner = Instance.new("UICorner")
				HueCorner.CornerRadius = UDim.new(0, 4)
				HueCorner.Parent = HueBar

				local HueGrad = Instance.new("UIGradient")
				HueGrad.Rotation = 90
				HueGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
				})
				HueGrad.Parent = HueBar

				local HueCursor = Instance.new("Frame")
				HueCursor.Size = UDim2.new(1, 4, 0, 4)
				HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
				HueCursor.Position = UDim2.new(0.5, 0, h, 0)
				HueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				HueCursor.BorderSizePixel = 0
				HueCursor.ZIndex = 2
				HueCursor.Parent = HueBar

				local HueCursorCorner = Instance.new("UICorner")
				HueCursorCorner.CornerRadius = UDim.new(1, 0)
				HueCursorCorner.Parent = HueCursor

				local HueCursorStroke = Instance.new("UIStroke")
				HueCursorStroke.Color = Color3.fromRGB(0, 0, 0)
				HueCursorStroke.Thickness = 1
				HueCursorStroke.Parent = HueCursor

				local ColorValBox = Instance.new("TextBox")
				ColorValBox.Size = UDim2.new(1, -16, 0, 22)
				ColorValBox.Position = UDim2.new(0, 8, 0, 110)
				ColorValBox.BackgroundColor3 = COLOR_SEARCH_BG
				ColorValBox.BorderSizePixel = 0
				ColorValBox.FontFace = FONT_MEDIUM
				ColorValBox.Text = string.format("rgb(%d, %d, %d)", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
				ColorValBox.TextColor3 = COLOR_TEXT_WHITE
				ColorValBox.TextSize = 11
				ColorValBox.ClearTextOnFocus = false
				ColorValBox.Parent = PickerPanel

				local ValBoxCorner = Instance.new("UICorner")
				ValBoxCorner.CornerRadius = UDim.new(0, 4)
				ValBoxCorner.Parent = ColorValBox

				local ValBoxStroke = Instance.new("UIStroke")
				ValBoxStroke.Color = COLOR_BOX_BORDER
				ValBoxStroke.Thickness = 1
				ValBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				ValBoxStroke.Parent = ColorValBox

				local function UpdateColor()
					color = Color3.fromHSV(h, s, v)
					SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
					SVCursor.Position = UDim2.new(s, 0, 1 - v, 0)
					SVCursor.BackgroundColor3 = color
					HueCursor.Position = UDim2.new(0.5, 0, h, 0)
					PreviewBtn.BackgroundColor3 = color
					ColorValBox.Text = string.format("rgb(%d, %d, %d)", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
					if callback then callback(color) end
				end

				local draggingSV = false
				local draggingHue = false

				SVBox.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						draggingSV = true
						local posX = math.clamp(input.Position.X - SVBox.AbsolutePosition.X, 0, SVBox.AbsoluteSize.X)
						local posY = math.clamp(input.Position.Y - SVBox.AbsolutePosition.Y, 0, SVBox.AbsoluteSize.Y)
						s = posX / SVBox.AbsoluteSize.X
						v = 1 - (posY / SVBox.AbsoluteSize.Y)
						UpdateColor()
					end
				end)

				HueBar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						draggingHue = true
						local posY = math.clamp(input.Position.Y - HueBar.AbsolutePosition.Y, 0, HueBar.AbsoluteSize.Y)
						h = posY / HueBar.AbsoluteSize.Y
						UpdateColor()
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						if draggingSV then
							local posX = math.clamp(input.Position.X - SVBox.AbsolutePosition.X, 0, SVBox.AbsoluteSize.X)
							local posY = math.clamp(input.Position.Y - SVBox.AbsolutePosition.Y, 0, SVBox.AbsoluteSize.Y)
							s = posX / SVBox.AbsoluteSize.X
							v = 1 - (posY / SVBox.AbsoluteSize.Y)
							UpdateColor()
						end
						if draggingHue then
							local posY = math.clamp(input.Position.Y - HueBar.AbsolutePosition.Y, 0, HueBar.AbsoluteSize.Y)
							h = posY / HueBar.AbsoluteSize.Y
							UpdateColor()
						end
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						draggingSV = false
						draggingHue = false
					end
				end)

				ColorValBox.FocusLost:Connect(function()
					local r, g, b = ColorValBox.Text:match("rgb%s*%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)")
					if r and g and b then
						color = Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255))
						h, s, v = color:ToHSV()
						UpdateColor()
					else
						local hex = ColorValBox.Text:gsub("#", "")
						if #hex == 6 then
							local hr, hg, hb = tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16)
							if hr and hg and hb then
								color = Color3.fromRGB(hr, hg, hb)
								h, s, v = color:ToHSV()
								UpdateColor()
							end
						end
					end
				end)

				PreviewBtn.MouseButton1Click:Connect(function()
					isOpen = not isOpen
					PickerPanel.Visible = isOpen
					Container.Size = isOpen and UDim2.new(1, 0, 0, 172) or UDim2.new(1, 0, 0, 24)
				end)

				local Picker = {}
				Picker.Set = function(val)
					color = val
					h, s, v = color:ToHSV()
					UpdateColor()
				end
				Picker.Get = function()
					return { r = math.floor(color.R * 255 + 0.5), g = math.floor(color.G * 255 + 0.5), b = math.floor(color.B * 255 + 0.5) }
				end

				if configKey then
					ConfigRegistry[configKey] = {
						Get = function()
							return { r = math.floor(color.R * 255 + 0.5), g = math.floor(color.G * 255 + 0.5), b = math.floor(color.B * 255 + 0.5) }
						end,
						Set = function(val)
							if type(val) == "table" and val.r then
								Picker.Set(Color3.fromRGB(val.r, val.g, val.b))
							end
						end
					}
				end

				return Picker
			end

			function Section:AddButton(btnConfig)
				btnConfig = btnConfig or {}
				local buttonText = btnConfig.Name or "Button"
				local callback = btnConfig.Callback

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 24)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local BtnBg = Instance.new("Frame")
				BtnBg.Size = UDim2.new(1, 0, 1, 0)
				BtnBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				BtnBg.BorderSizePixel = 0
				BtnBg.Parent = Container

				local BtnCorner = Instance.new("UICorner")
				BtnCorner.CornerRadius = UDim.new(0, 5)
				BtnCorner.Parent = BtnBg

				local BtnGradient = Instance.new("UIGradient")
				BtnGradient.Rotation = 90
				BtnGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20))
				})
				BtnGradient.Parent = BtnBg

				local BtnStroke = Instance.new("UIStroke")
				BtnStroke.Color = Color3.fromRGB(45, 45, 55)
				BtnStroke.Thickness = 1.2
				BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				BtnStroke.Parent = BtnBg

				local Button = Instance.new("TextButton")
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.BackgroundTransparency = 1
				Button.FontFace = FONT_MEDIUM
				Button.Text = string.lower(buttonText)
				Button.TextColor3 = COLOR_TEXT_WHITE
				Button.TextScaled = true
				Button.AutoButtonColor = false
				Button.Parent = Container

				local TextConstraint = Instance.new("UITextSizeConstraint")
				TextConstraint.MaxTextSize = 13
				TextConstraint.MinTextSize = 8
				TextConstraint.Parent = Button

				local BtnPadding = Instance.new("UIPadding")
				BtnPadding.PaddingTop = UDim.new(0, 4)
				BtnPadding.PaddingBottom = UDim.new(0, 4)
				BtnPadding.Parent = Button

				Button.MouseEnter:Connect(function()
					BtnGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)) })
					BtnStroke.Color = Color3.fromRGB(65, 65, 80)
				end)
				Button.MouseLeave:Connect(function()
					BtnGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)) })
					BtnStroke.Color = Color3.fromRGB(45, 45, 55)
				end)
				Button.MouseButton1Down:Connect(function()
					BtnGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 25)), ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 16)) })
				end)
				Button.MouseButton1Up:Connect(function()
					BtnGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)) })
				end)
				Button.MouseButton1Click:Connect(function()
					if callback then callback() end
				end)

				return Container
			end

			function Section:AddKeybind(keybindConfig)
				keybindConfig = keybindConfig or {}
				local labelText = keybindConfig.Name or "Keybind"
				local defaultKey = keybindConfig.Default or Enum.UserInputType.MouseButton3
				local callback = keybindConfig.Callback
				local configKey = keybindConfig.ConfigKey

				local boundKey = defaultKey
				local binding = false

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 22)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, -60, 1, 0)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_MUTED
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = Container

				local KeyBtnHolder = Instance.new("Frame")
				KeyBtnHolder.Size = UDim2.new(0, 36, 0, 20)
				KeyBtnHolder.Position = UDim2.new(1, 0, 0.5, 0)
				KeyBtnHolder.AnchorPoint = Vector2.new(1, 0.5)
				KeyBtnHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				KeyBtnHolder.BorderSizePixel = 0
				KeyBtnHolder.Parent = Container

				local KeyCorner = Instance.new("UICorner")
				KeyCorner.CornerRadius = UDim.new(0, 5)
				KeyCorner.Parent = KeyBtnHolder

				local KeyGradient = Instance.new("UIGradient")
				KeyGradient.Rotation = 90
				KeyGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)) })
				KeyGradient.Parent = KeyBtnHolder

				local KeyStroke = Instance.new("UIStroke")
				KeyStroke.Color = Color3.fromRGB(45, 45, 55)
				KeyStroke.Thickness = 1.2
				KeyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				KeyStroke.Parent = KeyBtnHolder

				local KeyBtn = Instance.new("TextButton")
				KeyBtn.Size = UDim2.new(1, 0, 1, 0)
				KeyBtn.BackgroundTransparency = 1
				KeyBtn.FontFace = FONT_BOLD
				KeyBtn.TextSize = 11
				KeyBtn.TextColor3 = COLOR_TEXT_WHITE
				KeyBtn.AutoButtonColor = false
				KeyBtn.Parent = KeyBtnHolder

				local function FormatKey(key)
					if not key then return "None" end
					if typeof(key) == "EnumItem" then
						if key.EnumType == Enum.KeyCode then
							if key == Enum.KeyCode.Unknown then return "None" end
							return key.Name
						elseif key.EnumType == Enum.UserInputType then
							if key == Enum.UserInputType.MouseButton1 then return "M1" end
							if key == Enum.UserInputType.MouseButton2 then return "M2" end
							if key == Enum.UserInputType.MouseButton3 then return "M3" end
							if key == Enum.UserInputType.MouseButton4 then return "M4" end
							if key == Enum.UserInputType.MouseButton5 then return "M5" end
						end
					end
					return tostring(key)
				end

				local function UpdateText()
					if binding then
						KeyBtn.Text = "..."
						KeyStroke.Color = COLOR_TEXT_WHITE
						KeyGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)) })
						Lbl.TextColor3 = COLOR_TEXT_WHITE
					else
						KeyBtn.Text = FormatKey(boundKey)
						KeyStroke.Color = Color3.fromRGB(45, 45, 55)
						KeyGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)) })
						Lbl.TextColor3 = COLOR_TEXT_MUTED
					end
					local textSize = TextService:GetTextSize(KeyBtn.Text, 11, Enum.Font.SourceSans, Vector2.new(120, 20))
					KeyBtnHolder.Size = UDim2.new(0, math.max(34, textSize.X + 14), 0, 20)
				end

				UpdateText()

				KeyBtn.MouseEnter:Connect(function()
					if not binding then
						KeyGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)) })
						KeyStroke.Color = Color3.fromRGB(65, 65, 80)
					end
				end)
				KeyBtn.MouseLeave:Connect(function()
					if not binding then
						KeyGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)) })
						KeyStroke.Color = Color3.fromRGB(45, 45, 55)
					end
				end)
				KeyBtn.MouseButton1Click:Connect(function()
					binding = true
					UpdateText()
				end)

				UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if binding then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							boundKey = input.KeyCode == Enum.KeyCode.Escape and nil or input.KeyCode
							binding = false
							UpdateText()
							if callback then callback(boundKey) end
						elseif string.find(input.UserInputType.Name, "MouseButton") then
							boundKey = input.UserInputType
							binding = false
							UpdateText()
							if callback then callback(boundKey) end
						end
					end
				end)

				local Keybind = {}
				Keybind.Get = function() return boundKey end
				Keybind.Set = function(val)
					boundKey = val
					UpdateText()
				end

				if configKey then
					ConfigRegistry[configKey] = {
						Get = function()
							if not boundKey then return nil end
							if typeof(boundKey) == "EnumItem" then return tostring(boundKey) end
							return nil
						end,
						Set = function(val)
							if type(val) == "string" then
								local ok, enumVal = pcall(function() return Enum.KeyCode[val] end)
								if ok and enumVal then
									Keybind.Set(enumVal)
								end
							end
						end
					}
				end

				return Keybind
			end

			function Section:AddSearchDropdown(dropConfig)
				dropConfig = dropConfig or {}
				local labelText = dropConfig.Name or "Search Dropdown"
				local callback = dropConfig.Callback
				local configKey = dropConfig.ConfigKey
				local playerMode = dropConfig.Player == true
				local teamMode = dropConfig.Team == true

				local selected = nil
				local isOpen = false
				local allOptions = {}

				local function BuildOptions()
					allOptions = {}
					if playerMode then
						for _, p in ipairs(Players:GetPlayers()) do
							table.insert(allOptions, { label = p.Name, type = "player", object = p })
						end
					end
					if teamMode then
						local teamsService = game:FindService("Teams")
						if teamsService then
							for _, t in ipairs(teamsService:GetTeams()) do
								table.insert(allOptions, { label = t.Name, type = "team", object = t })
							end
						end
					end
				end

				BuildOptions()

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 52)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, 0, 0, 16)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_MUTED
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = Container

				local Header = Instance.new("Frame")
				Header.Size = UDim2.new(1, 0, 0, 26)
				Header.Position = UDim2.new(0, 0, 0, 18)
				Header.BackgroundColor3 = COLOR_BOX_INACTIVE
				Header.BorderSizePixel = 0
				Header.Parent = Container

				local HeaderCorner = Instance.new("UICorner")
				HeaderCorner.CornerRadius = UDim.new(0, 5)
				HeaderCorner.Parent = Header

				local HeaderStroke = Instance.new("UIStroke")
				HeaderStroke.Color = COLOR_BOX_BORDER
				HeaderStroke.Thickness = 1
				HeaderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				HeaderStroke.Parent = Header

				local SearchBox = Instance.new("TextBox")
				SearchBox.Size = UDim2.new(1, -28, 1, 0)
				SearchBox.Position = UDim2.new(0, 8, 0, 0)
				SearchBox.BackgroundTransparency = 1
				SearchBox.FontFace = FONT_MEDIUM
				SearchBox.PlaceholderText = selected or "search..."
				SearchBox.PlaceholderColor3 = COLOR_TEXT_SUB
				SearchBox.Text = ""
				SearchBox.TextColor3 = COLOR_TEXT_WHITE
				SearchBox.TextSize = 12
				SearchBox.TextXAlignment = Enum.TextXAlignment.Left
				SearchBox.ClearTextOnFocus = false
				SearchBox.Parent = Header

				local Chevron = Instance.new("ImageLabel")
				Chevron.Size = UDim2.new(0, 12, 0, 12)
				Chevron.Position = UDim2.new(1, -8, 0.5, 0)
				Chevron.AnchorPoint = Vector2.new(1, 0.5)
				Chevron.BackgroundTransparency = 1
				Chevron.ImageColor3 = COLOR_TEXT_MUTED
				ApplyIcon(Chevron, "chevron-down")
				Chevron.Parent = Header

				local OptionHolder = Instance.new("Frame")
				OptionHolder.Size = UDim2.new(1, 0, 0, 0)
				OptionHolder.Position = UDim2.new(0, 0, 0, 48)
				OptionHolder.BackgroundColor3 = COLOR_BOX_INACTIVE
				OptionHolder.BorderSizePixel = 0
				OptionHolder.Visible = false
				OptionHolder.ClipsDescendants = true
				OptionHolder.ZIndex = 10
				OptionHolder.Parent = Container

				local HolderCorner = Instance.new("UICorner")
				HolderCorner.CornerRadius = UDim.new(0, 5)
				HolderCorner.Parent = OptionHolder

				local HolderStroke = Instance.new("UIStroke")
				HolderStroke.Color = COLOR_BOX_BORDER
				HolderStroke.Thickness = 1
				HolderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				HolderStroke.Parent = OptionHolder

				local HolderScrollFrame = Instance.new("ScrollingFrame")
				HolderScrollFrame.Size = UDim2.new(1, 0, 1, 0)
				HolderScrollFrame.BackgroundTransparency = 1
				HolderScrollFrame.BorderSizePixel = 0
				HolderScrollFrame.ScrollBarThickness = 3
				HolderScrollFrame.ScrollBarImageColor3 = COLOR_BORDER
				HolderScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
				HolderScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
				HolderScrollFrame.Parent = OptionHolder

				local HolderLayout = Instance.new("UIListLayout")
				HolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
				HolderLayout.Padding = UDim.new(0, 2)
				HolderLayout.Parent = HolderScrollFrame

				local HolderPadding = Instance.new("UIPadding")
				HolderPadding.PaddingTop = UDim.new(0, 4)
				HolderPadding.PaddingBottom = UDim.new(0, 4)
				HolderPadding.PaddingLeft = UDim.new(0, 4)
				HolderPadding.PaddingRight = UDim.new(0, 4)
				HolderPadding.Parent = HolderScrollFrame

				local function RebuildList(query)
					for _, child in ipairs(HolderScrollFrame:GetChildren()) do
						if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
					end
					BuildOptions()
					local filtered = {}
					local lower = string.lower(query or "")
					for _, opt in ipairs(allOptions) do
						if lower == "" or string.find(string.lower(opt.label), lower, 1, true) then
							table.insert(filtered, opt)
						end
					end
					for _, opt in ipairs(filtered) do
						local RowFrame = Instance.new("Frame")
						RowFrame.Size = UDim2.new(1, 0, 0, 24)
						RowFrame.BackgroundTransparency = 1
						RowFrame.Parent = HolderScrollFrame

						local RowLayout = Instance.new("UIListLayout")
						RowLayout.FillDirection = Enum.FillDirection.Horizontal
						RowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
						RowLayout.Padding = UDim.new(0, 6)
						RowLayout.Parent = RowFrame

						local RowPad = Instance.new("UIPadding")
						RowPad.PaddingLeft = UDim.new(0, 4)
						RowPad.Parent = RowFrame

						if opt.type == "player" then
							local AvatarImg = Instance.new("ImageLabel")
							AvatarImg.Size = UDim2.new(0, 16, 0, 16)
							AvatarImg.BackgroundTransparency = 1
							AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(opt.object.UserId) .. "&w=48&h=48"
							AvatarImg.Parent = RowFrame

							local AvatarCorner = Instance.new("UICorner")
							AvatarCorner.CornerRadius = UDim.new(1, 0)
							AvatarCorner.Parent = AvatarImg
						elseif opt.type == "team" then
							local TeamDot = Instance.new("Frame")
							TeamDot.Size = UDim2.new(0, 10, 0, 10)
							TeamDot.BackgroundColor3 = opt.object.TeamColor.Color
							TeamDot.BorderSizePixel = 0
							TeamDot.Parent = RowFrame

							local DotCorner = Instance.new("UICorner")
							DotCorner.CornerRadius = UDim.new(1, 0)
							DotCorner.Parent = TeamDot
						end

						local OptBtn = Instance.new("TextButton")
						OptBtn.Size = UDim2.new(1, -30, 1, 0)
						OptBtn.BackgroundTransparency = 1
						OptBtn.FontFace = FONT_REGULAR
						OptBtn.Text = opt.label
						OptBtn.TextColor3 = (opt.label == selected) and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
						OptBtn.TextSize = 11
						OptBtn.TextXAlignment = Enum.TextXAlignment.Left
						OptBtn.AutoButtonColor = false
						OptBtn.Parent = RowFrame

						OptBtn.MouseEnter:Connect(function()
							OptBtn.TextColor3 = COLOR_TEXT_WHITE
						end)
						OptBtn.MouseLeave:Connect(function()
							if opt.label ~= selected then
								OptBtn.TextColor3 = COLOR_TEXT_MUTED
							end
						end)
						OptBtn.MouseButton1Click:Connect(function()
							selected = opt.label
							SearchBox.PlaceholderText = selected
							SearchBox.Text = ""
							isOpen = false
							OptionHolder.Visible = false
							Chevron.Rotation = 0
							HeaderStroke.Color = COLOR_BOX_BORDER
							Container.Size = UDim2.new(1, 0, 0, 52)
							if callback then callback(selected, opt.type, opt.object) end
						end)
					end
					HolderLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
						HolderScrollFrame.CanvasSize = UDim2.new(0, 0, 0, HolderLayout.AbsoluteContentSize.Y)
					end)
					local count = #filtered
					local listHeight = math.min(count * 26 + 8, 120)
					OptionHolder.Size = UDim2.new(1, 0, 0, listHeight)
					Container.Size = UDim2.new(1, 0, 0, 48 + listHeight + 4)
				end

				local function OpenList()
					isOpen = true
					OptionHolder.Visible = true
					Chevron.Rotation = 180
					HeaderStroke.Color = COLOR_TEXT_WHITE
					RebuildList(SearchBox.Text)
				end

				local function CloseList()
					isOpen = false
					OptionHolder.Visible = false
					Chevron.Rotation = 0
					HeaderStroke.Color = COLOR_BOX_BORDER
					Container.Size = UDim2.new(1, 0, 0, 52)
				end

				SearchBox.Focused:Connect(function()
					OpenList()
				end)
				SearchBox.FocusLost:Connect(function()
					task.delay(0.15, function()
						if not SearchBox:IsFocused() then
							CloseList()
						end
					end)
				end)
				SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
					if isOpen then
						RebuildList(SearchBox.Text)
					end
				end)

				local SearchDropdown = {}
				SearchDropdown.Get = function() return selected end
				SearchDropdown.Set = function(val)
					selected = val
					SearchBox.PlaceholderText = val or "search..."
					SearchBox.Text = ""
				end

				if configKey then
					ConfigRegistry[configKey] = { Get = SearchDropdown.Get, Set = SearchDropdown.Set }
				end

				return SearchDropdown
			end

			function Section:AddImage(imageConfig)
				imageConfig = imageConfig or {}
				local imageId = imageConfig.ImageId or 0
				local imageWidth = imageConfig.Width or 100
				local imageHeight = imageConfig.Height or 100
				local imageRotation = imageConfig.Rotation or 0
				local imageScaleType = imageConfig.ScaleType or Enum.ScaleType.Fit
				local imageColor = imageConfig.Color or Color3.fromRGB(255, 255, 255)
				local imageTransparency = imageConfig.Transparency or 0
				local labelText = imageConfig.Name

				local totalHeight = imageHeight + (labelText and 20 or 0) + 8

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, totalHeight)
				Container.BackgroundTransparency = 1
				Container.ClipsDescendants = false
				Container.Parent = SecContent

				if labelText then
					local Lbl = Instance.new("TextLabel")
					Lbl.Size = UDim2.new(1, 0, 0, 16)
					Lbl.BackgroundTransparency = 1
					Lbl.FontFace = FONT_MEDIUM
					Lbl.Text = labelText
					Lbl.TextColor3 = COLOR_TEXT_MUTED
					Lbl.TextSize = 12
					Lbl.TextXAlignment = Enum.TextXAlignment.Left
					Lbl.Parent = Container
				end

				local yOffset = labelText and 20 or 0

				local ImageFrame = Instance.new("Frame")
				ImageFrame.Size = UDim2.new(0, imageWidth, 0, imageHeight)
				ImageFrame.Position = UDim2.new(0, 0, 0, yOffset)
				ImageFrame.BackgroundTransparency = 1
				ImageFrame.Rotation = imageRotation
				ImageFrame.Parent = Container

				local ImageLabel = Instance.new("ImageLabel")
				ImageLabel.Size = UDim2.new(1, 0, 1, 0)
				ImageLabel.BackgroundTransparency = 1
				ImageLabel.Image = type(imageId) == "number" and ("rbxassetid://" .. imageId) or tostring(imageId)
				ImageLabel.ImageColor3 = imageColor
				ImageLabel.ImageTransparency = imageTransparency
				ImageLabel.ScaleType = imageScaleType
				ImageLabel.Parent = ImageFrame

				local Image = {}
				Image.SetImageId = function(id)
					ImageLabel.Image = type(id) == "number" and ("rbxassetid://" .. id) or tostring(id)
				end
				Image.SetRotation = function(r)
					ImageFrame.Rotation = r
				end
				Image.SetSize = function(w, h)
					ImageFrame.Size = UDim2.new(0, w, 0, h)
					Container.Size = UDim2.new(1, 0, 0, h + (labelText and 20 or 0) + 8)
				end
				Image.SetColor = function(c)
					ImageLabel.ImageColor3 = c
				end
				Image.SetTransparency = function(t)
					ImageLabel.ImageTransparency = t
				end
				Image.GetFrame = function()
					return ImageFrame
				end

				return Image
			end

			function Section:ApplyConfigManager(configManagerConfig)
				configManagerConfig = configManagerConfig or {}
				local folder = self._window._configFolder

				local currentConfigNameInput
				local configDropdown
				local autoloadLabel

				local function RefreshDropdown()
					local configs = ListConfigs(folder)
					local autoload = GetAutoload(folder)
					if autoloadLabel then
						autoloadLabel.Text = autoload and ("autoload: " .. autoload) or "autoload: none"
					end
					if configDropdown and configDropdown._optionHolder then
						for _, child in ipairs(configDropdown._optionHolder:GetChildren()) do
							if child:IsA("TextButton") then child:Destroy() end
						end
						for _, cfgName in ipairs(configs) do
							local OptBtn = Instance.new("TextButton")
							OptBtn.Size = UDim2.new(1, 0, 0, 22)
							OptBtn.BackgroundColor3 = COLOR_ACTIVE_BG
							OptBtn.BackgroundTransparency = (cfgName == configDropdown._selected) and 0 or 1
							OptBtn.BorderSizePixel = 0
							OptBtn.FontFace = FONT_REGULAR
							OptBtn.Text = cfgName
							OptBtn.TextColor3 = (cfgName == configDropdown._selected) and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
							OptBtn.TextSize = 11
							OptBtn.TextXAlignment = Enum.TextXAlignment.Left
							OptBtn.AutoButtonColor = false
							OptBtn.Parent = configDropdown._optionHolder

							local OptPad = Instance.new("UIPadding")
							OptPad.PaddingLeft = UDim.new(0, 6)
							OptPad.Parent = OptBtn

							local OptCorner = Instance.new("UICorner")
							OptCorner.CornerRadius = UDim.new(0, 4)
							OptCorner.Parent = OptBtn

							OptBtn.MouseEnter:Connect(function()
								OptBtn.BackgroundTransparency = 0
								OptBtn.TextColor3 = COLOR_TEXT_WHITE
							end)
							OptBtn.MouseLeave:Connect(function()
								if cfgName ~= configDropdown._selected then
									OptBtn.BackgroundTransparency = 1
									OptBtn.TextColor3 = COLOR_TEXT_MUTED
								end
							end)
							OptBtn.MouseButton1Click:Connect(function()
								configDropdown._selected = cfgName
								configDropdown._selText.Text = cfgName
								configDropdown._isOpen = false
								configDropdown._optionHolder.Visible = false
								configDropdown._chevron.Rotation = 0
								configDropdown._headerStroke.Color = COLOR_BOX_BORDER
								configDropdown._container.Size = UDim2.new(1, 0, 0, 48)
								for _, child2 in ipairs(configDropdown._optionHolder:GetChildren()) do
									if child2:IsA("TextButton") then
										local isSel = (child2.Text == configDropdown._selected)
										child2.BackgroundTransparency = isSel and 0 or 1
										child2.TextColor3 = isSel and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
									end
								end
							end)
						end
					end
				end

				local NameInputContainer = Instance.new("Frame")
				NameInputContainer.Size = UDim2.new(1, 0, 0, 52)
				NameInputContainer.BackgroundTransparency = 1
				NameInputContainer.Parent = SecContent

				local NameLbl = Instance.new("TextLabel")
				NameLbl.Size = UDim2.new(1, 0, 0, 16)
				NameLbl.BackgroundTransparency = 1
				NameLbl.FontFace = FONT_MEDIUM
				NameLbl.Text = "Config Name"
				NameLbl.TextColor3 = COLOR_TEXT_WHITE
				NameLbl.TextSize = 12
				NameLbl.TextXAlignment = Enum.TextXAlignment.Left
				NameLbl.Parent = NameInputContainer

				local NameBoxContainer = Instance.new("Frame")
				NameBoxContainer.Size = UDim2.new(1, 0, 0, 24)
				NameBoxContainer.Position = UDim2.new(0, 0, 0, 18)
				NameBoxContainer.BackgroundColor3 = COLOR_BOX_INACTIVE
				NameBoxContainer.BorderSizePixel = 0
				NameBoxContainer.Parent = NameInputContainer

				local NameBoxCorner = Instance.new("UICorner")
				NameBoxCorner.CornerRadius = UDim.new(0, 5)
				NameBoxCorner.Parent = NameBoxContainer

				local NameBoxStroke = Instance.new("UIStroke")
				NameBoxStroke.Color = COLOR_BOX_BORDER
				NameBoxStroke.Thickness = 1
				NameBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				NameBoxStroke.Parent = NameBoxContainer

				local NameBox = Instance.new("TextBox")
				NameBox.Size = UDim2.new(1, -16, 1, 0)
				NameBox.Position = UDim2.new(0, 8, 0, 0)
				NameBox.BackgroundTransparency = 1
				NameBox.FontFace = FONT_REGULAR
				NameBox.PlaceholderText = "my config"
				NameBox.PlaceholderColor3 = COLOR_TEXT_SUB
				NameBox.Text = ""
				NameBox.TextColor3 = COLOR_TEXT_WHITE
				NameBox.TextSize = 11
				NameBox.TextXAlignment = Enum.TextXAlignment.Left
				NameBox.ClearTextOnFocus = false
				NameBox.Parent = NameBoxContainer

				NameBox.Focused:Connect(function() NameBoxStroke.Color = COLOR_TEXT_WHITE end)
				NameBox.FocusLost:Connect(function() NameBoxStroke.Color = COLOR_BOX_BORDER end)

				currentConfigNameInput = NameBox

				local DropLabelContainer = Instance.new("Frame")
				DropLabelContainer.Size = UDim2.new(1, 0, 0, 52)
				DropLabelContainer.BackgroundTransparency = 1
				DropLabelContainer.Parent = SecContent

				local DropLbl = Instance.new("TextLabel")
				DropLbl.Size = UDim2.new(1, 0, 0, 16)
				DropLbl.BackgroundTransparency = 1
				DropLbl.FontFace = FONT_MEDIUM
				DropLbl.Text = "Configs"
				DropLbl.TextColor3 = COLOR_TEXT_MUTED
				DropLbl.TextSize = 12
				DropLbl.TextXAlignment = Enum.TextXAlignment.Left
				DropLbl.Parent = DropLabelContainer

				local DropHeader = Instance.new("TextButton")
				DropHeader.Size = UDim2.new(1, 0, 0, 26)
				DropHeader.Position = UDim2.new(0, 0, 0, 18)
				DropHeader.BackgroundColor3 = COLOR_BOX_INACTIVE
				DropHeader.BorderSizePixel = 0
				DropHeader.AutoButtonColor = false
				DropHeader.Text = ""
				DropHeader.Parent = DropLabelContainer

				local DropHeaderCorner = Instance.new("UICorner")
				DropHeaderCorner.CornerRadius = UDim.new(0, 5)
				DropHeaderCorner.Parent = DropHeader

				local DropHeaderStroke = Instance.new("UIStroke")
				DropHeaderStroke.Color = COLOR_BOX_BORDER
				DropHeaderStroke.Thickness = 1
				DropHeaderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				DropHeaderStroke.Parent = DropHeader

				local DropSelText = Instance.new("TextLabel")
				DropSelText.Size = UDim2.new(1, -28, 1, 0)
				DropSelText.Position = UDim2.new(0, 8, 0, 0)
				DropSelText.BackgroundTransparency = 1
				DropSelText.FontFace = FONT_MEDIUM
				DropSelText.Text = "none"
				DropSelText.TextColor3 = COLOR_TEXT_WHITE
				DropSelText.TextSize = 12
				DropSelText.TextXAlignment = Enum.TextXAlignment.Left
				DropSelText.Parent = DropHeader

				local DropChevron = Instance.new("ImageLabel")
				DropChevron.Size = UDim2.new(0, 12, 0, 12)
				DropChevron.Position = UDim2.new(1, -8, 0.5, 0)
				DropChevron.AnchorPoint = Vector2.new(1, 0.5)
				DropChevron.BackgroundTransparency = 1
				DropChevron.ImageColor3 = COLOR_TEXT_MUTED
				ApplyIcon(DropChevron, "chevron-down")
				DropChevron.Parent = DropHeader

				local DropOptionHolder = Instance.new("Frame")
				DropOptionHolder.Size = UDim2.new(1, 0, 0, 0)
				DropOptionHolder.Position = UDim2.new(0, 0, 0, 48)
				DropOptionHolder.BackgroundColor3 = COLOR_BOX_INACTIVE
				DropOptionHolder.BorderSizePixel = 0
				DropOptionHolder.Visible = false
				DropOptionHolder.ClipsDescendants = true
				DropOptionHolder.ZIndex = 10
				DropOptionHolder.Parent = DropLabelContainer

				local DropHolderCorner = Instance.new("UICorner")
				DropHolderCorner.CornerRadius = UDim.new(0, 5)
				DropHolderCorner.Parent = DropOptionHolder

				local DropHolderStroke = Instance.new("UIStroke")
				DropHolderStroke.Color = COLOR_BOX_BORDER
				DropHolderStroke.Thickness = 1
				DropHolderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				DropHolderStroke.Parent = DropOptionHolder

				local DropHolderLayout = Instance.new("UIListLayout")
				DropHolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
				DropHolderLayout.Padding = UDim.new(0, 2)
				DropHolderLayout.Parent = DropOptionHolder

				local DropHolderPadding = Instance.new("UIPadding")
				DropHolderPadding.PaddingTop = UDim.new(0, 4)
				DropHolderPadding.PaddingBottom = UDim.new(0, 4)
				DropHolderPadding.PaddingLeft = UDim.new(0, 4)
				DropHolderPadding.PaddingRight = UDim.new(0, 4)
				DropHolderPadding.Parent = DropOptionHolder

				configDropdown = {
					_container = DropLabelContainer,
					_optionHolder = DropOptionHolder,
					_selText = DropSelText,
					_chevron = DropChevron,
					_headerStroke = DropHeaderStroke,
					_isOpen = false,
					_selected = nil
				}

				local function ToggleDropList()
					configDropdown._isOpen = not configDropdown._isOpen
					DropOptionHolder.Visible = configDropdown._isOpen
					DropChevron.Rotation = configDropdown._isOpen and 180 or 0
					DropHeaderStroke.Color = configDropdown._isOpen and COLOR_TEXT_WHITE or COLOR_BOX_BORDER
					if configDropdown._isOpen then
						RefreshDropdown()
						local configs = ListConfigs(folder)
						local totalHeight = (#configs * 24) + 8
						DropOptionHolder.Size = UDim2.new(1, 0, 0, math.min(math.max(totalHeight, 30), 120))
						DropLabelContainer.Size = UDim2.new(1, 0, 0, 48 + math.min(math.max(totalHeight, 30), 120) + 4)
					else
						DropLabelContainer.Size = UDim2.new(1, 0, 0, 52)
					end
				end

				DropHeader.MouseButton1Click:Connect(ToggleDropList)

				local AutoloadLabelFrame = Instance.new("Frame")
				AutoloadLabelFrame.Size = UDim2.new(1, 0, 0, 18)
				AutoloadLabelFrame.BackgroundTransparency = 1
				AutoloadLabelFrame.Parent = SecContent

				local AutoloadLbl = Instance.new("TextLabel")
				AutoloadLbl.Size = UDim2.new(1, 0, 1, 0)
				AutoloadLbl.BackgroundTransparency = 1
				AutoloadLbl.FontFace = FONT_MEDIUM
				AutoloadLbl.Text = "autoload: none"
				AutoloadLbl.TextColor3 = COLOR_TEXT_SUB
				AutoloadLbl.TextSize = 11
				AutoloadLbl.TextXAlignment = Enum.TextXAlignment.Left
				AutoloadLbl.Parent = AutoloadLabelFrame

				autoloadLabel = AutoloadLbl

				local function MakeActionButton(text, onClick)
					local Container2 = Instance.new("Frame")
					Container2.Size = UDim2.new(1, 0, 0, 24)
					Container2.BackgroundTransparency = 1
					Container2.Parent = SecContent

					local BtnBg2 = Instance.new("Frame")
					BtnBg2.Size = UDim2.new(1, 0, 1, 0)
					BtnBg2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					BtnBg2.BorderSizePixel = 0
					BtnBg2.Parent = Container2

					local BtnCorner2 = Instance.new("UICorner")
					BtnCorner2.CornerRadius = UDim.new(0, 5)
					BtnCorner2.Parent = BtnBg2

					local BtnGrad2 = Instance.new("UIGradient")
					BtnGrad2.Rotation = 90
					BtnGrad2.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)) })
					BtnGrad2.Parent = BtnBg2

					local BtnStroke2 = Instance.new("UIStroke")
					BtnStroke2.Color = Color3.fromRGB(45, 45, 55)
					BtnStroke2.Thickness = 1.2
					BtnStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					BtnStroke2.Parent = BtnBg2

					local Btn2 = Instance.new("TextButton")
					Btn2.Size = UDim2.new(1, 0, 1, 0)
					Btn2.BackgroundTransparency = 1
					Btn2.FontFace = FONT_MEDIUM
					Btn2.Text = string.lower(text)
					Btn2.TextColor3 = COLOR_TEXT_WHITE
					Btn2.TextScaled = true
					Btn2.AutoButtonColor = false
					Btn2.Parent = Container2

					local TC2 = Instance.new("UITextSizeConstraint")
					TC2.MaxTextSize = 13
					TC2.MinTextSize = 8
					TC2.Parent = Btn2

					local BP2 = Instance.new("UIPadding")
					BP2.PaddingTop = UDim.new(0, 4)
					BP2.PaddingBottom = UDim.new(0, 4)
					BP2.Parent = Btn2

					Btn2.MouseEnter:Connect(function()
						BtnGrad2.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)) })
						BtnStroke2.Color = Color3.fromRGB(65, 65, 80)
					end)
					Btn2.MouseLeave:Connect(function()
						BtnGrad2.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)) })
						BtnStroke2.Color = Color3.fromRGB(45, 45, 55)
					end)
					Btn2.MouseButton1Down:Connect(function()
						BtnGrad2.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 25)), ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 16)) })
					end)
					Btn2.MouseButton1Up:Connect(function()
						BtnGrad2.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)) })
					end)
					Btn2.MouseButton1Click:Connect(onClick)

					return Container2
				end

				MakeActionButton("Save Config", function()
					local name = currentConfigNameInput.Text
					if name == "" then
						Notify({ Title = "Config", Text = "Enter a config name first.", Icon = "x", Duration = 3 })
						return
					end
					local data = CollectConfigData()
					local ok = SaveConfig(folder, name, data)
					if ok then
						Notify({ Title = "Config", Text = "Saved \"" .. name .. "\".", Icon = "check", Duration = 3 })
						RefreshDropdown()
					else
						Notify({ Title = "Config", Text = "Failed to save config.", Icon = "x", Duration = 3 })
					end
				end)

				MakeActionButton("Load Config", function()
					local name = configDropdown._selected
					if not name then
						Notify({ Title = "Config", Text = "Select a config first.", Icon = "x", Duration = 3 })
						return
					end
					local data = LoadConfig(folder, name)
					if data then
						ApplyConfigData(data)
						Notify({ Title = "Config", Text = "Loaded \"" .. name .. "\".", Icon = "check", Duration = 3 })
					else
						Notify({ Title = "Config", Text = "Config not found.", Icon = "x", Duration = 3 })
					end
				end)

				MakeActionButton("Overwrite Config", function()
					local name = configDropdown._selected
					if not name then
						Notify({ Title = "Config", Text = "Select a config to overwrite.", Icon = "x", Duration = 3 })
						return
					end
					local data = CollectConfigData()
					local ok = SaveConfig(folder, name, data)
					if ok then
						Notify({ Title = "Config", Text = "Overwritten \"" .. name .. "\".", Icon = "check", Duration = 3 })
					else
						Notify({ Title = "Config", Text = "Failed to overwrite.", Icon = "x", Duration = 3 })
					end
				end)

				MakeActionButton("Set as Autoload", function()
					local name = configDropdown._selected
					if not name then
						Notify({ Title = "Config", Text = "Select a config first.", Icon = "x", Duration = 3 })
						return
					end
					SetAutoload(folder, name)
					AutoloadLbl.Text = "autoload: " .. name
					Notify({ Title = "Config", Text = "\"" .. name .. "\" set as autoload.", Icon = "check", Duration = 3 })
				end)

				local autoload = GetAutoload(folder)
				AutoloadLbl.Text = autoload and ("autoload: " .. autoload) or "autoload: none"

				if autoload then
					local data = LoadConfig(folder, autoload)
					if data then
						ApplyConfigData(data)
					end
				end
			end

			return Section
		end

		if #self._tabs == 0 then
			tabObj.ContentPage.Visible = true
			self._activeTabRef = tabObj
			SetTabActive(tabObj, true)
			UpdateHeader(tabName, tabIcon)
		end

		table.insert(self._tabs, tabObj)
		return Tab
	end

	return Window
end

Library.Notify = Notify

return Library
]=]
	local fn, err = loadstring(src)
	assert(fn, "Astra load failed: " .. tostring(err))
	local ok, lib = pcall(fn)
	assert(ok and lib, "Astra exec failed: " .. tostring(lib))
	Library = lib
end

-------------------------------------------------------------------------------
-- state / remotes
-------------------------------------------------------------------------------
local S = {
	antiAfk = false,
	deviceOn = false,
	deviceKind = "Computer",
	afkRemote = nil,
	deviceRemote = nil,
	conns = {},
	_hooked = false,
}

local function track(c)
	table.insert(S.conns, c)
	return c
end

local function findRemote(name)
	local function isRemote(x)
		return typeof(x) == "Instance" and (x:IsA("RemoteEvent") or x:IsA("RemoteFunction"))
	end
	local candidates = {}
	pcall(function()
		local a = ReplicatedStorage:FindFirstChild("Assets")
		local r = a and a:FindFirstChild("Remotes")
		if r then
			local x = r:FindFirstChild(name)
			if isRemote(x) then table.insert(candidates, x) end
		end
	end)
	pcall(function()
		for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
			if d.Name == name and isRemote(d) then table.insert(candidates, d) end
		end
	end)
	for _, c in ipairs(candidates) do
		local full = c:GetFullName()
		if full:find("Assets") and full:find("Remotes") then return c end
	end
	return candidates[1]
end

local function resolveRemotes()
	S.afkRemote = findRemote("AFK")
	S.deviceRemote = findRemote("Device")
	print("[Nameless] AFK:", S.afkRemote and S.afkRemote:GetFullName() or "NIL")
	print("[Nameless] Device:", S.deviceRemote and S.deviceRemote:GetFullName() or "NIL")
end

local function fireAfk(state)
	local r = S.afkRemote or findRemote("AFK")
	S.afkRemote = r
	if not r then return false end
	return pcall(function() r:FireServer(state == true) end)
end

local function fireDevice(kind)
	local r = S.deviceRemote or findRemote("Device")
	S.deviceRemote = r
	if not r then return false end
	return pcall(function() r:FireServer(kind) end)
end

local function applyDevice()
	if not S.deviceOn then return false end
	return fireDevice(S.deviceKind)
end

local function resetCharacter()
	pcall(function()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = 0
		elseif char then char:BreakJoints() end
	end)
end

local function applyDeviceWithReset()
	applyDevice()
	task.spawn(function()
		for _ = 1, 5 do
			task.wait(0.2)
			if not S.deviceOn then return end
			applyDevice()
		end
		if S.deviceOn then resetCharacter() end
	end)
end

local function installHook()
	if (getgenv and getgenv().__NamelessHooked) or S._hooked then
		S._hooked = true
		return
	end
	if type(hookmetamethod) ~= "function" then return end
	local ok = pcall(function()
		local old
		old = hookmetamethod(game, "__namecall", function(self, ...)
			local method = (getnamecallmethod and getnamecallmethod()) or ""
			if method == "FireServer" and typeof(self) == "Instance" then
				local args = {...}
				if self.Name == "AFK" and S.antiAfk then
					args[1] = false
					return old(self, unpack(args))
				end
				if self.Name == "Device" and S.deviceOn then
					args[1] = S.deviceKind
					return old(self, unpack(args))
				end
			end
			return old(self, ...)
		end)
	end)
	if ok then
		S._hooked = true
		if getgenv then getgenv().__NamelessHooked = true end
		print("[Nameless] hook on")
	end
end

local afkAcc, deviceAcc = 0, 0
local function startLoops()
	installHook()
	track(UserInputService.WindowFocusReleased:Connect(function()
		if not S.antiAfk then return end
		for _, t in ipairs({0, 0.05, 0.2, 0.5, 1}) do
			task.delay(t, function() if S.antiAfk then fireAfk(false) end end)
		end
	end))
	track(UserInputService.WindowFocused:Connect(function()
		if S.antiAfk then fireAfk(false) end
	end))
	track(RunService.Heartbeat:Connect(function(dt)
		if S.antiAfk then
			afkAcc += dt
			if afkAcc >= 0.5 then afkAcc = 0; fireAfk(false) end
		end
		if S.deviceOn then
			deviceAcc += dt
			if deviceAcc >= 2.5 then deviceAcc = 0; applyDevice() end
		end
	end))
	local function onChar()
		if S.deviceOn then
			task.delay(0.5, applyDevice)
			task.delay(1.5, applyDevice)
			task.delay(3, applyDevice)
		end
	end
	if LP.Character then onChar() end
	track(LP.CharacterAdded:Connect(onChar))
end

-------------------------------------------------------------------------------
-- Auto Recrutamento
-------------------------------------------------------------------------------
local Recruit = { model = nil, conns = {}, anchor = nil }

local function clearRecruit()
	for _, c in ipairs(Recruit.conns) do pcall(function() c:Disconnect() end) end
	table.clear(Recruit.conns)
	if Recruit.model then pcall(function() Recruit.model:Destroy() end) end
	Recruit.model = nil
	Recruit.anchor = nil
end

local function findOverhead(char)
	if not char then return nil end
	for _, n in ipairs({"Overhead","OverheadGui","Nametag","NameTag","RankGui"}) do
		local x = char:FindFirstChild(n, true)
		if x and x:IsA("BillboardGui") then return x end
	end
	local head = char:FindFirstChild("Head")
	if head then
		for _, d in ipairs(head:GetChildren()) do
			if d:IsA("BillboardGui") then return d end
		end
	end
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BillboardGui") then return d end
	end
	return nil
end

local function applyOH(gui, displayName, vip)
	if not gui then return end
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			local t = d.Text or ""
			if t == LP.Name or t == LP.DisplayName or d.Name:lower():find("name") then
				d.Text = displayName
			end
			if vip and (t:lower():find("vip") or d.Name:lower():find("vip")) then
				d.Visible = true
			end
		end
	end
end

local function userExists(username)
	username = tostring(username or ""):gsub("%s+","")
	if #username < 3 then return false end
	local ok, uid = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
	if ok and type(uid)=="number" and uid > 0 then
		local ok2, name = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
		return true, { userId = uid, name = ok2 and name or username }
	end
	return false
end

local function chatSay(msg)
	if not msg or msg == "" then return end
	local sent = false
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		if channels then
			local g = channels:FindFirstChild("RBXGeneral")
				or channels:FindFirstChild("General")
				or channels:FindFirstChildWhichIsA("TextChannel")
			if g and g.SendAsync then
				g:SendAsync(msg)
				sent = true
			end
		end
	end)
	if not sent then
		pcall(function()
			StarterGui:SetCore("ChatMakeSystemMessage", { Text = msg })
		end)
	end
	pcall(function()
		local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
		if ev and ev:FindFirstChild("SayMessageRequest") then
			ev.SayMessageRequest:FireServer(msg, "All")
			sent = true
		end
	end)
	-- bubble on recruit head
	pcall(function()
		if Recruit.model then
			local head = Recruit.model:FindFirstChild("Head")
			local hum = Recruit.model:FindFirstChildOfClass("Humanoid")
			if head and hum then
				game:GetService("Chat"):Chat(head, msg, Enum.ChatColor.White)
			end
		end
	end)
	return sent
end

local function spawnRecruit(opts)
	clearRecruit()
	local char = LP.Character
	if not char then
		Library.Notify({ Title = "Recruit", Text = "sem personagem", Icon = "x" })
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	if not hrp then return end

	local spawnCF = hrp.CFrame * CFrame.new(0, 0, -6)
	Recruit.anchor = spawnCF

	-- 1) pull target appearance
	local okDesc, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(opts.userId)
	end)
	if not okDesc or not desc then
		Library.Notify({ Title = "Recruit", Text = "não puxou skin do userId", Icon = "x" })
		return
	end

	-- 2) clone LOCAL character (keeps meshes/clothes structure), then ApplyDescription
	char.Archivable = true
	local okClone, dummy = pcall(function() return char:Clone() end)
	char.Archivable = false
	if not okClone or not dummy then
		Library.Notify({ Title = "Recruit", Text = "clone local falhou", Icon = "x" })
		return
	end
	dummy.Name = "NamelessRecruit_" .. tostring(opts.name)

	-- strip scripts / animate
	for _, d in ipairs(dummy:GetDescendants()) do
		if d:IsA("BaseScript") or d:IsA("LocalScript") or d:IsA("Script") then
			d:Destroy()
		end
	end
	-- also remove Animator noise
	local hum = dummy:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			local anim = hum:FindFirstChildOfClass("Animator")
			if anim then anim:Destroy() end
		end)
		-- apply TARGET skin
		local okApply = pcall(function()
			hum:ApplyDescription(desc)
		end)
		if not okApply then
			-- fallback: try CreateHumanoidModel and swap
			local ok2, created = pcall(function()
				return Players:CreateHumanoidModelFromDescription(desc, hum.RigType)
			end)
			if ok2 and created then
				dummy:Destroy()
				dummy = created
				dummy.Name = "NamelessRecruit_" .. tostring(opts.name)
				hum = dummy:FindFirstChildOfClass("Humanoid")
			end
		end
	end

	-- freeze parts AFTER description (ApplyDescription may rebuild parts)
	task.wait()
	hum = dummy:FindFirstChildOfClass("Humanoid")
	for _, d in ipairs(dummy:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.Massless = true
		end
		if d:IsA("BaseScript") or d:IsA("LocalScript") or d:IsA("Script") then
			d:Destroy()
		end
	end
	if hum then
		hum.DisplayName = opts.name
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		pcall(function() hum.JumpHeight = 0 end)
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
	end

	-- 3) overhead ALWAYS (template or custom)
	local head = dummy:FindFirstChild("Head") or dummy:FindFirstChild("HumanoidRootPart")
	-- clear existing billboards first
	for _, d in ipairs(dummy:GetDescendants()) do
		if d:IsA("BillboardGui") then d:Destroy() end
	end

	local template = findOverhead(char)
	if template and head then
		local oh = template:Clone()
		oh.Parent = head
		oh.Adornee = head
		oh.Enabled = true
		oh.AlwaysOnTop = true
		applyOH(oh, opts.name, opts.vip)
	end

	-- always add clean name tag on top (so it's never missing)
	if head then
		local bb = Instance.new("BillboardGui")
		bb.Name = "NamelessOverhead"
		bb.Size = UDim2.fromOffset(180, 50)
		bb.StudsOffset = Vector3.new(0, 3.2, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 200
		bb.Adornee = head
		bb.Parent = head

		local tl = Instance.new("TextLabel")
		tl.BackgroundTransparency = 1
		tl.Size = UDim2.new(1, 0, 0.55, 0)
		tl.Font = Enum.Font.GothamBold
		tl.TextSize = 16
		tl.TextColor3 = Color3.fromRGB(255, 255, 255)
		tl.TextStrokeTransparency = 0.3
		tl.Text = opts.name
		tl.Parent = bb

		local sub = Instance.new("TextLabel")
		sub.BackgroundTransparency = 1
		sub.Size = UDim2.new(1, 0, 0.45, 0)
		sub.Position = UDim2.new(0, 0, 0.55, 0)
		sub.Font = Enum.Font.Gotham
		sub.TextSize = 12
		sub.TextColor3 = opts.vip and Color3.fromRGB(255, 215, 80) or Color3.fromRGB(180, 180, 200)
		sub.TextStrokeTransparency = 0.5
		sub.Text = (opts.vip and "VIP · " or "") .. (opts.device or "")
		sub.Parent = bb
	end

	dummy:PivotTo(spawnCF)
	dummy.Parent = workspace
	Recruit.model = dummy

	-- keep anchored in place (re-anchor if description delayed)
	task.delay(0.5, function()
		if not Recruit.model then return end
		for _, d in ipairs(Recruit.model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
			end
		end
		pcall(function() Recruit.model:PivotTo(spawnCF) end)
	end)

	if opts.chat and #opts.chat > 0 then
		task.defer(function() chatSay(opts.chat) end)
	end

	Library.Notify({ Title = "Recruit", Text = opts.name .. " · skin + OH", Icon = "check" })
end

-------------------------------------------------------------------------------
-- UI
-------------------------------------------------------------------------------
local Window = Library.CreateWindow({
	Title = "Nameless",
	ConfigFolder = "NamelessConfigs",
})

local TabGame = Window:CreateTab({ Name = "Jogo atual", Icon = "gamepad-2" })
local Main = TabGame:CreateSection({ Name = PLACE_NAME .. " · " .. tostring(PLACE_ID) })

Main:AddLabel(game.PlaceId == PLACE_ID and "status: suportado" or ("status: PlaceId " .. tostring(game.PlaceId)))

Main:AddToggle({
	Name = "Anti AFK",
	Description = "Bloqueia AFK no Alt+Tab e idle",
	Default = false,
	Callback = function(v)
		S.antiAfk = v
		resolveRemotes()
		installHook()
		if v then
			fireAfk(false)
			Library.Notify({ Title = "Anti AFK", Text = S.afkRemote and "on" or "on (remote NIL)", Icon = "shield" })
		else
			Library.Notify({ Title = "Anti AFK", Text = "off", Icon = "shield-off" })
		end
	end,
})

Main:AddToggle({
	Name = "Spoofer",
	Description = "Device spoof + reset",
	Default = false,
	Callback = function(v)
		S.deviceOn = v
		resolveRemotes()
		installHook()
		if v then
			applyDeviceWithReset()
			Library.Notify({ Title = "Spoofer", Text = S.deviceKind .. " · reset", Icon = "smartphone" })
		else
			Library.Notify({ Title = "Spoofer", Text = "off", Icon = "smartphone" })
		end
	end,
})

Main:AddDropdown({
	Name = "Device",
	Description = "Mobile ou Computer",
	Options = { "Mobile", "Computer" },
	Default = "Computer",
	Callback = function(v)
		S.deviceKind = v
		if S.deviceOn then applyDeviceWithReset() end
	end,
})

Main:AddLabel("Auto Recrutamento")

local recName, recChat, recDevice, recVip = "", "", "Computer", false

Main:AddInput({
	Name = "Nome do player",
	Placeholder = "username",
	Default = "",
	Callback = function(t) recName = t end,
})

Main:AddInput({
	Name = "Mensagem no chat",
	Placeholder = "opcional",
	Default = "",
	Callback = function(t) recChat = t end,
})

Main:AddDropdown({
	Name = "Device do clone",
	Options = { "Mobile", "Computer" },
	Default = "Computer",
	Callback = function(v) recDevice = v end,
})

Main:AddToggle({
	Name = "VIP",
	Default = false,
	Callback = function(v) recVip = v end,
})

Main:AddButton({
	Name = "Recrutar",
	Callback = function()
		local ok, info = userExists(recName)
		if not ok then
			Library.Notify({ Title = "Recruit", Text = "player não existe", Icon = "x" })
			return
		end
		spawnRecruit({
			name = info.name,
			userId = info.userId,
			device = recDevice,
			vip = recVip,
			chat = recChat,
		})
	end,
})

Main:AddButton({
	Name = "Remover clone",
	Callback = function()
		clearRecruit()
		Library.Notify({ Title = "Recruit", Text = "removido", Icon = "check" })
	end,
})

local TabCombat = Window:CreateTab({ Name = "Combat", Icon = "swords" })
TabCombat:CreateSection({ Name = "Combat" }):AddLabel("em breve")

local TabVis = Window:CreateTab({ Name = "Visuals", Icon = "eye" })
TabVis:CreateSection({ Name = "Visuals" }):AddLabel("em breve")

local TabCfg = Window:CreateTab({ Name = "Config", Icon = "settings" })
pcall(function()
	TabCfg:CreateSection({ Name = "Settings" }):ApplyConfigManager()
end)

-------------------------------------------------------------------------------
-- boot
-------------------------------------------------------------------------------
pcall(resolveRemotes)
pcall(startLoops)
pcall(function()
	Library.Notify({ Title = "Nameless", Text = "RightShift · ready", Icon = "check", Duration = 3 })
end)
print("[Nameless] ready")

getgenv().NamelessUnload = function()
	pcall(clearRecruit)
	for _, c in ipairs(S.conns) do pcall(function() c:Disconnect() end) end
	table.clear(S.conns)
	S.antiAfk = false
	S.deviceOn = false
	pcall(function()
		local hui = (gethui and gethui()) or CoreGui
		local g = hui:FindFirstChild("AstraUI")
		if g then g:Destroy() end
	end)
end
