import XCTest
import Service

class ConfigTests: XCTestCase {
    func testLoad() throws {
        let config = try Config(["foo": "bar"])
        print(config)
    }

    static let allTests = [
        ("testLoad", testLoad),
    ]
}
