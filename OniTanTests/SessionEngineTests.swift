import XCTest
@testable import OniTan

final class SessionEngineTests: XCTestCase {
    func testWeakItemsPrepareReviewSession() {
        let weakKanji: Set<String> = ["B", "D"]
        let reviewOrdered = [q("A"), q("B"), q("C"), q("D")]
        let allQuestions = [q("X"), q("Y"), q("Z")]

        let session = SessionEngine.makeTodaySession(
            weakKanji: weakKanji,
            reviewOrdered: reviewOrdered,
            allQuestions: allQuestions
        )

        if case .review = session.action {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected review session")
        }
        XCTAssertEqual(session.questions.map(\.kanji), ["B", "D"])
    }

    func testNoWeakItemsPrepareGentleSession() {
        let weakKanji: Set<String> = []
        let reviewOrdered = [q("A"), q("B")]
        let allQuestions = [q("X"), q("Y"), q("Z")]

        let session = SessionEngine.makeTodaySession(
            weakKanji: weakKanji,
            reviewOrdered: reviewOrdered,
            allQuestions: allQuestions
        )

        if case .gentle = session.action {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected gentle session")
        }
        XCTAssertEqual(session.questions.map(\.kanji), ["X", "Y", "Z"])
    }

    func testCapsAtFive() {
        let weakKanji: Set<String> = ["A", "B", "C", "D", "E", "F", "G"]
        let reviewOrdered = [q("A"), q("B"), q("C"), q("D"), q("E"), q("F"), q("G")]

        let session = SessionEngine.makeTodaySession(
            weakKanji: weakKanji,
            reviewOrdered: reviewOrdered,
            allQuestions: []
        )

        XCTAssertEqual(session.count, 5)
        XCTAssertEqual(session.questions.map(\.kanji), ["A", "B", "C", "D", "E"])
    }

    func testFewerThanFive() {
        let weakKanji: Set<String> = ["A", "B", "C"]
        let reviewOrdered = [q("A"), q("B"), q("C")]

        let session = SessionEngine.makeTodaySession(
            weakKanji: weakKanji,
            reviewOrdered: reviewOrdered,
            allQuestions: [q("X"), q("Y"), q("Z"), q("W"), q("V"), q("U")]
        )

        XCTAssertEqual(session.count, 3)
        XCTAssertEqual(session.questions.map(\.kanji), ["A", "B", "C"])
    }

    func testNoDuplicateKanjiInSession_reviewAndGentle() {
        let reviewSession = SessionEngine.makeTodaySession(
            weakKanji: ["A", "B", "C"],
            reviewOrdered: [q("A"), q("A"), q("B"), q("C"), q("C"), q("B")],
            allQuestions: []
        )
        XCTAssertEqual(reviewSession.questions.map(\.kanji), ["A", "B", "C"])

        let gentleSession = SessionEngine.makeTodaySession(
            weakKanji: [],
            reviewOrdered: [q("A"), q("B")],
            allQuestions: [q("X"), q("X"), q("Y"), q("Y"), q("Z"), q("X")]
        )
        XCTAssertEqual(gentleSession.questions.map(\.kanji), ["X", "Y", "Z"])
    }

    func testDeterministicOrdering() {
        let weakKanji: Set<String> = ["B", "D", "F"]
        let reviewOrdered = [q("A"), q("B"), q("D"), q("F"), q("D"), q("B")]
        let allQuestions = [q("X"), q("Y"), q("Z"), q("X")]

        let first = SessionEngine.makeTodaySession(
            weakKanji: weakKanji,
            reviewOrdered: reviewOrdered,
            allQuestions: allQuestions
        )
        let second = SessionEngine.makeTodaySession(
            weakKanji: weakKanji,
            reviewOrdered: reviewOrdered,
            allQuestions: allQuestions
        )

        XCTAssertEqual(first.questions.map(\.kanji), second.questions.map(\.kanji))
    }

    private func q(_ kanji: String) -> Question {
        Question(
            kanji: kanji,
            choices: ["c1", "c2", "c3", "c4"],
            answer: "c1",
            explain: "exp"
        )
    }
}
