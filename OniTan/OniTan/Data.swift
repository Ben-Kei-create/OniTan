import Foundation

// Use a closure to load and validate data, avoiding top-level expressions.
let quizData: QuizData = {
    // 1. Load the entire nested structure from the JSON file.
    let loadedData: QuizData = load("questions.json")
    
    // 2. Perform validation.
    for stage in loadedData.stages {
        if stage.questions.count != 30 {
            print("⚠️ WARNING: Stage \(stage.stage) has \(stage.questions.count) questions, but should have 30.")
        }
    }
    
    // 3. Return the loaded data.
    return loadedData
}()

// Extract the questions from the validated data.
let questions: [Question] = quizData.stages.flatMap { $0.questions }


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
        let decoded = try decoder.decode(T.self, from: data);
        return decoded;
    } catch {
        print("--- DETAILED PARSING ERROR --")
        print(error)
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
