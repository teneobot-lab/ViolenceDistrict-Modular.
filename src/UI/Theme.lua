-- Theme tokens only; the host renderer decides how to draw them.
local Theme = {}

Theme.Presets = {
    Dark = {
        background = "#090F1A",
        surface = "#111C2B",
        surfaceAlt = "#17263A",
        text = "#E7EEF8",
        muted = "#8FA3BC",
        accent = "#4C9BFF",
        danger = "#E06C75",
    },
    Light = {
        background = "#EEF2F7",
        surface = "#FFFFFF",
        surfaceAlt = "#E3EAF3",
        text = "#172334",
        muted = "#607086",
        accent = "#236FC5",
        danger = "#C84650",
    },
}

function Theme.Get(name)
    local preset = Theme.Presets[name]
    assert(preset, "unknown theme: " .. tostring(name))
    return table.clone(preset)
end

return Theme
