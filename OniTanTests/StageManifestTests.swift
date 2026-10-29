import XCTest
@testable import OniTan

final class StageManifestTests: XCTestCase {

    /// Load from the application bundle so a missing Xcode resource also fails.
    func testExpandedStagesAreBundledAndPlayable() throws {
        let targets = [
            ("reading", 25, QuestionKind.sentenceReading),
            ("yojijukugo", 10, .yojijukugo),
            ("writing", 10, .writing),
            ("synonym", 5, .synonym),
            ("antonym", 5, .antonym),
            ("proverb", 5, .proverb),
            ("common_kanji", 5, .commonKanji),
        ]
        var stageIDs = Set<Int>()
        for (prefix, minimumCount, kind) in targets {
            let manifest: StageManifest = try safeLoad("\(prefix)_stages.json")
            XCTAssertGreaterThanOrEqual(manifest.stages.count, minimumCount, prefix)
            var prompts = Set<String>()
            let originalCount = prefix == "reading" ? 19 : 1
            for (index, entry) in manifest.stages.enumerated() {
                XCTAssertTrue(stageIDs.insert(entry.id).inserted, "Duplicate stage ID: \(entry.id)")
                let stage: Stage = try safeLoad(entry.file)
                XCTAssertEqual(stage.stage, entry.id, entry.file)
                XCTAssertFalse(stage.questions.isEmpty, entry.file)
                if index >= originalCount {
                    XCTAssertEqual(stage.questions.count, 10, entry.file)
                }
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
