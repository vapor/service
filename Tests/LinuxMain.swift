import XCTest
@testable import ServiceTests

XCTMain([
    testCase(ConfigTests.allTests),
    testCase(ServiceTests.allTests),
])
