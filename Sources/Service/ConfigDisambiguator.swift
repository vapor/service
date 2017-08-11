public final class ConfigDisambiguator: Disambiguator {
    private let config: Config

    /// Creates a new ConfigDisambiguator.
    public init(config: Config) {
        self.config = config
    }

    /// If multiple available services conform to the
    /// supplied protocol, you will need to disambiguate in
    /// the App's configuration.
    ///
    /// This can be done using config files:
    ///
    ///     `Config/app.json`
    ///     { "client": "engine" }
    ///
    /// Disambiguation can also be done manually:
    ///
    ///     try config.set("app.client", "engine")
    ///     let drop = try App(config, ...)
    ///
    public func disambiguateSingle<Type>(
        available: [ServiceFactory],
        type: Type.Type,
        for container: Container
        ) throws -> ServiceFactory {
        // generate a readable name from the type for config
        // ex: `ConsoleProtocol` -> 'console'
        let typeName = makeTypeName(Type.self)

        let chosen: ServiceFactory

        guard let disambiguation = config[typeName]?.string else {
            // no dismabiguating configuration was given.
            // we are unable to choose which service to use.
            throw ServiceError.disambiguationRequired(
                key: typeName,
                available: available.flatMap({ $0.serviceName }),
                type: Type.self
            )
        }

        // turn the disambiguated type name into a ServiceType
        // from the available service types.
        let disambiguated: [ServiceFactory] = available.flatMap { service in
            guard disambiguation == service.serviceName else {
                return nil
            }
            return service
        }

        if disambiguated.count > 1 {
            // multiple service types were found with the same name.
            // this is bad.
            throw ServiceError.duplicateServiceName(
                name: disambiguation,
                type: Type.self
            )
        } else if disambiguated.count == 0 {
            // no services were found that matched the supplied name.
            // we are uanble to choose which service to use.
            throw ServiceError.unknownService(
                name: disambiguation,
                available: available.flatMap({ $0.serviceName }),
                type: Type.self
            )
        } else {
            // the desired service was found, use it!
            chosen = disambiguated.first!
        }

        return chosen
    }

    /// Service type names that appear in the `container.json` file
    /// will be return in the results.
    ///
    /// The following example will initialize three service
    /// types matching the names "error", "date", and "file".
    ///
    ///     `Config/app.json`
    ///     { "middleware": ["error", "date", "file"] }
    ///
    /// The ordering from the config array is respected.
    ///
    /// Manually setting config also works.
    ///
    ///     try config.set("container.middleware", [
    ///         "error", "date", "file"
    ///     ])
    ///     let drop = try Application(config, ...)
    ///
    /// Any service instances matching this type will be
    /// appended to the end of the results.
    ///
    public func disambiguateMultiple<Type>(
        available: [ServiceFactory],
        type: Type.Type,
        for container: Container
        ) throws -> [ServiceFactory] {
        // create a readable key name for this service type
        // this will be used in the config
        // for example, `ConsoleProtocol` -> `console`
        var typeName = makeTypeName(Type.self)
        if typeName != "middleware" {
            typeName += "s"
        }

        // get the array of services specified in config
        // for this type.
        // if no services are specified, return only instances.
        guard let chosen = config[typeName]?.array?.flatMap({ $0.string }) else {
            return []
        }

        // loop over chosen service names from config
        // and convert to ServiceTypes from the Services struct.
        return try chosen.map { chosenName in
            // resolve services matching the supplied name
            let resolvedServices: [ServiceFactory] = available.flatMap { availableService in
                guard availableService.serviceName == chosenName else {
                    return nil
                }

                return availableService
            }

            if resolvedServices.count > 1 {
                // multiple services have the same name
                // this is bad.
                throw ServiceError.duplicateServiceName(
                    name: chosenName,
                    type: Type.self
                )
            } else if resolvedServices.count == 0 {
                // no services were found that have this name.
                throw ServiceError.unknownService(
                    name: chosenName,
                    available: available.map({ $0.serviceName }),
                    type: Type.self
                )
            } else {
                // the service they wanted was found!
                return resolvedServices[0]
            }
        }

    }
}

// MARK: Utilities

private var typeNameCache: [String: String] = [:]

fileprivate func makeTypeName<T>(_ any: T.Type) -> String {
    let rawTypeString = "\(T.self)"
    if let cached = typeNameCache[rawTypeString] {
        return cached
    }

    let formattedTypename = rawTypeString
        .replacingOccurrences(of: "Protocol", with: "")
        .replacingOccurrences(of: "Factory", with: "")
        .replacingOccurrences(of: "Renderer", with: "")
        .splitUppercaseCharacters()
        .joined(separator: "-")
        .lowercased()

    typeNameCache[rawTypeString] = formattedTypename
    return formattedTypename
}
