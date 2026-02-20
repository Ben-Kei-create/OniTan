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

        // Fatal validation: throws DataLoadError if critical data errors found
        try validateQuizDataStrict(data)

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

// MARK: - JSON Validation (non-fatal warnings)

/// Returns human-readable validation issues found in the data set.
/// All items are non-fatal warnings; for fatal error checking see `validateQuizDataStrict`.
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
            let qtag = "\(tag)/\(q.kanji.isEmpty ? "<空>" : q.kanji)"

            if q.kanji.isEmpty {
                issues.append("\(tag): 空の kanji フィールドがあります")
            }
            if q.choices.count < 2 {
                issues.append("\(qtag): 選択肢が \(q.choices.count) 個（最低2個必要）")
            }
            if !q.choices.contains(q.answer) {
                issues.append("\(qtag): 正解「\(q.answer)」が選択肢に含まれていません")
            }

            // ── New warnings (non-fatal) ──────────────────────────────────

            // 4-choice recommendation (choices ≥ 2 is already the hard minimum above)
            if q.choices.count >= 2 && q.choices.count < 4 {
                issues.append("⚠️ \(qtag): 選択肢が \(q.choices.count) 個です（推奨は4個）")
            }

            // Unknown kind
            if q.kind == .unknown {
                issues.append("⚠️ \(qtag): kind が不明な値です")
            }

            // Payload present but discriminator missing/empty
            if let p = q.payload, (p.type == nil || p.type?.isEmpty == true) {
                issues.append("⚠️ \(qtag): payload.type が空または未設定です")
            }

            // Yojijukugo: yoji should be exactly 4 characters
            if q.kind == .yojijukugo, let p = q.payload, let yoji = p.yoji, !yoji.isEmpty {
                let cleaned = yoji.replacingOccurrences(of: "□", with: "X")
                if cleaned.count != 4 {
                    issues.append("⚠️ \(qtag): yojijukugo の yoji「\(yoji)」の文字数が4ではありません")
                }
            }
        }
    }

    return issues
}

// MARK: - Strict Validation (fatal errors → throws)

/// Validates critical data invariants and throws `DataLoadError.validationFailed`
/// if any are violated. Called by the loader after `validateQuizData`.
///
/// - Checks common invariants: non-empty prompt, answer in choices, no duplicate kanji.
/// - Checks kind-specific payload constraints when a payload is present.
/// - Warnings (non-fatal) are left to `validateQuizData`.
func validateQuizDataStrict(_ data: QuizData) throws {
    var errors: [String] = []

    for stage in data.stages {
        let tag = "Stage \(stage.stage)"

        // Duplicate kanji (de-facto unique identifier)
        var seen = Set<String>()
        for q in stage.questions {
            if !seen.insert(q.kanji).inserted {
                errors.append("\(tag): 重複漢字 '\(q.kanji)' が複数存在します")
            }
        }

        for q in stage.questions {
            let qtag = "\(tag)/\(q.kanji.isEmpty ? "<空>" : q.kanji)"

            // Empty prompt
            if q.kanji.isEmpty {
                errors.append("\(qtag): kanji（prompt）が空です")
            }

            // Answer must be in choices
            if !q.choices.isEmpty && !q.choices.contains(q.answer) {
                errors.append("\(qtag): 正解「\(q.answer)」が選択肢に含まれていません")
            }

            // Empty choice strings
            if q.choices.contains(where: { $0.isEmpty }) {
                errors.append("\(qtag): 空文字列の選択肢が含まれています")
            }

            // Kind-specific payload checks (only when payload is present)
            guard let p = q.payload else { continue }

            switch q.kind {
            case .reading:
                if let k = p.targetKanji, k.isEmpty {
                    errors.append("\(qtag): reading payload.targetKanji が空です")
                }

            case .writing:
                if let k = p.kana, k.isEmpty {
                    errors.append("\(qtag): writing payload.kana が空です")
                }
                if let k = p.targetKanji, k.isEmpty {
                    errors.append("\(qtag): writing payload.targetKanji が空です")
                }

            case .cloze:
                if let sentence = p.sentence, let token = p.blankToken, !token.isEmpty {
                    if !sentence.contains(token) {
                        errors.append("\(qtag): cloze sentence に blankToken「\(token)」が含まれていません")
                    }
                }

            case .errorcorrection:
                if let wrong = p.wrongKanji, let correct = p.correctKanji,
                   !wrong.isEmpty, !correct.isEmpty, wrong == correct {
                    errors.append("\(qtag): errorcorrection の wrongKanji と correctKanji が同じです")
                }
                if let orig = p.originalSentence, orig.isEmpty {
                    errors.append("\(qtag): errorcorrection の originalSentence が空です")
                }

            case .composition:
                if let st = p.structureType, !QuestionKind.validStructureTypes.contains(st) {
                    errors.append("\(qtag): composition structureType「\(st)」が不正な値です（許可値: \(QuestionKind.validStructureTypes.sorted().joined(separator: ", "))）")
                }

            default:
                break
            }
        }
    }

    if !errors.isEmpty {
        throw DataLoadError.validationFailed(errors)
    }
}
