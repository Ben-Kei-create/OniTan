import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan", category: "DataLoading")

// MARK: - Safe Loading Entry Point

/// App-wide quiz data loaded once at startup.
/// On failure, `quizData` falls back to an empty placeholder and
/// `dataLoadError` carries the diagnostic so the UI can show a graceful error.
let (quizData, dataLoadError): (QuizData, DataLoadError?) = {
    do {
        let manifest: StageManifest = try safeLoad("stages.json")
        var loadedStages: [Stage] = []
        for entry in manifest.stages {
            let stage: Stage = try safeLoad(entry.file)
            loadedStages.append(stage)
        }
        let unusedQuestions: [Question]? = try? safeLoad("unused_questions.json")
        let data = QuizData(stages: loadedStages, unused_questions: unusedQuestions)

        // Non-fatal validation: log warnings but don't crash
        let issues = validateQuizData(data)
        issues.forEach { logger.warning("\($0, privacy: .public)") }

        logger.info("QuizData loaded: \(loadedStages.count) stages, \(data.stages.flatMap(\.questions).count) total questions")
        return (data, nil)

    } catch let error as DataLoadError {
        logger.error("Fatal data load error: \(error.localizedDescription, privacy: .public)")
        return (QuizData(stages: [], unused_questions: nil), error)
    } catch {
        let wrapped = DataLoadError.decodingFailed("unknown", underlying: error)
        logger.error("Unexpected load error: \(error.localizedDescription, privacy: .public)")
        return (QuizData(stages: [], unused_questions: nil), wrapped)
    }
}()

/// Flat list of all questions across all stages.
let questions: [Question] = quizData.stages.flatMap { $0.questions }

// MARK: - Safe Loaders

/// Throws `DataLoadError` — never calls fatalError.
func safeLoad<T: Decodable>(_ filename: String) throws -> T {
    guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
        throw DataLoadError.fileNotFound(filename)
    }
    do {
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(T.self, from: data)
        logger.info("Loaded \(filename, privacy: .public)")
        return decoded
    } catch let decodingError as DecodingError {
        throw DataLoadError.decodingFailed(filename, underlying: decodingError)
    } catch {
        throw DataLoadError.decodingFailed(filename, underlying: error)
    }
}

/// Returns nil on failure instead of crashing. Use for optional resources.
func loadOptional<T: Decodable>(_ filename: String) -> T? {
    try? safeLoad(filename)
}

// MARK: - JSON Validation

/// Returns human-readable validation issues found in the data set.
func validateQuizData(_ data: QuizData) -> [String] {
    var issues: [String] = []

    for stage in data.stages {
        let tag = "Stage \(stage.stage)"

        if stage.questions.isEmpty {
            issues.append("\(tag): 問題が0件です")
            continue
        }

        // Duplicate kanji detection
        var seen = Set<String>()
        var duplicates = Set<String>()
        for q in stage.questions {
            if !seen.insert(q.kanji).inserted { duplicates.insert(q.kanji) }
        }
        if !duplicates.isEmpty {
            issues.append("\(tag): 重複漢字 → \(duplicates.sorted().joined(separator: ", "))")
        }

        // Per-question sanity checks
        for q in stage.questions {
            if q.kanji.isEmpty {
                issues.append("\(tag): 空の kanji フィールドがあります")
            }
            if q.choices.count < 2 {
                issues.append("\(tag)/\(q.kanji): 選択肢が \(q.choices.count) 個（最低2個必要）")
            }
            if !q.choices.contains(q.answer) {
                issues.append("\(tag)/\(q.kanji): 正解「\(q.answer)」が選択肢に含まれていません")
            }
        }
    }

    return issues
}
