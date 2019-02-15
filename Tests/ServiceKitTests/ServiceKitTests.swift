import NIO
import ServiceKit
import XCTest

class ServiceKitTests: XCTestCase {
    func testProtocolCase() throws {
        var s = Services()
        s.instance(Log.self, PrintLog())
        s.instance(PrintLog.self, PrintLog())

        let c = BasicContainer(
            environment: .production,
            services: s,
            on: EmbeddedEventLoop()
        )
        XCTAssertNoThrow(try c.make(PrintLog.self))
        try XCTAssert(c.make(Log.self) is PrintLog)
    }

    func testConcreteCase() throws {
        var s = Services()
        s.instance(PrintLog.self, .init())
        s.instance(AllCapsLog.self, .init())

        let c = BasicContainer(
            environment: .production,
            services: s,
            on: EmbeddedEventLoop()
        )
        XCTAssertNoThrow(try c.make(AllCapsLog.self))
        XCTAssertNoThrow(try c.make(PrintLog.self))
    }

    func testProvider() throws {
        var s = Services()
        try s.provider(AllCapsProvider())

        let c = BasicContainer(
            environment: .production,
            services: s,
            on: EmbeddedEventLoop()
        )
        XCTAssertNoThrow(try c.make(AllCapsLog.self))
        try XCTAssertTrue(c.make(Log.self) is AllCapsLog)
    }
    
    func testBCryptProvider() throws {
        var s = Services()
        try s.provider(BCryptProvider())
        
        print(s)
        
        // production
        do {
            let c = BasicContainer(
                environment: .production,
                services: s,
                on: EmbeddedEventLoop()
            )
            
            try XCTAssertEqual(c.make(BCryptHasher.self).cost, 12)
            try XCTAssert(c.make(Hasher.self) is BCryptHasher)
        }
        
        // development
        do {
            let c = BasicContainer(
                environment: .development,
                services: s,
                on: EmbeddedEventLoop()
            )
            
            try XCTAssertEqual(c.make(BCryptHasher.self).cost, 4)
            try XCTAssert(c.make(Hasher.self) is BCryptHasher)
        }
    }
    
    func testCommands() throws {
        var s = Services()
        try s.provider(FluentProvider())
        
        s.register(ServeCommand.self) { c in
            return .init()
        }
        s.register(Commands.self) { c in
            var commands = Commands()
            try commands.add(c.make(ServeCommand.self), named: "serve")
            return commands
        }
        
        let c = BasicContainer(
            environment: .production,
            services: s,
            on: EmbeddedEventLoop()
        )
        
        let commands = try c.make(Commands.self)
        print(commands)
        XCTAssertEqual(commands.storage.count, 2)
    }
    
    func testSingleton() throws {
        var s = Services()
        
        struct Regular {
            static var count: Int = 0
        }
        struct Singleton {
            static var count: Int = 0
        }
        
        s.register(Regular.self) { c in
            Regular.count += 1
            return .init()
        }
        s.singleton(Singleton.self) { c in
            Singleton.count += 1
            return .init()
        }
        
        let c = BasicContainer(environment: .testing, services: s, on: EmbeddedEventLoop())
        
        _ = try c.make(Regular.self)
        _ = try c.make(Regular.self)
        XCTAssertEqual(Regular.count, 2)
        
        _ = try c.make(Singleton.self)
        _ = try c.make(Singleton.self)
        XCTAssertEqual(Singleton.count, 1)
        
        c.cache.clear()
        _ = try c.make(Singleton.self)
        XCTAssertEqual(Singleton.count, 2)
    }
    
    func testSingletonExample() throws {
        final class Counter {
            var count: Int
            init() {
                self.count = 0
            }
        }
        
        var s = Services()
        
        s.singleton(Counter.self) { c in
            return .init()
        }
        
        let c = BasicContainer(environment: .testing, services: s, on: EmbeddedEventLoop())
        try c.make(Counter.self).count += 1
        try c.make(Counter.self).count += 1
        try XCTAssertEqual(c.make(Counter.self).count, 2)
    }
    
    func testEnvironmentDynamicAccess() {
        Environment.process.DATABASE_PORT = 3306
        XCTAssertEqual(Environment.process.DATABASE_PORT, 3306)
        
        Environment.process.DATABASE_PORT = nil
        XCTAssertEqual(Environment.process.DATABASE_PORT, nil)
    }
    
    static var allTests = [
        ("testProtocolCase", testProtocolCase),
        ("testConcreteCase", testConcreteCase),
        ("testProvider", testProvider),
        ("testBCryptProvider", testBCryptProvider),
        ("testSingleton", testSingleton),
        ("testSingletonExample", testSingletonExample),
        ("testEnvironmentDynamicAccess", testEnvironmentDynamicAccess)
    ]
}
