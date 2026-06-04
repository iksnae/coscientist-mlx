extension GroundedDecoder {
    /// Builds a `DecoderRouting` that grounds the given `roles` (Generation + Reflection by
    /// default) with `tools`, routing every other role to `base` unchanged. The engine already
    /// consumes `DecoderRouting`, so enabling tool-use is purely a routing choice — no engine
    /// or agent change. With an empty registry it degrades to `StaticDecoderRouter(base)`, so
    /// "tools off" is byte-for-byte the current behavior.
    public static func router(
        base: any SchemaConstrainedDecoding,
        model: any LanguageModel,
        tools: ToolRegistry,
        roles: Set<AgentRole> = [.generation, .reflection],
        maxToolSteps: Int = 4,
        onToolCall: (@Sendable (ToolCall) -> Void)? = nil
    ) -> any DecoderRouting {
        guard !tools.isEmpty, !roles.isEmpty else { return StaticDecoderRouter(base) }
        let grounded = GroundedDecoder(
            model: model, tools: tools, inner: base,
            maxToolSteps: maxToolSteps, onToolCall: onToolCall)
        let overrides = Dictionary(
            uniqueKeysWithValues: roles.map { ($0, grounded as any SchemaConstrainedDecoding) })
        return RoleDecoderRouter(default: base, overrides: overrides)
    }
}
