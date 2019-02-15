import ServiceKit
import XCTest

final class EnvironmentTests: XCTestCase {
    func testDynamicAccess() {
        Environment.process.DATABASE_PORT = 3306
        XCTAssertEqual(Environment.process.DATABASE_PORT, 3306)
        
        Environment.process.DATABASE_PORT = nil
    }
    
    static let allTests = [
        ("testDynamicAccess", testDynamicAccess)
    ]
}
