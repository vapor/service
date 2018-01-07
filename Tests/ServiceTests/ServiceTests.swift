import Async
import Dispatch
import Service
import XCTest

class ServiceTests: XCTestCase {
    func testHappyPath() throws {
        let config = Config()
        var services = Services()
        services.register(PrintLog.self)

        let container = BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DispatchEventLoop(label: "unit-test")
        )
        let log = try container.make(Log.self, for: ServiceTests.self)
        XCTAssert(log is PrintLog)
    }

    func testMultiple() throws {
        var config = Config()
        config.prefer(PrintLog.self, for: Log.self)

        var services = Services()
        services.register(PrintLog.self)
        services.register(AllCapsLog.self)

        let container = BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DispatchEventLoop(label: "unit-test")
        )
        let log = try container.make(Log.self, for: ServiceTests.self)
        XCTAssert(log is PrintLog)
    }

    func testTagged() throws {
        var config = Config()
        config.prefer(PrintLog.self, tagged: "foo", for: Log.self)

        var services = Services()
        services.register(PrintLog.self)
        services.register(AllCapsLog.self)

        let foo = PrintLog()
        services.use(foo, as: Log.self, tag: "foo")

        let container = BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DispatchEventLoop(label: "unit-test")
        )
        let log = try! container.make(Log.self, for: ServiceTests.self)
        XCTAssert(log is PrintLog)
    }
    
    func testTagDisambiguation() throws {
        var config = Config()
        config.prefer(ConfigurableLog.self, tagged: "foo1", for: Log.self)
        
        var services = Services()
        services.register(Log.self, tag: "foo1") { _ -> ConfigurableLog in ConfigurableLog(config: "foo1") }
        services.register(Log.self, tag: "foo2") { _ -> ConfigurableLog in ConfigurableLog(config: "foo2") }
        
        let container = BasicContainer(
        	config: config,
         	environment: .production,
            services: services,
            on: DispatchEventLoop(label: "unit-test")
        )
        let log = try container.make(Log.self, for: ServiceTests.self)
        
        XCTAssertEqual((log as? ConfigurableLog)?.myConfig, "foo1")
    }

    func testClient() throws {
        var config = Config()
        config.prefer(PrintLog.self, for: Log.self, neededBy: ServiceTests.self)

        var services = Services()
        services.register(PrintLog.self)
        services.register(AllCapsLog.self)

        let container = BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DispatchEventLoop(label: "unit-test")
        )
        let log = try! container.make(Log.self, for: ServiceTests.self)
        XCTAssert(log is PrintLog)
    }

    func testSpecific() throws {
        let config = Config()
        var services = Services()
        services.register(PrintLog.self)
        services.register(AllCapsLog.self)

        let container = BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DispatchEventLoop(label: "unit-test")
        )
        let log = try container.make(AllCapsLog.self, for: ServiceTests.self)
        XCTAssert(type(of: log) == AllCapsLog.self)
    }

    func testProvider() throws {
        let config = Config()
        var services = Services()
        try services.register(AllCapsProvider())

        let container = BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DispatchEventLoop(label: "unit-test")
        )
        let log = try container.make(AllCapsLog.self, for: ServiceTests.self)
        XCTAssert(type(of: log) == AllCapsLog.self)
    }

    func testRequire() throws {
        var config = Config()
        config.require(PrintLog.self, for: Log.self)

        var services = Services()
        services.register(AllCapsLog.self)

        let container = BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DispatchEventLoop(label: "unit-test")
        )
        XCTAssertThrowsError(_ = try container.make(Log.self, for: ServiceTests.self), "Should not have resolved")
    }
    
    func testSupplement() throws {
#if os(Linux) // Currently asserts on macOS. Tracking as SR-???? (bugs.swift.org is down, will update when it comes up)
assert((ConfigurableLog(config: "test") as? AnyObject) == nil, "ConfigurableLog must be a value type for this test")
#endif

        let expectation1 = self.countedExpectation(expecting: 2, description: "ConfigurableLog-specific supplement 1 should have run twice")
        let expectation2 = self.countedExpectation(expecting: 2, description: "ConfigurableLog-specific supplement 2 should have run twice")
        let expectation3 = self.countedExpectation(expecting: 1, description: "PrintLog-specific supplement should have run once")
        let expectation4 = self.invertedExpectation(description: "Generic supplement should not have run")
        
        var config = Config()
        var services = Services()

        services.register(PrintLog.self)
        services.register(AllCapsLog.self)
        services.register(Log.self) { _ -> ConfigurableLog in ConfigurableLog(config: "foo") }
        config.prefer(ConfigurableLog.self, for: Log.self)

        services.supplement(ConfigurableLog.self) { (service: inout ConfigurableLog, _) in
            service.myConfig = "bar"
            expectation1.fulfill()
        }
        services.supplement(ConfigurableLog.self) { (service: inout ConfigurableLog, _) in
            service.myConfig = "baz"
            expectation2.fulfill()
        }
        services.supplement(PrintLog.self) { (service: inout PrintLog, _) in
            expectation3.fulfill()
        }
        services.supplement(Log.self) { (service: inout Log, _) in
            expectation4.fulfill()
        }
        
        let container = BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DispatchEventLoop(label: "unit-test")
        )
        
        let log1 = try container.make(Log.self, for: ServiceTests.self)
        let log2 = try container.make(Log.self, for: Log.self) // force it not to use the cache
        let _ = try container.make(PrintLog.self, for: ServiceTests.self) // The expectations do all the work on this one

        waitForExpectations(timeout: 0.0)

        XCTAssertNotNil(log1 as? ConfigurableLog)
        XCTAssertEqual((log1 as! ConfigurableLog).myConfig, "baz", "Supplement's effects should be lasting on value types and run in registration order")

        XCTAssertNotNil(log2 as? ConfigurableLog)
        XCTAssertEqual((log2 as! ConfigurableLog).myConfig, "baz", "Supplement's effects should happen for multiple invocations")
    }

    static var allTests = [
        ("testHappyPath", testHappyPath),
        ("testMultiple", testMultiple),
        ("testTagged", testTagged),
        ("testTagDisambiguation", testTagDisambiguation),
        ("testClient", testClient),
        ("testSpecific", testSpecific),
        ("testProvider", testProvider),
        ("testRequire", testRequire),
        ("testSupplement", testSupplement),
    ]
}


