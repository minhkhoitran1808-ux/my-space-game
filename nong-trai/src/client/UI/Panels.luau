--[[
	Panels: chỉ mở một bảng (cửa hàng, túi đồ, đi lại) tại một thời điểm.
]]

local Panels = {}

type Entry = { frame: GuiObject, onOpen: (() -> ())? }
local entries: { [string]: Entry } = {}

function Panels.register(name: string, frame: GuiObject, onOpen: (() -> ())?)
	entries[name] = { frame = frame, onOpen = onOpen }
	frame.Visible = false
end

function Panels.isOpen(name: string): boolean
	local entry = entries[name]
	return entry ~= nil and entry.frame.Visible
end

function Panels.open(name: string)
	for other, entry in pairs(entries) do
		if other ~= name then
			entry.frame.Visible = false
		end
	end
	local entry = entries[name]
	if entry then
		entry.frame.Visible = true
		if entry.onOpen then
			entry.onOpen()
		end
	end
end

function Panels.close(name: string)
	local entry = entries[name]
	if entry then
		entry.frame.Visible = false
	end
end

function Panels.toggle(name: string)
	if Panels.isOpen(name) then
		Panels.close(name)
	else
		Panels.open(name)
	end
end

return Panels
