/// Types conforming to this protocol can be used by
/// the service container to disambiguate situations where
/// multiple services are available for a given `.make()` request.
public protocol Disambiguator {
    func disambiguateSingle<Type>(
        available: [ServiceFactory],
        type: Type.Type,
        for container: Container
    ) throws -> ServiceFactory

    func disambiguateMultiple<Type>(
        available: [ServiceFactory],
        type: Type.Type,
        for container: Container
    ) throws -> [ServiceFactory]
}
