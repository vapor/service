import Mapper

public enum Config {
    case string(String)
    case int(Int)
    case double(Double)
    case array([Config])
    case dictionary([String: Config])
    case bool(Bool)
    case null
}

// MARK: protocols

public protocol ConfigInitializable {
    init(config: Config) throws
}

public protocol ConfigRepresentable {
    func makeConfig() throws -> Config
}

public typealias ConfigConvertible = ConfigInitializable & ConfigRepresentable

// MARK: convenience inits

extension Config {
    public init() {
        self = .dictionary([:])
    }

    public init(_ config: ConfigRepresentable) throws {
        try self.init(config: config.makeConfig())
    }
}

// MARK: conform self

extension Config: ConfigConvertible {
    public init(config: Config) throws {
        self = config
    }

    public func makeConfig() throws -> Config {
        return self
    }
}


// MARK: map

extension Config: MapConvertible {
    public init(map: Map) throws {
        switch map {
        case .array(let array):
            let array = try array.map { try Config(map: $0) }
            self = .array(array)
        case .dictionary(let dict):
            let obj = try dict.mapValues { try Config(map: $0) }
            self = .dictionary(obj)
        case .double(let double):
            self = .double(double)
        case .int(let int):
            self = .int(int)
        case .string(let string):
            self = .string(string)
        case .bool(let bool):
            self = .bool(bool)
        case .null:
            self = .null
        }
    }

    public func makeMap() throws -> Map {
        switch self {
        case .array(let array):
            let array = try array.map { try $0.makeMap() }
            return .array(array)
        case .dictionary(let obj):
            var dict: [String: Map] = [:]
            for (key, val) in obj {
                dict[key] = try val.makeMap()
            }
            return .dictionary(dict)
        case .double(let double):
            return .double(double)
        case .int(let int):
            return .int(int)
        case .string(let string):
            return .string(string)
        case .bool(let bool):
            return .bool(bool)
        case .null:
            return .null
        }
    }
}

extension Map: ConfigConvertible {
    public init(config: Config) throws {
        self = try config.makeMap()
    }

    public func makeConfig() throws -> Config {
        return try Config(map: self)
    }
}

// MARK: convenience access

extension Config: Polymorphic {}

// MARK: keyed

extension Config: Keyed {
    public var empty: Config { return .dictionary([:]) }

    public mutating func set(key: String, to value: Config?) {
        var dict: [String: Config]
        switch self {
        case .dictionary(let existing):
            dict = existing
        default:
            dict = [:]
        }
        dict[key] = value
        self = .dictionary(dict)
    }

    public func get(key: String) -> Config? {
        return dictionary?[key]
    }
}

// MARK: keyed convenience

extension Config {
    public mutating func set<T: ConfigRepresentable>(_ path: String..., to config: T) throws {
        try set(path, to: config) { try $0.makeConfig() }
    }

    public func get<T: ConfigInitializable>(_ path: String...) throws -> T {
        return try get(path) { try T(config: $0) }
    }
}

// MARK: compatible types

extension ConfigRepresentable where Self: MapRepresentable {
    public func makeConfig() throws -> Config { return try converted() }
}

extension ConfigInitializable where Self: MapInitializable {
    public init(config: Config) throws { self = try config.converted() }
}

extension Array: ConfigConvertible {}
extension Dictionary: ConfigConvertible {}
extension Optional: ConfigConvertible {}
extension String: ConfigConvertible {}
extension Int: ConfigConvertible {}
extension Double: ConfigConvertible {}
