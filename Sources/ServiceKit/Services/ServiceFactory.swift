///// Base protocol for all service factories. This is how the `Services` struct stores its registered services.
/////
///// You will usually not use this protocol directly. See `ServiceType` protocol and the `Services` struct instead.
//internal protocol ServiceFactory {
//    /// This service's actual type. Used for looking up the service uniquely.
//    var serviceType: Any.Type { get }
//
//    /// Creates an instance of the service for the supplied `Container`.
//    func serviceMake(for container: Container) throws -> Any
//}
