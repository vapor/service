/// An alias for another `Container`. All `Container` protocol requirements
/// are redirected to the aliased container.
public protocol ContainerAlias: Container {
    /// `KeyPath` to the aliased container.
    static var aliasedContainer: KeyPath<Self, Container> { get }
}

extension ContainerAlias {
    /// See `Container`
    public var config: Config {
        return aliasedContainer.config
    }

    /// See `Container`
    public var environment: Environment {
        return aliasedContainer.environment
    }

    /// See `Container`
    public var services: Services {
        return aliasedContainer.services
    }

    /// See `Container`
    public var serviceCache: ServiceCache {
        return aliasedContainer.serviceCache
    }

    /// See `Container`
    public var eventLoop: EventLoop {
        return aliasedContainer.eventLoop
    }

    /// Accesses the `Container` at `containerAliasKey`.
    internal var aliasedContainer: Container {
        return self[keyPath: Self.aliasedContainer]
    }
}
