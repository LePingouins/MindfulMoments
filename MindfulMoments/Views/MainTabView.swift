import SwiftUI

struct MainTabView: View {
    @AppStorage("mm_themePreference") private var themePreference: Int = 0   // 0 system, 1 light, 2 dark
    @AppStorage("mm_accentColorIndex") private var accentColorIndex: Int = 0

    private var colorScheme: ColorScheme? {
        switch themePreference {
        case 1: return .light
        case 2: return .dark
        default: return nil   // system
        }
    }

    private var accentColor: Color {
        AppearanceHelper.accentColor(for: accentColorIndex)
    }

    var body: some View {
        TabView {
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.closed")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }
            
            CalendarView()
                            .tabItem {
                                Label("Calendar", systemImage: "calendar")
                            }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .preferredColorScheme(colorScheme)
        .tint(accentColor)
    }
}
