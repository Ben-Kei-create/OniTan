import Foundation

// MARK: - CategoryEntry

struct CategoryEntry: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let questionKinds: [QuestionKind]
    let stageIDs: [Int]
    let targetAccuracy: Double
    let iconName: String
    let colorHex: String
    let unlockLevel: Int?

    init(
        id: String,
        title: String,
        description: String,
        questionKinds: [QuestionKind],
        stageIDs: [Int],
        targetAccuracy: Double,
        iconName: String,
        colorHex: String,
        unlockLevel: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.questionKinds = questionKinds
        self.stageIDs = stageIDs
        self.targetAccuracy = targetAccuracy
        self.iconName = iconName
        self.colorHex = colorHex
        self.unlockLevel = unlockLevel
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(String.self, forKey: .id)
        title          = try c.decode(String.self, forKey: .title)
        description    = try c.decode(String.self, forKey: .description)
        questionKinds  = try c.decode([QuestionKind].self, forKey: .questionKinds)
        stageIDs       = try c.decode([Int].self, forKey: .stageIDs)
        targetAccuracy = try c.decode(Double.self, forKey: .targetAccuracy)
        iconName       = try c.decode(String.self, forKey: .iconName)
        colorHex       = try c.decode(String.self, forKey: .colorHex)
        unlockLevel    = try c.decodeIfPresent(Int.self, forKey: .unlockLevel)
    }

    var displayKinds: String {
        questionKinds.map(\.displayName).joined(separator: " / ")
    }
}

// MARK: - CategoryManifest

struct CategoryManifest: Codable {
    let categories: [CategoryEntry]

    func entry(for id: String) -> CategoryEntry? {
        categories.first { $0.id == id }
    }

    func entry(for kind: QuestionKind) -> CategoryEntry? {
        categories.first { $0.questionKinds.contains(kind) }
    }
}

// MARK: - Global Load

/// Loaded once at app start; nil if categories.json is absent (graceful).
let categoryManifest: CategoryManifest? = loadOptional("categories.json")
