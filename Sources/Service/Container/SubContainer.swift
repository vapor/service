/// `SubContainer`s are `Container`s that have been created from a parent `Container`.
///
/// By default, `SubContainer`s share their parent's `Config`, `Environment`, and `Services`. They do not share
/// their parent's `ServiceCache` and `EventLoop`. This makes `SubContainer`s great for creating thread-specific containers.
///
/// See `Container` for more information.
public protocol SubContainer: Container {
    /// A reference to the parent `Container`.
    var superContainer: Container { get }
}

// MARK: Default Implementations

extension SubContainer {
    /// See `Container`.
    public var config: Config {
        return superContainer.config
    }

    /// See `Container`.
    public var environment: Environment {
        return superContainer.environment
    }

    /// See `Container`.
    public var services: Services {
        return superContainer.services
    }
}
