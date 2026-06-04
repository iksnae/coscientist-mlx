import Logging

/// Shared logger for the kit. Adapters and the engine log through this; the label is
/// reverse-DNS so downstream apps can filter it.
public enum Log {
    public static let logger = Logger(label: "com.iksnae.coscientist")
}
