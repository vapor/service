//
//  EnvironmentParser.swift
//  Service
//
//  Created by Anthony Castelli on 5/14/18.
//

import Foundation

public enum ParseError: Error {
    /// The data could not be interpreted according to the given encoding
    case encodingError
}

public class EnvironmentParser {
    
    var result: EnvironmentUnorderedObject = [:]
    
    private class func detectUnicodeEncoding(_ bytes: UnsafePointer<UInt8>, length: Int) -> (String.Encoding, skipLength: Int) {
        if length >= 2 {
            switch (bytes[0], bytes[1]) {
            case (0xEF, 0xBB):
                if length >= 3 && bytes[2] == 0xBF {
                    return (.utf8, 3)
                }
            case (0x00, 0x00):
                if length >= 4 && bytes[2] == 0xFE && bytes[3] == 0xFF {
                    return (.utf32BigEndian, 4)
                }
            case (0xFF, 0xFE):
                if length >= 4 && bytes[2] == 0x00 && bytes[3] == 0x00 {
                    return (.utf32LittleEndian, 4)
                }
                return (.utf16LittleEndian, 2)
            case (0xFE, 0xFF):
                return (.utf16BigEndian, 2)
            default:
                break
            }
        }
        if length >= 4 {
            switch (bytes[0], bytes[1], bytes[2], bytes[3]) {
            case (0, 0, 0, _):
                return (.utf32BigEndian, 0)
            case (_, 0, 0, 0):
                return (.utf32LittleEndian, 0)
            case (0, _, 0, _):
                return (.utf16BigEndian, 0)
            case (_, 0, _, 0):
                return (.utf16LittleEndian, 0)
            default:
                break
            }
        } else if length >= 2 {
            switch (bytes[0], bytes[1]) {
            case (0, _):
                return (.utf16BigEndian, 0)
            case (_, 0):
                return (.utf16LittleEndian, 0)
            default:
                break
            }
        }
        return (.utf8, 0)
    }

    public class func parse(with data: Data, encoding enc: String.Encoding? = nil) throws -> [String: Any] {
        return try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> [String: Any] in
            let encoding = enc != nil ? (enc!, skipLength: 0) : EnvironmentParser.detectUnicodeEncoding(bytes, length: data.count)
            let buffer = UnsafeBufferPointer<UInt8>(start: bytes.advanced(by: encoding.skipLength), count: data.count - encoding.skipLength)
            guard let rawText = String(bytes: buffer, encoding: encoding.0) else { throw ParseError.encodingError }
            return try EnvironmentParser.parse(rawText) as [String : Any]
        }
    }
    
    static func parse(_ text: String) throws -> EnvironmentUnorderedObject {
        let parser = try EnvironmentParser(content: text)
        return parser.result
    }
    
    private init(content: String) throws {
        let pattern = "(\\w+)=(?:\"([:<>;~=\\[\\]\\w\\s/?(\\\\\")!@#$%^&*(){},`'-\\.\\+\\|]+)\"|([:<>;~=\\[\\]\\w/?!@#$%^&*(){},`'-\\.\\+\\|]+)[\\s\\n\\r]*)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { throw ParseError.encodingError }
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
        
        // Reduce everything into a single dictionary
        let allResults = matches.reduce([:]) { result, match in
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
        
        for result in allResults {
            try self.parse(result)
        }
    }
    
    internal func parse(_ result: (AnyHashable, Any)) throws {
        guard let key = result.0 as? String else { throw ParseError.encodingError }
        let value = result.1

        // Bools
        if let value = value as? String, ["on", "true", "yes"].contains(value) { self.setValue(true, forKey: key) }
        else if let value = value as? String, ["off", "false", "no"].contains(value) { self.setValue(false, forKey: key) }
        
        // Everything else
        else { self.setValue(value, forKey: key) }
    }
    
    internal func setValue(_ value: Any, forKey key: String) {
        self.result[key] = value
    }
}

