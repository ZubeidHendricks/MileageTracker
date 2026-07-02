import SwiftUI
import AppFactoryKit

// Mileage Tracker — payments via native StoreKit 2 (no third-party SDK).
private enum Product {
    static let yearly = "mileage_pro_yearly"
    static let weekly = "mileage_pro_weekly"
}

@MainActor
enum MileageTrackerFactory {
    static func make() -> AppFactory {
        let config = AppFactoryConfiguration(
            appName: "Mileage Tracker",
            purchaseProvider: StoreKit2PurchaseProvider(productIDs: [Product.yearly, Product.weekly]),
            onboarding: OnboardingConfiguration(
                slides: [
                    .init(systemImage: "car.fill",
                          title: "Track Every Mile",
                          message: "Start a trip and your miles are logged automatically by GPS — all on-device."),
                    .init(systemImage: "dollarsign.circle",
                          title: "Maximize Your Deduction",
                          message: "Tag trips Business or Personal and watch your IRS-rate deduction add up.")
                ],
                presentsPaywallOnFinish: true,
                accent: .blue
            ),
            paywall: PaywallConfiguration(
                headline: "Unlock Mileage Tracker Pro",
                subheadline: "Every mile counted, every deduction claimed.",
                benefits: [
                    .init(systemImage: "infinity", title: "Unlimited trips"),
                    .init(systemImage: "tablecells", title: "CSV export for taxes"),
                    .init(systemImage: "dollarsign.circle", title: "IRS-rate deduction totals"),
                    .init(systemImage: "nosign", title: "No ads")
                ],
                productIDs: [Product.yearly, Product.weekly],
                highlightedProductID: Product.yearly,
                ctaTitle: "Continue",
                dismissButtonDelay: 4,
                isDismissable: true,
                termsURL: URL(string: "https://zubeidhendricks.github.io/MileageTracker/terms.html"),
                privacyURL: URL(string: "https://zubeidhendricks.github.io/MileageTracker/privacy.html"),
                style: PaywallStyle(accent: .blue, heroSystemImage: "car.circle")
            )
        )
        return AppFactory(config)
    }
}

@main
struct MileageTrackerApp: App {
    @StateObject private var factory = MileageTrackerFactory.make()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .appFactoryRoot(factory)
                .tint(.blue)
        }
    }
}
