import XCTest
@testable import OniTan

final class StageManifestTests: XCTestCase {

    /// Load from the application bundle so a missing Xcode resource also fails.
    func testExpandedStagesAreBundledAndPlayable() throws {
        let targets = [
            ("reading", 36, QuestionKind.sentenceReading),
            ("yojijukugo", 12, .yojijukugo),
            ("writing", 11, .writing),
            ("synonym", 5, .synonym),
            ("antonym", 5, .antonym),
            ("proverb", 5, .proverb),
            ("common_kanji", 5, .commonKanji),
            ("hyogai_reading", 5, .hyogaiReading),
            ("compound_reading_kun", 5, .compoundReadingKun),
            ("error_correction", 5, .errorCorrection),
        ]
        var stageIDs = Set<Int>()
        for (prefix, minimumCount, kind) in targets {
            let manifest: StageManifest = try safeLoad("\(prefix)_stages.json")
            XCTAssertGreaterThanOrEqual(manifest.stages.count, minimumCount, prefix)
            var prompts = Set<String>()
            for entry in manifest.stages {
                XCTAssertTrue(stageIDs.insert(entry.id).inserted, "Duplicate stage ID: \(entry.id)")
                let stage: Stage = try safeLoad(entry.file)
                XCTAssertEqual(stage.stage, entry.id, entry.file)
                XCTAssertFalse(stage.questions.isEmpty, entry.file)
                // The first two legacy reading stages retain 20 questions.
                // All other practice stages now use the 15-question format.
                let expectedCount = prefix == "reading" && entry.id <= 2 ? 20 : 15
                XCTAssertEqual(stage.questions.count, expectedCount, entry.file)
                for question in stage.questions {
                    XCTAssertEqual(question.kind, kind, entry.file)
                    let signature = "\(question.kanji)-\(question.answer)-\(question.payload?.sentenceContext ?? "")"
                    XCTAssertTrue(prompts.insert(signature).inserted, "Repeated question: \(signature)")
                    XCTAssertEqual(question.choices.count, 4, question.kanji)
                    XCTAssertEqual(Set(question.choices).count, 4, question.kanji)
                    XCTAssertEqual(question.choices.filter { $0 == question.answer }.count, 1)
                    XCTAssertFalse(question.explain.isEmpty)
                }
            }
        }
        XCTAssertNil(dataLoadError)
        XCTAssertTrue(stageIDs.isSubset(of: Set(quizData.stages.map(\.stage))))
        XCTAssertEqual(Set(quizData.stages.map(\.stage)).count, quizData.stages.count,
                       "Stage IDs must also be unique in the app's loaded data")
    }

    func testErrorCorrectionsReplaceExactlyOneCharacter() {
        let corrections = allQuestions.filter { $0.kind == .errorCorrection }
        XCTAssertFalse(corrections.isEmpty)
        for question in corrections {
            guard let payload = question.payload,
                  let original = payload.originalSentence,
                  let corrected = payload.correctedSentence,
                  let wrong = payload.wrongKanji,
                  let correct = payload.correctKanji else {
                XCTFail("Missing error correction payload: \(question.id)")
                continue
            }
            XCTAssertEqual(wrong.count, 1, question.id)
            XCTAssertEqual(correct.count, 1, question.id)
            XCTAssertNotEqual(wrong, correct, question.id)
            XCTAssertEqual(original.components(separatedBy: wrong).count - 1, 1, question.id)
            XCTAssertEqual(original.replacingOccurrences(of: wrong, with: correct), corrected, question.id)
            XCTAssertEqual(question.answer, "\(wrong)→\(correct)", question.id)
        }
    }

    // MARK: - StageEntry

    func testStageEntry_decoding() throws {
        let json = """
        { "id": 1, "file": "reading_stage1.json", "title": "準1級 基礎", "difficulty": 1 }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(StageEntry.self, from: json)
        XCTAssertEqual(entry.id, 1)
        XCTAssertEqual(entry.file, "reading_stage1.json")
        XCTAssertEqual(entry.title, "準1級 基礎")
        XCTAssertEqual(entry.difficulty, 1)
    }

    // MARK: - StageManifest

    func testStageManifest_decoding() throws {
        let json = """
        {
          "stages": [
            { "id": 1, "file": "reading_stage1.json", "title": "準1級 基礎", "difficulty": 1 },
            { "id": 2, "file": "reading_stage2.json", "title": "準1級 標準", "difficulty": 2 },
            { "id": 3, "file": "reading_stage3.json", "title": "準1級 鬼",   "difficulty": 3 }
          ]
        }
        """.data(using: .utf8)!

        let manifest = try JSONDecoder().decode(StageManifest.self, from: json)
        XCTAssertEqual(manifest.stages.count, 3)
        XCTAssertEqual(manifest.stages[0].id, 1)
        XCTAssertEqual(manifest.stages[1].title, "準1級 標準")
        XCTAssertEqual(manifest.stages[2].difficulty, 3)
    }

    func testStageManifest_orderPreserved() throws {
        let json = """
        {
          "stages": [
            { "id": 3, "file": "reading_stage3.json", "title": "C", "difficulty": 3 },
            { "id": 1, "file": "reading_stage1.json", "title": "A", "difficulty": 1 }
          ]
        }
        """.data(using: .utf8)!

        let manifest = try JSONDecoder().decode(StageManifest.self, from: json)
        // マニフェストの記載順が保持されること（ソートは呼び出し側の責務）
        XCTAssertEqual(manifest.stages[0].id, 3)
        XCTAssertEqual(manifest.stages[1].id, 1)
    }

    func testStageManifest_emptyStages() throws {
        let json = "{ \"stages\": [] }".data(using: .utf8)!
        let manifest = try JSONDecoder().decode(StageManifest.self, from: json)
        XCTAssertTrue(manifest.stages.isEmpty)
    }
}
