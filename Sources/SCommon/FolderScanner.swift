import Foundation
import UniformTypeIdentifiers

/// Lists the images and sub-folders of a directory (SV-203).
///
/// Hidden entries (dot files, which covers `._` AppleDouble files) and
/// anything whose type does not conform to `public.image` are skipped.
public enum FolderScanner {
    private static let keys: [URLResourceKey] = [
        .isRegularFileKey,
        .isDirectoryKey,
        .isPackageKey,
        .isHiddenKey,
        .fileSizeKey,
        .contentModificationDateKey,
        .contentTypeKey,
    ]

    public static func isHidden(_ url: URL) -> Bool {
        url.lastPathComponent.hasPrefix(".")
    }

    public static func isImage(_ url: URL) -> Bool {
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return type.conforms(to: .image)
        }
        return UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) ?? false
    }

    /// Image files directly inside `folder`, unsorted.
    public static func images(in folder: URL) throws -> [ImageItem] {
        try entries(of: folder).compactMap { url in
            let values = try url.resourceValues(forKeys: Set(keys))
            guard values.isRegularFile == true,
                values.isHidden != true,
                let type = values.contentType,
                type.conforms(to: .image)
            else {
                return nil
            }
            return ImageItem(
                url: url,
                size: Int64(values.fileSize ?? 0),
                modified: values.contentModificationDate ?? .distantPast,
                typeIdentifier: type.identifier
            )
        }
    }

    /// Visible sub-folders of `folder` in natural name order.
    public static func subfolders(of folder: URL) throws -> [URL] {
        let folders = try entries(of: folder).filter { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            return values?.isDirectory == true
                && values?.isPackage != true
                && values?.isHidden != true
        }
        return folders.sorted { Sorter.naturalLess($0.lastPathComponent, $1.lastPathComponent) }
    }

    /// Entries rebuilt on `folder` itself rather than the URLs the file
    /// manager returns, which may switch `/var` to `/private/var`; keeping the
    /// caller's form lets later path comparisons stay plain string compares.
    private static func entries(of folder: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        )
        .filter { !isHidden($0) }
        .map { folder.appendingPathComponent($0.lastPathComponent) }
    }
}
