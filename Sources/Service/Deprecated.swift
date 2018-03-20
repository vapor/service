extension Container {
    @available(*, deprecated, message: "for: label has been deprecated. Use `make(_:)`.")
    public func make<Interface, Client>(
        _ interface: Interface.Type = Interface.self,
        for client: Client.Type
    ) throws -> Interface {
        return try make(Interface.self)
    }
}
