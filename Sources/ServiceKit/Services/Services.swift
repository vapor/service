/// The `Services` struct is used for registering and storing a `Container`'s services.
///
/// # Registering Services
///
/// While the `Services` struct is mutable (before it is used to initialize a `Container`), new services
/// can be registered using a few different methods.
///
/// ## Factory
///
/// The most common method for registering services is by using a factory.
///
///     services.register(Logger.self) { container in
///         return PrintLogger()
///     }
///
/// This will ensure a new instance of your service is created for any `SubContainer`s. See the `register(_:factory:)`
/// methods for more information.
///
/// - note: You may need to disambiguate the closure return by adding `-> T`.
///
/// ## Type
///
/// A concise method for registering services is by using the `ServiceType` protocol. Types conforming
/// to this protocol can be registered to `Services` using just the type name.
///
///     extension PrintLogger: ServiceType { ... }
///
///     services.register(PrintLogger.self)
///
/// See `ServiceType` for more details.
///
/// ## Instance
///
/// You can also register pre-initialized instances of a service.
///
///     services.register(PrintLogger())
///
/// - warning: When used with reference types (classes), this method will share the same
///            object with all `SubContainer`s. Be careful to avoid race conditions.
///
/// # Making Services
///
/// Once you initialize a `Container` from a `Services` struct, the `Services` will become immutable.
/// After this point, you can use the `make(_:)` method on `Container` to start creating services.
///
/// - note: The `Services` are immutable on a `Container` to optimize caching.
///
/// See `Container` for more information.
public struct Services: CustomStringConvertible {
    /// All registered services.
    var factories: [ServiceID: Any]

    /// All registered service providers. These are stored so that their lifecycle methods can be called later.
    var providers: [ServiceProvider]
    
    var extensions: [ServiceID: [Any]]

    // MARK: Init

    /// Creates a new `Services`.
    public init() {
        self.factories = [:]
        self.providers = []
        self.extensions = [:]
    }

    // MARK: Instance
    
    /// Registers a pre-initialized instance of a `Service` conforming to a single interface to the `Services`.
    ///
    ///     services.register(PrintLogger(), as: Logger.self)
    ///
    /// - warning: When used with reference types (classes), this method will share the same
    ///            object with all subcontainers. Be careful to avoid race conditions.
    ///
    /// - parameters:
    ///     - instance: Pre-initialized `Service` instance to register.
    ///     - interface: An interface that this `Service` supports (besides its own type).
    public mutating func instance<S>(_ instance: S) {
        return self.instance(S.self, instance)
    }

    /// Registers a pre-initialized instance of a `Service` conforming to a single interface to the `Services`.
    ///
    ///     services.register(PrintLogger(), as: Logger.self)
    ///
    /// - warning: When used with reference types (classes), this method will share the same
    ///            object with all subcontainers. Be careful to avoid race conditions.
    ///
    /// - parameters:
    ///     - instance: Pre-initialized `Service` instance to register.
    ///     - interface: An interface that this `Service` supports (besides its own type).
    public mutating func instance<S>(_ interface: S.Type, _ instance: S) {
        let id = ServiceID(S.self)
        let factory = ServiceFactory<S> { c in
            return instance
        }
        self.factories[id] = factory
    }
    
    // MARK: Factory

    public mutating func register<S>(_ factory: @escaping (Container) throws -> (S)) {
        self.register(S.self, factory)
    }


    /// Registers a `Service` creating closure (service factory) conforming to a single interface to the `Services`.
    ///
    ///     services.register(Logger.self) { container in
    ///         return PrintLogger()
    ///     }
    ///
    /// This is the most common method for registering services as it ensures a new instance of the `Service` is
    /// initialized for each sub-container. It also provides access to the `Container` when the `Service` is initialized
    /// making it easy to query the `Container` for dependencies.
    ///
    ///     services.register(Cache.self) { container in
    ///         return try RedisCache(connection: container.make())
    ///     }
    ///
    /// See the other `register(_:factory:)` method that can accept zero or more interfaces.
    ///
    /// - parameters:
    ///     - interfaces: Zero or more interfaces that this `Service` supports (besides its own type).
    ///     - factory: `Container` accepting closure that returns an initialized instance of this `Service`.
    public mutating func register<S>(_ interface: S.Type, _ factory: @escaping (Container) throws -> (S)) {
        let id = ServiceID(S.self)
        let factory = ServiceFactory<S> { c in
            return try factory(c)
        }
        self.factories[id] = factory
    }

