import NIO
import ServiceKit
import XCTest

// MARK: Log

protocol Log {
    func log(_ string: String)
}

class PrintLog: Log {
    func log(_ string: String) {
        print("[Print Log] \(string)")
    }
}

class AllCapsLog: Log {
    func log(_ string: String) {
        print(string.uppercased())
    }
}

struct ConfigurableLog: Log {
    var myConfig: String
    
    init(config: String) {
        self.myConfig = config
    }

    func log(_ string: String) {
        print("[Config \(myConfig) Log] - \(string)")
    }
}

final class AllCapsProvider: ServiceProvider {
    func register(_ services: inout Services) throws {
        services.instance(AllCapsLog.self, .init())
        services.register(Log.self) { c in
            return try c.make(AllCapsLog.self)
        }
    }
}

// MARK: BCrypt

final class BCryptProvider: ServiceProvider {
    func register(_ s: inout Services) throws {
        s.register(BCryptConfig.self) { c in
            if c.environment.isRelease {
                return .init(cost: 12)
            } else {
                return .init(cost: 4)
            }
        }
        
        s.register(BCryptHasher.self) { c in
            let config = try c.make(BCryptConfig.self)
            return .init(cost: config.cost)
        }
        
        s.register(Hasher.self) { c in
            return try c.make(BCryptHasher.self)
        }
    }
}

protocol Hasher {
    func hash(_ string: String) -> String
}

class BCryptHasher: Hasher {
    let cost: Int

    init(cost: Int) {
        self.cost = cost
    }

    func hash(_ string: String) -> String {
        return "$2y:\(cost):\(string)"
    }
}

struct BCryptConfig {
    let cost: Int
    init(cost: Int) {
        self.cost = cost
    }
}

// MARK: Commands

protocol Command { }

struct Commands {
    var storage: [String: Command]
    init() {
        self.storage = [:]
    }
    mutating func add(_ command: Command, named name: String) {
        self.storage[name] = command
    }
}

struct ServeCommand: Command { }
struct MigrateCommand: Command { }

final class FluentProvider: ServiceProvider {
    func register(_ s: inout Services) throws {
        s.register(MigrateCommand.self) { c in
            return .init()
        }
        
        s.extend(Commands.self) { commands, c in
            try commands.add(c.make(MigrateCommand.self), named: "migrate")
        }
    }
}
