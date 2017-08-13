public protocol ServiceFactory {
    var serviceType: Any.Type { get }
    var serviceIsSingleton: Bool { get }
    var serviceSupports: [Any.Type] { get }
    func makeService(for container: Container) throws -> Any?
}
