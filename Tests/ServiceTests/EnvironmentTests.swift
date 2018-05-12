@testable import Service
import XCTest

class EnvironmentTests: XCTestCase {
    let env = Environment(name: "dotenv", isRelease: false)
    
    func testMultipleLines() throws {
        let parsedData = self.env.parse(with: """
            FOO=someValue
            BAR=theBarValue
            CAR=theCarValue
        """)
        XCTAssertEqual(parsedData["FOO"], "someValue")
        XCTAssertEqual(parsedData["BAR"], "theBarValue")
        XCTAssertEqual(parsedData["CAR"], "theCarValue")
    }
    
    func testUnquotedValue() throws {
        let parsedData = self.env.parse(with: """
            FOO=someValue
        """)
        XCTAssertEqual(parsedData["FOO"], "someValue")
    }
    
    func testUnquotedWhitespaceSeparatedValue() throws {
        let parsedData = self.env.parse(with: """
            FOO=some crazy phrase
        """)
        XCTAssertEqual(parsedData["FOO"], "some")
    }
    
    func testQuotedValue() throws {
        let parsedData = self.env.parse(with: """
            FOO="someValue"
        """)
        XCTAssertEqual(parsedData["FOO"], "someValue")
    }
    
    func testQuotedWhitespaceSeparatedValue() throws {
        let parsedData = self.env.parse(with: """
            FOO="some crazy phrase"
        """)
        XCTAssertEqual(parsedData["FOO"], "some crazy phrase")
    }
    
    func testInlineComment() throws {
        let parsedData = self.env.parse(with: """
            FOO=someValueWithAn # Inline Comment
        """)
        XCTAssertEqual(parsedData["FOO"], "someValueWithAn")
    }
    
    func testQuotedValueWithComment() throws {
        let parsedData = self.env.parse(with: """
            FOO="some Value With An" # Inline Comment
        """)
        XCTAssertEqual(parsedData["FOO"], "some Value With An")
    }
    
    func testValueWithSymbols() throws {
        let parsedData = self.env.parse(with: """
            FOO=a!b@c#d$e%f^g&h*j(k)l{m}.,'-+|
        """)
        XCTAssertEqual(parsedData["FOO"], "a!b@c#d$e%f^g&h*j(k)l{m}.,'-+|")
        
    }
    
    func test1PasswordGeneratedPasswordWith10Symbols() throws {
        let parsedData = self.env.parse(with: """
            FOO=6#}U2/Ri8#f@AaDJ,VYxDG(?&v+8
        """)
        XCTAssertEqual(parsedData["FOO"], "6#}U2/Ri8#f@AaDJ,VYxDG(?&v+8")
    }
    
    func testEscapedDoubleQuote() throws {
        let parsedData = self.env.parse(with: """
            FOO="some Value \" With An" # Inline Comment
        """)
        XCTAssertEqual(parsedData["FOO"], "some Value \" With An")
    }
    
    func testPostgreSQLUrl() throws {
        let parsedData = self.env.parse(with: """
            DATABSE_URL=psql://vapor@localhost:5432/vapor-test
        """)
        XCTAssertEqual(parsedData["DATABSE_URL"], "psql://vapor@localhost:5432/vapor-test")
    }
}
