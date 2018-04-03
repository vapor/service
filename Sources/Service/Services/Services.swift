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
    internal var factories: [ServiceFactory]

    /// All registered service providers. These are stored so that their lifecycle methods can be called later.
    internal var providers: [Provider]

    // MARK: Init

    /// Creates a new `Services`.
    public init() {
        self.factories = []
        self.providers = []
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
    public mutating func register<S>(_ instance: S, as interface: Any.Type) where S: Service {
        return self.register(instance, as: [interface])
    }

    /// Registers a pre-initialized instance of a `Service` to the `Services`.
    ///
    ///     services.register(PrintLogger())
    ///
    /// This method also supports declaring conformance for zero or more protocols.
    ///
    ///     services.register(PrintLogger(), as: [Logger.self, ErrorLogger.self])
    ///
    /// - warning: When used with reference types (classes), this method will share the same
    ///            object with all subcontainers. Be careful to avoid race conditions.
    ///
    /// - parameters:
    ///     - instance: Pre-initialized `Service` instance to register.
    ///     - interfaces: Zero or more interfaces that this `Service` supports (besides its own type).
    public mutating func register<S>(_ instance: S, as interfaces: [Any.Type] = []) where S: Service {
        let factory = BasicServiceFactory(S.self, supports: interfaces) { container in
            return instance
        }
        self.register(factory)
    }

    // MARK: Factory

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
    public mutating func register<S>(_ interface: Any.Type, factory: @escaping (Container) throws -> (S)) where S: Service {
        let factory = BasicServiceFactory(S.self, supports: [interface]) { worker in
            try factory(worker)
        }
        self.register(factory)
    }

    /// Registers a `Service` creating closure (service factory) to the `Services`.
    ///
    ///     services.register { container in
    ///         return PrintLogger()
    ///     }
    ///
    /// This is the most common method for registering services as it ensures a new instance of the `Service` is
    /// initialized for each sub-container. It also provides access to the `Container` when the `Service` is initialized
    /// making it easy to query the `Container` for dependencies.
    ///
    ///     services.register { container in
    ///         return try RedisCache(connection: container.make())
    ///     }
    ///
    /// This method also supports declaring conformance for zero or more protocols.
    ///
    ///     services.register([Logger.self, ErrorLogger.self]) { container in
    ///         return PrintLogger()
    ///     }
    ///
    /// See the other `register(_:factory:)` method that accepts a single interface.
    ///
    /// - parameters:
    ///     - interfaces: Zero or more interfaces that this `Service` supports (besides its own type).
    ///     - factory: `Container` accepting closure that returns an initialized instance of this `Service`.
    public mutating func register<S>(_ interfaces: [Any.Type] = [], factory: @escaping (Container) throws -> (S)) where S: Service {
        let factory = BasicServiceFactory(S.self, supports: interfaces) { worker in
            try factory(worker)
        }
        self.register(factory)
    }

    // MARK: Type

    /// Registers a `ServiceType` to the `Services`. This is the most concise register method since the `ServiceType`
    /// protocol supplies all required information.
    ///
    ///     extension PrintLogger: ServiceType { ... }
    ///
    ///     services.register(PrintLogger.self)
    ///
    /// See `ServiceType` for more information.
    public mutating func register<S>(_ type: S.Type = S.self) where S: ServiceType {
        let factory = TypeServiceFactory(S.self)
        self.register(factory)
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
    public mutating func register<P>(_ provider: P) throws where P: Provider {
        guard !providers.contains(where: { Swift.type(of: $0) == P.self }) else {
            return
        }
        try provider.register(&self)
        providers.append(provider)
    }

    // MARK: Custom

    /// Registers any type conforming to `ServiceFactory`. This method should only be used when implementing custom
    /// behavior. All other register methods call this method.
    public mutating func register(_ factory: ServiceFactory) {
        if let existing = factories.index(where: { $0.serviceType == factory.serviceType }) {
            factories[existing] = factory
        } else {
            factories.append(factory)
        }
    }

    // MARK: CustomStringConvertible

    /// See `CustomStringConvertible`.
    public var description: String {
        var desc: [String] = []

        desc.append("Services:")
        if factories.isEmpty {
            desc.append("- none")
        } else {
            for factory in factories {
                if factory.serviceSupports.isEmpty {
                    desc.append("- \(factory.serviceType)")
                } else {
                    let interfaces = factory.serviceSupports.map { "\($0)" }.joined(separator: ", ")
                    desc.append("- \(factory.serviceType): \(interfaces)")
                }
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
