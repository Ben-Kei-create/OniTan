import Foundation

@MainActor
final class AppNavigationState: ObservableObject {
    @Published private(set) var shouldPopToRoot = false

    func popToRoot() {
        shouldPopToRoot = true
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            shouldPopToRoot = false
        }
    }
}
