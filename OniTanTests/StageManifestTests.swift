import XCTest
@testable import OniTan

final class StageManifestTests: XCTestCase {

    // MARK: - StageEntry

    func testStageEntry_decoding() throws {
        let json = """
        { "id": 1, "file": "stage1.json", "title": "準1級 基礎", "difficulty": 1 }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(StageEntry.self, from: json)
        XCTAssertEqual(entry.id, 1)
        XCTAssertEqual(entry.file, "stage1.json")
        XCTAssertEqual(entry.title, "準1級 基礎")
        XCTAssertEqual(entry.difficulty, 1)
    }

    // MARK: - StageManifest

    func testStageManifest_decoding() throws {
        let json = """
        {
          "stages": [
            { "id": 1, "file": "stage1.json", "title": "準1級 基礎", "difficulty": 1 },
            { "id": 2, "file": "stage2.json", "title": "準1級 標準", "difficulty": 2 },
            { "id": 3, "file": "stage3.json", "title": "準1級 鬼",   "difficulty": 3 }
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
            { "id": 3, "file": "stage3.json", "title": "C", "difficulty": 3 },
            { "id": 1, "file": "stage1.json", "title": "A", "difficulty": 1 }
          ]
        }
        """.data(using: .utf8)!

        let manifest = try JSONDecoder().decode(StageManifest.self, from: json)
        // マニフェストの記載順が保持されること（ソートは呼び出し側の責務）
        XCTAssertEqual(manifest.stages[0].id, 3)
        XCTAssertEqual(manifest.stages[1].id, 1)
    }

    func testStageManifest_emptyStages() throws {
        let json = """{ "stages": [] }""".data(using: .utf8)!
        let manifest = try JSONDecoder().decode(StageManifest.self, from: json)
        XCTAssertTrue(manifest.stages.isEmpty)
    }
}
