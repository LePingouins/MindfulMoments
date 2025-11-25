import SwiftUI

enum AppTextSize: Int {
    case small = 0
    case normal = 1
    case large = 2
}

struct AppearanceHelper {

    static func accentColor(for index: Int) -> Color {
        switch index {
        case 1: return .purple
        case 2: return .green
        case 3: return .orange
        case 4: return .pink
        default: return .blue
        }
    }

    static func textSize(from index: Int) -> AppTextSize {
        AppTextSize(rawValue: index) ?? .normal
    }

    static func bodyFont(for textSize: AppTextSize) -> Font {
        switch textSize {
        case .small: return .subheadline
        case .normal: return .body
        case .large: return .title3
        }
    }

    static func headlineFont(for textSize: AppTextSize) -> Font {
        switch textSize {
        case .small: return .footnote
        case .normal: return .headline
        case .large: return .title2
        }
    }

    static func secondaryFont(for textSize: AppTextSize) -> Font {
        switch textSize {
        case .small: return .caption
        case .normal: return .subheadline
        case .large: return .body
        }
    }

    static func color(forMood mood: String) -> Color {
        switch mood {
        case "😭": return .red
        case "☹️": return .orange
        case "😐": return .gray
        case "😊": return .green
        case "🤩": return .purple
        default: return .blue
        }
    }
}
