import Foundation

// MARK: - ReadinessScore

struct ReadinessScore {
    /// 0…1 composite readiness.
    let overall: Double
    /// Estimated exam accuracy (0…1).
    let estimatedExamScore: Double
    /// Per-kind accuracy.
    let byKind: [QuestionKind: Double]
    /// Kinds with accuracy below threshold, sorted worst-first.
    let weakestKinds: [QuestionKind]
    /// Human-readable next-step recommendation.
    let recommendation: String

    var overallPercent: Int { Int(overall * 100) }
    var estimatedScorePercent: Int { Int(estimatedExamScore * 100) }

    static let zero = ReadinessScore(
        overall: 0,
        estimatedExamScore: 0,
        byKind: [:],
        weakestKinds: [],
        recommendation: "まずは読み道場から始めましょう"
    )
}

// MARK: - ReadinessCalculator

struct ReadinessCalculator {

    // Kanken Pre-1 content kinds and their exam weight (mirrors exam_blueprints.json full distribution)
    static let coreKinds: [(QuestionKind, Double)] = [
        (.reading,            0.25),
        (.hyogaiReading,      0.10),
        (.compoundReadingKun, 0.10),
        (.commonKanji,        0.10),
        (.errorCorrection,    0.10),
        (.yojijukugo,         0.15),
        (.synonym,            0.05),
        (.antonym,            0.05),
        (.proverb,            0.05),
        (.passageReading,     0.025),
        (.passageVocabulary,  0.025),
    ]

    private static let passingThreshold = 0.70

    /// Calculates readiness from mastery records + optional recent exam results.
    ///
    /// Formula:
    ///   readiness = 0.35 × overall accuracy
    ///             + 0.25 × category coverage
    ///             + 0.20 × mastery ratio
    ///             + 0.20 × mock exam average (defaults to accuracy if no exams)
    @MainActor
    static func calculate(
        masteryRepo: MasteryRepository,
        allQuestions: [Question],
        examResultRepo: ExamResultRepository
    ) -> ReadinessScore {

        guard !allQuestions.isEmpty else { return .zero }

        // Per-kind accuracy
        var kindAccuracies: [QuestionKind: Double] = [:]
        for (kind, _) in coreKinds {
            kindAccuracies[kind] = masteryRepo.accuracy(for: kind)
        }

        // Component 1: weighted overall accuracy across core kinds
        let weightedAccuracy: Double = coreKinds.reduce(0) { sum, pair in
            sum + (kindAccuracies[pair.0] ?? 0) * pair.1
        }

        // Component 2: category coverage (fraction of questions attempted)
        let attempted = masteryRepo.records.values.filter { $0.attempts > 0 }.count
        let coverage = Double(attempted) / Double(allQuestions.count)

        // Component 3: mastery ratio
        let mastered = Double(masteryRepo.masteredCount)
        let masteryRatio = mastered / Double(allQuestions.count)

        // Component 4: recent exam average
        let examAvg = examResultRepo.overallAverageAccuracy() ?? weightedAccuracy

        let readiness = 0.35 * weightedAccuracy
                      + 0.25 * coverage
                      + 0.20 * masteryRatio
                      + 0.20 * examAvg

        // Estimated exam score: weighted accuracy is closest to exam performance
        let estimatedScore = min(1.0, weightedAccuracy * 1.05)  // slight optimism factor

        // Weakest kinds
        let weakest = coreKinds
            .filter { (kindAccuracies[$0.0] ?? 0) < passingThreshold }
            .sorted { (kindAccuracies[$0.0] ?? 0) < (kindAccuracies[$1.0] ?? 0) }
            .map(\.0)

        let recommendation = buildRecommendation(
            weakest: weakest,
            coverage: coverage,
            readiness: readiness
        )

        return ReadinessScore(
            overall: min(1.0, readiness),
            estimatedExamScore: min(1.0, estimatedScore),
            byKind: kindAccuracies,
            weakestKinds: Array(weakest.prefix(3)),
            recommendation: recommendation
        )
    }

    private static func buildRecommendation(
        weakest: [QuestionKind],
        coverage: Double,
        readiness: Double
    ) -> String {
        if coverage < 0.30 {
            return "まだ未挑戦の問題が多いです。各道場を一通りこなしましょう。"
        }
        if let w = weakest.first {
            return "\(w.displayName)の正答率が低いです。\(w.displayName)道場で集中練習しましょう。"
        }
        if readiness >= 0.85 {
            return "合格圏内です！本番模試で最終確認しましょう。"
        }
        if readiness >= 0.70 {
            return "もう一息です。苦手集中モードと模試ミニを繰り返しましょう。"
        }
        return "各カテゴリをまんべんなく練習しましょう。模試ミニで弱点を確認してください。"
    }
}
