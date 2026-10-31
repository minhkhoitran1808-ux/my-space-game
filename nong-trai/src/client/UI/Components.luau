--[[
	Components: các khối giao diện dùng chung (dựng bằng code).
]]

local Theme = require(script.Parent.Theme)

local Components = {}
local C = Theme.Colors

function Components.create(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for key, value in pairs(props) do
			if key == "Parent" then
				parent = value
			else
				(inst :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end
local create = Components.create

function Components.corner(radius: number?): UICorner
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function Components.stroke(color: Color3, thickness: number?): UIStroke
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Components.padding(px: number): UIPadding
	return create("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

function Components.list(direction: Enum.FillDirection, gap: number, align: Enum.HorizontalAlignment?): UIListLayout
	return create("UIListLayout", {
		FillDirection = direction,
		Padding = UDim.new(0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
end

-- Chữ: nền trong suốt, font Nunito đậm, màu mực
function Components.text(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		FontFace = Theme.Font.ExtraBold,
		TextColor3 = C.Ink,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for key, value in pairs(defaults) do
		if props[key] == nil then
			props[key] = value
		end
	end
	return create("TextLabel", props)
end

-- Bảng nền kem viền vàng nhạt
function Components.panel(props: { [string]: any }): Frame
	props.BackgroundColor3 = props.BackgroundColor3 or C.Cream
	local frame = create("Frame", props)
	Components.corner(18).Parent = frame
	Components.stroke(C.CreamBorder, 4).Parent = frame
	return frame
end

--[[
	Nút "khối" theo thiết kế: nền màu + gờ đáy sẫm. Trả về (khung ngoài, nút).
	Đặt Size/Position/LayoutOrder lên khung ngoài.
]]
function Components.button(props: {
	Text: string,
	Color: Color3,
	Dark: Color3,
	TextColor: Color3?,
	TextSize: number?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	Parent: Instance?,
}): (Frame, TextButton)
	local root = create("Frame", {
		BackgroundColor3 = props.Dark,
		Size = props.Size or UDim2.fromOffset(120, 50),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
	}, { Components.corner(14) })

	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 1, -5),
		BackgroundColor3 = props.Color,
		AutoButtonColor = true,
		Text = props.Text,
		FontFace = Theme.Font.Heavy,
		TextSize = props.TextSize or 18,
		TextColor3 = props.TextColor or C.White,
		TextWrapped = true,
		Parent = root,
	}, { Components.corner(14), Components.stroke(props.Dark, 3) })

	button.MouseButton1Down:Connect(function()
		button.Position = UDim2.fromOffset(0, 3)
	end)
	local function release()
		button.Position = UDim2.new()
	end
	button.MouseButton1Up:Connect(release)
	button.MouseLeave:Connect(release)

	if props.Parent then
		root.Parent = props.Parent
	end
	return root, button
end

-- Xoá mọi GuiObject con (giữ lại layout)
function Components.clear(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Nút đóng (X đỏ) ở góc phải trên của một bảng
function Components.closeButton(parent: Instance, onClick: () -> ())
	local _, button = Components.button({
		Text = "X",
		Color = C.Danger,
		Dark = C.DangerDark,
		Size = UDim2.fromOffset(48, 48),
		Position = UDim2.new(1, -10, 0, 10),
		AnchorPoint = Vector2.new(1, 0),
		Parent = parent,
	})
	button.Activated:Connect(onClick)
end

return Components
