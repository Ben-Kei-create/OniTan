import Foundation

// Load the questions from the JSON file.
let questions: [Question] = load("questions.json")

// Generic function to load and decode a JSON file from the app bundle.
func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    // The user needs to ensure that 'questions.json' is included in the app's main bundle.
    // In Xcode, this is typically done by adding the file to the "Copy Bundle Resources" build phase.
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
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
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

