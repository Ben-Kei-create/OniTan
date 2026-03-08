import Foundation

struct QuestionReadingMetadata: Equatable {
    enum AnswerKind: Equatable {
        case onyomi
        case kunyomi
        case shared
        case unknown
    }

    let onyomi: [String]
    let kunyomi: [String]

    var sharedReadings: [String] {
        var result: [String] = []
        let kunSet = Set(kunyomi)
        for reading in onyomi where kunSet.contains(reading) && !result.contains(reading) {
            result.append(reading)
        }
        return result
    }

    func answerKind(for answer: String) -> AnswerKind {
        let inOn = onyomi.contains(answer)
        let inKun = kunyomi.contains(answer)

        switch (inOn, inKun) {
        case (true, true): return .shared
        case (true, false): return .onyomi
        case (false, true): return .kunyomi
        default: return .unknown
        }
    }

    func playerNote(for answer: String) -> String? {
        guard answerKind(for: answer) == .shared else { return nil }
        return "この読みは音読み・訓読みの両方で使われます。今回は読みそのものが合っていれば正解です。"
    }
}

extension Question {
    var readingMetadata: QuestionReadingMetadata {
        QuestionReadingMetadata(
            onyomi: extractReadings(from: "音読み: "),
            kunyomi: extractReadings(from: "訓読み: ")
        )
    }

    private func extractReadings(from prefix: String) -> [String] {
        guard let line = explain.split(separator: "\n").map(String.init).first(where: { $0.hasPrefix(prefix) }) else {
            return []
        }

        let values = line
            .replacingOccurrences(of: prefix, with: "")
            .split(separator: "・")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}
