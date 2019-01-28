import NIO

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
public protocol Container: class {
    /// Service `Environment` (e.g., production, dev). Use this to dynamically swap services based on environment.
    var environment: Environment { get }

    /// Available services. This struct contains all of this `Container`'s available service implementations.
    var services: Services { get }
    
    var eventLoop: EventLoop { get }
}

extension Container {
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
    public func make<S>(_ service: S.Type = S.self) throws -> S {
        // create service lookup identifier
        let id = ServiceID(S.self)
        
        // fetch service factory if one exists
        guard let factory = self.services.factories[id] as? ServiceFactory<S> else {
            fatalError("No services available for \(S.self)")
        }
        
        // create the service
        var instance = try factory.serviceMake(for: self)
        
        // check for any extensions
        if let extensions = self.services.extensions[id] as? [ServiceExtension<S>], !extensions.isEmpty {
            // loop over extensions, modifying instace
            try extensions.forEach { try $0.serviceExtend(&instance, self) }
        }
        
        // return created, extended instance
        return instance
    }
    
    /// All `Provider`s that have been registered to this `Container`'s `Services`.
    public var providers: [ServiceProvider] {
        return self.services.providers
    }
}
