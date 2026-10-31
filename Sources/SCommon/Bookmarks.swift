import Foundation

/// Folders the user handed over, kept across launches (DECISIONS
/// 2026-10-31): one `<path>\t<base64 bookmark>` line per folder in
/// `~/.config/<app>/bookmarks`, so a sandboxed app asks once per folder,
/// not once per launch. Security-scoped in the sandbox, plain otherwise,
/// so the same code runs in tests and in a `swift run`.
public struct Bookmarks: Sendable, Equatable {
    public let file: URL
    public let securityScoped: Bool

    public init(
        file: URL,
        securityScoped: Bool = Sandbox.isActive
    ) {
        self.file = file
        self.securityScoped = securityScoped
    }

    public init(
        paths: ConfigPaths,
        securityScoped: Bool = Sandbox.isActive
    ) {
        self.init(
            file: paths.directory.appendingPathComponent("bookmarks"),
            securityScoped: securityScoped
        )
    }

    /// Stores a bookmark for `folder`, replacing one for the same path.
    public func remember(_ folder: URL) throws {
        let options: URL.BookmarkCreationOptions = securityScoped ? [.withSecurityScope] : []
        let data = try folder.bookmarkData(
            options: options,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        var entries = read().filter { $0.path != Self.key(folder) }
        entries.append((Self.key(folder), data))
        try write(entries)
    }

    /// Drops the bookmark for `folder`, if there is one.
    public func forget(_ folder: URL) throws {
        let entries = read()
        let kept = entries.filter { $0.path != Self.key(folder) }
        if kept.count != entries.count {
            try write(kept)
        }
    }

    /// The remembered folders, as stored.
    public var folders: [String] {
        read().map(\.path)
    }

    /// The remembered folder that is `url` or holds it, the deepest when
    /// several do, resolved. A stale bookmark is renewed; one that no
    /// longer resolves is dropped. Access is not started.
    public func folder(covering url: URL) -> URL? {
        let target = Self.key(url)
        let candidates = read()
            .filter { target == $0.path || target.hasPrefix($0.path.hasSuffix("/") ? $0.path : $0.path + "/") }
            .sorted { $0.path.count > $1.path.count }
        for candidate in candidates {
            if let resolved = resolve(candidate) {
                return resolved
            }
        }
        return nil
    }

    /// Starts access to the remembered folder covering `url` and returns
    /// it; the access lasts until the caller stops it or the app quits,
    /// which is what a window showing that folder wants.
    public func startAccess(covering url: URL) -> URL? {
        guard let folder = folder(covering: url) else {
            return nil
        }
        if securityScoped {
            _ = folder.startAccessingSecurityScopedResource()
        }
        return folder
    }

    /// Runs `body` with access to the remembered folder covering `url`;
    /// nil when there is none.
    public func withAccess<T>(
        to url: URL,
        _ body: (URL) throws -> T
    ) rethrows -> T? {
        guard let folder = startAccess(covering: url) else {
            return nil
        }
        defer {
            if securityScoped {
                folder.stopAccessingSecurityScopedResource()
            }
        }
        return try body(folder)
    }

    private func resolve(_ entry: (path: String, data: Data)) -> URL? {
        let options: URL.BookmarkResolutionOptions = securityScoped ? [.withSecurityScope, .withoutUI] : [.withoutUI]
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: entry.data,
            options: options,
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ), FileManager.default.fileExists(atPath: url.path) else {
            try? forget(URL(fileURLWithPath: entry.path))
            return nil
        }
        if stale {
            let started = securityScoped && url.startAccessingSecurityScopedResource()
            try? remember(url)
            if started {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return url
    }

    private func read() -> [(path: String, data: Data)] {
        guard let text = try? String(contentsOf: file, encoding: .utf8) else {
            return []
        }
        return text.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "\t", maxSplits: 1)
            guard parts.count == 2, let data = Data(base64Encoded: String(parts[1])) else {
                return nil
            }
            return (String(parts[0]), data)
        }
    }

    private func write(_ entries: [(path: String, data: Data)]) throws {
        try FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let text = entries.map { "\($0.path)\t\($0.data.base64EncodedString())\n" }.joined()
        try Data(text.utf8).write(to: file, options: .atomic)
    }

    static func key(_ url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().path
    }
}
