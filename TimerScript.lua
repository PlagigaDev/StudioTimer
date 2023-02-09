local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local toolbar = plugin:CreateToolbar("Studio Timer")

local newScriptButton = toolbar:CreateButton("Show Timer", "Show the Timer UI", "rbxassetid://12432317029")

local StudioTimerScreen = script:WaitForChild("StudioTimer")

StudioTimerScreen.Parent = game:GetService("CoreGui")
local TimerFrame = StudioTimerScreen:WaitForChild("TimerFrame")

local Timer = TimerFrame:WaitForChild("Timer")

local clock = plugin:GetSetting(game.GameId.. "clock") or {
	["days"] = 0,
	["hours"] = 0,
	["minutes"] = 0,
	["seconds"] = 0
}

local showTime = "%sd %sh %sm %ss"

local function ShowAndHideTimer()
	StudioTimerScreen.Enabled = (not StudioTimerScreen.Enabled)
end

local function UpdateTimer()
	clock.seconds += 1
	if(clock.seconds >= 60) then
		clock.seconds = 0
		clock.minutes += 1
	end
	if(clock.minutes >= 60) then
		clock.minutes = 0
		clock.hours += 1
	end
	if (clock.hours >= 24) then
		clock.hours = 0
		clock.days += 1
	end
	
	plugin:SetSetting(game.GameId.. "clock", clock)

    Timer.Text = string.format(showTime, clock.days, clock.hours, clock.minutes, clock.seconds)
end

newScriptButton.Click:Connect(ShowAndHideTimer)

while true do
	task.wait(1)
	UpdateTimer()
end

