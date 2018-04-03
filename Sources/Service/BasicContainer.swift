/// A basic `Container` implementation.
///
/// This does not boot any providers and is mostly used for testing.
public final class BasicContainer: Container {
    /// See `Container.`
    public var config: Config

    /// See `Container.`
    public var environment: Environment

    /// See `Container.`
    public var services: Services

    /// See `Container.`
    public var serviceCache: ServiceCache

    /// See `Container.`
    public var eventLoop: EventLoop

    /// Create a new `BasicContainer`.
    public init(config: Config, environment: Environment, services: Services, on worker: Worker) {
        self.config = config
        self.environment = environment
        self.services = services
        self.serviceCache = .init()
        self.eventLoop = worker.eventLoop
    }
}
