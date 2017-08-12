import XCTest
import Service

class ConfigTests: XCTestCase {
    /// Tests that BCryptConfig can be added as an instance
    func testBCryptConfig() throws {
        var services = Services()
        services.register(BCryptHasher.self)

        let bcryptConfig = BCryptConfig(cost: 4)
        services.register(bcryptConfig, name: "bcrypt")

        let container = try TestContainer(
            environment: .production,
            services: services
        )

        let hasher = try container.make(Hasher.self)
        XCTAssertEqual(hasher.hash("foo"), "$2y:4:foo")
    }

    /// Tests BCryptConfig can be added as a ServiceType
    func testBCryptConfigType() throws {
        var services = Services()
        services.register(BCryptHasher.self)
        services.register(BCryptConfig.self)

        let container = try TestContainer(
            environment: .production,
            services: services
        )

        let hasher = try container.make(Hasher.self)
        XCTAssertEqual(hasher.hash("foo"), "$2y:12:foo")
    }

    /// Tests lack of BCryptConfig results correct error message
    func testBCryptConfigError() throws {
        var services = Services()
        services.register(BCryptHasher.self)

        let container = try TestContainer(
            environment: .production,
            services: services
        )

        do {
            _ = try container.make(Hasher.self)
            XCTFail("No error thrown")
        } catch let error as ServiceError {
            XCTAssertEqual(error.reason, "No services are available for 'BCryptConfig'")
        }
    }

    /// Tests too many BCryptConfigs registered
    func testBCryptConfigTooManyError() throws {
        var services = Services()
        services.register(BCryptHasher.self)

        let bcryptConfig4 = BCryptConfig(cost: 4)
        services.register(bcryptConfig4, name: "bcrypt-4")
        let bcryptConfig5 = BCryptConfig(cost: 5)
        services.register(bcryptConfig5, name: "bcrypt-5")

        let container = try TestContainer(
            environment: .production,
            services: services
        )

        _ = try container.make(Hasher.self)
    }

    static let allTests = [
        ("testBCryptConfig", testBCryptConfig),
        ("testBCryptConfigType", testBCryptConfigType),
        ("testBCryptConfigError", testBCryptConfigError),
        ("testBCryptConfigTooManyError", testBCryptConfigTooManyError),
    ]
}
