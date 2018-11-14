/// Caches services. All API besides creating a new `ServiceCache` are internal.
public final class ServiceCache {
    /// The internal services cache.
    private var services: [ServiceID: ResolvedService]

    /// Create a new service cache.
    public init() {
        self.services = [:]
    }

    /// Gets the cached service if one exists.
    ///
    /// - throws if the service was cached as an error
    internal func get<T>(_ interface: T.Type) throws -> T? {
        guard let resolved = services[.init(T.self)] else {
            return nil
        }

        return try resolved.resolve() as? T
    }

    /// internal method for setting cache based on ResolvedService enum.
    internal func set<T>(error: Error, _ interface: T.Type) {
        set(.error(error), T.self)
    }

    /// internal method for setting cache based on ResolvedService enum.
    internal func set<T>(service: Service, _ interface: T.Type) {
        set(.service(service), T.self)
    }

    /// internal method for setting cache based on ResolvedService enum.
    private func set<T>(_ resolved: ResolvedService, _ interface: T.Type) {
        services[.init(T.self)] = resolved
    }
}

/// A cacheable, resolved Service. Can be either an error or the actual service.
fileprivate enum ResolvedService {
    case service(Service)
    case error(Error)

    /// returns the service or throws the error
    internal func resolve() throws -> Service {
        switch self {
        case .error(let error): throw error
        case .service(let service): return service
        }
    }
}
