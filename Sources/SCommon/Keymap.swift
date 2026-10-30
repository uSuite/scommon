import Foundation

/// The command vocabulary of an app, as its keymap file writes it.
public protocol KeymapCommand: Sendable, Hashable {
    /// Parses `name [args]`; the error's description is shown to the user.
    static func parse(_ text: String) throws -> Self
}

/// A command with its vim count prefix (`5n` is next with count 5).
public struct Invocation<C: KeymapCommand>: Sendable, Equatable {
    public let command: C
    public let count: Int?

    public init(
        _ command: C,
        count: Int? = nil
    ) {
        self.command = command
        self.count = count
    }

    public var times: Int { max(1, count ?? 1) }
}

/// Bindings from key sequences to an app's commands, read from its keymap
/// file: one `<keys> <command> [args]` per line, the grammar of
/// `KeyValueParser` and `Key`. `<keys> nop` in a file laid over the
/// defaults removes that default.
public struct Keymap<C: KeymapCommand>: Sendable, Equatable {
    public typealias Issue = LineIssue

    public struct Binding: Sendable, Equatable {
        public let keys: [Key]
        public let command: C
        public let text: String

        public init(
            keys: [Key],
            command: C,
            text: String
        ) {
            self.keys = keys
            self.command = command
            self.text = text
        }
    }

    /// The command word that unbinds instead of binding.
    public static var unbindWord: String { "nop" }

    /// In file order; a later line for the same keys replaces the earlier one.
    public private(set) var bindings: [Binding] = []

    public init(bindings: [Binding] = []) {
        for binding in bindings {
            add(binding)
        }
    }

    public mutating func add(_ binding: Binding) {
        bindings.removeAll { $0.keys == binding.keys }
        bindings.append(binding)
    }

    public mutating func remove(_ keys: [Key]) {
        bindings.removeAll { $0.keys == keys }
    }

    public func command(for keys: [Key]) -> C? {
        bindings.last { $0.keys == keys }?.command
    }

    /// Key sequences bound to `command`, for menus and help.
    public func keys(for command: C) -> [[Key]] {
        bindings.filter { $0.command == command }.map(\.keys)
    }

    public static func parse(_ text: String) -> (keymap: Keymap, issues: [Issue]) {
        overlaid(text, over: Keymap())
    }

    /// `text` applied over `base`: its lines replace bindings with the same
    /// keys and `nop` lines remove them, so keys new in a later version of
    /// the defaults reach users whose file predates them.
    public static func overlaid(
        _ text: String,
        over base: Keymap
    ) -> (keymap: Keymap, issues: [Issue]) {
        var keymap = base
        var issues: [Issue] = []
        for entry in KeyValueParser.parse(text) {
            do {
                let keys = try Key.parseSequence(entry.key)
                if entry.value == unbindWord {
                    keymap.remove(keys)
                    continue
                }
                keymap.add(
                    Binding(
                        keys: keys,
                        command: try C.parse(entry.value),
                        text: entry.value
                    )
                )
            } catch {
                issues.append(Issue(line: entry.line, message: "\(error)"))
            }
        }
        return (keymap, issues)
    }
}
