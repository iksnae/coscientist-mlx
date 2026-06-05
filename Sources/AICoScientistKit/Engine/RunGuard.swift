/// Device thermal state, mirrored so the domain layer needn't import `Foundation.ProcessInfo`.
public enum DeviceThermalState: String, Sendable, Equatable {
    case nominal, fair, serious, critical
}

/// On-device run-safety decisions. Pure so the app feeds live signals
/// (`os_proc_available_memory()`, `ProcessInfo.thermalState`) and the logic stays unit-testable
/// without a device. The app composes user-facing messages from these categories.
public enum RunGuard {
    public enum MemoryDecision: String, Sendable, Equatable {
        case proceed   // ample free memory
        case warn      // tight; run may be slow or stop
        case block     // not enough to load the model safely
    }

    /// Decide from free memory (MB) vs the model's approximate in-memory footprint (GB).
    /// Need ≈ model size + 512 MB headroom; warn within another 512 MB.
    public static func memory(freeMB: Int, modelApproxGB: Double) -> MemoryDecision {
        let neededMB = Int(modelApproxGB * 1024) + 512
        if freeMB < neededMB { return .block }
        if freeMB < neededMB + 512 { return .warn }
        return .proceed
    }

    public enum ThermalAction: String, Sendable, Equatable {
        case proceed
        case stop      // critical thermal — stop the run cleanly
    }

    public static func thermal(_ state: DeviceThermalState) -> ThermalAction {
        state == .critical ? .stop : .proceed
    }
}
