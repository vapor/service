/// Types conforming to this protocol can be used by
/// the service container to disambiguate situations where
/// multiple services are available for a given `.make()` request.
public struct Config {
    fileprivate var preferences: [ServiceIdentifier: ServiceConfig]
    fileprivate var requirements: [ServiceIdentifier: ServiceConfig]

    /// Creates an empty `Config`.
    public init() {
        self.preferences = [:]
        self.requirements = [:]
    }
    
    /// Use this method to disambiguate multiple available implementations for a given interface.
    public mutating func prefer(
        _ type: Any.Type,
        for interface: Any.Type
    ) {
        let config = ServiceConfig(type: type)
        let id = ServiceIdentifier(interface)
        preferences[id] = config
    }

    ///  Use this method to require a given implementation for an interface.
    public mutating func require(
        _ type: Any.Type,
        for interface: Any.Type
    ) {
        let config = ServiceConfig(type: type)
        let id = ServiceIdentifier(interface)
        requirements[id] = config
    }

    /// MARK: Internal

    internal func choose(
        from available: [ServiceFactory],
        interface: Any.Type,
        for container: Container
    ) throws -> ServiceFactory {
        let specific = ServiceIdentifier(interface)
        guard let preference = preferences[specific] else {
            throw ServiceError(
                identifier: "ambiguity",
                reason: "Please choose which \(interface) you prefer, multiple are available: \(available.readable).",
                suggestedFixes: available.map { service in
                    return "`config.prefer(\(service.serviceType).self, for: \(interface).self)`."
                }
            )
        }

        let chosen = available.filter { factory in
            return preference.type == factory.serviceType
        }

        guard chosen.count == 1 else {
            if chosen.count < 1 {
                throw ServiceError(
                    identifier: "missing",
                    reason: "No service \(preference.type) has been registered for \(interface)."
                )
            } else {
                throw ServiceError(
                    identifier: "tooMany",
                    reason: "Too many services registered for this type."
                )
            }

        }

        return chosen[0]
    }

    internal func approve(
        chosen: ServiceFactory,
        interface: Any.Type,
        for container: Container
    ) throws {
        let specific = ServiceIdentifier(interface)
        guard let requirement = requirements[specific] else {
            return
        }

        guard requirement.type == chosen.serviceType else {
            throw ServiceError(
                identifier: "typeRequirement",
                reason: "\(interface) \(chosen.serviceType) is not required type \(requirement.type)."
            )
        }
    }
}

extension Array where Element == ServiceFactory {
    var readable: String {
        return map { "\($0.serviceType)" }.joined(separator: ", ")
    }
}

fileprivate struct ServiceIdentifier: Hashable {
    static func ==(lhs: ServiceIdentifier, rhs: ServiceIdentifier) -> Bool {
        return lhs.interface == rhs.interface
    }

    var hashValue: Int {
        return interface.hashValue
    }

    var interface: ObjectIdentifier

    init(_ type: Any.Type) {
        self.interface = ObjectIdentifier(type)
    }
}

fileprivate struct ServiceConfig {
    var type: Any.Type
}