    // MARK: Provider

    /// Registers a `Provider` to the services. This will automatically register all of the `Provider`'s available
    /// services. It will also store the provider so that its lifecycle methods can be called later.
    ///
    ///     try services.register(PrintLoggerProvider())
    ///
    /// See `Provider` for more information.
    ///
    /// - parameters:
    ///     - provider: Initialized `Provider` to register.
    /// - throws: The provider can throw errors while registering services.
    public mutating func provider<P>(_ provider: P) throws where P: ServiceProvider {
        guard !providers.contains(where: { Swift.type(of: $0) == P.self }) else {
            return
        }
        try provider.register(&self)
        providers.append(provider)
    }
    
    // MARK: Extend
    
    /// Adds a supplement closure for the given Service type
    public mutating func extend<S>(_ service: S.Type, _ closure: @escaping (inout S, Container) throws -> Void) {
        let id = ServiceID(S.self)
        let ext = ServiceExtension<S>(closure: closure)
        self.extensions[id, default: []].append(ext)
    }


    // MARK: CustomStringConvertible

    /// See `CustomStringConvertible`.
    public var description: String {
        var desc: [String] = []

        desc.append("Services:")
        if factories.isEmpty {
            desc.append("<none>")
        } else {
            for (id, _) in factories {
                desc.append("- \(id.type)")
            }
        }

        desc.append("Providers:")
        if providers.isEmpty {
            desc.append("- none")
        } else {
            for provider in providers {
                desc.append("- \(type(of: provider))")
            }
        }

        return desc.joined(separator: "\n")
    }
}

// MARK: Private

/// Basic, closure-based `ServiceFactory` implementation.
///
///     let factory = BasicServiceFactory(MyFoo.self, suppports: [Foo.self]) { container in
///         return MyFoo()
///     }
///
struct ServiceFactory<T> {
    /// Accepts a `Container`, returning an initialized service.
    let closure: (Container) throws -> T
    
    /// Create a new `BasicServiceFactory`.
    ///
    /// - parameters:
    ///     - type: The `ServiceFactory` service type. This is the type that should be returned by the factory closure.
    ///     - interfaces: A list of protocols that the service supports. Empty array if the service does not support any protocols.
    ///     - factory: A closure that accepts a container and returns an initialized service.
    public init(_ closure: @escaping (Container) throws -> T) {
        self.closure = closure
    }
    
    /// See `ServiceFactory`.
    public func serviceMake(for worker: Container) throws -> T {
        return try closure(worker)
    }
}

/// Simple wrapper around an `Any.Type` to provide better debug information.
struct ServiceID: Hashable, Equatable, CustomStringConvertible {
    /// See `Equatable`.
    static func ==(lhs: ServiceID, rhs: ServiceID) -> Bool {
        return lhs.type == rhs.type
    }
    
    /// See `Hashable`.
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type))
    }
    
    /// The wrapped type.
    internal let type: Any.Type
    
    /// See `CustomStringConvertible`
    var description: String {
        return "\(type)"
    }
    
    /// Creates a new `ServiceID`, wrapping the supplied type.
    init(_ type: Any.Type) {
        self.type = type
    }
}

struct ServiceExtension<T> {
    public let closure: (inout T, Container) throws -> Void
    
    public init(closure: @escaping (inout T, Container) throws -> Void) {
        self.closure = closure
    }
    
    public func serviceExtend(_ instance: inout T, _ c: Container) throws {
        try closure(&instance, c)
    }
}
