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

    static var allTests = [
        ("testHappyPath", testHappyPath),
        ("testMultiple", testMultiple),
        ("testTagged", testTagged),
        ("testClient", testClient),
        ("testSpecific", testSpecific),
        ("testProvider", testProvider),
        ("testRequire", testRequire),
    ]
}
