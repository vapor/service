import Foundation

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
        return .init(name: "production")
    }

    /// An environment for developing your application.
    public static var development: Environment {
        return .init(name: "development")
    }

    /// An environment for testing your application.
    public static var testing: Environment {
        return .init(name: "testing")
    }

    /// Creates a custom environment.
    public static func custom(name: String) -> Environment {
        return .init(name: name)
    }

    // MARK: Env

    /// Gets a key from the process environment
    public static func get(_ key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }
    
    // MARK: Equatable

    /// See `Equatable`
    public static func ==(lhs: Environment, rhs: Environment) -> Bool {
        return lhs.name == rhs.name && lhs.isRelease == rhs.isRelease
    }

    /// The current process of the environment.
    public static var process: Process {
        return Process()
    }
    
    // MARK: Properties

    /// The environment's unique name.
    public let name: String

    /// `true` if this environment is meant for production use cases.
    ///
    /// This usually means reducing logging, disabling debug information, and sometimes
    /// providing warnings about configuration states that are not suitable for production.
    public var isRelease: Bool {
        return !_isDebugAssertConfiguration()
    }
    
    /// The command-line arguments for this `Environment`.
    public var arguments: [String]

    // MARK: Init

    /// Create a new `Environment`.
    public init(name: String, arguments: [String] = CommandLine.arguments) {
        self.name = name
        self.arguments = arguments
    }
}
