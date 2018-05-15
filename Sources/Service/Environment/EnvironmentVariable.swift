//
//  EnvironmentToken.swift
//  Service
//
//  Created by Anthony Castelli on 5/14/18.
//

import Foundation

// This extension allows us to directly question whether a given Character (e.g.
// a full-blown grapheme cluster) is a member of a CharacterSet. This isn't
// really correct for surrogate pairs especially, since CharacterSet only deals
// in UnicodeScalars (e.g. individual code points), but it's close enough.
//
// There has to be a more efficient way to do this - is this fast if it's
// "known" that there's only one scalar in a given grapheme cluster?
extension CharacterSet {
    func contains(_ member: Character) -> Bool {
        for s in member.unicodeScalars {
            if !contains(s) {
                return false
            }
        }
        return true
    }
}

/// A raw Environment token
internal enum Token: Equatable {
    case signedInteger(Substring)
    case unsignedInteger(Substring)
    case decimal(Substring)
    case bareFalse(Substring) // "off", "false", or "no"
    case bareTrue(Substring) // "on", "true", or "yes"
    case text(Substring) // non-whitespace
    
    static func ==(lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.signedInteger(let l), .signedInteger(let r)): return l == r
        case (.unsignedInteger(let l), .unsignedInteger(let r)):return l == r
        case (.decimal(let l), .decimal(let r)): return l == r
        case (.bareFalse(let l), .bareFalse(let r)): return l == r
        case (.bareTrue(let l), .bareTrue(let r)): return l == r
        case (.text(let l), .text(let r)): return l == r
        default: return false
        }
    }
}

/// A raw Enviroment token and information on where in the data it was found
internal struct EnvironmentVariable: Equatable {
    let position: String.Index
    let line: UInt
    let data: Token
    
    static func ==(lhs: EnvironmentVariable, rhs: EnvironmentVariable) -> Bool {
        return lhs.position == rhs.position && lhs.line == rhs.line && lhs.data == rhs.data
    }
}

/// Tokenizer
internal struct EnvironmentTokenizer {
    // - MARK: "External" interface
    
    init(_ text: String) {
        self.text = text
        self.loc = text.startIndex
        self.line = 1
    }
    
    mutating func nextToken() throws -> EnvironmentVariable? {
        return try self.parseToken()
    }
    
    static func tokenize(_ text: String) throws -> [EnvironmentVariable] {
        var tokens: [EnvironmentVariable] = []
        var tokenizer = EnvironmentTokenizer(text)
        
        while let token = try tokenizer.nextToken() {
            tokens.append(token)
        }
        return tokens
    }
    
    static func tokenize(_ text: String, work: (EnvironmentTokenizer, EnvironmentVariable) throws -> Void) throws {
        var tokenizer = EnvironmentTokenizer(text)
        
        while let token = try tokenizer.nextToken() {
            try work(tokenizer, token)
        }
    }
    
