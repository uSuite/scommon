import Foundation

/// Moves between folders: siblings, parent, children, and the recursive
/// flattening of a tree into one sequence (SV-204, SV-205).
public enum FolderTree {
    public static func parent(of folder: URL) -> URL? {
        let standard = folder.standardizedFileURL
        let parent = standard.deletingLastPathComponent().standardizedFileURL
        return parent.path == standard.path ? nil : parent
    }

    /// The sibling `offset` steps away from `folder` in natural order,
    /// skipping siblings without images when `skipEmpty` is set. A count past
    /// the end stops at the last sibling reached; `nil` when none was.
    public static func sibling(
        of folder: URL,
        offset: Int,
        skipEmpty: Bool = true
    ) throws -> URL? {
        guard offset != 0, let parent = parent(of: folder) else {
            return nil
        }
        let siblings = try FolderScanner.subfolders(of: parent)
        let name = folder.standardizedFileURL.lastPathComponent
        guard var index = siblings.firstIndex(where: { $0.lastPathComponent == name }) else {
            return nil
        }
        let step = offset > 0 ? 1 : -1
        var remaining = abs(offset)
        var found: URL?
        while remaining > 0 {
            index += step
            guard siblings.indices.contains(index) else {
                break
            }
            let candidate = siblings[index]
            if skipEmpty, !hasImages(candidate) {
                continue
            }
            found = candidate
            remaining -= 1
        }
        return found
    }

    public static func hasImages(_ folder: URL) -> Bool {
        (try? FolderScanner.images(in: folder).isEmpty == false) ?? false
    }

    /// The first descendant of `folder`, depth first in natural order, that
    /// contains images; `folder` itself when it has images.
    public static func firstFolderWithImages(under folder: URL) throws -> URL? {
        if hasImages(folder) {
            return folder
        }
        for child in try FolderScanner.subfolders(of: folder) {
            if let found = try firstFolderWithImages(under: child) {
                return found
            }
        }
        return nil
    }

    /// All images under `root`, depth first, folders in natural order.
    public static func flattened(_ root: URL) throws -> [ImageItem] {
        var result = try FolderScanner.images(in: root)
        for child in try FolderScanner.subfolders(of: root) {
            result += try flattened(child)
        }
        return result
    }
}
