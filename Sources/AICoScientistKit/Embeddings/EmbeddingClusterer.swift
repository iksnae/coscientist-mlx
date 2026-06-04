import Foundation

/// Pure, deterministic clustering of embedding vectors by cosine-similarity threshold via
/// union-find. Kept dependency-free and MLX-free so it is fully unit-testable; the actual
/// embedding computation is abstracted behind `EmbeddingModel`.
public enum EmbeddingClusterer {

    /// Group vectors so that any two with cosine similarity ≥ `threshold` end up in the same
    /// cluster (transitively). Returns clusters as lists of input indices, in first-seen order.
    public static func cluster(_ embeddings: [[Float]], threshold: Float) -> [[Int]] {
        let n = embeddings.count
        guard n > 0 else { return [] }

        var parent = Array(0..<n)
        func find(_ x: Int) -> Int {
            var root = x
            while parent[root] != root {
                parent[root] = parent[parent[root]]  // path halving
                root = parent[root]
            }
            return root
        }
        func union(_ a: Int, _ b: Int) {
            let ra = find(a), rb = find(b)
            if ra != rb { parent[ra] = rb }
        }

        for i in 0..<n {
            for j in (i + 1)..<n where cosine(embeddings[i], embeddings[j]) >= threshold {
                union(i, j)
            }
        }

        var groups: [Int: [Int]] = [:]
        var order: [Int] = []
        for i in 0..<n {
            let root = find(i)
            if groups[root] == nil { order.append(root) }
            groups[root, default: []].append(i)
        }
        return order.map { groups[$0]! }
    }

    /// Cosine similarity, robust to non-normalized inputs.
    public static func cosine(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0, normA: Float = 0, normB: Float = 0
        for k in 0..<a.count {
            dot += a[k] * b[k]
            normA += a[k] * a[k]
            normB += b[k] * b[k]
        }
        let denom = normA.squareRoot() * normB.squareRoot()
        return denom > 0 ? dot / denom : 0
    }
}
