/// Empty protocol for declaring types that can be registered as a service.
///
///     extension RedisCache: Service { }
///
/// This protocol allows the Service package to prevent ambiguous service registration, i.e., preventing closures
/// that yield a service from being registered _as_ a service.
public protocol Service {}
