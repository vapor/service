extension Services {
    /// Adds an initialized provider
    public mutating func register<P: Provider & ConfigInitializable>(_ type: P.Type, using config: Config) throws {
        let p = try P(config: config)
        try register(p)
    }
}
