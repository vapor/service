/// Base protocol for all service factories. This is how the `Services` struct stores its registered services.
///
/// You will usually not use this protocol directly. See `ServiceType` protocol and the `Services` struct instead.
public protocol ServiceFactory {
    /// This service's actual type. Used for looking up the service uniquely.
    var serviceType: Any.Type { get }

    /// An array of protocols (or interfaces) that this service supports.
    ///
    /// - note: This service _must_ be force-castable to all interfaces provided in this array.
    var serviceSupports: [Any.Type] { get }

    /// Creates an instance of the service for the supplied `Container`.
    func makeService(for worker: Container) throws -> Any
}
