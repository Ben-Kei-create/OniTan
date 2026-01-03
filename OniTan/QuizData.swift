import Foundation

// Matches the top-level structure of the JSON file
struct QuizData: Codable {
    let stages: [Stage]
    let unused_questions: [Question]?
}

// Matches each object inside the "stages" array
struct Stage: Codable {
    let stage: Int
    let questions: [Question]
}
