import Foundation

/// The environment the application is running in, i.e., production, dev, etc.
public struct Environment {
    /// The environment name.
    public let name: String

    /// `true` if this environment is production.
    public let isRelease: Bool

    /// Create a new environment.
    /// Use the static helper methods.
    internal init(name: String, isRelease: Bool) {
        self.name = name
        self.isRelease = isRelease
    }
}

/// MARK: Default

extension Environment {
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
}

extension Environment: Equatable {
    public static func ==(lhs: Environment, rhs: Environment) -> Bool {
        return lhs.name == rhs.name && lhs.isRelease == rhs.isRelease
    }
}

extension Environment {
    /// Gets a key from the process environment
    public static func get(_ key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }
    
    /// Gets a key from the process environment with default value
    public static func get(_ key: String, default defaultValue: String) -> String {
        return get(key) ?? defaultValue
    }
}
