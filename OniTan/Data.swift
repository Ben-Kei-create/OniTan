import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan", category: "DataLoading")

// MARK: - Safe Loading Entry Point

/// App-wide quiz data loaded once at startup.
/// On failure, `quizData` falls back to an empty placeholder and
/// `dataLoadError` carries the diagnostic so the UI can show a graceful error.
let (quizData, dataLoadError): (QuizData, DataLoadError?) = {
    do {
        let manifestFiles = [
            "reading_stages.json",
            "yojijukugo_stages.json",
            "writing_stages.json",
            "common_kanji_stages.json",
            "error_correction_stages.json",
            "synonym_stages.json",
            "antonym_stages.json",
            "proverb_stages.json",
            "passage_stages.json",
            "hyogai_reading_stages.json",
            "compound_reading_kun_stages.json",
        ]
        var loadedStages: [Stage] = []
        for manifestFile in manifestFiles {
            let manifest: StageManifest = try safeLoad(manifestFile)
            for entry in manifest.stages {
                let stage: Stage = try safeLoad(entry.file)
                let stamped = Stage(
                    stage: stage.stage,
                    questions: stage.questions.enumerated().map { idx, q in
                        q.stamped(stageNumber: stage.stage, index: idx)
                    }
                )
                loadedStages.append(stamped)
            }
        }
        let reviewQuestions: [Question]? = try? safeLoad("review_questions.json")
        let unusedQuestions: [Question]? = try? safeLoad("unused_questions.json")
        let data = QuizData(
            stages: loadedStages,
            review_questions: reviewQuestions,
            unused_questions: unusedQuestions
        )

        var validationStages = loadedStages
        if let reviewQuestions, !reviewQuestions.isEmpty {
            validationStages.append(Stage(stage: -1, questions: reviewQuestions))
        }
        let validationData = QuizData(stages: validationStages)

        // Non-fatal validation: log warnings but don't crash
        let issues = validateQuizData(validationData)
        issues.forEach { logger.warning("\($0, privacy: .public)") }

        // Fatal validation: throws DataLoadError if critical data errors found
        try validateQuizDataStrict(validationData)

        let reviewCount = reviewQuestions?.count ?? 0
        logger.info("QuizData loaded: \(loadedStages.count) stages, \(data.stages.flatMap(\.questions).count) main questions, \(reviewCount) review questions")
        return (data, nil)

    } catch let error as DataLoadError {
        logger.error("Fatal data load error: \(error.localizedDescription, privacy: .public)")
        return (QuizData(stages: [], review_questions: nil, unused_questions: nil), error)
    } catch {
        let wrapped = DataLoadError.decodingFailed("unknown", underlying: error)
        logger.error("Unexpected load error: \(error.localizedDescription, privacy: .public)")
        return (QuizData(stages: [], review_questions: nil, unused_questions: nil), wrapped)
    }
}()

/// Flat list of main-stage questions.
let questions: [Question] = quizData.stages.flatMap { $0.questions }
let reviewQuestions: [Question] = quizData.review_questions ?? []

/// Questions from standalone kind-specific JSON files (yojijukugo, writing, etc.).
let supplementalQuestions: [Question] = {
    let files = [
        "kanji_catalog_questions.json",
        "yojijukugo_questions.json",
        "synonym_questions.json",
        "antonym_questions.json",
        "writing_questions.json",
        "hyogai_reading_questions.json",
        "compound_reading_kun_questions.json",
        "common_kanji_questions.json",
        "error_correction_questions.json",
        "proverb_questions.json",
        "passage_questions.json",
    ]
    let loaded = files.flatMap { (loadOptional($0) as [Question]?) ?? [] }
    logger.info("Supplemental questions loaded: \(loaded.count, privacy: .public)")
    return loaded
}()

let allQuestions: [Question] = questions + reviewQuestions + supplementalQuestions

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

            if q.kind == .reading, q.readingMetadata.answerKind(for: q.answer) == .shared {
                issues.append("⚠️ \(qtag): 正解の読みが音読み・訓読みの両方に存在します")
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

            // CommonKanji: blankTerms should contain □
            if q.kind == .commonKanji, let p = q.payload, let terms = p.blankTerms, !terms.isEmpty {
                for term in terms where !term.contains("□") {
                    issues.append("⚠️ \(qtag): commonKanji blankTerm「\(term)」に「□」が含まれていません")
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
            case .reading, .sentenceReading, .hyogaiReading:
                if let k = p.targetKanji, k.isEmpty {
                    errors.append("\(qtag): reading payload.targetKanji が空です")
                }

            case .errorCorrection:
                if let wrong = p.wrongKanji, let correct = p.correctKanji,
                   !wrong.isEmpty, !correct.isEmpty, wrong == correct {
                    errors.append("\(qtag): errorCorrection の wrongKanji と correctKanji が同じです")
                }
                if let orig = p.originalSentence, orig.isEmpty {
                    errors.append("\(qtag): errorCorrection の originalSentence が空です")
                }

            case .yojijukugo:
                if let yoji = p.yoji, !yoji.isEmpty {
                    let cleaned = yoji.replacingOccurrences(of: "□", with: "X")
                    if cleaned.count != 4 {
                        errors.append("\(qtag): yojijukugo の yoji「\(yoji)」の文字数が4ではありません")
                    }
                }

            case .passageVocabulary:
                if p.type == "cloze" {
                    if let sentence = p.sentence,
                       let blankToken = p.blankToken,
                       !blankToken.isEmpty,
                       !sentence.contains(blankToken) {
                        errors.append("\(qtag): cloze の sentence に blankToken「\(blankToken)」が含まれていません")
                    }
                    if let passageText = p.passageText,
                       let passageBlankToken = p.passageBlankToken,
                       !passageBlankToken.isEmpty,
                       !passageText.contains(passageBlankToken) {
                        errors.append("\(qtag): passageVocabulary の passageText に passageBlankToken「\(passageBlankToken)」が含まれていません")
                    }
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
