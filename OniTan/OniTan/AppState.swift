import Foundation
import SwiftUI

class AppState: ObservableObject {
    // Remove @Published here, AppStorageCodable already handles publishing changes
    @AppStorageCodable(wrappedValue: [], "clearedStages") var clearedStages: Set<Int>
    
    @Published var showingResetAlert: Bool = false
    @Published var showResetConfirmation: Bool = false
    @Published var showingCannotResetAlert: Bool = false

    init() {}
}