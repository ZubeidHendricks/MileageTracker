import SwiftUI
import AppFactoryKit

// Mileage Tracker — start a trip and it logs miles by GPS; tag Business/Personal
// for an IRS deduction estimate. Free tier caps trips; Pro is unlimited + CSV.
struct ContentView: View {
    @EnvironmentObject private var factory: AppFactory
    @StateObject private var tracker = TripTracker()
    @StateObject private var store = TripStore()
    @State private var purpose = "Business"
    @State private var shareItem: ShareItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    liveCard
                    totals
                    list
                }
                .padding(20)
            }
            .navigationTitle("Mileage")
            .toolbar { if !store.trips.isEmpty { Button { exportCSV() } label: { Image(systemName: "square.and.arrow.up") } } }
        }
        .task { tracker.requestAuth() }
        .sheet(item: $shareItem) { ActivityView(items: $0.items) }
    }

    private var liveCard: some View {
        VStack(spacing: 16) {
            Text(String(format: "%.2f mi", tracker.isTracking ? tracker.currentMiles : 0))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(tracker.isTracking ? .blue : .secondary)
            Picker("Purpose", selection: $purpose) { Text("Business").tag("Business"); Text("Personal").tag("Personal") }
                .pickerStyle(.segmented).disabled(tracker.isTracking)
            Button { toggle() } label: {
                Label(tracker.isTracking ? "Stop & Save Trip" : "Start Trip",
                      systemImage: tracker.isTracking ? "stop.circle.fill" : "play.circle.fill")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent).tint(tracker.isTracking ? .red : .blue)
            .disabled(!tracker.authorized)
            if !tracker.authorized { Text("Allow location access to track trips.").font(.caption).foregroundStyle(.secondary) }
        }
        .padding(20).background(RoundedRectangle(cornerRadius: 18).fill(.blue.opacity(0.10)))
    }

    private var totals: some View {
        HStack {
            stat("Total Miles", String(format: "%.1f", store.totalMiles))
            stat("Deduction", store.totalDeduction.formatted(.currency(code: "USD")))
        }
    }
    private func stat(_ t: String, _ v: String) -> some View {
        VStack(spacing: 4) { Text(v).font(.title3.bold()); Text(t).font(.caption).foregroundStyle(.secondary) }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary.opacity(0.5)))
    }

    private var list: some View {
        VStack(spacing: 8) {
            ForEach(store.sorted) { t in
                HStack {
                    VStack(alignment: .leading) { Text(t.purpose); Text(t.date, style: .date).font(.caption).foregroundStyle(.secondary) }
                    Spacer()
                    Text(String(format: "%.1f mi", t.miles))
                    Button { store.remove(t) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func toggle() {
        if tracker.isTracking {
            let miles = tracker.stop()
            if store.reachedFreeLimit(isSubscribed: factory.subscriptions.isSubscribed) {
                factory.presentPaywall(placement: "trip_limit")
            } else if miles > 0.01 {
                store.add(Trip(date: Date(), miles: miles, purpose: purpose))
            }
        } else {
            tracker.start()
        }
    }

    private func exportCSV() {
        factory.requirePremium(feature: "export_csv") {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("mileage.csv")
            try? store.csv().write(to: url, atomically: true, encoding: .utf8)
            shareItem = ShareItem(items: [url])
        }
    }
}

struct ShareItem: Identifiable { let id = UUID(); let items: [Any] }

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
