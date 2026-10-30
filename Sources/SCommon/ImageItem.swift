import Foundation

/// One image file in a folder, with the attributes sorting needs.
public struct ImageItem: Sendable, Hashable {
    public let url: URL
    public let size: Int64
    public let modified: Date
    public let typeIdentifier: String

    public init(
        url: URL,
        size: Int64,
        modified: Date,
        typeIdentifier: String
    ) {
        self.url = url
        self.size = size
        self.modified = modified
        self.typeIdentifier = typeIdentifier
    }

    public var name: String { url.lastPathComponent }
    public var stem: String { url.deletingPathExtension().lastPathComponent }
}
