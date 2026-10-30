import Foundation

/// The shared grammar of the config and keymap files: one entry per line,
/// the first whitespace-separated token is the key, the rest of the line is
/// the value; blank lines and lines starting with `#` are skipped.
public enum KeyValueParser {
    public struct Entry: Sendable, Equatable {
        public let key: String
        public let value: String
        public let line: Int
    }

    public static func parse(_ text: String) -> [Entry] {
        var entries: [Entry] = []
        for (offset, raw) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }
            let key = line.prefix { !$0.isWhitespace }
            let value = line.dropFirst(key.count).trimmingCharacters(in: .whitespaces)
            entries.append(
                Entry(
                    key: String(key),
                    value: value,
                    line: offset + 1
                )
            )
        }
        return entries
    }

    /// Returns `text` with the first active `key` line replaced by
    /// `key value`, or the pair appended when the key is absent. Comments and
    /// the layout of every other line are kept.
    public static func setting(
        _ key: String,
        to value: String,
        in text: String
    ) -> String {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let entry = "\(key) \(value)"
        if let index = lines.firstIndex(where: { parse($0).first?.key == key }) {
            lines[index] = entry
            return lines.joined(separator: "\n")
        }
        if let last = lines.last, last.isEmpty {
            lines.removeLast()
        }
        lines.append(entry)
        return lines.joined(separator: "\n") + "\n"
    }
}
