import SwiftUI

struct OnboardingPage {
    let systemImage: String
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var currentPage: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "sparkles",
            title: "Welcome to Mindful Moments",
            subtitle: "Capture how you feel, one small reflection at a time."
        ),
        OnboardingPage(
            systemImage: "chart.bar.xaxis",
            title: "See your patterns",
            subtitle: "Track moods, streaks, and trends to understand your emotional rhythm."
        ),
        OnboardingPage(
            systemImage: "lock.circle",
            title: "Your space, your privacy",
            subtitle: "Protect your journal with Face ID / Touch ID and keep everything just for you."
        )
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 0)

                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        let page = pages[index]

                        VStack(spacing: 24) {
                            Image(systemName: page.systemImage)
                                .font(.system(size: 64))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Color.accentColor)

                            VStack(spacing: 8) {
                                Text(page.title)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)

                                Text(page.subtitle)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal, 32)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .automatic))
                .frame(maxHeight: 380)

                Spacer()

                // Bottom controls
                HStack {
                    Button("Skip") {
                        onFinish()
                    }
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            onFinish()
                        }
                    }) {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get started")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}
