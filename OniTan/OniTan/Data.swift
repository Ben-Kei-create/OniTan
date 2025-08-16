import Foundation

// 1. Load the entire nested structure from the JSON file.
let quizData: QuizData = load("questions.json")

// 2. Extract the questions from all stages and flatten them into a single array.
let questions: [Question] = quizData.stages.flatMap { $0.questions }

// --- Validation Function ---
// This function is called once when the app starts.
private func validateStageData() {
    for stage in quizData.stages {
        if stage.questions.count != 30 {
            print("⚠️ WARNING: Stage \(stage.stage) has \(stage.questions.count) questions, but should have 30.")
        }
    }
}
// Run the validation.
validateStageData()
// --- End Validation ---


// Generic function to load and decode a JSON file from the app bundle.
func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        // This will now print the detailed error to the console before crashing.
        print("--- DETAILED PARSING ERROR ---")
        print(error)
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
