import Foundation

/// Makes a folder readable before an app lists it (DECISIONS 2026-10-31).
/// Outside the sandbox, and inside it for a folder Finder, `open -a` or a
/// panel already granted, the listing just works. Otherwise a remembered
/// bookmark is tried, and only then the user is asked through `ask`, the
/// app's Open panel preset to the folder (AppKit stays in the app); what
/// they choose is remembered, so each folder is asked for once.
public struct FolderAccess: Sendable, Equatable {
    public let bookmarks: Bookmarks

    public init(bookmarks: Bookmarks) {
        self.bookmarks = bookmarks
    }

    /// `folder` once it can be listed, nil when the user declines or picks
    /// a folder that does not hold it.
    @MainActor
    public func ensureReadable(
        _ folder: URL,
        ask: @MainActor (URL) async -> URL?
    ) async -> URL? {
        if Self.canList(folder) {
            return folder
        }
        if bookmarks.startAccess(covering: folder) != nil, Self.canList(folder) {
            return folder
        }
        guard let granted = await ask(folder) else {
            return nil
        }
        try? bookmarks.remember(granted)
        return Self.canList(folder) ? folder : nil
    }

    static func canList(_ folder: URL) -> Bool {
        (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) != nil
    }
}
