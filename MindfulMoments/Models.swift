import Foundation
import SwiftData

@Model
class Entry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var mood: String
    var content: String
    var isFavorite: Bool
    var category: String   

    init(
        id: UUID = UUID(),
        date: Date = .now,
        mood: String = "😐",
        content: String,
        isFavorite: Bool = false,
        category: String = "General"   // default
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.content = content
        self.isFavorite = isFavorite
        self.category = category
    }
}
