import Foundation

/// One key press as the keymap sees it: a printed character (case carries
/// shift, so `G` is not `shift-g`) or a named key, plus modifiers.
public struct Key: Sendable, Hashable, CustomStringConvertible {
    public struct Modifiers: OptionSet, Sendable, Hashable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let shift = Modifiers(rawValue: 1)
        public static let control = Modifiers(rawValue: 2)
        public static let option = Modifiers(rawValue: 4)
        public static let command = Modifiers(rawValue: 8)
    }

    public static let names: Set<String> = [
        "space", "enter", "tab", "esc", "backspace", "delete",
        "left", "right", "up", "down", "home", "end", "pageup", "pagedown",
        "hash", "lt", "gt",
        "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
    ]

    private static let modifierNames: [(String, Modifiers)] = [
        ("cmd", .command),
        ("ctrl", .control),
        ("alt", .option),
        ("shift", .shift),
    ]

    /// A single character, or a name from `names`.
    public let base: String
    public let modifiers: Modifiers

    public init(
        _ base: String,
        modifiers: Modifiers = []
    ) {
        // Aliases for characters the file grammar cannot hold literally.
        switch base {
        case "space":
            self.base = " "
        case "hash":
            self.base = "#"
        case "lt":
            self.base = "<"
        case "gt":
            self.base = ">"
        default:
            self.base = base
        }
        // Shift is already in a printed character's case.
        self.modifiers = self.base.count == 1 && self.base != " " ? modifiers.subtracting(.shift) : modifiers
    }

    public var isDigit: Bool { modifiers.isEmpty && base.count == 1 && base.first!.isASCII && base.first!.isNumber }

    public var description: String {
        var parts = Self.modifierNames.filter { modifiers.contains($0.1) }.map(\.0)
        switch base {
        case " ":
            parts.append("space")
        case "#":
            parts.append("hash")
        default:
            parts.append(base)
        }
        let text = parts.joined(separator: "-")
        return text.count == 1 ? text : "<\(text)>"
    }

    public enum ParseError: Error, Equatable, CustomStringConvertible {
        case empty
        case badKey(String)

        public var description: String {
            switch self {
            case .empty:
                return "no keys"
            case .badKey(let text):
                return "bad key '\(text)'"
            }
        }
    }

    /// Parses one named key with optional modifiers: `space`, `cmd-n`,
    /// `ctrl-shift-left`, or a single character with modifiers (`ctrl-d`).
    public static func parseNamed(_ text: String) throws(ParseError) -> Key {
        var rest = Substring(text)
        var modifiers: Modifiers = []
        var matched = true
        while matched {
            matched = false
            for (name, modifier) in modifierNames where rest.lowercased().hasPrefix(name + "-") && rest.count > name.count + 1 {
                modifiers.insert(modifier)
                rest = rest.dropFirst(name.count + 1)
                matched = true
            }
        }
        let base = String(rest)
        if base.count == 1 {
            return Key(base, modifiers: modifiers)
        }
        guard names.contains(base.lowercased()) else {
            throw .badKey(text)
        }
        return Key(base.lowercased(), modifiers: modifiers)
    }

    /// Parses a keymap key token into a sequence. A whole token that is a
    /// named key (`space`, `cmd-n`) is that key; otherwise each character is
    /// a key and `<name>` inserts a named one (`g<space>`).
    public static func parseSequence(_ token: String) throws(ParseError) -> [Key] {
        guard !token.isEmpty else {
            throw .empty
        }
        if token.count > 1, !token.contains("<"), let key = try? parseNamed(token) {
            return [key]
        }
        var keys: [Key] = []
        var index = token.startIndex
        while index < token.endIndex {
            let character = token[index]
            if character == "<", let close = token[index...].firstIndex(of: ">"), close > token.index(after: index) {
                keys.append(try parseNamed(String(token[token.index(after: index)..<close])))
                index = token.index(after: close)
            } else {
                keys.append(Key(String(character)))
                index = token.index(after: index)
            }
        }
        return keys
    }
}
