public enum Environment {
    case production
    case development
    case testing
    case custom(String)
}

extension Environment {
    public init(string: String) {
        switch string {
        case "prod", "production":
            self = .production
        case "dev", "development":
            self = .development
        case "test", "testing":
            self = .testing
        default:
            self = .custom(string)
        }
    }
}
