/// The environment the application is running in, i.e., production, dev, etc. All `Container`'s will have
/// an `Environment` that can be used to dynamically register and configure services.
///
///     switch env {
///     case .production: config.prefer(ProductionLogger.self, for: Logger.self)
///     default: config.prefer(DebugLogger.self, for: Logger.self)
///     }
///
/// The `Environment` can also be used to retrieve variables from the Process's ENV.
///
///     print(Environment.get("DB_PASSWORD"))
///
public struct Environment: Equatable {
    // MARK: Presets

    /// An environment for deploying your application to consumers.
    public static var production: Environment {
        return .init(name: "production", isRelease: true)
    }

    /// An environment for developing your application.
    public static var development: Environment {
        return .init(name: "development", isRelease: false)
    }

    /// An environment for testing your application.
    public static var testing: Environment {
        return .init(name: "testing", isRelease: false)
    }

    /// Creates a custom environment.
    public static func custom(name: String, isRelease: Bool = false) -> Environment {
        return .init(name: name, isRelease: isRelease)
    }

    // MARK: Env

    /// Gets a key from the process environment
    public static func get(_ key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }
    
    /// Gets an instance of `LosslessStringConvertible` type `T` initialized from
    /// the string value associated with the `key` from the process environment.
    ///
    ///     let port = Environment.get("APP_PORT") ?? 9092
    ///     let isEnabled = Environment.get("FEATURE_IS_ENABLED") ?? false
    ///     let pollInterval: TimeInterval = Environment.get("POLL_INTERVAL") ?? 10
    ///
    /// The above variables would be parsed from the process environment
    /// in a type-safe way using the `LosslessStringConvertible` protocol.
    ///
    /// Default values are provided with nil coalescing in the event the value is
    /// missing from the environment or `LosslessStringConvertible` initialization fails.
    public static func get<T>(_ key: String) -> T? where T: LosslessStringConvertible {
        return get(key).flatMap { T($0) }
    }

    // MARK: Equatable

    /// See `Equatable`
    public static func ==(lhs: Environment, rhs: Environment) -> Bool {
        return lhs.name == rhs.name && lhs.isRelease == rhs.isRelease
    }

    // MARK: Properties

    /// The environment's unique name.
    public let name: String

    /// `true` if this environment is meant for production use cases.
    ///
    /// This usually means reducing logging, disabling debug information, and sometimes
    /// providing warnings about configuration states that are not suitable for production.
    public let isRelease: Bool

    /// The command-line arguments for this `Environment`.
    public var arguments: [String]

    // MARK: Init

    /// Create a new `Environment`.
    public init(name: String, isRelease: Bool, arguments: [String] = CommandLine.arguments) {
        self.name = name
        self.isRelease = isRelease
        self.arguments = arguments
    }
}
