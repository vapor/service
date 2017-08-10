import XCTest
@testable import Configs

class ConfigTests: XCTestCase {
    func testLoad() throws {
        let config = try Config(["foo": "bar"])
        print(config)
    }

    static let allTests = [
        ("testLoad", testLoad),
    ]
}
