//
//  EnvrionmentDecoder.swift
//  Service
//
//  Created by Anthony Castelli on 5/14/18.
//

import Foundation

internal typealias EnvironmentUnorderedObject = [String: Any]

extension DecodingError {
    public static func typeMismatch(_ type: Any.Type, atPath path: [CodingKey], message: String? = nil) -> DecodingError {
        let pathString = path.map { $0.stringValue }.joined(separator: ".")
        let context = DecodingError.Context(
            codingPath: path,
            debugDescription: message ?? "No \(type) was found at path \(pathString)"
        )
        return Swift.DecodingError.typeMismatch(type, context)
    }
}

public class EnvironmentDecoder {
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let topLevel = try EnvironmentParser.parse(with: data)
        let decoder = try _EnvironmentDecoder(referencing: topLevel, userInfo: self.userInfo)
        return try T(from: decoder)
    }
}

public class _EnvironmentDecoder: Decoder {

    private let container: Any
    public var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    
    init(referencing: Any, codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey: Any]) throws {
        guard codingPath.count < 2 else {
            throw DecodingError.keyNotFound(
                codingPath.last!,
                DecodingError.Context(codingPath: codingPath, debugDescription: "Environment does not support nesting more than 1 level")
            )
        }
        self.container = referencing
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
    
    fileprivate func with<T>(pushedKey key: CodingKey, _ work: () throws -> T) rethrows -> T {
        self.codingPath.append(key)
        let ret: T = try work()
        self.codingPath.removeLast()
        return ret
    }
    
    fileprivate func unboxInt<T>(_ rawValue: Any, as type: T.Type) throws -> T where T: FixedWidthInteger {
        guard let rawValue = rawValue as? String else { throw DecodingError.typeMismatch(T.self, atPath: self.codingPath) }
        if let value = UInt(rawValue) {
            guard let result = T(exactly: value) else {
                throw DecodingError.typeMismatch(T.self, atPath: self.codingPath)
            }
            return result
        } else if let value = Int(rawValue) {
            guard let result = T(exactly: value) else {
                throw DecodingError.typeMismatch(T.self, atPath: self.codingPath)
            }
            return result
        } else {
            throw DecodingError.typeMismatch(T.self, atPath: self.codingPath)
        }
    }
    
    fileprivate func unboxFloat<T>(_ rawValue: Any, as type: T.Type) throws -> T where T: BinaryFloatingPoint {
        guard let rawValue = rawValue as? String else { throw DecodingError.typeMismatch(T.self, atPath: self.codingPath) }
        if let value = Double(rawValue) {
            return T(value)
        } else if let value = Float(rawValue) {
            return T(value)
        } else {
            throw DecodingError.typeMismatch(T.self, atPath: self.codingPath)
        }
    }
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        guard let data = self.container as? EnvironmentUnorderedObject else {
            throw DecodingError.typeMismatch(EnvironmentUnorderedObject.self, atPath: self.codingPath)
        }
        return KeyedDecodingContainer(EnvironmentKeyedDecodingContainer<Key>(referencing: self, wrapping: data))
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DecodingError.typeMismatch([Any].self, atPath: self.codingPath, message: "Arrays are not supported by .env")
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return EnvironmentSingleValueDecodingContainer(referencing: self, wrapping: self.container)
    }
}

