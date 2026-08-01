import XCTest
// TripTracker.swift compiled into this test target.

final class MileageTests: XCTestCase {
    func testBusinessDeductionUsesIRSRate() {
        let t = Trip(date: Date(), miles: 100, purpose: "Business")
        XCTAssertEqual(t.deduction, 100 * Trip.irsRate, accuracy: 0.001)
    }

    func testPersonalHasNoDeduction() {
        let t = Trip(date: Date(), miles: 100, purpose: "Personal")
        XCTAssertEqual(t.deduction, 0)
    }

    func testCSVHasHeaderAndRow() {
        let store = TripStore()
        let csv = store.csv()
        XCTAssertTrue(csv.hasPrefix("Date,Purpose,Miles,Deduction"))
    }

    // Competence-feedback logic (see ../PLAYBOOK.md).
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d))!
    }

    func testYearDeductionOnlyCountsBusinessTripsInThatYear() {
        let trips = [Trip(date: date(2026, 3, 1), miles: 100, purpose: "Business"),
                     Trip(date: date(2025, 3, 1), miles: 50, purpose: "Business"),
                     Trip(date: date(2026, 4, 1), miles: 10, purpose: "Personal")]
        XCTAssertEqual(TripStore.deduction(in: trips, year: 2026), 100 * Trip.irsRate, accuracy: 0.001)
    }

    func testBestMonthDeductionPicksTopMonth() {
        let trips = [Trip(date: date(2026, 1, 5), miles: 10, purpose: "Business"),
                     Trip(date: date(2026, 2, 5), miles: 30, purpose: "Business"),
                     Trip(date: date(2026, 2, 20), miles: 20, purpose: "Business")]
        XCTAssertEqual(TripStore.bestMonthDeduction(in: trips), 50 * Trip.irsRate, accuracy: 0.001)
    }

    func testBestMonthDeductionEmptyIsZero() {
        XCTAssertEqual(TripStore.bestMonthDeduction(in: []), 0)
    }
}
