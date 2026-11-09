-- Inject a storage implementation from the host.
-- Deliberately no filesystem or executor-specific APIs are assumed.
local StorageAdapter = {}
StorageAdapter.__index = StorageAdapter

function StorageAdapter.new(backend)
    assert(type(backend) == "table", "storage backend required")
    assert(type(backend.Read) == "function" and type(backend.Write) == "function")
    return setmetatable({ backend = backend }, StorageAdapter)
end

function StorageAdapter:Read(key) return self.backend:Read(key) end
function StorageAdapter:Write(key, value) return self.backend:Write(key, value) end

return StorageAdapter
