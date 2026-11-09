local Runtime = {}
Runtime.__index = Runtime

function Runtime.new()
    return setmetatable({ startedAt = os.clock(), samples = {} }, Runtime)
end

function Runtime:Sample(label, value)
    self.samples[label] = { value = value, at = os.clock() }
end

function Runtime:Snapshot()
    return {
        uptime = os.clock() - self.startedAt,
        samples = table.clone(self.samples),
    }
end

return Runtime
