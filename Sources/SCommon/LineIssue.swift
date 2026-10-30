/// A problem on one line of a `key value` file (config or keymap), reported
/// without stopping the rest of the file from loading.
public struct LineIssue: Sendable, Equatable, CustomStringConvertible {
    public let line: Int
    public let message: String

    public init(
        line: Int,
        message: String
    ) {
        self.line = line
        self.message = message
    }

    public var description: String { "line \(line): \(message)" }
}
