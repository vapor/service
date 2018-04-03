import Async
import Dispatch

/// `Container`s are used to create instances of services that your application needs in a configurable way.
///
///     let client = try container.make(Client.self)
///
/// Each `Container` has `Config`, `Environment`, and `Services`. It uses this information to dynamically provide
/// services based on your configuration and environment.
///
///     switch env {
///     case .production: config.prefer(ProductionLogger.self, for: Logger.self)
///     default: config.prefer(DebugLogger.self, for: Logger.self)
///     }
///
///     ...
///
///     let logger = try container.make(Logger.self) // changes based on environment
///
/// Containers are also `Worker`s, meaning they have a reference to an `EventLoop`.
///
///     print(container.eventLoop)
///
/// - warning: You should never use services created from a `Container` on _another_ `Container`'s `EventLoop`.
public protocol Container: ServiceCacheable, BasicWorker {
    /// Service `Config`. Used to disambiguate and/or require concrete services for a given interface.
    var config: Config { get }

    /// Service `Environment` (e.g., production, dev). Use this to dynamically swap services based on environment.
    var environment: Environment { get }

    /// Available services. This struct contains all of this `Container`'s available service implementations.
    var services: Services { get }
}

extension Container {
    /// All `Provider`s that have been registered to this `Container`'s `Services`.
    public var providers: [Provider] {
        return services.providers
    }

    /// Creates a service for the supplied interface or type.
    ///
    ///     let redis = try container.make(RedisCache.self)
    ///
    /// If a protocol is supplied, a service conforming to the protocol will be returned.
    ///
    ///     let client = try container.make(Client.self)
    ///     print(type(of: client)) // EngineClient
    ///
    /// Subsequent calls to `make(_:)` for the same type will yield a cached result.
    ///
    /// - parameters:
    ///     - type: Service or interface type `T` to create.
    /// - throws: Any error finding or initializing the requested service.
    /// - returns: Initialized instance of `T`
    public func make<T>(_ type: T.Type = T.self) throws -> T {
        // check if we've previously resolved this service
        if let service = try serviceCache.get(T.self) {
            return service
        }

        do {
            // resolve the service and cache it
            let service = try anyMake(T.self) as! T
            serviceCache.set(.service(service), T.self)
            return service
        } catch {
            // cache the error
            serviceCache.set(.error(error), T.self)
            throw error
        }
    }

    /// Type-erased version of `make(_:)`.
    ///
    /// - parameters:
    ///     - type: Service or interface type `Any.Type` to create.
    /// - throws: Any error finding or initializing the requested service.
    /// - returns: Initialized instance of supplied type.
    internal func anyMake(_ interface: Any.Type) throws -> Any {
        // find all available service types that match the requested type.
        let available = services.factories(supporting: interface)

        let chosen: ServiceFactory

        if available.count > 1 {
            // multiple services are available,
            // we will need to disambiguate
            chosen = try config.choose(
                from: available,
                interface: interface,
                for: self
            )
        } else if available.count == 0 {
            // no services are available matching
            // the type requested.
            throw ServiceError(
                identifier: "make",
                reason: "No services are available for '\(interface)'.",
                suggestedFixes: [
                    "Register a service for '\(interface)'.",
                    "`services.register(\(interface).self) { ... }`."
                ]
            )
        } else {
            // only one service matches, no need to disambiguate.
            // let's use it!
            chosen = available[0]
        }

        try config.approve(
            chosen: chosen,
            interface: interface,
            for: self
        )

        return try chosen.makeService(for: self)
    }
}