    // These sets are made available for use by the writer
    internal static let identifier = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-")), notIdentifier = identifier.inverted
    internal static let whitespace = CharacterSet.whitespaces, notWhitespace = whitespace.inverted
    internal static let newline = CharacterSet.newlines
    internal static let doubleQuoteStops = CharacterSet(charactersIn: "\"\\").union(CharacterSet.newlines)
    internal static let singleQuoteStops = CharacterSet(charactersIn: "'\\").union(CharacterSet.newlines)
    internal static let significant = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "[]="))
    
    // - MARK: Guts
    
    var text: String
    var loc: String.Index
    var line: UInt
    
    /// Are we currently at the string EOF?
    func eof() -> Bool { return self.loc >= self.end() }
    
    /// Convenience to get String.endIndex on NSString
    func end() -> String.Index { return text.endIndex }
    
    /// String.index(_, offsetBy:, limitedBy:) that returns the limit instead of
    /// nil if it's reached.
    func minIdx(for adv: Int) -> String.Index {
        return self.text.index(self.loc, offsetBy: adv, limitedBy: self.end()) ?? self.end()
    }
    
    /// Find the next character in string which is in the given `CharacterSet`,
    /// optionally skipping past that character while returning it and always
    /// returning the text which was skipped over.
    func nextOf(_ set: CharacterSet, skipping: Bool) -> (loc: String.Index, char: Character?, skipped: Substring) {
        let place = text.rangeOfCharacter(from: set, options: [], range: loc..<end())
        
        if let p = place {
            return (
                loc: skipping ? text.index(after: p.lowerBound) : p.lowerBound,
                char: text[p.lowerBound],
                skipped: text[loc..<p.lowerBound]
            )
        } else {
            return (loc: end(), char: nil, skipped: text[loc..<end()])
        }
    }
    
    /// Just an equality comparison which takes a range to search
    func matchAgainst(_ str: String, options cmpOpts: String.CompareOptions = []) -> Bool {
        return text.compare(str, options: cmpOpts, range: loc..<minIdx(for: str.count), locale: nil) == .orderedSame
    }
    
    /// Sneak peek at what the next character is
    func peekChar() -> Character {
        return text[loc]
    }
    
    /// Get the next character and advance past it
    mutating func nextChar() -> Character {
        let c = text[loc]
        loc = text.index(after: loc)
        return c
    }
    
    /// Read a single or double quoted string, interpreting \ escapes as needed
    mutating func nextQuotedString() throws -> Token {
        let type = nextChar()
        
        assert(type == "\"" || type == "'", "Quoted string got called when it wasn't one")
        
        var tok = ""
        
        while !self.eof() {
            let nextStop = self.nextOf(type == "\"" ? EnvironmentTokenizer.doubleQuoteStops : EnvironmentTokenizer.singleQuoteStops, skipping: true)
            
            switch nextStop.char {
            case .none:
                throw EnvironmentSerialization.SerializationError.unterminatedString(line: self.line)
            case .some(let char) where char == type:
                self.loc = nextStop.loc
                return .quotedString(tok + nextStop.skipped, doubleQuoted: type == "\"")
            case .some(let char) where char == "\\":
                self.loc = nextStop.loc
                tok += nextStop.skipped
                if self.eof() {
                    throw EnvironmentSerialization.SerializationError.unterminatedString(line: self.line)
                }
                let nextc = self.nextChar()
                switch nextc {
                case "\\": tok += "\\"
                case type: tok.append(type)
                case _ where EnvironmentTokenizer.newline.contains(nextc): throw EnvironmentSerialization.SerializationError.unterminatedString(line: line)
                default: tok.append("\\"); tok.append(nextc)
                }
            case .some: // only newlines left in the set, we'll just assume this
                throw EnvironmentSerialization.SerializationError.unterminatedString(line: line)
            }
        }
        // Is it actually possible to get here?
        throw EnvironmentSerialization.SerializationError.unterminatedString(line: self.line) // EOF
    }
    
    /// Read a newline, treating a \r\n sequence as a single newline
    mutating func nextNewline() -> Token {
        assert(EnvironmentTokenizer.newline.contains(peekChar()), "Newline get called when it wasn't one")
        
        let nl = self.nextChar()
        
        if nl == "\r" && self.peekChar() == "\n" {
            _ = self.nextChar() // Skip \r\n-style newline
        }
        return .newline
    }
    
    /// Read some whitespace
    mutating func nextWhitespace() -> Token {
        assert(EnvironmentTokenizer.whitespace.contains(peekChar()), "Whitespace got called when it wasn't")
        
        let nextStop = self.nextOf(EnvironmentTokenizer.notWhitespace, skipping: false)
        
        assert(nextStop.skipped.count > 0, "Can't skip zero if next character was in the set")
        self.loc = nextStop.loc
        return .whitespace(nextStop.skipped)
    }
    
    /// Read text data, interpreting boolean and numeric values if those were
    /// respectively requested, and deciding whether the text qualifies as an
    /// identifier.
    mutating func nextText() -> Token {
        assert(EnvironmentTokenizer.significant.inverted.contains(peekChar()), "Text got called but something more significant is available")
        
        let nextStop = self.nextOf(EnvironmentTokenizer.significant, skipping: false)
        
        assert(nextStop.skipped.count > 0, "Can't skip zero if next character was in the set")
        self.loc = nextStop.loc
        
        // Treat boolean names specially
        if nextStop.skipped.compare("true", options: .caseInsensitive, range: nil, locale: nil) == .orderedSame ||
            nextStop.skipped.compare("yes", options: .caseInsensitive, range: nil, locale: nil) == .orderedSame ||
            nextStop.skipped.compare("on", options: .caseInsensitive, range: nil, locale: nil) == .orderedSame {
            return .bareTrue(nextStop.skipped)
        }
        if nextStop.skipped.compare("false", options: .caseInsensitive, range: nil, locale: nil) == .orderedSame ||
            nextStop.skipped.compare("no", options: .caseInsensitive, range: nil, locale: nil) == .orderedSame ||
            nextStop.skipped.compare("off", options: .caseInsensitive, range: nil, locale: nil) == .orderedSame {
            return .bareFalse(nextStop.skipped)
        }
        // Interpret integer and floating-point values
        if let _ = UInt(nextStop.skipped) {
            return .unsignedInteger(nextStop.skipped)
        }
        if let _ = Int(nextStop.skipped) {
            return .signedInteger(nextStop.skipped)
        }
        if let _ = Double(nextStop.skipped) {
            return .decimal(nextStop.skipped)
        }
        
        // If there aren't any non-identifier characters, it's an identifier
        if nextStop.skipped.rangeOfCharacter(from: EnvironmentTokenizer.notIdentifier) == nil {
            return .identifier(nextStop.skipped)
        }
        
        // Otherwise it's text
        return .text(nextStop.skipped)
    }
    
    /// Parse the next token, returning nil on EOF
    mutating func parseToken() throws -> EnvironmentVariable? {
        // Quit if we hit the end
        guard !self.eof() else { return nil }
        
        // Save the token start and check out the next character
        let tokStart = self.loc
        let character = self.peekChar()
        
        switch character {
            
        // Comment
        case "#":
            return EnvironmentVariable(position: tokStart, line: self.line, data: .commentMarker(String(self.nextChar())))
            
        // Key/value separator
        case "=":
            _ = self.nextChar()
            return EnvironmentVariable(position: tokStart, line: self.line, data: .separator)
            
        // Quoted string
        case "\"", "'":
            return EnvironmentVariable(position: tokStart, line: self.line, data: try self.nextQuotedString())
            
        // Whitespace
        case _ where EnvironmentTokenizer.whitespace.contains(character):
            return EnvironmentVariable(position: tokStart, line: self.line, data: self.nextWhitespace())
            
        // Newline
        case _ where EnvironmentTokenizer.newline.contains(character):
            self.line += 1 // Do this here so returned values are accurate
            return EnvironmentVariable(position: tokStart, line: self.line - 1, data: self.nextNewline())
            
        // Boolean, number, identifer, or text
        default: return EnvironmentVariable(position: tokStart, line: self.line, data: self.nextText())
        }
    }
}
