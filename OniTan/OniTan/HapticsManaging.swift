
import Foundation
import UIKit

protocol HapticsManaging {
    func play(_ type: UINotificationFeedbackGenerator.FeedbackType)
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle)
}

extension HapticsManager: HapticsManaging {}

class MockHapticsManager: HapticsManaging {
    func play(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        print("Playing haptic feedback of type: \(type)")
    }

    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        print("Playing haptic impact of style: \(style)")
    }
}
