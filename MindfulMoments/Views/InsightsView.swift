import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Entry.date, order: .forward) private var entries: [Entry]

    @AppStorage("mm_textSizePreference") private var textSizePreference: Int = 1
    @AppStorage("mm_showWeeklyMood") private var showWeeklyMood: Bool = true

    @StateObject private var viewModel = InsightsViewModel()

    // Computed values powered by the ViewModel
    private var moodStats: [MoodStat] {
        viewModel.moodStats(from: entries)
    }

    private var categoryStats: [CategoryStat] {
        viewModel.categoryStats(from: entries)
    }

    private var totalEntries: Int {
        viewModel.totalEntries(from: entries)
    }

    private var lastEntryDateText: String {
        viewModel.lastEntryDateText(from: entries)
    }

    private var streakCurrent: Int {
        viewModel.streakStats(from: entries).current
    }

    private var streakLongest: Int {
        viewModel.streakStats(from: entries).longest
    }

    private var weeklyStats: [DailyMoodStat] {
        viewModel.weeklyMoodStats(from: entries)
    }

    private var textSize: AppTextSize {
        AppearanceHelper.textSize(from: textSizePreference)
    }

    private var exportText: String {
        guard !entries.isEmpty else {
            return "Mindful Moments — no entries yet."
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let parts = entries.map { entry in
            let dateString = formatter.string(from: entry.date)
            return """
            Mindful Moments — \(dateString)
            Mood: \(entry.mood)
            Category: \(entry.category)

            \(entry.content)
            """
        }

        return parts.joined(separator: "\n\n— — — — — — — — —\n\n")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Overview card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(AppearanceHelper.headlineFont(for: textSize))

                        Text("Total entries: \(totalEntries)")
                            .font(AppearanceHelper.bodyFont(for: textSize))
                        Text("Last entry: \(lastEntryDateText)")
                            .font(AppearanceHelper.secondaryFont(for: textSize))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Streaks card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Streaks")
                            .font(AppearanceHelper.headlineFont(for: textSize))

                        Text("Current streak: \(streakCurrent) day\(streakCurrent == 1 ? "" : "s")")
                            .font(AppearanceHelper.bodyFont(for: textSize))
                        Text("Longest streak: \(streakLongest) day\(streakLongest == 1 ? "" : "s")")
                            .font(AppearanceHelper.secondaryFont(for: textSize))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Mood frequency chart (all time)
                    if moodStats.isEmpty {
                        ContentUnavailableView(
                            "No insights yet",
                            systemImage: "chart.bar",
                            description: Text("Add a few entries to see your mood trends.")
                        )
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mood frequency (all time)")
                                .font(AppearanceHelper.headlineFont(for: textSize))

                            Chart(moodStats) { stat in
                                BarMark(
                                    x: .value("Mood", stat.mood),
                                    y: .value("Entries", stat.count)
                                )
                                .foregroundStyle(AppearanceHelper.color(forMood: stat.mood))
                            }
                            .frame(height: 240)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.thickMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    if !categoryStats.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Entries by category")
                                .font(AppearanceHelper.headlineFont(for: textSize))

                            Chart(categoryStats) { stat in
                                BarMark(
                                    x: .value("Category", stat.category),
                                    y: .value("Entries", stat.count)
                                )
                            }
                            .frame(height: 240)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.thickMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    if showWeeklyMood {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Weekly mood (last 7 days)")
                                .font(AppearanceHelper.headlineFont(for: textSize))

                            if weeklyStats.isEmpty {
                                Text("No entries in the last week yet.")
                                    .font(AppearanceHelper.secondaryFont(for: textSize))
                                    .foregroundStyle(.secondary)
                            } else {
                                Chart(weeklyStats) { stat in
                                    LineMark(
                                        x: .value("Day", stat.date),
                                        y: .value("Mood score", stat.averageScore)
                                    )
                                    PointMark(
                                        x: .value("Day", stat.date),
                                        y: .value("Mood score", stat.averageScore)
                                    )
                                }
                                .frame(height: 240)

                                Text("Mood scale: 1 = 😭, 2 = ☹️, 3 = 😐, 4 = 😊, 5 = 🤩")
                                    .font(AppearanceHelper.secondaryFont(for: textSize))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.thickMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export journal")
                            .font(AppearanceHelper.headlineFont(for: textSize))

                        Text("Share all of your entries as plain text to save them elsewhere.")
                            .font(AppearanceHelper.secondaryFont(for: textSize))
                            .foregroundStyle(.secondary)

                        ShareLink(item: exportText) {
                            Label("Export all entries", systemImage: "square.and.arrow.up.on.square")
                                .font(AppearanceHelper.bodyFont(for: textSize))
                        }
                        .disabled(entries.isEmpty)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Spacer(minLength: 0)
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }
}
