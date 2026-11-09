-- Stores user-selected local graphics preferences; no hidden post-processing injection.
local GraphicsProfile = {}
GraphicsProfile.__index = GraphicsProfile

function GraphicsProfile.new()
    return setmetatable({
        bloom = false,
        fog = false,
        depthOfField = false,
        qualityPreset = "Default",
    }, GraphicsProfile)
end

function GraphicsProfile:SetPreset(name)
    local allowed = { Default = true, Low = true, Balanced = true, High = true }
    assert(allowed[name], "unsupported graphics preset")
    self.qualityPreset = name
end

return GraphicsProfile
