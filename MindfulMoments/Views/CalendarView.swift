import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.date, order: .forward) private var entries: [Entry]

    @AppStorage("mm_textSizePreference") private var textSizePreference: Int = 1

    @State private var monthAnchor: Date = Date()
    @State private var selectedDate: Date? = Date()
    @State private var entryToEdit: Entry?
    @State private var isPresentingSheet = false

    private let calendar = Calendar.current

    private var textSize: AppTextSize {
        AppearanceHelper.textSize(from: textSizePreference)
    }

    private var monthStart: Date {
        let comps = calendar.dateComponents([.year, .month], from: monthAnchor)
        return calendar.date(from: comps) ?? Date()
    }

    private var monthDays: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    private var entryDays: Set<Date> {
        Set(entries.map { calendar.startOfDay(for: $0.date) })
    }

    private var entriesForSelectedDay: [Entry] {
        guard let selected = selectedDate else { return [] }
        return entries.filter { calendar.isDate($0.date, inSameDayAs: selected) }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: monthStart)
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        if first > 0 {
            let head = symbols[first...]
            let tail = symbols[..<first]
            return Array(head + tail)
        } else {
            return symbols
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                HStack {
                    Button {
                        withAnimation {
                            changeMonth(by: -1)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(monthTitle)
                        .font(AppearanceHelper.headlineFont(for: textSize))

                    Spacer()

                    Button {
                        withAnimation {
                            changeMonth(by: 1)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

                HStack {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol.uppercased())
                            .font(AppearanceHelper.secondaryFont(for: textSize))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)

                // Days grid
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(monthDays, id: \.self) { day in
                        let dayNumber = calendar.component(.day, from: day)
                        let isToday = calendar.isDateInToday(day)
                        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false
                        let hasEntries = entryDays.contains(calendar.startOfDay(for: day))

                        Button {
                            selectedDate = day
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(dayNumber)")
                                    .font(AppearanceHelper.bodyFont(for: textSize))
                                    .frame(maxWidth: .infinity)

                                Circle()
                                    .fill(hasEntries ? Color.accentColor : Color.clear)
                                    .frame(width: 6, height: 6)
                            }
                            .padding(6)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(
                                Group {
                                    if isSelected {
                                        Color.accentColor.opacity(0.2)
                                    } else if isToday {
                                        Color.accentColor.opacity(0.08)
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)

                Divider()
                    .padding(.horizontal)

                // Entries for selected day
                VStack(alignment: .leading, spacing: 8) {
                    if let selected = selectedDate {
                        Text("Entries on \(formattedDay(selected))")
                            .font(AppearanceHelper.headlineFont(for: textSize))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if entriesForSelectedDay.isEmpty {
                        Text("No entries for this day.")
                            .font(AppearanceHelper.secondaryFont(for: textSize))
                            .foregroundStyle(.secondary)
                    } else {
                        List {
                            ForEach(entriesForSelectedDay) { entry in
                                Button {
                                    entryToEdit = entry
                                } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        Text(entry.mood)
                                            .font(.largeTitle)

                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(entry.date, style: .time)
                                                    .font(AppearanceHelper.secondaryFont(for: textSize))

                                                if entry.isFavorite {
                                                    Image(systemName: "star.fill")
                                                        .foregroundStyle(.yellow)
                                                        .imageScale(.small)
                                                }
                                            }

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
                            }
                        }
                        .listStyle(.plain)
                        .frame(maxHeight: 280)
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 0)
            }
            .navigationTitle("Calendar")
            .sheet(item: $entryToEdit) { entry in
                NavigationStack {
                    EntryFormView(entryToEdit: entry)
                }
            }
        }
    }


    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: monthAnchor) {
            monthAnchor = newDate

            if let selected = selectedDate,
               !calendar.isDate(selected, equalTo: monthStart, toGranularity: .month) {
                selectedDate = monthStart
            }
        }
    }

    private func formattedDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}
