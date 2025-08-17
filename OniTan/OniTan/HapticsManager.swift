import SwiftUI

class HapticsManager {
    static let shared = HapticsManager()
    private let generator = UINotificationFeedbackGenerator()

    private init() {}

    func play(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        generator.notificationOccurred(type)
    }

    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactGenerator = UIImpactFeedbackGenerator(style: style)
        impactGenerator.impactOccurred()
    }
}
