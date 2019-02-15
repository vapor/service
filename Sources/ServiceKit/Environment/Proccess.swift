import Foundation

extension Environment {
    
    /// The process information of an environment. Wraps `ProcessInto.processInfo`.
    @dynamicMemberLookup public struct Process {
        
        /// The process information of the environment.
        public let info: ProcessInfo
        
        /// Creates a new `Process` wrapper for process information.
        ///
        /// - parameter info: The process info that the wrapper accesses. Defaults to `ProcessInto.processInfo`.
        public init(info: ProcessInfo = .processInfo) {
            self.info = info
        }
        
        /// Gets a key from the proccess environment
        ///
        ///     Environment.process.DATABASE_PORT = 3306
        ///     Environment.process.DATABASE_PORT // 3306
        public subscript<T>(dynamicMember member: String) -> T? where T: LosslessStringConvertible {
            get {
                guard let raw = self.info.environment[member], let value = T(raw) else {
                    return nil
                }
                
                return value
            }
            set (value) {
                if let raw = value?.description {
                    setenv(member, value?.description ?? nil, 1)
                } else {
                    unsetenv(member)
                }
            }
        }
    }
}
