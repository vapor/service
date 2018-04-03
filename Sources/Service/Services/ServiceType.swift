/// A `Service` type that is capable of statically conforming to `ServiceFactory`.
///
/// `ServiceTypes` can be registered using just their type name.
///
///     services.register(RedisCache.self)
///
/// This protocol implies `Service` conformance on the created service.
public protocol ServiceType: Service {
    /// An array of protocols (or types) that this service conforms to.
    ///
    /// For example, when `container.make(X.self)` is called, all services that support `X` will be considered.
    ///
    /// See `ServiceFactory` for more information.
    static var serviceSupports: [Any.Type] { get }

    /// Creates a new instance of the service for the supplied `Container`.
    ///
    /// See `ServiceFactory` for more information.
    static func makeService(for worker: Container) throws -> Self
}

/// MARK: Default Implementations

extension ServiceType {
    /// See `ServiceType`
    public static var serviceSupports: [Any.Type] {
        return []
    }
}
