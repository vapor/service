import Async

/// Services available for a service container.
public struct Services: CustomStringConvertible {
    var factories: [ServiceFactory]
    var providers: [Provider]

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

    public init() {
        self.factories = []
        self.providers = []
    }

    /// Returns all factories that support the supplied interface.
    internal func factories(supporting interface: Any.Type) -> [ServiceFactory] {
        var factories = [ServiceFactory]()

        for factory in self.factories where factory.serviceType == interface || factory.serviceSupports.contains(where: { $0 == interface }) {
            factories.append(factory)
        }

        return factories
    }
}

// MARK: Factory

extension Services {
    /// Adds a closure based service factory
    public mutating func register<S>(
        _ supports: [Any.Type] = [],
        factory: @escaping (Container) throws -> (S)
    ) where S: Service {
        let factory = BasicServiceFactory(
            S.self,
            supports: supports
        ) { worker in
            try factory(worker)
        }
        self.register(factory)
    }

    /// Adds a closure based service factory
    public mutating func register<S>(
        _ interface: Any.Type,
        factory: @escaping (Container) throws -> (S)
    ) where S: Service {
        let factory = BasicServiceFactory(
            S.self,
            supports: [interface]
        ) { worker in
            try factory(worker)
        }
        self.register(factory)
    }

    /// Adds any type conforming to ServiceFactory
    public mutating func register(_ factory: ServiceFactory) {
        if let existing = factories.index(where: {
            $0.serviceType == factory.serviceType
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
    public mutating func register<S>(_ instance: S, as interface: Any.Type) where S: Service {
        return self.register(instance, as: [interface])
    }

    /// Adds an instance of a service to the Services.
    public mutating func register<S>(_ instance: S, as supports: [Any.Type] = []) where S: Service {
        let factory = BasicServiceFactory(
            S.self,
            supports: supports
        ) { container in
            return instance
        }
        self.register(factory)
    }
}
