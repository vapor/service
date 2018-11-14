/// A basic `SubContainer` implementation.
public final class BasicSubContainer: SubContainer {
    /// See `SubContainer`.
    public var superContainer: Container

    /// See `Container`.
    public var eventLoop: EventLoop

    /// See `Container`.
    public var serviceCache: ServiceCache

    /// Create a new `BasicSubContainer`.
    public init(super: Container, on worker: Worker) {
        self.superContainer = `super`
        self.eventLoop = worker.eventLoop
        self.serviceCache = .init()
    }
}
