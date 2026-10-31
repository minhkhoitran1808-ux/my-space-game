--[[
	Notifications: thông báo nổi ở giữa phía trên màn hình.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.UI.Theme)
local Components = require(script.Parent.UI.Components)

local Notifications = {}
local C = Theme.Colors

local holder: Frame
local counter = 0

function Notifications.init(gui: ScreenGui)
	local layout = Components.list(Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	holder = Components.create("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 78),
		Size = UDim2.new(0.6, 0, 0, 200),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Components.create("UISizeConstraint", { MaxSize = Vector2.new(460, 200) }),
		layout,
	})
end

function Notifications.show(text: string, kind: string?)
	if not holder then
		return
	end
	counter += 1
	local bg, fg = C.Water, C.White
	if kind == "error" then
		bg = C.Danger
	elseif kind == "success" then
		bg = C.Leaf
	end

	local toast = Components.text({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.05,
		BackgroundColor3 = bg,
		TextColor3 = fg,
		TextSize = 17,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = text,
		LayoutOrder = counter,
		Parent = holder,
	})
	Components.corner(12).Parent = toast
	Components.padding(8).Parent = toast

	-- Giữ tối đa 3 thông báo
	local toasts = {}
	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(toasts, child)
		end
	end
	table.sort(toasts, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = 1, #toasts - 3 do
		toasts[i]:Destroy()
	end

	task.delay(3, function()
		if toast.Parent then
			local tween = TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 })
			tween:Play()
			tween.Completed:Wait()
			toast:Destroy()
		end
	end)
end

return Notifications
