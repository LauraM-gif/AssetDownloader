import XCTest
@testable import AVAssetDownloader

final class AVAssetDownloaderTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(AVAssetDownloader().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
