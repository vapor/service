import XCTest
import Service

class ServiceTests: XCTestCase {
    func testHappyPath() throws {
        var services = Services()
        services.register(PrintLog.self)

        let container = try TestContainer(services: services)
        let log = try container.make(Log.self)
        log.log("hello!")
    }

    func testMultiple() throws {
        var services = Services()
        services.register(PrintLog.self)
        services.register(AllCapsLog.self)

        let container = try TestContainer(services: services)
        let log = try container.make(Log.self)
        log.log("hello!")
    }

    func testArray() throws {
        var services = Services()
        services.register(PrintLog.self)
        services.register(AllCapsLog.self)

        let container = try TestContainer(services: services)
        let log = try container.make([Log.self])
        XCTAssertEqual(log.count, 2)
    }

    func testSpecific() throws {
        var services = Services()
        services.register(PrintLog.self)
        services.register(AllCapsLog.self)

        let container = try TestContainer(services: services)
        let log = try container.make(AllCapsLog.self)
        print(log)
    }

    func testProvider() throws {
        var services = Services()
        try services.register(AllCapsProvider())

        let container = try TestContainer(services: services)
        let log = try container.make(AllCapsLog.self)
        print(log)
    }

    static var allTests = [
        ("testHappyPath", testHappyPath),
    ]
}