/// Keyed container
fileprivate struct EnvironmentKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    typealias Key = K
    
    private let decoder: _EnvironmentDecoder
    private let container: EnvironmentUnorderedObject
    
    public var codingPath: [CodingKey]
    
    public var allKeys: [Key] {
        return self.container.keys.compactMap({ Key(stringValue: $0) })
    }
    
    public func contains(_ key: Key) -> Bool {
        return self.container[key.stringValue] != nil
    }
    
    fileprivate init(referencing: _EnvironmentDecoder, wrapping: EnvironmentUnorderedObject) {
        self.decoder = referencing
        self.container = wrapping
        self.codingPath = self.decoder.codingPath
    }
    
    private func requireKey(_ key: K) throws -> Any {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(
                key,
                DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\").")
            )
        }
        return entry
    }
    
    private func requireType<T>(_ type: T.Type, forKey key: K) throws -> T {
        return try self.decoder.with(pushedKey: key) {
            guard let value = try self.requireKey(key) as? T else {
                throw DecodingError.valueNotFound(
                    type,
                    DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found something else.")
                )
            }
            return value
        }
    }
    
    private func unbox<T>(_ type: T.Type, forKey key: K) throws -> T where T: FixedWidthInteger {
        return try self.decoder.with(pushedKey: key) { try self.decoder.unboxInt(self.requireKey(key), as: type) }
    }
    private func unbox<T>(_ type: T.Type, forKey key: K) throws -> T where T: BinaryFloatingPoint {
        return try self.decoder.with(pushedKey: key) { try self.decoder.unboxFloat(self.requireKey(key), as: type) }
    }
    
    public func decodeNil(forKey key: K) throws -> Bool {
        return try self.decoder.with(pushedKey: key) {
            let rawValue = try self.requireKey(key)
            
            if let value = rawValue as? String, value == "" {
                return true
            }
            return false
        }
    }
    
    public func decode(_ type: Bool.Type, forKey key: K) throws -> Bool     { return try self.requireType(type, forKey: key) }
    public func decode(_ type: Int.Type, forKey key: K) throws -> Int       { return try self.unbox(type, forKey: key) }
    public func decode(_ type: Int8.Type, forKey key: K) throws -> Int8     { return try self.unbox(type, forKey: key) }
    public func decode(_ type: Int16.Type, forKey key: K) throws -> Int16   { return try self.unbox(type, forKey: key) }
    public func decode(_ type: Int32.Type, forKey key: K) throws -> Int32   { return try self.unbox(type, forKey: key) }
    public func decode(_ type: Int64.Type, forKey key: K) throws -> Int64   { return try self.unbox(type, forKey: key) }
    public func decode(_ type: UInt.Type, forKey key: K) throws -> UInt     { return try self.unbox(type, forKey: key) }
    public func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8   { return try self.unbox(type, forKey: key) }
    public func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 { return try self.unbox(type, forKey: key) }
    public func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 { return try self.unbox(type, forKey: key) }
    public func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 { return try self.unbox(type, forKey: key) }
    public func decode(_ type: Float.Type, forKey key: K) throws -> Float   { return try self.unbox(type, forKey: key) }
    public func decode(_ type: Double.Type, forKey key: K) throws -> Double { return try self.unbox(type, forKey: key) }
    public func decode(_ type: String.Type, forKey key: K) throws -> String { return try self.requireType(type, forKey: key) }
    public func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        return try self.decoder.with(pushedKey: key) {
            let value = try self.requireKey(key)
            return try T(from: _EnvironmentDecoder(
                referencing: value,
                codingPath: self.decoder.codingPath,
                userInfo: self.decoder.userInfo
            ))
        }
    }
    
    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let value = try self.requireType(EnvironmentUnorderedObject.self, forKey: key)
        return KeyedDecodingContainer(EnvironmentKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: value))
    }
    
    public func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        throw DecodingError.typeMismatch([Any].self, atPath: self.codingPath, message: "Arrays are not supported by Vapor Environment Decoder")
    }
    
    public func superDecoder() throws -> Decoder {
        return try _EnvironmentDecoder(
            referencing: container,
            codingPath: self.decoder.codingPath,
            userInfo: self.decoder.userInfo
        )
    }
    
    public func superDecoder(forKey key: K) throws -> Decoder {
        return try self.decoder.with(pushedKey: key) { try superDecoder() }
    }
}

fileprivate struct EnvironmentSingleValueDecodingContainer: SingleValueDecodingContainer {

    public var codingPath: [CodingKey]
    
    private let decoder: _EnvironmentDecoder
    private let container: Any
    
    fileprivate init(referencing: _EnvironmentDecoder, wrapping: Any) {
        self.decoder = referencing
        self.container = wrapping
        self.codingPath = decoder.codingPath
    }
    
    private func requireType<T>(_ type: T.Type) throws -> T {
        guard let value = container as? T else {
            throw DecodingError.valueNotFound(
                type,
                DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found something else.")
            )
        }
        return value
    }
    
    public func decodeNil() -> Bool {
        if let value = container as? String, value == "" {
            return true
        }
        return false
    }
    
    public func decode(_ type: Bool.Type) throws -> Bool     { return try self.requireType(type) }
    public func decode(_ type: Int.Type) throws -> Int       { return try self.decoder.unboxInt(container, as: type) }
    public func decode(_ type: Int8.Type) throws -> Int8     { return try self.decoder.unboxInt(container, as: type) }
    public func decode(_ type: Int16.Type) throws -> Int16   { return try self.decoder.unboxInt(container, as: type) }
    public func decode(_ type: Int32.Type) throws -> Int32   { return try self.decoder.unboxInt(container, as: type) }
    public func decode(_ type: Int64.Type) throws -> Int64   { return try self.decoder.unboxInt(container, as: type) }
    public func decode(_ type: UInt.Type) throws -> UInt     { return try self.decoder.unboxInt(container, as: type) }
    public func decode(_ type: UInt8.Type) throws -> UInt8   { return try self.decoder.unboxInt(container, as: type) }
    public func decode(_ type: UInt16.Type) throws -> UInt16 { return try self.decoder.unboxInt(container, as: type) }
    public func decode(_ type: UInt32.Type) throws -> UInt32 { return try self.decoder.unboxInt(container, as: type) }
    public func decode(_ type: UInt64.Type) throws -> UInt64 { return try self.decoder.unboxInt(container, as: type) }
    public func decode(_ type: Float.Type) throws -> Float   { return try self.decoder.unboxFloat(container, as: type) }
    public func decode(_ type: Double.Type) throws -> Double { return try self.decoder.unboxFloat(container, as: type) }
    public func decode(_ type: String.Type) throws -> String { return try self.requireType(type) }
    
    public func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try T(from: _EnvironmentDecoder(
            referencing: container,
            codingPath: self.decoder.codingPath,
            userInfo: self.decoder.userInfo
        ))
    }
}
