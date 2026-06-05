/// Plain-language, correctly pluralized status text for a finished run. Pure + testable, so the
/// apps don't hand-build status strings (which produced bugs like "1 repairs").
public enum RunStatusText {
    /// "1 repair" / "0 repairs" — explicit singular/plural to handle irregulars (hypothesis →
    /// hypotheses).
    public static func count(_ n: Int, _ singular: String, _ plural: String) -> String {
        "\(n) \(n == 1 ? singular : plural)"
    }

    /// The headline for a completed, successful run.
    public static func finished(hypotheses: Int, repairs: Int, decodeFailures: Int) -> String {
        "Done · " + count(hypotheses, "hypothesis", "hypotheses")
            + " · " + count(repairs, "repair", "repairs")
            + " · " + count(decodeFailures, "decode failure", "decode failures")
    }
}
