import Foundation

private let serviceCacheKey = "service:serviceCache"

extension Container {
    /// Makes all available services for the given type.
    ///
    /// If a protocol is supplied, all services conforming
    /// to the protocol will be returned.
    public func make<Type>(_ type: [Type.Type] = [Type.self]) throws -> [Type] {
        // create a key name for caching the result
        // the make array always caches
        let keyName = "array-\(Type.self)"

        // check to see if we already have a cached result
        if let existing = serviceCache[keyName] as? [Type] {
            return existing
        }

        // find all available service types
        let availableServices = services.factories(supporting: Type.self)

        // disambiguate the chosen types
        let chosenServices = try disambiguator.disambiguateMultiple(
            available: availableServices,
            type: Type.self,
            for: self
        )

        // lazy loading
        // initialize all of the requested services type.
        // then append onto that the already intialized service instances.
        let array = try chosenServices.flatMap { chosenService in
            return try _makeServiceFactoryConsultingCache(chosenService, ofType: Type.self)
        }

        // cache the result
        serviceCache[keyName] = array

        return array
    }

    /// Returns or creates a service for the given type.
    ///
    /// If a protocol is supplied, a service conforming
    /// to the protocol will be returned.
    public func make<Type>(_ type: Type.Type = Type.self) throws -> Type {
        // find all available service types that match the requested type.
        let available = services.factories(supporting: Type.self)

        let chosen: ServiceFactory

        if available.count > 1 {
            // multiple services are available,
            // we will need to disambiguate
            chosen = try disambiguator.disambiguateSingle(
                available: available,
                type: Type.self,
                for: self
            )
        } else if available.count == 0 {
            // no services are available matching
            // the type requested.
            throw ServiceError.noneAvailable(type: Type.self)
        } else {
            // only one service matches, no need to disambiguate.
            // let's use it!
            chosen = available[0]
        }

        // lazy loading
        // create an instance of this service type.
        let item = try _makeServiceFactoryConsultingCache(chosen, ofType: Type.self)

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
