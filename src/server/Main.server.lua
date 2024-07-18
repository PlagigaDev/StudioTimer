local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local Roact = require(script.Parent:WaitForChild("Roact"))

local toolbar = plugin:CreateToolbar("Studio Timer")

local pluginButton = toolbar:CreateButton(
"Studio Timer", --Text that will appear below button
"Show how long you have been working on the current Game", --Text that will appear if you hover your mouse on button
"rbxassetid://12432317029") --Button icon

pluginButton.ClickableWhenViewportHidden = true

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

local SAVE_INTERVALL = 15

local showTimeTypes = {
    CURRENT_SESSION = "Current Session",
    TOTAL_GAME_TIME = "Total Game Time",
    TOTAL_TIME = "Total Time"
}

local isFocused = false

UserInputService.WindowFocused:Connect(function()
    isFocused = true
end)

UserInputService.WindowFocusReleased:Connect(function()
    isFocused = false
end)


local theme = settings():GetService("Studio").Theme

local isOpen = plugin:GetSetting("on") or false

local isLocalPlace = game.GameId == 0

local initGameNameState

if isLocalPlace then
    initGameNameState = game.Name
    if string.find(initGameNameState,".rbxlx") or string.find(initGameNameState,".rbxl") then
        local gameNameStateSplit = initGameNameState:split(".")
        table.remove(gameNameStateSplit,#gameNameStateSplit)
        initGameNameState = table.concat(gameNameStateSplit)
    end
else
    initGameNameState = MarketplaceService:GetProductInfo(game.PlaceId)["Name"]
end


local totalGameTimePassed = plugin:GetSetting(game.GameId.. "clock") or 0
local totalTimePassed = plugin:GetSetting("totalTime") or 0

if isLocalPlace then
    totalGameTimePassed = plugin:GetSetting("local".. initGameNameState.. "clock") or 0
end

local onIsFocusedSave = plugin:GetSetting("onIsFocused") or false

local hasSaved = false
-- convert legacy save into new
if typeof(totalGameTimePassed) == "table" then
    totalGameTimePassed = (((totalGameTimePassed.days * 24 + totalGameTimePassed.hours) * 60 + totalGameTimePassed.minutes) * 60 + totalGameTimePassed.seconds)   
end

local showTimeTypeSave = plugin:GetSetting("showTimeType") or showTimeTypes.TOTAL_GAME_TIME

local Clock = Roact.Component:extend("Clock")

function Clock:init()
    self:setState({
        startTime = os.clock(),
        currentSeconds = 0,
        currentMinutes = 0,
        currentHours = 0,
        currentDays = 0,
        showTimeType = showTimeTypeSave,
        gameName = initGameNameState,
        onIsFocused = onIsFocusedSave,
        skipTime = 0 --This might not be the best solution but it's my solution
    })
end

function focusedButton(clock: Roact.Component, focus: boolean): Roact.Element
    return Roact.createElement("TextButton",{
        Size = UDim2.new(.1,0,.25,0),
        Position = UDim2.new(.99,0,.99,0),
        AnchorPoint = Vector2.new(1,1),
        TextScaled = true,
        TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainButton),
        Text = focus and "On Focus" or "Always",
        [Roact.Event.MouseButton1Click] = function()
            focus = not focus
            plugin:SetSetting("onIsFocused", focus)
            clock:setState({onIsFocused = focus})
        end
    }, {
        UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0,8)
        })
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
            local showTimeType = clock.state.showTimeType
            local newTimeType

            if showTimeType == showTimeTypes.CURRENT_SESSION then
                newTimeType = showTimeTypes.TOTAL_GAME_TIME
            elseif showTimeType == showTimeTypes.TOTAL_GAME_TIME then
                newTimeType = showTimeTypes.TOTAL_TIME
            else
                newTimeType = showTimeTypes.CURRENT_SESSION
            end
            plugin:SetSetting("showTimeType", newTimeType)
            clock:setState({showTimeType = newTimeType})
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
        ChangeTimeButton = changeTimeButton(self, self.state.showTimeType),
        FocusedButton = focusedButton(self, self.state.onIsFocused)
    })
end

local function save(totalSeconds: number) 
    if not isLocalPlace then
        plugin:SetSetting(game.GameId.. "clock", totalSeconds + totalGameTimePassed)
    else
        plugin:SetSetting("local".. initGameNameState.. "clock", totalSeconds + totalGameTimePassed)
    end
    plugin:SetSetting("totalTime", totalSeconds + totalTimePassed)
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

function calcTime(self)
    local startTime = self.state.startTime
    local showTimeType = self.state.showTimeType
    local totalSeconds = os.clock() - startTime
    
    
    totalSeconds -= math.floor(self.state.skipTime)
    totalSeconds = math.floor(totalSeconds)
    trySave(totalSeconds)
    
    if showTimeType == showTimeTypes.TOTAL_GAME_TIME then
        totalSeconds += totalGameTimePassed
    elseif showTimeType == showTimeTypes.TOTAL_TIME then
        totalSeconds += totalTimePassed
    end
    local totalMinutes = math.floor(totalSeconds / 60)
    local totalHours = math.floor(totalMinutes / 60)
    local totalDays = math.floor(totalHours / 24)
        
    self:setState(function(_state)
        return {
            currentSeconds = totalSeconds % 60,
            currentMinutes = totalMinutes % 60,
            currentHours = totalHours % 24,
            currentDays = totalDays
        }
    end)
end

function Clock:didMount()
    calcTime(self)
    RunService.Heartbeat:Connect(function(dt)
        if self.state.onIsFocused and not isFocused then
            self:setState({skipTime = self.state.skipTime + dt})
            return
        end
        calcTime(self)
    end)
end

local handle = Roact.mount(Roact.createElement(Clock), widget, "Clock UI")

theme.Changed:Connect(function(_property)
    Roact.update(handle, Clock)
end)

if isOpen then
    widget.Enabled = isOpen
	pluginButton:SetActive(isOpen)
end

pluginButton.Click:Connect(function()
	isOpen = not widget.Enabled
    plugin:SetSetting("on", isOpen)
    widget.Enabled = isOpen
	pluginButton:SetActive(isOpen)
end)
