import Foundation

/// Where an s-app keeps its files: `$XDG_CONFIG_HOME/<app>/` when set,
/// `~/.config/<app>/` otherwise, and nowhere else. `config` and `keymap`
/// are plain `key value` text; `state.json` is disposable.
public struct ConfigPaths: Sendable, Equatable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public init(
        app: String,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        home: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        let base: URL
        if let xdg = environment["XDG_CONFIG_HOME"], xdg.hasPrefix("/") {
            base = URL(fileURLWithPath: xdg, isDirectory: true)
        } else {
            base = home.appendingPathComponent(".config", isDirectory: true)
        }
        directory = base.appendingPathComponent(app, isDirectory: true)
    }

    public var config: URL { directory.appendingPathComponent("config") }
    public var keymap: URL { directory.appendingPathComponent("keymap") }
    public var state: URL { directory.appendingPathComponent("state.json") }

    /// Creates the directory and writes any missing default file. Existing
    /// files are never touched.
    public func ensureDefaults(
        config configText: String,
        keymap keymapText: String
    ) throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        for (url, text) in [(config, configText), (keymap, keymapText)]
        where !FileManager.default.fileExists(atPath: url.path) {
            try Data(text.utf8).write(to: url, options: .atomic)
        }
    }

    /// The settings in the config file, defaults when it is missing.
    public func load<Settings: KeyValueSettings>(_ type: Settings.Type) -> (config: Settings, issues: [LineIssue]) {
        guard let text = try? String(contentsOf: config, encoding: .utf8) else {
            return (Settings(), [])
        }
        return Settings.parse(text)
    }

    /// `:set` path: validates against `type`, then rewrites only that line
    /// of the file, keeping comments and layout.
    public func persist<Settings: KeyValueSettings>(
        _ key: String,
        _ value: String,
        as type: Settings.Type
    ) throws {
        var probe = Settings()
        try probe.set(key, value)
        let text = (try? String(contentsOf: config, encoding: .utf8)) ?? Settings.defaultText
        let updated = KeyValueParser.setting(key, to: value, in: text)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try Data(updated.utf8).write(to: config, options: .atomic)
    }
}
