import MLX

/// Runtime knobs for the MLX backend, exposed so apps can tune without importing `MLX`.
public enum MLXRuntime {
    /// Cap the GPU buffer cache (bytes). On iOS keep this small (LLMEval uses 20 MB) so MLX
    /// doesn't hoard buffers and trip jetsam. Replaces the deprecated `GPU.set(cacheLimit:)`.
    public static func setGPUCacheLimit(bytes: Int) {
        MLX.Memory.cacheLimit = bytes
    }
}
