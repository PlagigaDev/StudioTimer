local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local toolbar = plugin:CreateToolbar("Studio Timer")

local newScriptButton = toolbar:CreateButton("Show Timer", "Show the Timer UI", "rbxassetid://4458901886")

local StudioTimerScreen = script:WaitForChild("StudioTimer")

StudioTimerScreen.Parent = game:GetService("CoreGui")
local TimerFrame = StudioTimerScreen:WaitForChild("TimerFrame")

local Timer = TimerFrame:WaitForChild("Timer")

newScriptButton.ClickableWhenViewportHidden = true

local clock = plugin:GetSetting("clock") or {
	["days"] = 0,
	["hours"] = 0,
	["minutes"] = 0,
	["seconds"] = 0
}

local function ShowAndHideTimer()
	print("Hello")
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
	if (clock.seconds == 0) then
		plugin:SetSetting("clock", clock)
	end
end

newScriptButton.Click:Connect(ShowAndHideTimer)

while true do
	task.wait(1)
	UpdateTimer()
end

