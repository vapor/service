import NIO

/// A basic `Container` implementation.
///
/// This does not boot any providers and is mostly used for testing.
public final class BasicContainer: Container {
    /// See `Container.`
    public let environment: Environment

    /// See `Container.`
    public let services: Services

    /// See `Container.`
    public let eventLoopGroup: EventLoopGroup

    /// Create a new `BasicContainer`.
    public init(environment: Environment, services: Services, on eventLoopGroup: EventLoopGroup) {
        self.environment = environment
        self.services = services
        self.eventLoopGroup = eventLoopGroup
    }
}
