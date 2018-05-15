//
//  EnvironmentConfig.swift
//  Service
//
//  Created by Anthony Castelli on 5/14/18.
//

import Foundation
import Core
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

public protocol EnvironmentConfig: Decodable {
    /// Loads a specific environment config in a given directory.
    /// - parameter environmentConfig: The File name to load.
    /// - parameter directory: The directory to look for the config file in
    /// The format for the config file should match the traditional .env file of `Key=Value`
    /// ```
    /// # Comments are allowed too
    /// DATABASE_URL="http://localhost:5432/database"
    /// ```
    static func load(environmentConfig fileName: String, inDirectory directory: String) throws -> Self
    
    /// Sets the loaded config variables to the environment, allowing you the ability to use the
    /// `Environment.get("")` to fetch the parameters if you need them in other cases
    func setEnvironmentVariables()
}

extension EnvironmentConfig {
    /// Default implementation to load a `.env` configuration in the current working directory.
    /// `let configs = MyConfigs.load()`
    public static func load(environmentConfig fileName: String = ".env", inDirectory directory: String = DirectoryConfig.detect().workDir) throws -> Self {
        let url = URL(fileURLWithPath: DirectoryConfig.detect().workDir).appendingPathComponent(fileName)
        return try EnvironmentDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
    
    /// Default implementation for setting the loaded config vairables to current Environment
    public func setEnvironmentVariables() {
        let mirror = Mirror(reflecting: self)
        for (name, value) in mirror.children {
            // Convert it to a string to sent the environment variable
            setenv(name, "\(value)", 1)
        }
    }
}
