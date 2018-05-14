
import Core
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

extension Environment {
    /// Loads the ".env" and the ".env.environment" files if they exist
    /// Both a generic .env file and an environment specific file are loaded.
    /// This allows you to set custom credentials to specific environments such as
    /// production, testing, and development.
    /// If you use custom environments, those will also be loaded.
    public func load() {
        // Load the default one
        self.load(environment: ".env")
        
        // Load any environment specific ones next
        self.load(environment: ".env.\(self.name)")
    }
    
    /// Loads the specific env file and sets the appropiate environment variables
    /// Parse the contents of the .env file into a readable key/value
    /// - parameter environment: The filename of the .env file to load. i.e. `.env`.
    /// Note: The .env files must be loaced in the root directory.
    public func load(environment fileName: String) {
        // Create the file path
        let url = URL(fileURLWithPath: DirectoryConfig.detect().workDir).appendingPathComponent(fileName)
        
        // Read the contents of the file
        guard let environmentVariables = try? String(contentsOf: url, encoding: .utf8) else { return }
        
        // Loop through all the key/values and set the environment variables
        self.parse(content: environmentVariables).forEach { (key, value) in
            setenv(key, value, 1)
        }
    }
    
    /// Parse the contents of the .env file into a readable key/value
    /// - parameter content: The .env string. This can be multiples lines. i.e. `"USERNAME="Vapor"`
    /// - returns: Returns a Dictionary of Key/Value strings.
    /// NOTE: The content must be formatted in a Key=Value format. 
    func parse(content: String) -> [String : String] {
        let pattern = "(\\w+)=(?:\"([:<>;~=\\[\\]\\w\\s/?(\\\\\")!@#$%^&*(){},`'-\\.\\+\\|]+)\"|([:<>;~=\\[\\]\\w/?!@#$%^&*(){},`'-\\.\\+\\|]+)[\\s\\n\\r]*)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [:] }
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
        
        // Reduce everything into a single dictionary
        return matches.reduce([:]) { result, match in
            var result = result
            
            // We should alwys have 4 returned ranges, if not, then we have an issue
            if match.numberOfRanges == 4 {
                
                // Grab the 3 range types
                let keyRange = Range(match.range(at: 1), in: content)
                let quotedValueRange = Range(match.range(at: 2), in: content)
                let nonQuotedValueRange = Range(match.range(at: 3), in: content)
                
                // Check if the value is quoted or unquoted
                if let keyRange = keyRange, let quotedValueRange = quotedValueRange {
                    let key = String(content[keyRange])
                    let value = String(content[quotedValueRange])
                    result[key] = value
                } else if let keyRange = keyRange, let nonQuotedValueRange = nonQuotedValueRange {
                    let key = String(content[keyRange])
                    let value = String(content[nonQuotedValueRange])
                    result[key] = value
                }
            }
            return result
        }
    }
}
