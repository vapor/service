public struct BasicServiceFactory: ServiceFactory {
    public typealias ServiceFactoryClosure = (Container) throws -> Any?

    public let serviceType: Any.Type
    public let serviceIsSingleton: Bool
    public var serviceSupports: [Any.Type]

    public let closure: ServiceFactoryClosure

    public init(
        _ serviceType: Any.Type,
        supports: [Any.Type],
        isSingleton: Bool,
        factory closure: @escaping ServiceFactoryClosure
    ) {
        self.serviceType = serviceType
        self.serviceSupports = supports
        self.serviceIsSingleton = isSingleton
        self.closure = closure
    }

    public func makeService(for container: Container) throws -> Any? {
        return try closure(container)
    }
}
