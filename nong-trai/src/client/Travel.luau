--[[
	Travel: bảng "Đi lại": sang Đảo Chợ, về đảo mình, thăm đảo bạn bè.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Theme = require(script.Parent.UI.Theme)
local Components = require(script.Parent.UI.Components)
local Panels = require(script.Parent.UI.Panels)

local Travel = {}
local C = Theme.Colors
local create = Components.create

local TravelRemote = Remotes.event("Travel")
local player = Players.LocalPlayer

function Travel.init(gui: ScreenGui)
	local panel = Components.panel({
		Name = "Travel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(320, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = gui,
	})
	Components.padding(14).Parent = panel
	local layout = Components.list(Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Center)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = panel

	local body = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = panel,
	}, { Components.list(Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Center) })

	Components.text({
		Size = UDim2.new(1, 0, 0, 30),
		Text = "Đi đâu bây giờ?",
		TextSize = 22,
		FontFace = Theme.Font.Heavy,
		TextColor3 = C.Leaf,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		Parent = panel,
	})

	local function destination(order: number, text: string, color: Color3, dark: Color3, target: any)
		local _, button = Components.button({
			Text = text,
			Color = color,
			Dark = dark,
			TextSize = 17,
			Size = UDim2.new(1, 0, 0, 52),
			LayoutOrder = order,
			Parent = body,
		})
		button.Activated:Connect(function()
			TravelRemote:FireServer(target)
			Panels.close("Travel")
		end)
	end

	local function render()
		Components.clear(body)
		destination(1, "Đảo Chợ", C.Leaf, C.LeafDark, "market")
		destination(2, "Về đảo của tôi", C.Bag, C.SoilDark, "home")
		local order = 2
		local islands = workspace:FindFirstChild("World")
		if islands then
			for _, island in ipairs(islands:GetChildren()) do
				local ownerId = island:GetAttribute("OwnerId")
				if type(ownerId) == "number" and ownerId ~= 0 and ownerId ~= player.UserId then
					local owner = Players:GetPlayerByUserId(ownerId)
					if owner then
						order += 1
						destination(order, "Thăm đảo " .. owner.DisplayName, C.Water, C.WaterDark, ownerId)
					end
				end
			end
		end
		order += 1
		local _, close = Components.button({
			Text = "Đóng",
			Color = C.Grey,
			Dark = C.GreyDark,
			TextSize = 16,
			Size = UDim2.new(1, 0, 0, 46),
			LayoutOrder = order,
			Parent = body,
		})
		close.Activated:Connect(function()
			Panels.close("Travel")
		end)
	end

	Panels.register("Travel", panel, render)
end

return Travel
