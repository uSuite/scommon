/// An app's settings read from its `key value` config file. Bad lines become
/// issues and leave the default in place, so a typo never stops an app from
/// starting.
public protocol KeyValueSettings: Sendable {
    associatedtype SetError: Error & CustomStringConvertible

    init()

    /// Applies one `key value` pair; `:set` takes the same path.
    mutating func set(_ key: String, _ value: String) throws(SetError)

    /// Written to the config file on first run so the file documents itself.
    static var defaultText: String { get }
}

extension KeyValueSettings {
    public static func parse(_ text: String) -> (config: Self, issues: [LineIssue]) {
        var settings = Self()
        var issues: [LineIssue] = []
        for entry in KeyValueParser.parse(text) {
            do {
                try settings.set(entry.key, entry.value)
            } catch {
                issues.append(LineIssue(line: entry.line, message: error.description))
            }
        }
        return (settings, issues)
    }
}
