import XCTest
@testable import OniTan

final class SessionEngineTests: XCTestCase {

    func testPrepareTodaySession_usesReviewWhenWeakExists() {
        let weakOrdered = [
            makeQuestion("鬱"),
            makeQuestion("燎"),
            makeQuestion("鬱")
        ]
        let data = QuizData(stages: [Stage(stage: 1, questions: [makeQuestion("逞")])], unused_questions: nil)

        let session = SessionEngine.prepareTodaySession(
            weakQuestionsOrdered: weakOrdered,
            quizData: data
        )

        XCTAssertEqual(session.action, .review)
        XCTAssertEqual(session.questions.map(\.kanji), ["鬱", "燎"])
        XCTAssertEqual(session.questionCount, 2)
    }

    func testPrepareTodaySession_usesGentleWhenNoWeakQuestions() {
        let data = QuizData(
            stages: [
                Stage(stage: 2, questions: [makeQuestion("燎"), makeQuestion("蹙")]),
                Stage(stage: 1, questions: [makeQuestion("鬱"), makeQuestion("逞")])
            ],
            unused_questions: nil
        )

        let session = SessionEngine.prepareTodaySession(
            weakQuestionsOrdered: [],
            quizData: data
        )

        XCTAssertEqual(session.action, .gentle)
        XCTAssertEqual(session.questions.map(\.kanji), ["鬱", "逞", "燎", "蹙"])
    }

    func testPrepareTodaySession_capsToFiveQuestions() {
        let weakOrdered = [
            makeQuestion("一"),
            makeQuestion("二"),
            makeQuestion("三"),
            makeQuestion("四"),
            makeQuestion("五"),
            makeQuestion("六")
        ]
        let data = QuizData(stages: [], unused_questions: nil)

        let session = SessionEngine.prepareTodaySession(
            weakQuestionsOrdered: weakOrdered,
            quizData: data
        )

        XCTAssertEqual(session.questions.map(\.kanji), ["一", "二", "三", "四", "五"])
        XCTAssertEqual(session.questionCount, 5)
    }

    func testPrepareTodaySession_handlesFewerThanFiveQuestions() {
        let data = QuizData(
            stages: [Stage(stage: 1, questions: [makeQuestion("鬱"), makeQuestion("燎")])],
            unused_questions: nil
        )

        let session = SessionEngine.prepareTodaySession(
            weakQuestionsOrdered: [],
            quizData: data
        )

        XCTAssertEqual(session.questions.map(\.kanji), ["鬱", "燎"])
        XCTAssertEqual(session.questionCount, 2)
    }

    func testPrepareTodaySession_isDeterministicForSameInput() {
        let data = QuizData(
            stages: [
                Stage(stage: 3, questions: [makeQuestion("逞"), makeQuestion("鬱")]),
                Stage(stage: 1, questions: [makeQuestion("燎"), makeQuestion("蹙")]),
                Stage(stage: 2, questions: [makeQuestion("鬱"), makeQuestion("翳")])
            ],
            unused_questions: nil
        )

        let first = SessionEngine.prepareTodaySession(
            weakQuestionsOrdered: [],
            quizData: data
        )
        let second = SessionEngine.prepareTodaySession(
            weakQuestionsOrdered: [],
            quizData: data
        )

        XCTAssertEqual(first.action, .gentle)
        XCTAssertEqual(first.questions.map(\.kanji), second.questions.map(\.kanji))
        XCTAssertEqual(first.questions.map(\.kanji), ["燎", "蹙", "鬱", "翳", "逞"])
    }

    private func makeQuestion(_ kanji: String) -> Question {
        Question(
            kanji: kanji,
            choices: ["a", "b"],
            answer: "a",
            explain: "test"
        )
    }
}
