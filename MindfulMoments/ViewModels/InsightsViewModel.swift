import Foundation
import SwiftData
import Combine

struct MoodStat: Identifiable {
    let id = UUID()
    let mood: String
    let count: Int
}

struct DailyMoodStat: Identifiable {
    let id = UUID()
    let date: Date
    let averageScore: Double
}

struct CategoryStat: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

@MainActor
class InsightsViewModel: ObservableObject {


    func moodStats(from entries: [Entry]) -> [MoodStat] {
        guard !entries.isEmpty else { return [] }

        var counts: [String: Int] = [:]
        for entry in entries {
            counts[entry.mood, default: 0] += 1
        }

        return counts.map { MoodStat(mood: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }


    func categoryStats(from entries: [Entry]) -> [CategoryStat] {
        guard !entries.isEmpty else { return [] }

        var counts: [String: Int] = [:]
        for entry in entries {
            let cat = entry.category.isEmpty ? "General" : entry.category
            counts[cat, default: 0] += 1
        }

        return counts.map { CategoryStat(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }


    func totalEntries(from entries: [Entry]) -> Int {
        entries.count
    }

    func lastEntryDateText(from entries: [Entry]) -> String {
        guard let last = entries.last else { return "No entries yet" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: last.date)
    }


    func streakStats(from entries: [Entry]) -> (current: Int, longest: Int) {
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


    func weeklyMoodStats(from entries: [Entry]) -> [DailyMoodStat] {
        guard !entries.isEmpty else { return [] }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let last7 = entries.filter { entry in
            let day = calendar.startOfDay(for: entry.date)
            guard let diff = calendar.dateComponents([.day], from: day, to: today).day else { return false }
            return diff >= 0 && diff < 7
        }

        guard !last7.isEmpty else { return [] }

        var grouped: [Date: [Int]] = [:]   // date -> mood scores

        for entry in last7 {
            let day = calendar.startOfDay(for: entry.date)
            if let score = moodScore(for: entry.mood) {
                grouped[day, default: []].append(score)
            }
        }

        let stats = grouped.map { (date, scores) -> DailyMoodStat in
            let avg = Double(scores.reduce(0, +)) / Double(scores.count)
            return DailyMoodStat(date: date, averageScore: avg)
        }

        return stats.sorted { $0.date < $1.date }
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
}
