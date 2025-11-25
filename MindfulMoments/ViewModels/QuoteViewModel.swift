import Foundation
import Combine

struct QuoteResponse: Decodable {
    let content: String
    let author: String
}

@MainActor
class QuoteViewModel: ObservableObject {
    @Published var quoteText: String = ""
    @Published var quoteAuthor: String = ""
    @Published var isLoading: Bool = false

    private let endpoint = URL(string: "https://api.quotable.io/random")!

    private let fallbackQuotes: [(String, String)] = [
        ("Be where you are; otherwise you will miss your life.", "Thich Nhat Hanh"),
        ("You are allowed to be a work in progress and a masterpiece at the same time.", "Unknown"),
        ("Small, consistent steps matter more than big, perfect ones.", "Mindful Moments"),
        ("You don’t have to fix the feeling; you just have to notice it.", "Unknown")
    ]

    func fetchQuoteIfNeeded() {
        if quoteText.isEmpty {
            fetchQuote()
        }
    }

    func fetchQuote() {
        isLoading = true

        let request = URLRequest(url: endpoint)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    print("Quote fetch error: \(error)")
                    self.useFallbackQuote()
                    return
                }

                guard let data = data else {
                    self.useFallbackQuote()
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(QuoteResponse.self, from: data)
                    self.quoteText = decoded.content
                    self.quoteAuthor = decoded.author
                } catch {
                    print("Quote decode error: \(error)")
                    self.useFallbackQuote()
                }
            }
        }.resume()
    }

    private func useFallbackQuote() {
        if let random = fallbackQuotes.randomElement() {
            quoteText = random.0
            quoteAuthor = random.1
        } else {
            quoteText = "Take a moment to breathe and notice how you feel."
            quoteAuthor = "Mindful Moments"
        }
    }
}
