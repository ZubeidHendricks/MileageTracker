# MileageTracker

Generated from niche `mileage-tracker` (Finance, tier A, score 75).

**Utility:** Auto-log drives for tax/expense
**Primary ASO keyword:** `mileage tracker`
**Also target:** `mile log`, `gas mileage`, `tax mileage`, `drive log`
**Paywall hook:** Auto-tracking, IRS reports, unlimited trips

> Gig workers/self-employed; tax season spikes. Auto-detect drives is the hook.

## Build it

```bash
brew install xcodegen        # once
cd MileageTracker
xcodegen generate
open MileageTracker.xcodeproj
```

The app runs immediately on a MockPurchaseProvider (real paywall UI, fake
purchases). To go live:

1. Replace `revenueCatKey` in `Sources/App.swift` with your RevenueCat key.
2. In App Store Connect create products `mileage-tracker_yearly` and `mileage-tracker_weekly`,
   map them into a RevenueCat offering, entitlement id `premium`.
3. Build the real feature in `Sources/ContentView.swift`.
4. **Guideline 4.3:** make the function, UI, screenshots and keywords genuinely
   distinct from any sibling app. Re-niche, never reskin.

Bundle id: `com.zubeid.mileagetracker`

## Ship to TestFlight

This app ships with a Fastlane lane + GitHub Actions workflow. One-time account
setup (API key, signing) is documented in the kit's `Tools/appgen/DEPLOYMENT.md`.
Once your GitHub secrets are set, trigger the **TestFlight** workflow (or push a
`v*` tag), or run locally:

```bash
bundle install
bundle exec fastlane beta
```
