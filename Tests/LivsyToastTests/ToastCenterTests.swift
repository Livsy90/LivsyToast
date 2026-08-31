import XCTest
@testable import LivsyToast

@MainActor
final class ToastCenterTests: XCTestCase {
    func testPausedDismissalCanBeResumed() async {
        let center = ToastCenter()
        let id = center.show("Toast", duration: 0.02)

        center.pauseDismissal(for: id)
        try? await Task.sleep(nanoseconds: 60_000_000)
        XCTAssertEqual(center.entries.map(\.id), [id])

        center.resumeDismissal(for: id)
        try? await Task.sleep(nanoseconds: 60_000_000)
        XCTAssertTrue(center.entries.isEmpty)
    }

    func testOnDismissRunsAfterRemovalAnimation() async {
        let center = ToastCenter()
        var didDismiss = false
        let id = center.show("Toast", duration: nil) {
            didDismiss = true
        }

        center.dismiss(id)
        XCTAssertTrue(center.entries.isEmpty)

        try? await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertFalse(didDismiss)

        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(didDismiss)
    }
}
