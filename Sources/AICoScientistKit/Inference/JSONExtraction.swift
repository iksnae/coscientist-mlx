/// Tolerant extraction of a single JSON object from noisy model output. This is the
/// *fallback* path for models without schema-constrained decoding (the primary path,
/// landing with MLX). It scans for the first balanced `{ … }`, respecting string literals
/// and escapes so braces inside strings do not unbalance the match.
public enum JSONExtraction {

    /// Returns the first balanced top-level JSON object substring, or `nil` if none exists.
    public static func extractObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{") else { return nil }

        var depth = 0
        var inString = false
        var escaped = false
        var cursor = start

        while cursor < text.endIndex {
            let c = text[cursor]
            if escaped {
                escaped = false
            } else if c == "\\" {
                escaped = true
            } else if c == "\"" {
                inString.toggle()
            } else if !inString {
                if c == "{" {
                    depth += 1
                } else if c == "}" {
                    depth -= 1
                    if depth == 0 {
                        return String(text[start...cursor])
                    }
                }
            }
            cursor = text.index(after: cursor)
        }
        return nil  // unbalanced — no complete object
    }
}
