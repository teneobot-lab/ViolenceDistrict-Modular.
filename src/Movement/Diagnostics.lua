-- Passive movement telemetry for debugging one's own experience.
-- The host must inject a sampler; this module never writes velocity/speed.
-- Sampler contract: Subscribe(callback) returns a disconnect function or
-- a connection table with Disconnect(). The host owns data collection.
local Diagnostics = {}
Diagnostics.__index = Diagnostics

function Diagnostics.new()
    return setmetatable({
        last = nil,
        enabled = false,
        sampler = nil,
        connection = nil,
    }, Diagnostics)
end

function Diagnostics:Init(context)
    self.sampler = context and context.movementSampler or nil
end

function Diagnostics:Enable()
    if self.enabled then return end
    self.enabled = true

    if self.sampler and type(self.sampler.Subscribe) == "function" then
        local ok, connection = pcall(function()
            return self.sampler:Subscribe(function(sample)
                self:Push(sample)
            end)
        end)
        if ok then self.connection = connection end
    end
end

function Diagnostics:Disable()
    self.enabled = false
    local connection = self.connection
    self.connection = nil

    if type(connection) == "function" then
        pcall(connection)
    elseif type(connection) == "table" and type(connection.Disconnect) == "function" then
        pcall(function() connection:Disconnect() end)
    end
end

function Diagnostics:Push(sample)
    if not self.enabled or type(sample) ~= "table" then return end
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
