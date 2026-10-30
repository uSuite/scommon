/// Turns key presses into invocations: count prefixes, multi-key sequences
/// and the vim wait when a binding is also the prefix of a longer one
/// (SV-301, SV-302).
public struct KeyMatcher<C: KeymapCommand>: Sendable {
    public enum Result: Sendable, Equatable {
        /// A binding fired.
        case matched(Invocation<C>)
        /// More keys may follow; show `display` as pending input.
        case pending(display: String)
        /// The keys bound nothing; the pending input was dropped.
        case unmatched
    }

    public private(set) var keymap: Keymap<C>
    private var prefixes: Set<[Key]> = []
    private var pending: [Key] = []
    private var count: Int?

    public init(keymap: Keymap<C>) {
        self.keymap = keymap
        for binding in keymap.bindings where binding.keys.count > 1 {
            for length in 1..<binding.keys.count {
                prefixes.insert(Array(binding.keys.prefix(length)))
            }
        }
    }

    public var isPending: Bool { !pending.isEmpty || count != nil }

    public var display: String {
        (count.map(String.init) ?? "") + pending.map(\.description).joined()
    }

    public mutating func reset() {
        pending = []
        count = nil
    }

    public mutating func feed(_ key: Key) -> Result {
        if pending.isEmpty, key.isDigit, let digit = Int(key.base) {
            if count != nil || (digit != 0 && keymap.command(for: [key]) == nil) {
                let next = (count ?? 0) * 10 + digit
                count = min(next, 99_999)
                return .pending(display: display)
            }
        }
        if key == Key("esc"), isPending {
            reset()
            return .pending(display: "")
        }
        pending.append(key)
        let exact = keymap.command(for: pending)
        if prefixes.contains(pending) {
            return .pending(display: display)
        }
        defer { reset() }
        guard let command = exact else {
            return .unmatched
        }
        return .matched(Invocation(command, count: count))
    }

    /// Resolves a pending sequence that is itself bound, after the UI's
    /// timeout (vim's `timeoutlen`). Clears the pending input either way.
    public mutating func flush() -> Invocation<C>? {
        defer { reset() }
        guard !pending.isEmpty, let command = keymap.command(for: pending) else {
            return nil
        }
        return Invocation(command, count: count)
    }
}
