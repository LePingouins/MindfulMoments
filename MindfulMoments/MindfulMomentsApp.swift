import SwiftUI
import SwiftData

@main
struct MindfulMomentsApp: App {
    @StateObject private var lockManager = AppLockManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(lockManager)
        }
        .modelContainer(for: Entry.self)
    }
}

// MARK: - RootView: onboarding + lock + main tabs + theme (no accent customization)

struct RootView: View {
    @EnvironmentObject var lockManager: AppLockManager
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("mm_lockEnabled") private var lockEnabled: Bool = false
    @AppStorage("mm_hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("mm_themeStyle") private var themeStyle: Int = 0    // 0 system, 1 light, 2 dark

    // Just handle light/dark/system; accent uses system default
    private var colorScheme: ColorScheme? {
        switch themeStyle {
        case 1: return .light
        case 2: return .dark
        default: return nil       // system default
        }
    }

    var body: some View {
        Group {
            // 1) First run → onboarding
            if !hasSeenOnboarding {
                OnboardingView {
                    hasSeenOnboarding = true

                    if lockEnabled {
                        Task {
                            await lockManager.authenticate()
                        }
                    } else {
                        lockManager.isUnlocked = true
                    }
                }
            }
            // 2) Lock screen
            else if lockEnabled && !lockManager.isUnlocked {
                LockScreenView()
            }
            // 3) Main app
            else {
                MainTabView()
            }
        }
        .preferredColorScheme(colorScheme)
        .onAppear {
            // Keep lock state consistent when app starts
            if hasSeenOnboarding {
                if lockEnabled {
                    if !lockManager.isUnlocked {
                        Task {
                            await lockManager.authenticate()
                        }
                    }
                } else {
                    lockManager.isUnlocked = true
                }
            }
        }
        .onChange(of: lockEnabled) { _, newValue in
            if newValue {
                // Turning lock ON → lock and require auth
                lockManager.lock()
                Task {
                    await lockManager.authenticate()
                }
            } else {
                // Turning lock OFF → keep app unlocked
                lockManager.isUnlocked = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                if lockEnabled {
                    lockManager.lock()
                }
            case .active:
                if hasSeenOnboarding && lockEnabled && !lockManager.isUnlocked {
                    Task {
                        await lockManager.authenticate()
                    }
                }
            default:
                break
            }
        }
    }
}
