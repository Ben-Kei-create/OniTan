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
    /// Eligibility is only consumed by `markPromptRequested()`, so a cancelled
    /// completion presentation can try again after a later session.
    func sessionCompleted(currentStreak: Int) -> Bool {
        let count = defaults.integer(forKey: sessionCountKey) + 1
        defaults.set(count, forKey: sessionCountKey)

        guard !defaults.bool(forKey: hasPromptedKey) else { return false }
        guard count >= Self.sessionThreshold || currentStreak >= Self.streakThreshold else { return false }

        return true
    }

    func markPromptRequested() {
        defaults.set(true, forKey: hasPromptedKey)
    }
}

/// A completion offers one interruption at most. StoreKit may choose not to
/// display a requested review, but that must never turn into a second ad prompt.
enum CompletionPresentation: Equatable {
    case review
    case advertisement

    static func select(reviewEligible: Bool, hasDonated: Bool) -> Self? {
        if reviewEligible { return .review }
        return hasDonated ? nil : .advertisement
    }

    var delayNanoseconds: UInt64 {
        switch self {
        case .review: return 1_200_000_000
        case .advertisement: return 2_500_000_000
        }
    }
}

/// Owns the delayed presentation so leaving the result or presenting another
/// modal can cancel it instead of allowing a stale callback to fire later.
@MainActor
final class CompletionPresentationCoordinator: ObservableObject {
    private var pendingTask: Task<Void, Never>?

    @discardableResult
    func schedule(
        _ presentation: CompletionPresentation,
        sleep: @escaping @MainActor (UInt64) async throws -> Void = {
            try await Task.sleep(nanoseconds: $0)
        },
        canPresent: @escaping @MainActor () -> Bool,
        present: @escaping @MainActor (CompletionPresentation) -> Void
    ) -> Task<Void, Never> {
        cancel()
        let task = Task {
            do {
                try await sleep(presentation.delayNanoseconds)
            } catch {
                return
            }
            guard !Task.isCancelled, canPresent() else { return }
            present(presentation)
        }
        pendingTask = task
        return task
    }

    func cancel() {
        pendingTask?.cancel()
        pendingTask = nil
    }

    deinit {
        pendingTask?.cancel()
    }
}
