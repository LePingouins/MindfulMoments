import Foundation
import SwiftData
import Combine

@MainActor
class EntryFormViewModel: ObservableObject {
    @Published var date: Date
    @Published var mood: String
    @Published var content: String
    @Published var category: String

    let moodOptions = ["😭", "☹️", "😐", "😊", "🤩"]

    let categoryOptions = ["General", "School", "Work", "Friends", "Health", "Gratitude"]

    // Guided prompts
    let prompts: [String] = [
        "What went well today?",
        "What is one small thing you’re grateful for right now?",
        "Where in your body did you notice tension today?",
        "What is something you’d like to let go of?",
        "What gave you energy today?",
        "What is one kind thing you did for yourself or someone else?",
        "If today had a ‘headline’, what would it be?",
        "What did you learn about yourself today?",
        "What emotion showed up the most today?",
        "What would you like tomorrow-you to remember about today?"
    ]

    @Published var currentPrompt: String?

    private(set) var entryToEdit: Entry?

    init(entryToEdit: Entry? = nil) {
        self.entryToEdit = entryToEdit

        if let entry = entryToEdit {
            self.date = entry.date
            self.mood = entry.mood
            self.content = entry.content
            self.category = entry.category
            self.currentPrompt = nil
        } else {
            self.date = Date()
            self.mood = "😐"
            self.content = ""
            self.category = "General"
            self.currentPrompt = prompts.randomElement()
        }
    }

    var title: String {
        entryToEdit == nil ? "New Entry" : "Edit Entry"
    }

    var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }


    func pickRandomPrompt() {
        currentPrompt = prompts.randomElement()
    }

    func insertCurrentPromptIntoContent() {
        guard let prompt = currentPrompt else { return }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            content = prompt + "\n"
        } else if !trimmed.contains(prompt) {
            content += "\n\n" + prompt
        }
    }


    func save(using context: ModelContext) throws {
        if let entry = entryToEdit {
            entry.date = date
            entry.mood = mood
            entry.content = content
            entry.category = category
        } else {
            let newEntry = Entry(
                date: date,
                mood: mood,
                content: content,
                isFavorite: false,
                category: category
            )
            context.insert(newEntry)
        }

        try context.save()
    }
}
