import Testing
@testable import AICoScientistKit

@Suite("Embedding clusterer")
struct EmbeddingClustererTests {

    @Test("Empty input yields no clusters")
    func empty() {
        #expect(EmbeddingClusterer.cluster([], threshold: 0.8).isEmpty)
    }

    @Test("Cosine: identical = 1, orthogonal = 0")
    func cosine() {
        #expect(EmbeddingClusterer.cosine([1, 0], [1, 0]) == 1)
        #expect(EmbeddingClusterer.cosine([1, 0], [0, 1]) == 0)
    }

    @Test("Similar vectors cluster; orthogonal stays separate")
    func grouping() {
        let groups = EmbeddingClusterer.cluster([[1, 0], [1, 0], [0, 1]], threshold: 0.9)
        #expect(groups.count == 2)
        #expect(groups.contains([0, 1]))
        #expect(groups.contains([2]))
    }

    @Test("High threshold makes every vector a singleton")
    func allSingletons() {
        let groups = EmbeddingClusterer.cluster([[1, 0], [0, 1], [0.6, 0.8]], threshold: 0.99)
        #expect(groups.count == 3)
    }

    @Test("Transitive merging via a bridge vector")
    func transitive() {
        // Unit vectors at 0°, 15°, 30°: a~b=cos15≈0.966, b~c=cos15≈0.966, a~c=cos30≈0.866.
        // At threshold 0.95 a-b and b-c are edges but a-c is not — all merge through b.
        let a: [Float] = [1.0, 0.0]
        let b: [Float] = [0.9659, 0.2588]
        let c: [Float] = [0.8660, 0.5000]
        let groups = EmbeddingClusterer.cluster([a, b, c], threshold: 0.95)
        #expect(groups.count == 1)
        #expect(groups.first?.count == 3)
    }
}
