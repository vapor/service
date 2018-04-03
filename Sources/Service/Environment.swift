/// The environment the application is running in, i.e., production, dev, etc.
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

    // MARK: Equatable

    /// See `Equatable`
    public static func ==(lhs: Environment, rhs: Environment) -> Bool {
        return lhs.name == rhs.name && lhs.isRelease == rhs.isRelease
    }

    // MARK: Properties

    /// The environment name.
    public let name: String

    /// `true` if this environment is production.
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
