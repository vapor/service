/// Services available for a service container.
public struct Services {
    var factories: [ServiceFactory]

    public init() {
        self.factories = []
    }
}

// MARK: Services

extension Services {
    /// Adds a service type to the Services.
    public mutating func register<S: ServiceType>(_ type: S.Type = S.self) {
        let factory = TypeServiceFactory(S.self)
        register(factory)
    }

    /// Adds an instance of a service to the Services.
    public mutating func register<S>(
        _ instance: S,
        name: String,
        supports: [Any.Type],
        isSingleton: Bool = true
    ) {
        let factory = BasicServiceFactory(S.self, name: name, supports: supports, isSingleton: isSingleton) { drop in
            return instance
        }
        register(factory)
    }

    /// Adds any type conforming to ServiceFactory
    public mutating func register(_ factory: ServiceFactory) {
        guard !factories.contains(where: {
            $0.serviceType == factory.serviceType && $0.serviceName == factory.serviceName
        }) else {
            return
        }
        
        factories.append(factory)
    }

    /// Adds an initialized provider
    public mutating func register<P: Provider>(_ provider: P) throws {
        try provider.register(&self)
    }
}
