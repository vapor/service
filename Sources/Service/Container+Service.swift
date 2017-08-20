import Foundation

private let serviceCacheKey = "service:service-cache"

extension Container {
    /// Returns or creates a service for the given type.
    ///
    /// If a protocol is supplied, a service conforming
    /// to the protocol will be returned.
    public func make<Interface, Client>(
        _ type: Interface.Type = Interface.self,
        for client: Client.Type
    ) throws -> Interface {
        // find all available service types that match the requested type.
        let available = services.factories(supporting: Interface.self)

        let chosen: ServiceFactory

        if available.count > 1 {
            // multiple services are available,
            // we will need to disambiguate
            chosen = try config.choose(
                from: available,
                interface: Interface.self,
                for: self,
                neededBy: Client.self
            )
        } else if available.count == 0 {
            // no services are available matching
            // the type requested.
            throw ServiceError.noneAvailable(type: Interface.self)
        } else {
            // only one service matches, no need to disambiguate.
            // let's use it!
            chosen = available[0]
        }

        try config.approve(
            chosen: chosen,
            interface: Interface.self,
            for: self,
            neededBy: Client.self
        )

        // lazy loading
        // create an instance of this service type.
        let item = try _makeServiceFactoryConsultingCache(chosen, ofType: Interface.self)

        return item!
    }

    fileprivate func _makeServiceFactoryConsultingCache<T>(
        _ serviceFactory: ServiceFactory, ofType: T.Type
    ) throws -> T? {
        let key = "\(serviceFactory.serviceType)"
        if serviceFactory.serviceIsSingleton {
            if let cached = serviceCache[key] as? T {
                return cached
            }
        }

        guard let new = try serviceFactory.makeService(for: self) as? T? else {
            throw ServiceError.incorrectType(
                type: serviceFactory.serviceType,
                desired: T.self
            )
        }

        if serviceFactory.serviceIsSingleton {
            serviceCache[key] = new
        }

        return new
    }

    fileprivate var serviceCache: [String: Any] {
        get {
            return extend[serviceCacheKey] as? [String: Any] ?? [:]
        }
        set {
            extend[serviceCacheKey] = newValue
        }
    }
}

// MARK: Service Utilities

extension Services {
    internal func factories<P>(supporting protocol: P.Type) -> [ServiceFactory] {
        return factories.filter { factory in
            return factory.serviceType == P.self || factory.serviceSupports.contains(where: { $0 == P.self })
        }
    }
}
