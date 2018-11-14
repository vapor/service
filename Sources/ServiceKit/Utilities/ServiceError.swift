#warning("error enum")
/// An error using Services.
public struct ServiceError: Error {
    /// See `Debuggable`.
    public static let readableName = "Service Error"

    /// See `Debuggable`.
    public let identifier: String

    /// See `Debuggable`.
    public var reason: String

    /// See `Debuggable`.
    public var possibleCauses: [String]

    /// See `Debuggable`.
    public var suggestedFixes: [String]

    /// Creates anew `ServiceError`.
    public init(
        identifier: String,
        reason: String,
        possibleCauses: [String] = [],
        suggestedFixes: [String] = [],
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.identifier = identifier
        self.reason = reason
        self.possibleCauses = possibleCauses
        self.suggestedFixes = suggestedFixes
    }
}
