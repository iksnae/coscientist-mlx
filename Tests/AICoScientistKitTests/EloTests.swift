import Testing
@testable import AICoScientistKit

/// Elo behaviour must match the Python reference exactly: expected score from the rating
/// gap, move by `kFactor * (actual - expected)`, integer-truncated toward zero.
@Suite("Elo rating")
struct EloTests {

    @Test("Equal ratings: winner +16, loser -16 at k=32")
    func equalRatings() {
        var winner = Hypothesis(text: "w", eloRating: 1200)
        var loser = Hypothesis(text: "l", eloRating: 1200)
        let oldWinner = winner.eloRating
        winner.updateElo(opponentElo: loser.eloRating, didWin: true, kFactor: 32)
        loser.updateElo(opponentElo: oldWinner, didWin: false, kFactor: 32)
        #expect(winner.eloRating == 1216)
        #expect(loser.eloRating == 1184)
    }

    @Test("Underdog win is truncated toward zero (1200 beats 1400 → 1224)")
    func underdogWin() {
        var underdog = Hypothesis(text: "u", eloRating: 1200)
        underdog.updateElo(opponentElo: 1400, didWin: true, kFactor: 32)
        // expected ≈ 0.2403 → 32*(1-0.2403)=24.31 → trunc → 24
        #expect(underdog.eloRating == 1224)
    }

    @Test("Favourite loss is truncated toward zero (1400 loses to 1200 → 1376)")
    func favouriteLoss() {
        var favourite = Hypothesis(text: "f", eloRating: 1400)
        favourite.updateElo(opponentElo: 1200, didWin: false, kFactor: 32)
        // expected ≈ 0.7597 → 32*(0-0.7597)=-24.31 → trunc → -24
        #expect(favourite.eloRating == 1376)
    }

    @Test("Win/loss counters increment with outcome")
    func counters() {
        var h = Hypothesis(text: "h")
        h.updateElo(opponentElo: 1200, didWin: true)
        h.updateElo(opponentElo: 1200, didWin: false)
        h.updateElo(opponentElo: 1200, didWin: true)
        #expect(h.winCount == 2)
        #expect(h.lossCount == 1)
        #expect(h.totalMatches == 3)
    }
}
