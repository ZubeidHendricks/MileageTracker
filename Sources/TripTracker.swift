import Foundation
import CoreLocation
import Combine

struct Trip: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var miles: Double
    var purpose: String           // "Business" / "Personal"
    /// 2024 IRS business standard mileage rate.
    static let irsRate = 0.67
    var deduction: Double { purpose == "Business" ? miles * Trip.irsRate : 0 }
}

/// Live GPS trip tracker. Accumulates distance from location updates while a trip
/// is active. Fully on-device.
final class TripTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isTracking = false
    @Published var currentMiles = 0.0
    @Published var authorized = false

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.activityType = .automotiveNavigation
    }

    func requestAuth() { manager.requestWhenInUseAuthorization() }

    func start() {
        currentMiles = 0; lastLocation = nil
        isTracking = true
        manager.startUpdatingLocation()
    }

    /// Stop and return the finished trip's mileage.
    func stop() -> Double {
        manager.stopUpdatingLocation()
        isTracking = false
        return currentMiles
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorized = manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }
        for loc in locations where loc.horizontalAccuracy >= 0 && loc.horizontalAccuracy < 50 {
            if let last = lastLocation {
                let meters = loc.distance(from: last)
                if meters > 0 { currentMiles += meters / 1609.344 }
            }
            lastLocation = loc
        }
    }
}

/// Persisted trip log. Free tier caps total trips; Pro unlimited + CSV export.
final class TripStore: ObservableObject {
    @Published private(set) var trips: [Trip] = []
    static let freeLimit = 5
    private let key = "trips.v1"

    init() { load() }

    var totalMiles: Double { trips.reduce(0) { $0 + $1.miles } }
    var totalDeduction: Double { trips.reduce(0) { $0 + $1.deduction } }
    var sorted: [Trip] { trips.sorted { $0.date > $1.date } }

    // Competence feedback per ../PLAYBOOK.md: money recovered is the score —
    // evidence of real trips logged, never app opens. Static so tests can drive
    // the logic with fixed trip arrays.
    static func deduction(in trips: [Trip], year: Int, calendar: Calendar = .current) -> Double {
        trips.filter { calendar.component(.year, from: $0.date) == year }.reduce(0) { $0 + $1.deduction }
    }
    /// Best calendar month's deduction ever — a personal record.
    static func bestMonthDeduction(in trips: [Trip], calendar: Calendar = .current) -> Double {
        Dictionary(grouping: trips) { t -> String in
            let c = calendar.dateComponents([.year, .month], from: t.date)
            return "\(c.year ?? 0)-\(c.month ?? 0)"
        }
        .values.map { $0.reduce(0) { $0 + $1.deduction } }.max() ?? 0
    }
    var thisYearDeduction: Double { Self.deduction(in: trips, year: Calendar.current.component(.year, from: Date())) }
    var bestMonthDeduction: Double { Self.bestMonthDeduction(in: trips) }
    func reachedFreeLimit(isSubscribed: Bool) -> Bool { !isSubscribed && trips.count >= Self.freeLimit }

    func add(_ t: Trip) { trips.append(t); save() }
    func remove(_ t: Trip) { trips.removeAll { $0.id == t.id }; save() }

    func csv() -> String {
        var out = "Date,Purpose,Miles,Deduction\n"
        let df = ISO8601DateFormatter()
        for t in sorted { out += "\(df.string(from: t.date)),\(t.purpose),\(String(format: "%.2f", t.miles)),\(String(format: "%.2f", t.deduction))\n" }
        return out
    }

    private func load() {
        guard let d = UserDefaults.standard.data(forKey: key), let v = try? JSONDecoder().decode([Trip].self, from: d) else { return }
        trips = v
    }
    private func save() { if let d = try? JSONEncoder().encode(trips) { UserDefaults.standard.set(d, forKey: key) } }
}
