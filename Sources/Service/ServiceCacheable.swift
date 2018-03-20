/// Capable of caching services
public protocol ServiceCacheable {
    /// The service cache
    var serviceCache: ServiceCache { get }
}

public final class ServiceCache {
    /// The internal services cache.
    private var services: [InterfaceIdentifier: ResolvedService]

    /// Create a new service cache.
    public init() {
        self.services = [:]
    }

    /// Gets the cached service if one exists.
    /// - throws if the service was cached as an error
    internal func get<Interface>(_ interface: Interface.Type) throws -> Interface? {
        let key = InterfaceIdentifier(interface: Interface.self)
        guard let resolved = services[key] else {
            return nil
        }

        return try resolved.resolve() as? Interface
    }

    /// internal method for setting cache based on ResolvedService enum.
    internal func set<Interface>(_ resolved: ResolvedService, _ interface: Interface.Type) {
        let key = InterfaceIdentifier(interface: Interface.self)
        services[key] = resolved
    }
}

/// a resolved service, either error or the service
internal enum ResolvedService {
    case service(Any)
    case error(Error)

    /// returns the service or throws the error
    internal func resolve() throws -> Any {
        switch self {
        case .error(let error): throw error
        case .service(let service): return service
        }
    }
}

/// hashable struct for an interface type
internal struct InterfaceIdentifier: Hashable {
    static func ==(lhs: InterfaceIdentifier, rhs: InterfaceIdentifier) -> Bool {
        return lhs.interface == rhs.interface
    }

    let hashValue: Int

    private let interface: ObjectIdentifier

    public init(interface: Any.Type) {
        self.interface = ObjectIdentifier(interface)
        self.hashValue = self.interface.hashValue
    }
}
