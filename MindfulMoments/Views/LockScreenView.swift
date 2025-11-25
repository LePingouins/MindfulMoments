import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject var lockManager: AppLockManager

    @AppStorage("mm_themePreference") private var themePreference: Int = 0
    @AppStorage("mm_accentColorIndex") private var accentColorIndex: Int = 0

    private var colorScheme: ColorScheme? {
        switch themePreference {
        case 1: return .light
        case 2: return .dark
        default: return nil  // system
        }
    }

    private var accentColor: Color {
        AppearanceHelper.accentColor(for: accentColorIndex)
    }

    var body: some View {
        ZStack {
            // Background that respects theme
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(accentColor)

                Text("Journal Locked")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Unlock with Face ID, Touch ID, or your device passcode to view your entries.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Button {
                    Task {
                        await lockManager.authenticate()
                    }
                } label: {
                    Label("Unlock", systemImage: "faceid")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .preferredColorScheme(colorScheme)
        .tint(accentColor)
        .onAppear {
            // Try to authenticate automatically when lock screen appears
            Task {
                await lockManager.authenticate()
            }
        }
    }
}
