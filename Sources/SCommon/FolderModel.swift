import Foundation

/// The sorted image sequence of one folder: data only, no navigation state.
public struct FolderModel: Sendable, Equatable {
    public let folder: URL
    public private(set) var items: [ImageItem]
    public private(set) var order: SortOrder

    public init(
        folder: URL,
        items: [ImageItem],
        order: SortOrder = SortOrder()
    ) {
        self.folder = folder
        self.order = order
        self.items = Sorter.sorted(items, by: order)
    }

    /// Scans `folder`; `recursive` flattens the whole tree under it.
    public static func load(
        _ folder: URL,
        order: SortOrder = SortOrder(),
        recursive: Bool = false
    ) throws -> FolderModel {
        FolderModel(
            folder: folder,
            items: recursive ? try FolderTree.flattened(folder) : try FolderScanner.images(in: folder),
            order: order
        )
    }

    public var count: Int { items.count }
    public var isEmpty: Bool { items.isEmpty }

    public func index(of url: URL) -> Int? {
        let target = url.standardizedFileURL.path
        return items.firstIndex { $0.url.standardizedFileURL.path == target }
    }

    public mutating func sort(by order: SortOrder) {
        self.order = order
        items = Sorter.sorted(items, by: order)
    }

    /// Replaces the contents after a rescan, keeping the current order.
    public mutating func replace(items: [ImageItem]) {
        self.items = Sorter.sorted(items, by: order)
    }
}
