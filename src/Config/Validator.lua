local Validator = {}

function Validator.Validate(input, schema)
    local clean = {}
    for key, rule in pairs(schema) do
        local value = input[key]
        if value == nil then
            clean[key] = rule.default
        elseif type(value) ~= rule.type then
            return nil, "invalid type for " .. key
        elseif rule.min and value < rule.min then
            return nil, "value below minimum for " .. key
        elseif rule.max and value > rule.max then
            return nil, "value above maximum for " .. key
        else
            clean[key] = value
        end
    end
    return clean
end

return Validator
