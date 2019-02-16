@available(*, unavailable, message: "Empty protocol conformance no longer required.")
public typealias Service = Any

@available(*, unavailable, message: "Any.Type service registration no longer supported.")
public typealias ServiceType = Any

@available(*, unavailable, renamed: "Container")
public typealias BasicContainer = Container

extension Container {
    @available(*, unavailable, renamed: "env")
    public var environment: Environment {
        return self.env
    }
}
