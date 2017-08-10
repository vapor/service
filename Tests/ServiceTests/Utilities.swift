import Configs
import Service

final class TestContainer: Container {
    static var configKey = "app"
    let config: Config
    let services: Services
    var extend: [String: Any]

    init(config: Config, services: Services) {
        self.config = config
        self.services = services
        self.extend = [:]
    }
}

protocol Log {
    func log(_ string: String)
}

class PrintLog: Log {
    func log(_ string: String) {
        print("[Print Log] \(string)")
    }
}

extension PrintLog: ServiceType {
    static let serviceName = "print"
    static let serviceSupports: [Any.Type] = [Log.self]
    static func makeService(for container: Container) throws -> Self? {
        return .init()
    }
}


class AllCapsLog: Log {
    func log(_ string: String) {
        print(string.uppercased())
    }
}

extension AllCapsLog: ServiceType {
    static let serviceName = "all-caps"
    static let serviceSupports: [Any.Type] = [Log.self]
    static func makeService(for container: Container) throws -> Self? {
        return .init()
    }
}


class AllCapsProvider: Provider, ConfigInitializable {
    static let repositoryName = "all-caps-provider"

    required init(config: Config) throws {
        
    }

    func register(_ services: inout Services) throws {
        services.register(AllCapsLog.self)
    }

    func boot(_ container: Container) throws { }
}
