import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan", category: "DataLoading")

let quizData: QuizData = {
    var allStages: [Stage] = []
    for i in 1...3 {
        let filename = "stage\(i).json"
        let loadedStage: Stage = load(filename)
        allStages.append(loadedStage)
    }
    let loadedUnusedQuestions: [Question]? = loadOptional("unused_questions.json")
    let loadedData = QuizData(stages: allStages, unused_questions: loadedUnusedQuestions)
    for stage in loadedData.stages {
        if stage.questions.count != 30 {
            logger.warning("Stage \(stage.stage, privacy: .public) has \(stage.questions.count, privacy: .public) questions, expected 30.")
        }
    }
    return loadedData
}()

let questions: [Question] = quizData.stages.flatMap { $0.questions }

func load<T: Decodable>(_ filename: String) -> T {
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    do {
        let data = try Data(contentsOf: file)
        let decoded = try JSONDecoder().decode(T.self, from: data)
        logger.info("Loaded \(filename, privacy: .public)")
        return decoded
    } catch {
        logger.error("Failed to parse \(filename, privacy: .public): \(error)")
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

func loadOptional<T: Decodable>(_ filename: String) -> T? {
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
        return nil
    }
    do {
        let data = try Data(contentsOf: file)
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        logger.error("Failed to parse \(filename, privacy: .public): \(error)")
        return nil
    }
}
