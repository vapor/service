/// Basic, closure-based `ServiceFactory` implementation.
///
///     let factory = BasicServiceFactory(MyFoo.self, suppports: [Foo.self]) { container in
///         return MyFoo()
///     }
///
public struct BasicServiceFactory: ServiceFactory {
    /// See `ServiceFactory`.
    public let serviceType: Any.Type

    /// See `ServiceFactory`.
    public var serviceSupports: [Any.Type]

    /// Accepts a `Container`, returning an initialized service.
    public let closure: (Container) throws -> Any

    /// Create a new `BasicServiceFactory`.
    ///
    /// - parameters:
    ///     - type: The `ServiceFactory` service type. This is the type that should be returned by the factory closure.
    ///     - interfaces: A list of protocols that the service supports. Empty array if the service does not support any protocols.
    ///     - factory: A closure that accepts a container and returns an initialized service.
    public init(
        _ type: Any.Type,
        supports interfaces: [Any.Type],
        factory closure: @escaping (Container) throws -> Any
    ) {
        self.serviceType = type
        self.serviceSupports = interfaces
        self.closure = closure
    }

    /// See `ServiceFactory`.
    public func makeService(for worker: Container) throws -> Any {
        return try closure(worker)
    }
}
