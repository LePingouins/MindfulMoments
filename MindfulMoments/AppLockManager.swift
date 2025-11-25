import Foundation
import LocalAuthentication
import Combine

@MainActor
class AppLockManager: ObservableObject {
    @Published var isUnlocked: Bool = false

    func lock() {
        isUnlocked = false
    }

    func authenticate() async {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Unlock your journal"

            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: reason
                )

                if success {
                    isUnlocked = true
                } else {
                    isUnlocked = false
                }
            } catch {
                print("Authentication error: \(error.localizedDescription)")
                isUnlocked = false
            }
        } else {
            print("Biometry not available, unlocking by default.")
            isUnlocked = true
        }
    }
}
