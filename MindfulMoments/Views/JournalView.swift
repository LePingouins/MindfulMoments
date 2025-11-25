import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]

    @AppStorage("mm_textSizePreference") private var textSizePreference: Int = 1
    @AppStorage("mm_showQuoteOfDay") private var showQuoteOfDay: Bool = true
    @AppStorage("mm_weeklyGoal") private var weeklyGoal: Int = 3   // 🆕 goal

    @State private var isPresentingAddSheet = false
    @State private var entryToEdit: Entry?

    @StateObject private var viewModel = EntryListViewModel()

    // Filtered list using the ViewModel
    private var filteredEntries: [Entry] {
        viewModel.filteredEntries(from: entries)
    }

    private var textSize: AppTextSize {
        AppearanceHelper.textSize(from: textSizePreference)
    }

    // MARK: - Today summary helpers

    private var todayEntries: [Entry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDateInToday($0.date) }
    }

    private var todayEntryCount: Int {
        todayEntries.count
    }

    private var todayAverageMoodEmoji: String? {
        guard !todayEntries.isEmpty else { return nil }
        let scores = todayEntries.compactMap { moodScore(for: $0.mood) }
        guard !scores.isEmpty else { return nil }

        let avg = Double(scores.reduce(0, +)) / Double(scores.count)
        let rounded = Int(round(avg))
        return emoji(forScore: rounded)
    }

    private var currentStreak: Int {
        streakStats().current
    }

    // 🆕 Entries in the last 7 days (including today)
    private var entriesThisWeek: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return entries.filter { entry in
            let day = calendar.startOfDay(for: entry.date)
            guard let diff = calendar.dateComponents([.day], from: day, to: today).day else {
                return false
            }
            return diff >= 0 && diff < 7
        }.count
    }

    // 🆕 Summary string for goal/progress
    private var weeklyGoalSummary: String? {
        guard weeklyGoal > 0 else { return nil }
        let reached = entriesThisWeek >= weeklyGoal
        let symbol = reached ? "✅" : "⚠️"
        return "Goal: \(weeklyGoal)/week · This week: \(entriesThisWeek) \(symbol)"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    VStack(alignment: .leading, spacing: 8) {
                        if todayEntryCount == 0 {
                            Text("No entries yet today.")
                                .font(AppearanceHelper.bodyFont(for: textSize))
                                .foregroundStyle(.secondary)

                            Button {
                                NotificationManager.shared.scheduleOneOffReminderLaterToday()
                            } label: {
                                Label("Remind me later today", systemImage: "bell.badge")
                            }
                            .font(AppearanceHelper.bodyFont(for: textSize))
                        } else {
                            Text("Entries today: \(todayEntryCount)")
                                .font(AppearanceHelper.bodyFont(for: textSize))

                            if let avgMood = todayAverageMoodEmoji {
                                Text("Average mood: \(avgMood)")
                                    .font(AppearanceHelper.bodyFont(for: textSize))
                            }
                        }

                        let streak = currentStreak
                        if streak > 0 {
                            Text("Current streak: \(streak) day\(streak == 1 ? "" : "s")")
                                .font(AppearanceHelper.secondaryFont(for: textSize))
                                .foregroundStyle(.secondary)
                        }

                        if let summary = weeklyGoalSummary {
                            Text(summary)
                                .font(AppearanceHelper.secondaryFont(for: textSize))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if showQuoteOfDay {
                    Section("Quote of the Day") {
                        QuoteCardView()
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                    }
                }

                Section("Date filter") {
                    DatePicker(
                        "Show entries from",
                        selection: Binding(
                            get: { viewModel.selectedDate ?? Date() },
                            set: { viewModel.selectedDate = $0 }
                        ),
                        displayedComponents: .date
                    )

                    Button("Clear date filter") {
                        viewModel.selectedDate = nil
                    }
                    .disabled(viewModel.selectedDate == nil)
                }

                if filteredEntries.isEmpty {
                    Section {
                        Text(entries.isEmpty
                             ? "No entries yet. Tap the + button to add your first mindful moment."
                             : "No results. Try changing your search, mood, date, category, or favorites filter, or tap Clear.")
                        .font(AppearanceHelper.secondaryFont(for: textSize))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    }
                } else {
                    ForEach(filteredEntries) { entry in
                        Button {
                            entryToEdit = entry
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Text(entry.mood)
                                    .font(.largeTitle)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(entry.date, style: .date)
                                            .font(AppearanceHelper.headlineFont(for: textSize))

                                        if entry.isFavorite {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(.yellow)
                                                .imageScale(.small)
                                        }
                                    }

                                    Text(entry.date, style: .time)
                                        .font(AppearanceHelper.secondaryFont(for: textSize))
                                        .foregroundStyle(.secondary)

                                    Text(entry.category)
                                        .font(AppearanceHelper.secondaryFont(for: textSize))
                                        .foregroundStyle(.secondary)

                                    Text(entry.content)
                                        .font(AppearanceHelper.bodyFont(for: textSize))
                                        .lineLimit(2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .contextMenu {
                            ShareLink(item: shareText(for: entry)) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }

                            Button {
                                toggleFavorite(entry)
                            } label: {
                                Label(
                                    entry.isFavorite ? "Remove from favorites" : "Add to favorites",
                                    systemImage: entry.isFavorite ? "star.slash" : "star"
                                )
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                toggleFavorite(entry)
                            } label: {
                                Label(
                                    entry.isFavorite ? "Unfavorite" : "Favorite",
                                    systemImage: "star"
                                )
                            }

                            Button(role: .destructive) {
                                if let index = filteredEntries.firstIndex(where: { $0.id == entry.id }) {
                                    deleteEntries(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteEntries)
                }
            }
            .navigationTitle("Mindful Moments")
            .searchable(text: $viewModel.searchText,
                        placement: .automatic,
                        prompt: "Search reflections")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All moods") {
                            viewModel.selectedMoodFilter = nil
                        }

                        Divider()

                        ForEach(viewModel.moodFilterOptions, id: \.self) { mood in
                            Button {
                                viewModel.selectedMoodFilter = mood
                            } label: {
                                HStack {
                                    Text(mood)
                                        .font(.title2)
                                    if viewModel.selectedMoodFilter == mood {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        if let mood = viewModel.selectedMoodFilter {
                            HStack(spacing: 4) {
                                Text(mood)
                                Image(systemName: "line.3.horizontal.decrease.circle")
                            }
                        } else {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {

                    // Category filter menu
                    Menu {
                        Button("All categories") {
                            viewModel.selectedCategoryFilter = nil
                        }

                        Divider()

                        ForEach(viewModel.categoryFilterOptions, id: \.self) { cat in
                            Button {
                                viewModel.selectedCategoryFilter = cat
                            } label: {
                                HStack {
                                    Text(cat)
                                    if viewModel.selectedCategoryFilter == cat {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "tag")
                    }
                    .help("Filter by category")

                    Button {
                        viewModel.showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                    }
                    .help("Show favorites only")

                    // Clear all filters button
                    Button {
                        viewModel.clearAllFilters()
                    } label: {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                    }
                    .help("Clear search, mood, date, category, and favorites filters")
                    .disabled(!viewModel.hasActiveFilters)

                    // Add entry button
                    Button {
                        entryToEdit = nil
                        isPresentingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Add entry")
                }
            }
            .sheet(isPresented: $isPresentingAddSheet) {
                NavigationStack {
                    EntryFormView(entryToEdit: entryToEdit)
                }
            }
            .onChange(of: entryToEdit) { _, newValue in
                if newValue != nil {
                    isPresentingAddSheet = true
                }
            }
        }
    }


    private func deleteEntries(at offsets: IndexSet) {
        viewModel.deleteEntries(at: offsets, from: entries, context: context)
    }


    private func toggleFavorite(_ entry: Entry) {
        entry.isFavorite.toggle()
        do {
            try context.save()
        } catch {
            print("Failed to update favorite: \(error)")
        }
    }


    private func shareText(for entry: Entry) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let dateString = formatter.string(from: entry.date)

        return """
        Mindful Moments — \(dateString)
        Mood: \(entry.mood)
        Category: \(entry.category)

        \(entry.content)
        """
    }


    private func moodScore(for mood: String) -> Int? {
        switch mood {
        case "😭": return 1
        case "☹️": return 2
        case "😐": return 3
        case "😊": return 4
        case "🤩": return 5
        default: return nil
        }
    }

    private func emoji(forScore score: Int) -> String? {
        switch score {
        case 1: return "😭"
        case 2: return "☹️"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "🤩"
        default: return nil
        }
    }

    private func streakStats() -> (current: Int, longest: Int) {
        guard !entries.isEmpty else { return (0, 0) }

        let calendar = Calendar.current
        let days = Array(
            Set(entries.map { calendar.startOfDay(for: $0.date) })
        ).sorted()

        guard !days.isEmpty else { return (0, 0) }

        var longest = 1
        var currentRun = 1

        for i in 1..<days.count {
            let diff = calendar.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            if diff == 1 {
                currentRun += 1
            } else {
                longest = max(longest, currentRun)
                currentRun = 1
            }
        }

        longest = max(longest, currentRun)
        let current = currentRun

        return (current, longest)
    }
}
