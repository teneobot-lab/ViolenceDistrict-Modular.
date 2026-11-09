local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
    return setmetatable({ listeners = {} }, EventBus)
end

function EventBus:On(eventName, callback)
    assert(type(callback) == "function", "callback must be a function")
    self.listeners[eventName] = self.listeners[eventName] or {}
    local list = self.listeners[eventName]
    list[#list + 1] = callback
    local active = true
    return function()
        if not active then return end
        active = false
        for i, fn in ipairs(list) do
            if fn == callback then table.remove(list, i) break end
        end
    end
end

function EventBus:Emit(eventName, ...)
    local list = self.listeners[eventName]
    if not list then return end
    for _, callback in ipairs(list) do
        local ok, err = pcall(callback, ...)
        if not ok and self.onError then self.onError(eventName, err) end
    end
end

function EventBus:Clear()
    self.listeners = {}
end

return EventBus
