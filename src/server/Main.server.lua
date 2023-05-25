local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local Roact = require(script.Parent:WaitForChild("Roact"))

local toolbar = plugin:CreateToolbar("Studio Timer 2")

local pluginButton = toolbar:CreateButton(
"Studio Timer", --Text that will appear below button
"Show how long you have been working on the current Game", --Text that will appear if you hover your mouse on button
"rbxassetid://12432317029") --Button icon

local info = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right, --From what side gui appears
	false, --Widget will be initially enabled
	false, --Don't overdrive previouse enabled state
	200, --default weight
	300, --default height
	150, --minimum weight (optional)
	150 --minimum height (optional)
)

local widget = plugin:CreateDockWidgetPluginGui(
"Timer", --A unique and consistent identifier used to storing the widget’s dock state and other internal details
info --dock widget info
)

local PluginId = "12432477060"

local theme = settings():GetService("Studio").Theme

local isOpen = false

local isLocalPlace = game.GameId == 0

local initGameNameState

if isLocalPlace then
    initGameNameState = game.Name
else
    initGameNameState = game:GetService("MarketplaceService"):GetProductInfo(game.GameId,Enum.InfoType.Product)
end

local timeSave = plugin:GetSetting(game.GameId.. "clock")

local totalTimePassed

-- convert legacy save into new
if timeSave["days"] ~= nil then
    timePassed = (((timeSave.days * 24 + timeSave.hours) * 60 + timeSave.minutes) * 60 + timeSave.seconds)
else
    totalTimePassed = timeSave
end

local Clock = Roact.Component:extend("Clock")

function Clock:init()
    -- In init, we can use setState to set up our initial component state.
    self:setState({
        startTime = os.clock(),
        currentTime = 0,
        currentDays = 0,
        currentHours = 0,
        currentMinutes = 0,
        currentSeconds = 0,
        gameName = initGameNameState
    })
end

function timeLabel(xScale: number, time: number)
    return Roact.createElement("TextLabel", {
        Size = UDim2.new(.25, 0, .5, 0),
        Position = UDim2.new(xScale,0,.5,0),
        AnchorPoint = Vector2.new(0,.5),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextScaled = true,
        Text = "".. time,
        BorderSizePixel = 0,
        TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
    }, {
        UICorner = Roact.createElement("UICorner",{})
    })
end

function TimeFrame(state)
    return Roact.createElement("Frame",{
        AnchorPoint = Vector2.new(.5,.5),
        Size = UDim2.new(.5,0,.5,0),
        Position = UDim2.new(.5,0,.75,0),
        BackgroundTransparency = 1
    }, {
        DayLabel = timeLabel(.0, state.currentDays),
        HourLabel = timeLabel(.25, state.currentHours),
        MinuteLabel = timeLabel(.5, state.currentMinutes),
        SecondLabel = timeLabel(.75, state.currentSeconds),
    })
end

-- This render function is almost completely unchanged from the first example.
function Clock:render()
    -- As a convention, we'll pull currentTime out of state right away.
    local currentTime = self.state.currentTime

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
    }, {
        TimeFrame = TimeFrame(self.state),
        GameName = Roact.createElement("TextLabel",{
            TextScaled = true,
            TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
            BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
            Text = self.state.gameName
        })
    })
end

-- Set up our loop in didMount, so that it starts running when our
-- component is created.
function Clock:didMount()
    
    self.showTotalTime = true
    
    -- We don't want to block the main thread, so we spawn a new one!
    task.spawn(function()
        RunService.Heartbeat:Connect(function(dt)
            if not isLocalPlace then
                if self.showTotalTime then
                    
                end 
            end
            local seconds = math.floor(os.clock() - self.state.startTime)
            if seconds % 15 == 0 then
                plugin:SetSetting()
            end
            
            self:setState(function(state)
                return {
                    currentTime = math.floor(os.clock() - state.startTime)
                }
            end)
        end)
            

    end)
end

-- Create our UI, which now runs on its own!
local handle = Roact.mount(Roact.createElement(Clock), widget, "Clock UI")

theme.Changed:Connect(function(property)
    Roact.update(handle, Clock)
end)

pluginButton.Click:Connect(function()
	local isOn = not widget.Enabled
    widget.Enabled = isOn
	pluginButton:SetActive(isOn)
end)
