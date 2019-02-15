import XCTest
@testable import ServiceKitTests

XCTMain([
    testCase(ServiceKitTests.allTests),
    testCase(EnvironmentTests.allTests)
])
