import Async

/// Services available for a service container.
public struct Services {
    var factories: [ServiceFactory]
    public internal(set) var providers: [Provider]
    public internal(set) var supplements: [ServiceSupplement]

    public init() {
        self.factories = []
        self.providers = []
        self.supplements = []
    }
}

// MARK: Factory

extension Services {
    /// Adds a closure based service factory
    public mutating func register<S>(
        _ supports: [Any.Type] = [],
        tag: String? = nil,
        isSingleton: Bool = false,
        factory: @escaping (Container) throws -> (S)
    ) where S: Service {
        let factory = BasicServiceFactory(
            S.self,
            tag: tag,
            supports: supports,
            isSingleton: isSingleton
        ) { worker in
            try factory(worker)
        }
        self.register(factory)
    }

    /// Adds a closure based service factory
    public mutating func register<S>(
        _ interface: Any.Type,
        tag: String? = nil,
        isSingleton: Bool = false,
        factory: @escaping (Container) throws -> (S)
    ) where S: Service {
        let factory = BasicServiceFactory(
            S.self,
            tag: tag,
            supports: [interface],
            isSingleton: isSingleton
        ) { worker in
            try factory(worker)
        }
        self.register(factory)
    }

    /// Adds any type conforming to ServiceFactory
    public mutating func register(_ factory: ServiceFactory) {
        if let existing = factories.index(where: {
            $0.serviceType == factory.serviceType &&
                $0.serviceTag == factory.serviceTag
        }) {
            factories[existing] = factory
        } else {
            factories.append(factory)
        }
    }

    /// Adds a service type to the Services.
    public mutating func register<S>(_ type: S.Type = S.self) where S: ServiceType {
        let factory = TypeServiceFactory(S.self)
        self.register(factory)
    }
}

/// MARK: Provider

extension Services {
    /// Adds an initialized provider
    public mutating func register<P>(_ provider: P) throws where P: Provider {
        guard !providers.contains(where: { Swift.type(of: $0) == P.self }) else {
            return
        }
        try provider.register(&self)
        providers.append(provider)
    }
}

// MARK: Instance

extension Services {
    /// Adds an instance of a service to the Services.
    public mutating func register<S>(
        _ instance: S,
        as interface: Any.Type,
        tag: String? = nil,
        isSingleton: Bool = false
    ) where S: Service {
        return self.register(instance, as: [interface], tag: tag, isSingleton: isSingleton)
    }

    /// Adds an instance of a service to the Services.
    public mutating func register<S>(
        _ instance: S,
        as supports: [Any.Type] = [],
        tag: String? = nil,
        isSingleton: Bool = false
    ) where S: Service {
        let factory = BasicServiceFactory(
            S.self,
            tag: tag,
            supports: supports,
            isSingleton: isSingleton
        ) { container in
            return instance
        }
        self.register(factory)
    }
}

// MARK: Supplement

// Implementation note: Supplements are stored in a property on the Services
// object rather than in a property on the individual ServiceFactory objects.
// This choice was made to permit the "replace the existing service factory"
// pattern to function without additionally wiping out the supplement closures
// already added for the interface. It also avoids adding additional protocol
// requirements to ServiceFactory.
//
// TODO: Is this desired behavior, or should replacing the factory also replace
// the supplements?

extension Services {
    /// Adds a supplement type to the given Service type
    public mutating func supplement(
        _ interface: Any.Type,
        tag: String? = nil,
        with supplementSpecification: ServiceSupplement
    ) {
        supplements.append(supplementSpecification)
    }
    
    /// Adds a supplement closure for the given Service type
    public mutating func supplement<S>(
        _ interface: Any.Type,
        tag: String? = nil,
        with closure: @escaping (inout S, Container) throws -> Void
    ) {
        let supplementSpec = BasicServiceSupplement(
            tag: tag,
            closure: closure
        )
        self.supplement(interface, with: supplementSpec)
    }
}

// MARK: Deprecated
extension Services {
    /// Adds an instance of a service to the Services.
    @available(*, unavailable, renamed: "register")
    public mutating func use<S>(
        _ instance: S,
        as interface: Any.Type,
        tag: String? = nil,
        isSingleton: Bool = false
    ) where S: Service {
        return self.register(instance, as: [interface], tag: tag, isSingleton: isSingleton)
    }

    /// Adds an instance of a service to the Services.
    @available(*, unavailable, renamed: "register")
    public mutating func use<S>(
        _ instance: S,
        as supports: [Any.Type] = [],
        tag: String? = nil,
        isSingleton: Bool = false
    ) where S: Service {
        return self.register(instance, as: supports, tag: tag, isSingleton: isSingleton)
    }
}
