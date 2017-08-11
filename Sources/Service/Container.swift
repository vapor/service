import Core

public protocol Container: Extendable {
    var disambiguator: Disambiguator { get }
    var environment: Environment { get }
    var services: Services { get }
}
