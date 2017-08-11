import XCTest
import Service

class ConfigTests: XCTestCase {
    /// Tests that BCryptConfig can be added as an instance
    func testBCryptConfig() throws {
        let config: Config = ["foo": "bar"]


        var services = Services()
        services.register(BCryptHasher.self)

        let bcryptConfig = BCryptConfig(cost: 4)
        services.register(bcryptConfig, name: "bcrypt")

        let container = TestContainer(
            config: config,
            environment: .production,
            services: services
        )

        let hasher = try container.make(Hasher.self)
        XCTAssertEqual(hasher.hash("foo"), "$2y:4:foo")
    }

    /// Tests BCryptConfig can be added as a ServiceType
    func testBCryptConfigType() throws {
        let config: Config = ["foo": "bar"]

        var services = Services()
        services.register(BCryptHasher.self)
        services.register(BCryptConfig.self)

        let container = TestContainer(
            config: config,
            environment: .production,
            services: services
        )

        let hasher = try container.make(Hasher.self)
        XCTAssertEqual(hasher.hash("foo"), "$2y:12:foo")
    }

    /// Tests lack of BCryptConfig results correct error message
    func testBCryptConfigError() throws {
        let config: Config = ["foo": "bar"]

        var services = Services()
        services.register(BCryptHasher.self)

        let container = TestContainer(
            config: config,
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

    /// Tests legacy method of configuration using JSON files
    func testBCryptConfigLegacy() throws {
        let config: Config = [
            "bcrypt": [
                "cost": 42
            ]
        ]

        var services = Services()
        services.register(BCryptHasher.self)

        let bcryptConfig = try BCryptConfig(config: config)
        services.register(bcryptConfig, name: "bcrypt")

        let container = TestContainer(
            config: config,
            services: services
        )

        let hasher = try container.make(Hasher.self)
        XCTAssertEqual(hasher.hash("foo"), "$2y:42:foo")
    }

    static let allTests = [
        ("testBCryptConfig", testBCryptConfig),
        ("testBCryptConfigType", testBCryptConfigType),
        ("testBCryptConfigError", testBCryptConfigError),
        ("testBCryptConfigLegacy", testBCryptConfigLegacy),
    ]
}
