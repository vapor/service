/// The service `Config` is used to disambigute which concrete service should be used if multiple are
/// available for a given protocol
///
///     config.prefer(RedisCache.self, for: Cache.self)
///
/// Service `Config` can also be used to set concrete service requirements to ensure a specific concrete
/// services are being used. This can be helpful if you want to ensure non-dev dependencies are being used in production.
///
///     config.require(ProductionLogger.self, for: Logger.self)
///
public struct Config: CustomStringConvertible {
    /// Stored service preferences. [Interface: Service]
    fileprivate var preferences: [ServiceID: ServiceID]

    /// Stored service requirements. [Interface: Service]
    fileprivate var requirements: [ServiceID: ServiceID]

    /// See `CustomStringConvertible`
    public var description: String {
        var desc: [String] = []

        func list(_ name: String, _ list: [ServiceID: ServiceID]) {
            desc.append("\(name):")
            if list.isEmpty {
                desc.append("- none")
            } else {
                for (key, val) in list {
                    desc.append("- \(key): \(val)")
                }
            }
        }
        list("Preferences", preferences)
        list("Requirements", requirements)

        return desc.joined(separator: "\n")
    }

    /// Creates an empty `Config`.
    public init() {
        self.preferences = [:]
        self.requirements = [:]
    }
    
    /// Use this method to disambiguate multiple available service implementations for a given interface.
    ///
    ///     config.prefer(RedisCache.self, for: Cache.self)
    ///
    /// - parameters:
    ///     - type: Concrete service type to prefer. This should not be a protocol.
    ///     - interface: The interface to prefer this concrete service for. This must be a protocol that the service conforms to.
    public mutating func prefer(_ type: Any.Type, for interface: Any.Type) {
        preferences[.init(interface)] = .init(type)
    }

    ///  Use this method to require a given implementation for an interface.
    ///
    ///     config.require(ProductionLogger.self, for: Logger.self)
    ///
    /// - parameters:
    ///     - type: Concrete service type to require. This should not be a protocol.
    ///     - interface: The interface to require this concrete service for. This must be a protocol that the service conforms to.
    public mutating func require(_ type: Any.Type, for interface: Any.Type ) {
        requirements[.init(interface)] = .init(type)
    }

    /// MARK: Internal

    /// Chooses appropriate `ServiceFactory` from available factories taking into account the preferences of this config.
    internal func choose(from available: [ServiceFactory], interface: Any.Type, for container: Container) throws -> ServiceFactory {
        guard let preference = preferences[.init(interface)] else {
            let readable = available.map { "\($0.serviceType)" }.joined(separator: ", ")
            throw ServiceError(
                identifier: "ambiguity",
                reason: "Please choose which \(interface) you prefer, multiple are available: \(readable).",
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
                throw ServiceError(identifier: "missing", reason: "No service '\(preference)' has been registered for '\(interface)'.")
            } else {
                throw ServiceError(identifier: "tooMany", reason: "Too many services registered for this type.")
            }

        }

        return chosen[0]
    }

    /// Approves the chosen service for use taking into account the requirements of this config.
    internal func approve(chosen: ServiceFactory, interface: Any.Type, for container: Container) throws {
        guard let requirement = requirements[.init(interface)] else {
            return
        }

        guard requirement.type == chosen.serviceType else {
            throw ServiceError(identifier: "typeRequirement", reason: "'\(chosen.serviceType)' for '\(interface)' is not required type '\(requirement)'.")
        }
    }
}
