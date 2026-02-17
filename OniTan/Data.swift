import Foundation

// Use a closure to load and validate data, avoiding top-level expressions.
let quizData: QuizData = {
    var allStages: [Stage] = []

    // Load each stage JSON file
    for i in 1...3 { // Assuming stage1.json, stage2.json, stage3.json
        let filename = "stage\(i).json"
        // Each stageX.json directly decodes to a Stage struct
        let loadedStage: Stage = load(filename)
        allStages.append(loadedStage)
    }
    
    // Load unused_questions.json optionally
    let loadedUnusedQuestions: [Question]? = loadOptional("unused_questions.json")
    
    // Create a QuizData object from the loaded stages and unused questions
    let loadedData = QuizData(stages: allStages, unused_questions: loadedUnusedQuestions)

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
    print("Attempting to load file: \(filename)")
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
        fatalError("Couldn\'t find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
        print("Successfully loaded data from file: \(filename)")
    } catch {
        fatalError("Couldn\'t load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(T.self, from: data);
        print("Successfully parsed \(filename) as \(T.self)")
        return decoded;
    } catch {
        print("---" + "DETAILED PARSING ERROR for \(filename)")
        print(error)
        fatalError("Couldn\'t parse \(filename) as \(T.self):\n\(error)")
    }
}

// New optional load function
func loadOptional<T: Decodable>(_ filename: String) -> T? {
    print("Attempting to optionally load file: \(filename)")
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
        print("File \(filename) not found, returning nil.")
        return nil
    }
    
    do {
        let data = try Data(contentsOf: file)
        print("Successfully loaded data from file: \(filename)")
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(T.self, from: data)
        print("Successfully parsed \(filename) as \(T.self)")
        return decoded
    } catch {
        print("---" + "DETAILED PARSING ERROR for \(filename)")
        print(error)
        print("Couldn\'t parse \(filename) as \(T.self), returning nil.")
        return nil
    }
    
}
