-- Crosshair state model. Rendering is provided by a host UI adapter.
local Crosshair = {}
Crosshair.__index = Crosshair

function Crosshair.new()
    return setmetatable({
        enabled = false,
        style = { size = 6, thickness = 1, gap = 3 },
    }, Crosshair)
end

function Crosshair:Enable() self.enabled = true end
function Crosshair:Disable() self.enabled = false end

function Crosshair:SetStyle(style)
    for key, value in pairs(style) do
        if self.style[key] ~= nil and type(value) == "number" then
            self.style[key] = math.clamp(value, 0, 32)
        end
    end
end

return Crosshair
