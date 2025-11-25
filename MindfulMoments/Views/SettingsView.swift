import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var lockManager: AppLockManager

    @AppStorage("mm_themeStyle") private var themeStyle: Int = 0          // 0 system, 1 light, 2 dark
    @AppStorage("mm_textSizePreference") private var textSizePreference: Int = 1

    @AppStorage("mm_showQuoteOfDay") private var showQuoteOfDay: Bool = true
    @AppStorage("mm_showWeeklyMood") private var showWeeklyMood: Bool = true

    @AppStorage("mm_lockEnabled") private var lockEnabled: Bool = false

    @AppStorage("mm_dailyReminderEnabled") private var dailyReminderEnabled: Bool = false
    @AppStorage("mm_dailyReminderHour") private var dailyReminderHour: Int = 20
    @AppStorage("mm_dailyReminderMinute") private var dailyReminderMinute: Int = 0

    @AppStorage("mm_weeklyGoal") private var weeklyGoal: Int = 3   // entries per week goal

    @State private var reminderTime: Date =
        Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Appearance
                Section("Appearance") {
                    Picker("Theme", selection: $themeStyle) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }

                    Picker("Text size", selection: $textSizePreference) {
                        Text("Small").tag(0)
                        Text("Medium").tag(1)
                        Text("Large").tag(2)
                    }
                }

                // MARK: - Journal
                Section("Journal") {
                    Toggle("Show Quote of the Day", isOn: $showQuoteOfDay)
                    Toggle("Show weekly mood chart", isOn: $showWeeklyMood)
                }

                // MARK: - Reflection goal
                Section("Reflection goal") {
                    Stepper(
                        value: $weeklyGoal,
                        in: 0...7
                    ) {
                        if weeklyGoal == 0 {
                            Text("No weekly goal")
                        } else if weeklyGoal == 1 {
                            Text("1 entry per week")
                        } else {
                            Text("\(weeklyGoal) entries per week")
                        }
                    }

                    Text("This goal is used to show your progress for the last 7 days in the Today section.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Reminders
                Section("Reminders") {
                    Toggle("Daily reminder", isOn: $dailyReminderEnabled)

                    if dailyReminderEnabled {
                        DatePicker(
                            "Reminder time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }

                    Text("You’ll get a daily notification to check in and write a reflection.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Privacy
                Section("Privacy") {
                    Toggle("Require Face ID / Touch ID", isOn: $lockEnabled)

                    Text("When enabled, you’ll need to authenticate to open your journal.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            syncReminderTimeFromStorage()
        }
        .onChange(of: dailyReminderEnabled) { _, newValue in
            if newValue {
                scheduleDailyReminder()
            } else {
                NotificationManager.shared.cancelDailyReminder()
            }
        }
        .onChange(of: reminderTime) { _, _ in
            if dailyReminderEnabled {
                scheduleDailyReminder()
            }
        }
    }

    // MARK: - Reminder helpers

    private func syncReminderTimeFromStorage() {
        var comps = DateComponents()
        comps.hour = dailyReminderHour
        comps.minute = dailyReminderMinute
        if let date = Calendar.current.date(from: comps) {
            reminderTime = date
        }
    }

    private func scheduleDailyReminder() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        dailyReminderHour = comps.hour ?? 20
        dailyReminderMinute = comps.minute ?? 0

        NotificationManager.shared.scheduleDailyReminder(
            hour: dailyReminderHour,
            minute: dailyReminderMinute
        )
    }
}
