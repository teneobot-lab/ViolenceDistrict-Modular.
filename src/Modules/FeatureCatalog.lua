-- Safe feature manifest. Entries are local preferences or passive diagnostics.
return {
    { name = "MovementDiagnostics", group = "Movement", description = "Passive movement telemetry." },
    { name = "Crosshair", group = "Visual", description = "Local crosshair state model." },
    { name = "GraphicsProfile", group = "Visual", description = "Local graphics preference profile." },
    { name = "RuntimeDiagnostics", group = "Diagnostics", description = "Runtime uptime and sample snapshots." },
}
