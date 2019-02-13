/// Stores cached singleton services.
public struct ServiceCache {
    /// Private storage.
    private var storage: [ServiceID: Any]
    
    /// Creates a new `ServiceCache`.
    public init() {
        self.storage = [:]
    }
    
    /// Returns the service if cached.
    public func get<S>(service: S.Type) -> S? {
        let id = ServiceID(S.self)
        guard let service = self.storage[id] as? S else {
            return nil
        }
        return service
    }
    
    /// Sets a new service on the cache.
    public mutating func set<S>(service: S) {
        let id = ServiceID(S.self)
        self.storage[id] = service
    }
    
    /// Clears any existing cached services.
    public mutating func clear() {
        self.storage = [:]
    }
}
