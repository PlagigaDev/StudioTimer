local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Roact = require(script.Parent:WaitForChild("Roact"))

local toolbar = plugin:CreateToolbar("Studio Timer")

local pluginButton = toolbar:CreateButton(
"Studio Timer", --Text that will appear below button
"Show how long you have been working on the current Game", --Text that will appear if you hover your mouse on button
"rbxassetid://12432317029") --Button icon

local info = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Top, --From what side gui appears
	false, --Widget will be initially enabled
	false, --Don't overdrive previouse enabled state
	400, --default weight
	200, --default height
	150, --minimum weight (optional)
	75 --minimum height (optional)
)

local widget = plugin:CreateDockWidgetPluginGui(
"Timer", --A unique and consistent identifier used to storing the widget’s dock state and other internal details
info --dock widget info
)

local SAVE_INTERVALL = 5

local currentSessionString = "Current Session"
local totalTimeString = "Total Time"

local theme = settings():GetService("Studio").Theme

local isOpen = false

local isLocalPlace = game.GameId == 0

local initGameNameState

if isLocalPlace then
    initGameNameState = game.Name
    if string.find(initGameNameState,".rbxlx") or string.find(initGameNameState,".rbxlx") then
        local gameNameStateSplit = initGameNameState:split(".")
        initGameNameState = ""
        for i in 1, #gameNameStateSplit-1 do
            initGameNameState += gameNameStateSplit[i]
        end
    end
else
    local MarketplaceService = game:GetService("MarketplaceService")
    initGameNameState = MarketplaceService:GetProductInfo(game.PlaceId)["Name"]
end


local timeSave 
if isLocalPlace then
    timeSave = plugin:GetSetting("local".. initGameNameState.. "clock") or 0
else
    timeSave = plugin:GetSetting(game.GameId.. "clock") or 0
end

local totalTimePassed

local hasSaved = false

-- convert legacy save into new
if typeof(timeSave) == "table" then
    totalTimePassed = (((timeSave.days * 24 + timeSave.hours) * 60 + timeSave.minutes) * 60 + timeSave.seconds)
else
    totalTimePassed = timeSave
end


local Clock = Roact.Component:extend("Clock")

function Clock:init()
    self:setState({
        startTime = os.clock(),
        currentSeconds = 0,
        currentMinutes = 0,
        currentHours = 0,
        currentDays = 0,
        showTotalTime = true,
        showTimeText = totalTimeString,
        gameName = initGameNameState
    })
end

function timeLabel(times: {number})
    return Roact.createElement("TextLabel", {
        Size = UDim2.new(1, 0, .5, 0),
        Position = UDim2.new(0,0,1,0),
        AnchorPoint = Vector2.new(0,1),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextScaled = true,
        Text = string.format("%02d:%02d:%02d:%02d",times.days, times.hours, times.minutes, times.seconds),
        BorderSizePixel = 0,
        TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
    }, {
        UICorner = Roact.createElement("UICorner",{})
    })
end

function TimeFrame()
    return Roact.createElement("Frame",{
        AnchorPoint = Vector2.new(.5,.5),
        Size = UDim2.new(.5,0,.5,0),
        Position = UDim2.new(.5,0,.75,0),
        BackgroundTransparency = 1
    }, {
        
    })
end

function gameNameLabel(gameName: string)
    return Roact.createElement("TextLabel",{
        TextScaled = true,
        TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
        Text = "Game: ".. gameName,
        Size = UDim2.new(.5,0,.5,0),
        BorderSizePixel = 0
    })
end

function changeTimeButton(clock, currentTimeDisplay: string)
    return Roact.createElement("TextButton",{
        Size = UDim2.new(.25,0,.25,0),
        Position = UDim2.new(.99,0,.01,0),
        AnchorPoint = Vector2.new(1,0),
        TextScaled = true,
        TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainButton),
        Text = "Displaying: ".. currentTimeDisplay,
        [Roact.Event.MouseButton1Click] = function()
            clock:setState({showTotalTime = not clock.state.showTotalTime})
        end
    }, {
        UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0,8)
        })
    })
end

function Clock:render()
    local state = self.state
    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
    }, {
        TimeLabel = timeLabel({["days"] = state.currentDays, ["hours"] = state.currentHours, ["minutes"] = state.currentMinutes, ["seconds"] = state.currentSeconds}),
        GameName = gameNameLabel(self.state.gameName),
        ChangeTimeButton = changeTimeButton(self, self.state.showTimeText)
    })
end

local function save(totalSeconds: number) 
    if not isLocalPlace then
        plugin:SetSetting(game.GameId.. "clock", totalSeconds)
    else
        plugin:SetSetting("local".. initGameNameState.. "clock", totalSeconds)
    end
end

local function trySave(totalSeconds: number)
    if totalSeconds % SAVE_INTERVALL == 0 then
        if not hasSaved then
            hasSaved = true
            save(totalSeconds)
        end
   else
       hasSaved = false
   end
end

function Clock:didMount()
    RunService.Heartbeat:Connect(function(dt)
        local startTime = self.state.startTime
        local  showTotalTime = self.state.showTotalTime
        local totalSeconds = math.floor(os.clock() - startTime)
        local timeString = currentSessionString

        trySave(totalSeconds + totalTimePassed)

        if showTotalTime then
            totalSeconds += totalTimePassed
            timeString = totalTimeString
        end

        local totalMinutes = math.floor(totalSeconds / 60)
        local totalHours = math.floor(totalMinutes / 60)
        local totalDays = math.floor(totalHours / 24)
        
        self:setState(function(state)
            return {
                currentSeconds = totalSeconds % 60,
                currentMinutes = totalMinutes % 60,
                currentHours = totalHours % 24,
                currentDays = totalDays,
                showTimeText = timeString
            }
        end)
    end)
end

local handle = Roact.mount(Roact.createElement(Clock), widget, "Clock UI")

theme.Changed:Connect(function(property)
    Roact.update(handle, Clock)
end)

pluginButton.Click:Connect(function()
	local isOn = not widget.Enabled
    widget.Enabled = isOn
	pluginButton:SetActive(isOn)
end)
