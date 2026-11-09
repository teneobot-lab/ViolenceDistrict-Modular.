-- Local profile metadata only. Does not change character physics or server state.
local Profile = {}
Profile.__index = Profile

function Profile.new()
    return setmetatable({
        name = "Default",
        preferences = {
            showMovementDiagnostics = true,
            showVelocityGraph = false,
        },
    }, Profile)
end

function Profile:SetPreference(key, value)
    assert(self.preferences[key] ~= nil, "unknown preference")
    assert(type(value) == "boolean", "preference must be boolean")
    self.preferences[key] = value
end

return Profile
