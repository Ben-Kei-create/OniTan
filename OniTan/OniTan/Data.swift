import Foundation

class QuizDataLoader {
    func load() -> QuizData {
        var allStages: [Stage] = []

        // Dynamically load all stage JSON files
        if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) {
            let stageUrls = urls.filter { $0.lastPathComponent.hasPrefix("stage") && $0.lastPathComponent.contains(".json") }
            
            let sortedStageUrls = stageUrls.sorted { url1, url2 in
                guard let stageNumber1 = Int(url1.lastPathComponent.replacingOccurrences(of: "stage", with: "").replacingOccurrences(of: ".json", with: "")),
                      let stageNumber2 = Int(url2.lastPathComponent.replacingOccurrences(of: "stage", with: "").replacingOccurrences(of: ".json", with: "")) else {
                    return false
                }
                return stageNumber1 < stageNumber2
            }
            
            for url in sortedStageUrls {
                let filename = url.lastPathComponent
                let loadedStage: Stage = load(filename)
                allStages.append(loadedStage)
            }
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
    }
    
    // Generic function to load and decode a JSON file from the app bundle.
    private func load<T: Decodable>(_ filename: String) -> T {
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
            fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
        }
    }

    // New optional load function
    private func loadOptional<T: Decodable>(_ filename: String) -> T? {
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: file)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            return nil
        }
        
    }
}