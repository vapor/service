@testable import Service
import XCTest

class EnvironmentTests: XCTestCase {    
    func testDecoder() throws {
        struct Test: EnvironmentConfig {
            let string: String
            let float: Float
            let double: Double
            let int: Int
            let uint: UInt
            let bool: Bool
        }
        
        let data = """
        # This is a test comment
        string="Coding Test" # Another Comment
        float=0.3
        double=0.2
        int=1
        uint=12
        bool=true
        """.data(using: .utf8)!
        
        let decoder = EnvironmentDecoder()
        let object = try decoder.decode(Test.self, from: data)
        print(object)
        XCTAssertEqual(object.string, "Coding Test")
        XCTAssertEqual(object.float, 0.3)
        XCTAssertEqual(object.double, 0.2)
        XCTAssertEqual(object.int, 1)
        XCTAssertEqual(object.uint, 12)
        XCTAssertEqual(object.bool, true)
    }
}
