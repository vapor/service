/// Types conforming to extendable can have stored
/// properties added in extension by using the
/// provided dictionary.
public protocol Extendable: class {
    var extend: Extend { get set }
}

/// A wrapper around a simple [String: Any]
/// storage dictionary.
///
/// This wrapper is required to conform to
/// Codable.
///
/// Extensions are used for convenience and should
/// not be encoded or decoded.
public struct Extend: Codable {
    /// The internal storage.
    public var storage: [String: Any]

    /// Create a new extend.
    public init() {
        storage = [:]
    }

    /// Simply ignore this while encoding.
    public func encode(to encoder: Encoder) throws {
        // skip
    }

    /// Decode as an empty object.
    public init(from decoder: Decoder) throws {
        // skip
        storage = [:]
    }

    /// Allow subscripting
    public subscript(_ key: String) -> Any? {
        get { return storage[key] }
        set { storage[key] = newValue }
    }

    /// Get with default.
    public func get<T>(_ key: String, `default` d: T) -> T {
        return self[key] as? T ?? d
    }

    /// Set.
    public mutating func set<T>(_ key: String, to newValue: T) {
        return self[key] = newValue
    }

    /// Get with default.
    public func get<T>(_ key: AnyKeyPath, `default` d: T) -> T {
        return get(key.hashValue.description, default: d)
    }

    /// Set.
    public mutating func set<T>(_ key: AnyKeyPath, to newValue: T) {
        set(key.hashValue.description, to: newValue)
    }
}

/// Allow Extend to be declared as [:]
extension Extend: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = Any

    public init(dictionaryLiteral elements: (String, Any)...) {
        self.init()
        for (key, value) in elements {
            self[key] = value
        }
    }

}

