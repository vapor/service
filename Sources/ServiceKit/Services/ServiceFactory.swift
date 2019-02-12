/// Basic, closure-based `ServiceFactory` implementation.
///
///     let factory = BasicServiceFactory(MyFoo.self, suppports: [Foo.self]) { container in
///         return MyFoo()
///     }
///
struct ServiceFactory<T> {
    /// Accepts a `Container`, returning an initialized service.
    let closure: (Container) throws -> T
    
    /// Create a new `BasicServiceFactory`.
    ///
    /// - parameters:
    ///     - type: The `ServiceFactory` service type. This is the type that should be returned by the factory closure.
    ///     - interfaces: A list of protocols that the service supports. Empty array if the service does not support any protocols.
    ///     - factory: A closure that accepts a container and returns an initialized service.
    public init(_ closure: @escaping (Container) throws -> T) {
        self.closure = closure
    }
    
    /// See `ServiceFactory`.
    public func serviceMake(for worker: Container) throws -> T {
        return try closure(worker)
    }
}
