import SwiftUI

struct OnboardingView: SwiftUI.View {
    /// Call this when user finishes onboarding.
    var onDone: () -> Void

    @SwiftUI.State private var pageIndex: Int = 0

    // Match your mockups
    private let bgOrange   = SwiftUI.Color(red: 1.00, green: 0.30, blue: 0.10)  // #FF4D1A-ish
    private let darkOrange = SwiftUI.Color(red: 0.36, green: 0.14, blue: 0.00)  // deep button color

    var body: some SwiftUI.View {
        SwiftUI.ZStack {
            // Full-screen orange gradient background on every page
            SwiftUI.LinearGradient(
                colors: [bgOrange, darkOrange],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            SwiftUI.GeometryReader { _ in
                SwiftUI.VStack(spacing: 0) {
                    // ---- MAIN CONTENT (Pages) ----
                    SwiftUI.TabView(selection: $pageIndex) {
                        OnbPage(textImage: "onb-txt-01", phoneImagePhone: "onb-ss-01", phoneImageiPad: "ipad-screen-01")
                            .tag(0 as Int)
                        OnbPage(textImage: "onb-txt-02", phoneImagePhone: "onb-ss-02", phoneImageiPad: "ipad-screen-02")
                            .tag(1 as Int)
                        OnbPage(textImage: "onb-txt-03", phoneImagePhone: "onb-ss-03", phoneImageiPad: "ipad-screen-03")
                            .tag(2 as Int)
                        OnbPage(textImage: "onb-txt-04", phoneImagePhone: "onb-ss-04", phoneImageiPad: "ipad-screen-04")
                            .tag(3 as Int)
                    }
                    .tabViewStyle(SwiftUI.PageTabViewStyle(indexDisplayMode: .never)) // hide default dots

                    // ---- GUTTER AREA (flexible) ----
                    // These two Spacers center the pagination dots BETWEEN the screenshot and the CTA,
                    // while minLength ensures the dots never touch either side.
                    SwiftUI.Spacer(minLength: 24) // ensure distance from the screenshot
                    PaginationDots(current: pageIndex, total: 4)
                        .padding(.horizontal, 24)
                        .frame(height: 20)
                        .accessibilityHidden(true)
                    SwiftUI.Spacer(minLength: 16) // ensure distance above the CTA

                    // ---- CTA BUTTON ----
                    SwiftUI.Button {
                        onDone()
                    } label: {
                        SwiftUI.ZStack {
                            SwiftUI.RoundedRectangle(cornerRadius: 12)
                                .fill(bgOrange)
                                .frame(height: 64)

                            // Your PNG overlaid as the button title
                            SwiftUI.Image("onb-cta")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 18)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24) // space above home indicator
                }
                .padding(.top, 8)
            }
        }
    }
}

// One page: PNG headline + device screenshot
private struct OnbPage: SwiftUI.View {
    let textImage: String
    let phoneImagePhone: String
    let phoneImageiPad: String

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some SwiftUI.View {
        let deviceImage = isPad ? phoneImageiPad : phoneImagePhone

        return SwiftUI.VStack(spacing: 24) {
            // Headline PNG (white/black artwork)
            SwiftUI.Image(textImage)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 24)
                .padding(.top, 8)

            // Device mock/screenshot (iPhone on phones, iPad on iPad)
            SwiftUI.Image(deviceImage)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 24)
                .shadow(color: .black.opacity(0.15), radius: 16, y: 8)

            SwiftUI.Spacer(minLength: 0)
        }
    }
}

// Custom pagination dots so we can control exact placement
private struct PaginationDots: SwiftUI.View {
    let current: Int
    let total: Int

    var body: some SwiftUI.View {
        SwiftUI.HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { idx in
                SwiftUI.Circle()
                    .fill(idx == current ? SwiftUI.Color.white : SwiftUI.Color.white.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: current)
            }
        }
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some SwiftUI.View {
        OnboardingView(onDone: {})
            .previewDevice("iPhone 15 Pro")
    }
}
