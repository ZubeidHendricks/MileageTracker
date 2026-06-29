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
}
