import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class EntryListViewModel: ObservableObject {
    // UI state
    @Published var searchText: String = ""
    @Published var selectedMoodFilter: String? = nil
    @Published var selectedDate: Date? = nil
    @Published var showFavoritesOnly: Bool = false
    @Published var selectedCategoryFilter: String? = nil

    // Same moods as in EntryFormView
    let moodFilterOptions = ["😭", "☹️", "😐", "😊", "🤩"]

    // Categories used in filters
    let categoryFilterOptions = ["General", "School", "Work", "Friends", "Health", "Gratitude"]


    func filteredEntries(from entries: [Entry]) -> [Entry] {
        entries.filter { entry in
            // Text search
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch: Bool
            if trimmed.isEmpty {
                matchesSearch = true
            } else {
                let query = trimmed.lowercased()
                let haystack = (entry.content + " " + entry.mood + " " + entry.category).lowercased()
                matchesSearch = haystack.contains(query)
            }

            // Mood filter
            let matchesMood: Bool
            if let mood = selectedMoodFilter {
                matchesMood = entry.mood == mood
            } else {
                matchesMood = true
            }

            // Date filter
            let matchesDate: Bool
            if let filterDate = selectedDate {
                matchesDate = Calendar.current.isDate(entry.date, inSameDayAs: filterDate)
            } else {
                matchesDate = true
            }

            // Favorites filter
            let matchesFavorite: Bool
            if showFavoritesOnly {
                matchesFavorite = entry.isFavorite
            } else {
                matchesFavorite = true
            }

            // Category filter
            let matchesCategory: Bool
            if let cat = selectedCategoryFilter {
                matchesCategory = entry.category == cat
            } else {
                matchesCategory = true
            }

            return matchesSearch && matchesMood && matchesDate && matchesFavorite && matchesCategory
        }
    }


    func deleteEntries(at offsets: IndexSet,
                       from entries: [Entry],
                       context: ModelContext) {
        let current = filteredEntries(from: entries)

        for index in offsets {
            let entry = current[index]
            context.delete(entry)
        }

        do {
            try context.save()
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }


    func clearAllFilters() {
        searchText = ""
        selectedMoodFilter = nil
        selectedDate = nil
        showFavoritesOnly = false
        selectedCategoryFilter = nil  
    }

    var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedMoodFilter != nil ||
        selectedDate != nil ||
        showFavoritesOnly ||
        selectedCategoryFilter != nil
    }
}
