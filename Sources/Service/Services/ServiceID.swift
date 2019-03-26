/// Simple wrapper around an `Any.Type` to provide better debug information.
internal struct ServiceID: Hashable, Equatable, CustomStringConvertible {
    /// See `Equatable`.
    static func ==(lhs: ServiceID, rhs: ServiceID) -> Bool {
        return lhs.type == rhs.type
    }

    // #if compiler(>=4.2)
    #if swift(>=4.1.50)
    /// See `Hashable`.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self._hashValue)
    }
    #else
    /// See `Hashable`.
    public var hashValue: Int {
        return self._hashValue
    }
    #endif
    
    private let _hashValue: Int

    /// The wrapped type.
    internal let type: Any.Type

    /// See `CustomStringConvertible`
    var description: String {
        return "\(type)"
    }

    /// Creates a new `ServiceID`, wrapping the supplied type.
    init(_ type: Any.Type) {
        self.type = type
        self._hashValue = ObjectIdentifier(type).hashValue
    }
}
