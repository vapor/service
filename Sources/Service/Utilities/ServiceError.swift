import Debugging

/// An error using Services.
public struct ServiceError: Debuggable {
    /// See `Debuggable`.
    public static let readableName = "Service Error"

    /// See `Debuggable`.
    public let identifier: String

    /// See `Debuggable`.
    public var reason: String

    /// See `Debuggable`.
    public var sourceLocation: SourceLocation?

    /// See `Debuggable`.
    public var stackTrace: [String]

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
        self.sourceLocation = SourceLocation(file: file, function: function, line: line, column: column, range: nil)
        self.stackTrace = ServiceError.makeStackTrace()
        self.possibleCauses = possibleCauses
        self.suggestedFixes = suggestedFixes
    }
}
