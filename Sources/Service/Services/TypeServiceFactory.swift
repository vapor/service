/// `ServiceFactory` conformance for `ServiceType`.
internal struct TypeServiceFactory<S>: ServiceFactory where S: ServiceType {
    /// See `ServiceFactory`
    var serviceType: Any.Type {
        return S.self
    }

    /// See `ServiceFactory`
    var serviceSupports: [Any.Type] {
        return S.serviceSupports
    }

    /// See `ServiceFactory`
    func makeService(for worker: Container) throws -> Any {
        return try S.makeService(for: worker)
    }

    /// Creates a new `TypeServiceFactory`
    init(_ s: S.Type = S.self) { }
}
