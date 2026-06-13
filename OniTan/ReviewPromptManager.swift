import Foundation

/// Tracks when it's appropriate to ask the user for an App Store review.
///
/// Apple's StoreKit `requestReview` action self-throttles (the system decides
/// whether to actually show the prompt), so this manager only needs to avoid
/// calling it too eagerly — e.g. trigger once the user has shown some
/// engagement (a multi-day streak or several completed sessions).
final class ReviewPromptManager: ObservableObject {
    private let defaults: UserDefaults
    private let sessionCountKey = "reviewPrompt_sessionCompleteCount"
    private let hasPromptedKey = "reviewPrompt_hasPrompted"

    /// Minimum completed sessions before the first prompt is considered.
    static let sessionThreshold = 5
    /// Minimum current streak (days) before the first prompt is considered.
    static let streakThreshold = 3

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Call each time a quiz session is completed.
    /// Returns `true` if this is a good moment to call `requestReview()`.
    func sessionCompleted(currentStreak: Int) -> Bool {
        let count = defaults.integer(forKey: sessionCountKey) + 1
        defaults.set(count, forKey: sessionCountKey)

        guard !defaults.bool(forKey: hasPromptedKey) else { return false }
        guard count >= Self.sessionThreshold || currentStreak >= Self.streakThreshold else { return false }

        defaults.set(true, forKey: hasPromptedKey)
        return true
    }
}
