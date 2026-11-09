-- Passive movement telemetry for debugging one's own experience.
-- The host must inject a sampler; this module never writes velocity/speed.
local Diagnostics = {}
Diagnostics.__index = Diagnostics

function Diagnostics.new()
    return setmetatable({ last = nil, enabled = false }, Diagnostics)
end

function Diagnostics:Enable()
    self.enabled = true
end

function Diagnostics:Disable()
    self.enabled = false
end

function Diagnostics:Push(sample)
    if not self.enabled then return end
    if type(sample) ~= "table" then return end
    self.last = {
        timestamp = os.clock(),
        position = sample.position,
        velocity = sample.velocity,
        grounded = sample.grounded,
    }
end

function Diagnostics:GetLastSample()
    return self.last
end

return Diagnostics
