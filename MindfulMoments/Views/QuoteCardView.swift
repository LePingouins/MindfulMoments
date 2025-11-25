import SwiftUI

struct QuoteCardView: View {
    @StateObject private var viewModel = QuoteViewModel()

    @AppStorage("mm_textSizePreference") private var textSizePreference: Int = 1

    private var textSize: AppTextSize {
        AppearanceHelper.textSize(from: textSizePreference)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.isLoading && viewModel.quoteText.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if !viewModel.quoteText.isEmpty {
                Text("“\(viewModel.quoteText)”")
                    .font(AppearanceHelper.bodyFont(for: textSize))

                if !viewModel.quoteAuthor.isEmpty {
                    Text("— \(viewModel.quoteAuthor)")
                        .font(AppearanceHelper.secondaryFont(for: textSize))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Take a moment to breathe and notice how you feel.")
                    .font(AppearanceHelper.bodyFont(for: textSize))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            viewModel.fetchQuoteIfNeeded()
        }
    }
}
