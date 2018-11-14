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
            on: EmbeddedEventLoop()
        )
        let log = try container.make(Log.self)
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
            on: EmbeddedEventLoop()
        )
        let log = try container.make(Log.self)
        XCTAssert(log is PrintLog)
    }

    func testTagged() throws {
        var config = Config()
        config.prefer(PrintLog.self, for: Log.self)

        var services = Services()
        services.register(PrintLog.self)
        services.register(AllCapsLog.self)

        let foo = PrintLog()
        services.register(foo, as: Log.self)

        let container = BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: EmbeddedEventLoop()
        )
        let log = try container.make(Log.self)
        XCTAssert(log is PrintLog)
    }

    func testClient() throws {
        var config = Config()
        config.prefer(PrintLog.self, for: Log.self)

        var services = Services()
        services.register(PrintLog.self)
        services.register(AllCapsLog.self)

        let container = BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: EmbeddedEventLoop()
        )
        let log = try container.make(Log.self)
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
            on: EmbeddedEventLoop()
        )
        let log = try container.make(AllCapsLog.self)
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
            on: EmbeddedEventLoop()
        )
        let log = try container.make(AllCapsLog.self)
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
            on: EmbeddedEventLoop()
        )
        XCTAssertThrowsError(_ = try container.make(Log.self), "Should not have resolved")
    }
    
    func testSupplement() throws {
        assert(!(type(of: ConfigurableLog(config: "test")) is AnyObject.Type), "ConfigurableLog must be a value type for this test") // See SR-6715

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        let expectation1 = self.countedExpectation(expecting: 2, description: "ConfigurableLog-specific supplement 1 should have run twice")
        let expectation2 = self.countedExpectation(expecting: 2, description: "ConfigurableLog-specific supplement 2 should have run twice")
        let expectation3 = self.countedExpectation(expecting: 1, description: "PrintLog-specific supplement should have run once")
        let expectation4 = self.invertedExpectation(description: "Generic supplement should not have run")
#endif

        var config = Config()
        var services = Services()

        services.register(PrintLog.self)
        services.register(AllCapsLog.self)
        services.register(Log.self) { _ -> ConfigurableLog in ConfigurableLog(config: "foo") }
        config.prefer(ConfigurableLog.self, for: Log.self)

        services.supplement(ConfigurableLog.self) { (service: inout ConfigurableLog, _) in
            service.myConfig = "bar"
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
            expectation1.fulfill()
#endif
        }
        services.supplement(ConfigurableLog.self) { (service: inout ConfigurableLog, _) in
            service.myConfig = "baz"
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
            expectation2.fulfill()
#endif
        }
        services.supplement(PrintLog.self) { (service: inout PrintLog, _) in
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
            expectation3.fulfill()
#endif
        }
        services.supplement(Log.self) { (service: inout Log, _) in
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
            expectation4.fulfill()
#endif
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

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        waitForExpectations(timeout: 0.0)
#endif

        XCTAssertNotNil(log1 as? ConfigurableLog)
        XCTAssertEqual((log1 as! ConfigurableLog).myConfig, "baz", "Supplement's effects should be lasting on value types and run in registration order")

        XCTAssertNotNil(log2 as? ConfigurableLog)
        XCTAssertEqual((log2 as! ConfigurableLog).myConfig, "baz", "Supplement's effects should happen for multiple invocations")
    }

    static var allTests = [
        ("testHappyPath", testHappyPath),
        ("testMultiple", testMultiple),
        ("testTagged", testTagged),
        ("testClient", testClient),
        ("testSpecific", testSpecific),
        ("testProvider", testProvider),
        ("testRequire", testRequire),
        ("testSupplement", testSupplement),
    ]
}
