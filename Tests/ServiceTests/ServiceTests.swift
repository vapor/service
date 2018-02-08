import Async
import Dispatch
import Service
import XCTest

class ServiceTests: XCTestCase {
    func testHappyPath() throws {
        let config = Config()
        var services = Services()
        services.register(PrintLog.self)

        let container = try BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DefaultEventLoop(label: "unit-test")
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

        let container = try BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DefaultEventLoop(label: "unit-test")
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
        services.register(foo, as: Log.self, tag: "foo")

        let container = try BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DefaultEventLoop(label: "unit-test")
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
        
        let container = try BasicContainer(
        	config: config,
         	environment: .production,
            services: services,
            on: DefaultEventLoop(label: "unit-test")
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

        let container = try BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DefaultEventLoop(label: "unit-test")
        )
        let log = try! container.make(Log.self, for: ServiceTests.self)
        XCTAssert(log is PrintLog)
    }

    func testSpecific() throws {
        let config = Config()
        var services = Services()
        services.register(PrintLog.self)
        services.register(AllCapsLog.self)

        let container = try BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DefaultEventLoop(label: "unit-test")
        )
        let log = try container.make(AllCapsLog.self, for: ServiceTests.self)
        XCTAssert(type(of: log) == AllCapsLog.self)
    }

    func testProvider() throws {
        let config = Config()
        var services = Services()
        try services.register(AllCapsProvider())

        let container = try BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DefaultEventLoop(label: "unit-test")
        )
        let log = try container.make(AllCapsLog.self, for: ServiceTests.self)
        XCTAssert(type(of: log) == AllCapsLog.self)
    }

    func testRequire() throws {
        var config = Config()
        config.require(PrintLog.self, for: Log.self)

        var services = Services()
        services.register(AllCapsLog.self)

        let container = try BasicContainer(
            config: config,
            environment: .production,
            services: services,
            on: DefaultEventLoop(label: "unit-test")
        )
        XCTAssertThrowsError(_ = try container.make(Log.self, for: ServiceTests.self), "Should not have resolved")
    }
    
    func testSingletonHandling() throws {
        let config = Config()
        var services = Services()
        
        services.register(isSingleton: true) { _ in PrintLog() }
        services.register { _ in ConfigurableLog(config: "whatever") }
        services.register { _ in NotAClassService() }
        
        let container = try BasicContainer(config: config, environment: .production, services: services, on: DefaultEventLoop(label: "unit-test"))

        let printLog1 = try container.make(PrintLog.self, for: ServiceTests.self)
        let printLog2 = try container.make(PrintLog.self, for: BasicContainer.self)
        let configLog1 = try container.make(ConfigurableLog.self, for: ServiceTests.self)
        let configLog2 = try container.make(ConfigurableLog.self, for: BasicContainer.self)
        let notClass1 = try container.make(NotAClassService.self, for: ServiceTests.self)
        let notClass2 = try container.make(NotAClassService.self, for: BasicContainer.self)

        XCTAssertEqual(ObjectIdentifier(printLog1), ObjectIdentifier(printLog2), "Singleton service must give the same object for different clients")
        XCTAssertNotEqual(ObjectIdentifier(configLog1), ObjectIdentifier(configLog2), "Instance service must NOT give the same object for different clients")
        XCTAssertNotEqual(notClass1.counter, notClass2.counter, "Struct service must NOT return the same struct for different clients")

        print(container.serviceCache.debugDescription)
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
        ("testSingletonHandling", testSingletonHandling),
    ]
}


