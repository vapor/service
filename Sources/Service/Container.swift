import Core

public protocol Container: Extendable {
    static var configKey: String { get }
    var config: Config { get }
    var environment: Environment { get }
    var services: Services { get }
}
